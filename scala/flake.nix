{
  description = "A Nix-flake-based Scala development environment";

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
        let
          javaVersion = 21; # Change this value to update the whole stack
          scalaVersion = 3;
          # scalaVersion = "2_12";
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (_final: prev: rec {
                # inherit (prev) jdk;
                jdk = prev."jdk${toString javaVersion}";
                scala = prev."scala_${toString scalaVersion}" { jre = jdk; };
                sbt = prev.sbt.override { jre = jdk; };
              })
            ];
          };

          # https://flake.parts/options/treefmt-nix.html
          # Example: https://github.com/nix-community/buildbot-nix/blob/main/nix/treefmt/flake-module.nix
          treefmt = {
            projectRootFile = "flake.nix";
            settings.global.excludes = [ ];

            programs = {
              deadnix.enable = true;
              nixfmt.enable = true;
              scalafmt.enable = true;
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
            shellHook = ''
              ${config.pre-commit.installationScript}
              echo 1>&2 "Welcome to the development shell!"
            '';

            packages =
              with pkgs;
              [
                scala
                sbt
                coursier
              ]
              ++ config.pre-commit.settings.enabledPackages;
          };
        };
    };
}
