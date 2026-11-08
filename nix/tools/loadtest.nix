{ cabal-install, checkedShellScript, coreutils, python3Packages, withTools, writers }:
let
  mergeMonitorResults = writers.writePython3 "postgrest-merge-monitor-results" {
    libraries = with python3Packages; [ pandas tabulate ];
  } (builtins.readFile ./merge_monitor_result.py);
in
checkedShellScript {
  name = "postgrest-loadtest-jwt";
  docs = "Loadtest JWT verification with the local jose-jwt library";
  workingDir = "/";
  redirectTixFiles = false;
  withPath = [ coreutils ];
}
''
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT
  output="$tmpdir/report.md"

  ${cabal-install}/bin/cabal v2-build -v0 -f-dev --enable-benchmarks bench:loadtest-jwt
  benchmark=$(${cabal-install}/bin/cabal list-bin -f-dev --enable-benchmarks bench:loadtest-jwt)

  printf "## JWT Verification Loadtest\n\n" >> "$output"

  for algorithm in RS256 ES256 Ed25519; do
    ${withTools.withMonitor} --subseconds "$tmpdir/$algorithm.csv" \
      "$benchmark" --algorithm "$algorithm" +RTS -N1 -RTS >> "$output"
  done

  printf "\n## CPU/MEM usage\n\n" >> "$output"
  printf '%s\n' "$tmpdir"/*.csv | ${mergeMonitorResults} >> "$output"
  cat "$output"
''
