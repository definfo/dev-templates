{
  description = "A Nix-flake-based Tauri development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    rust-overlay.url = "github:oxalica/rust-overlay";
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
              inputs.rust-overlay.overlays.default
              (_final: prev: {
                rustToolchain =
                  let
                    rust = prev.rust-bin;
                  in
                  if builtins.pathExists ./rust-toolchain.toml then
                    rust.fromRustupToolchainFile ./rust-toolchain.toml
                  else if builtins.pathExists ./rust-toolchain then
                    rust.fromRustupToolchainFile ./rust-toolchain
                  else
                    rust.stable.latest.default.override {
                      extensions = [
                        "rust-src"
                        "rust-analyzer"
                      ];
                    };
              })
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
              autocorrect.enable = true;
              biome.enable = true;
              nixfmt.enable = true;
              rustfmt.enable = true;
            };
          };

          # https://flake.parts/options/git-hooks-nix.html
          # Example: https://github.com/cachix/git-hooks.nix/blob/master/template/flake.nix
          pre-commit.settings.hooks = {
            /*
              clippy = {
                enable = true;
                packageOverrides = {
                  cargo = pkgs.rustToolchain;
                  clippy = pkgs.rustToolchain;
                };
                settings = {
                  allFeatures = true;
                  denyWarnings = true;
                };
              };
            */
            commitizen.enable = true;
            eclint.enable = true;
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

            packages =
              with pkgs;
              [
                # Rust toolchain
                rustToolchain
                openssl
                pkg-config
                # rustPlatform.bindgenHook

                nodejs
                pnpm
                yarn
                # yarn-berry
              ]
              ++ lib.optionals stdenv.hostPlatform.isLinux [
                glib-networking
                # Tauri v1
                gtk3
                libsoup_2_4
                webkitgtk_4_0
                # Tauri v2
                # gtk4
                # libsoup_3
                # webkitgtk_4_1
              ];
          };
        };
    };
}
