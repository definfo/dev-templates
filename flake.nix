{
  description = "Ready-made templates for easily creating flake-driven environments";

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
          scriptDrvs =
            let
              forEachDir = exec: ''
                for dir in */; do
                  (
                    cd "''${dir}"

                    ${exec}
                  )
                done
              '';
            in
            {
              # only run this locally, as Actions will run out of disk space
              build = pkgs.writeShellApplication {
                name = "build";
                text = ''
                  ${forEachDir ''
                    echo "building ''${dir}"
                    nix build .#devShells.${system}.default
                  ''}
                '';
              };

              check = pkgs.writeShellApplication {
                name = "check";
                text = forEachDir ''
                  echo "checking ''${dir}"
                  nix flake check --all-systems --no-build
                '';
              };

              update = pkgs.writeShellApplication {
                name = "update";
                text = forEachDir ''
                  echo "updating ''${dir}"
                  nix flake update
                '';
              };
            };
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
            shellHook = ''
              ${config.pre-commit.installationScript}
              echo 1>&2 "Welcome to the development shell!"
            '';
            packages =
              with scriptDrvs;
              [
                build
                check
                update
              ]
              ++ config.pre-commit.settings.enabledPackages;
          };
        };
      flake = {
        templates = rec {
          c-cpp = {
            path = ./c-cpp;
            description = "C/C++ development environment";
          };

          coq = {
            path = ./coq;
            description = "Rocq(Coq) development environment";
          };

          java = {
            path = ./java;
            description = "Java development environment";
          };

          kotlin = {
            path = ./kotlin;
            description = "Kotlin development environment";
          };

          latex = {
            path = ./latex;
            description = "LaTeX development environment";
          };

          markdown = {
            path = ./markdown;
            description = "Markdown development environment";
          };

          node = {
            path = ./node;
            description = "Node.js development environment";
          };

          ocaml = {
            path = ./ocaml;
            description = "OCaml development environment";
          };

          rust = {
            path = ./rust;
            description = "Rust development environment";
          };

          scala = {
            path = ./scala;
            description = "Scala development environment";
          };

          shell = {
            path = ./shell;
            description = "Shell script development environment";
          };

          tauri = {
            path = ./tauri;
            description = "Tauri development environment";
          };

          typst = {
            path = ./typst;
            description = "Typst development environment";
          };

          # Aliases
          c = c-cpp;
          cpp = c-cpp;
          cxx = c-cpp;
          md = markdown;
          js = node;
          nodejs = node;
          rocq = coq;
          tex = latex;
        };
      };
    };
}
