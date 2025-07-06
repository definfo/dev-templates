{
  description = "A Nix-flake-based Node.js development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.pre-commit-hooks.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        # Bun is unsupported due to its fragile offline-mode & lockfile
        let
          nodeVersion = 22; # Change this value to update the whole stack
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (_final: prev: rec {
                # inherit (prev) nodejs;
                nodejs = prev."nodejs_${toString nodeVersion}";

                pnpm = prev.pnpm.override { inherit nodejs; };
                yarn = prev.yarn.override { inherit nodejs; };
                yarn-berry = prev.yarn-berry.override { inherit nodejs; };
              })
            ];
          };

          # https://flake.parts/options/treefmt-nix.html
          # Example: https://github.com/nix-community/buildbot-nix/blob/main/nix/treefmt/flake-module.nix
          treefmt = {
            projectRootFile = "flake.nix";
            settings.global.excludes = [ ];

            programs = {
              autocorrect.enable = true;
              prettier.enable = true;
              nixfmt.enable = true;
            };
          };

          # https://flake.parts/options/git-hooks-nix.html
          # Example: https://github.com/cachix/git-hooks.nix/blob/master/template/flake.nix
          pre-commit.settings.hooks = {
            commitizen.enable = true;
            eclint.enable = true;
            # eslint.enable = true;
            treefmt.enable = true;
          };

          devShells.default = pkgs.mkShell {
            inputsFrom = [
              config.treefmt.build.devShell
              config.pre-commit.devShell
            ];

            shellHook = ''
              echo 1>&2 "Welcome to the development shell!"
            '';

            packages = with pkgs; [
              nodejs
              pnpm
              yarn
              # yarn-berry
            ];
          };
        };
    };
}
