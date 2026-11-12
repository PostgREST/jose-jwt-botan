{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [ inputs.haskell-flake.flakeModule ];

      perSystem = { self', pkgs, ... }:
        let
          checkedShellScript = pkgs.callPackage ./nix/overlays/checked-shell-script.nix { };
          genCtags = pkgs.callPackage ./nix/tools/devTools.nix { inherit checkedShellScript; };
          withTools = pkgs.callPackage ./nix/tools/withTools.nix { inherit checkedShellScript; };
          loadtestJwt = pkgs.callPackage ./nix/tools/loadtest.nix { inherit checkedShellScript withTools; };
        in
        {

        # Typically, you just want a single project named "default". But
        # multiple projects are also possible, each using different GHC version.
        haskellProjects.default = {
          # The base package set representing a specific GHC version.
          # By default, this is pkgs.haskellPackages.
          # You may also create your own. See https://community.flake.parts/haskell-flake/package-set
          # basePackages = pkgs.haskellPackages;

          # Extra package information. See https://community.flake.parts/haskell-flake/dependency
          #
          # Note that local packages are automatically included in `packages`
          # (defined by `defaults.packages` option).
          #
          packages = {
            # aeson.source = "1.5.0.0";      # Override aeson to a custom version from Hackage
            # shower.source = inputs.shower; # Override shower to a custom source path
          };
          settings = {
            #  aeson = {
            #    check = false;
            #  };
            #  relude = {
            #    haddock = false;
            #    broken = false;
            #  };
          };

          devShell = {
            mkShellArgs = {
              buildInputs = [ pkgs.botan3 ];
              nativeBuildInputs = [ pkgs.pkg-config ];
            };
            tools = _: {
              postgrest-gen-ctags = genCtags.bin;
              postgrest-loadtest-jwt = loadtestJwt.bin;
            };
            # Enabled by default
            # enable = true;

            # Programs you want to make available in the shell.
            # Default programs can be disabled by setting to 'null'
            # tools = hp: { fourmolu = hp.fourmolu; ghcid = null; };

            # Check that haskell-language-server works
            # hlsCheck.enable = true; # Requires sandbox to be disabled
          };
        };

        # haskell-flake doesn't set the default package, but you can do it here.
        packages.default = self'.packages.jose-jwt-botan;
      };
    };
}
