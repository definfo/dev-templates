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
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (_final: prev: rec {
                inherit (prev) nodejs;
                # nodejs = prev.nodejs_latest;

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
              biome.enable = true;
              deadnix.enable = true;
              # deno.enable = true;
              nixfmt.enable = true;
              statix.enable = true;
              /*
                prettier = {
                  enable = true;
                  # Use Prettier 2.x for CJK pangu formatting
                  package = pkgs.nodePackages.prettier.override {
                    version = "2.8.8";
                    src = pkgs.fetchurl {
                      url = "https://registry.npmjs.org/prettier/-/prettier-2.8.8.tgz";
                      sha512 = "tdN8qQGvNjw4CHbY+XXk0JgCXn9QiF21a55rBe5LJAU+kDyC4WQn4+awm2Xfk2lQMk5fKup9XgzTZtGkjBdP9Q==";
                    };
                  };
                  settings.editorconfig = true;
                };
              */
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
                nodejs
                pnpm
                yarn
                # yarn-berry
              ]
              ++ config.pre-commit.settings.enabledPackages;
          };
        };
    };
}
