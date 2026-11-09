{ checkedShellScript, ctags, haskellPackages }:
checkedShellScript
  {
    name = "postgrest-gen-ctags";
    docs = "Generate ctags for Haskell and Python code";
    workingDir = "/";
  }
  ''
    ${haskellPackages.haskdogs}/bin/haskdogs
    ${ctags}/bin/ctags -a -R --fields=+l --languages=python --python-kinds=-iv -f ./tags nix/tools/
  ''
