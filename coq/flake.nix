{
  description = "A Nix-flake-based Rocq(Coq) development environment";

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
          ...
        }:
        let
          coqVersion = "8_15"; # Change this value to update the whole stack
          # coqVersion = "8_20";
          coqPackages = pkgs."coqPackages_${coqVersion}";
        in
        {
          # https://flake.parts/options/treefmt-nix.html
          # Example: https://github.com/nix-community/buildbot-nix/blob/main/nix/treefmt/flake-module.nix
          treefmt = {
            projectRootFile = "flake.nix";
            settings.global.excludes = [ ];

            programs = {
              deadnix.enable = true;
              nixfmt.enable = true;
              statix.enable = true;
            };
          };

          # https://flake.parts/options/git-hooks-nix.html
          # Example: https://github.com/cachix/git-hooks.nix/blob/master/template/flake.nix
          pre-commit.settings.hooks = {
            commitizen.enable = true;
            eclint.enable = true;
            editorconfig-checker.enable = true;
            treefmt.enable = true;
          };

          devShells.default = pkgs.mkShell {
            # TODO: `gradle -Dorg.gradle.java.home=$JAVA_HOME`
            shellHook = ''
              ${config.pre-commit.installationScript}
              echo 1>&2 "Welcome to the development shell!"
            '';

            packages =
              with coqPackages;
              [
                coq
                # For coq.version <= 8.15, use legacy version instead
                # coq-lsp
              ]
              ++ config.pre-commit.settings.enabledPackages;
          };
        };
    };
}
