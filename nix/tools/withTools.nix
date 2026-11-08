{ checkedShellScript, python3Packages, writers }:
let
  withMonitor =
    checkedShellScript
      {
        name = "postgrest-with-monitor";
        docs = "Run a command and monitor its CPU and memory usage";
        args = [
          "ARG_OPTIONAL_BOOLEAN([subseconds],, [Sample every 0.1 seconds instead of full seconds])"
          "ARG_POSITIONAL_SINGLE([monitor], [Monitoring CSV file])"
          "ARG_POSITIONAL_SINGLE([command], [Command to run])"
          "ARG_LEFTOVERS([command arguments])"
        ];
        positionalCompletion = "_command";
      }
      ''
        "$_arg_command" "''${_arg_leftovers[@]}" &
        pid=$!

        if [[ "$_arg_subseconds" == "on" ]]; then
          ${monitorPid} --subseconds "$pid" > "$_arg_monitor" &
        else
          ${monitorPid} "$pid" > "$_arg_monitor" &
        fi
        monitor_pid=$!

        wait "$pid"
        wait "$monitor_pid"
      '';

  monitorPid = writers.writePython3 "postgrest-monitor-pid" {
    libraries = [
      python3Packages.pandas
      python3Packages.tabulate
      python3Packages.psutil
    ];
  } (builtins.readFile ./monitor_pid.py);
in
{
  inherit withMonitor monitorPid;
}
