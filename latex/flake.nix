{
  description = "A Nix-flake-based LaTeX development environment";

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
    # See https://flake.parts/module-arguments for module arguments
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        ...
      }:
      {
        imports = [
          inputs.treefmt-nix.flakeModule
          inputs.pre-commit-hooks.flakeModule
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];
        perSystem =
          {
            config,
            pkgs,
            ...
          }:
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
                texfmt.enable = true;
              };
            };

            # https://flake.parts/options/git-hooks-nix.html
            # Example: https://github.com/cachix/git-hooks.nix/blob/master/template/flake.nix
            pre-commit.settings.addGcRoot = true;
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
                  texlive.combined.scheme-full
                  texlab
                  tectonic
                  pandoc
                ]
                ++ config.pre-commit.settings.enabledPackages;
            };
          };
      }
    );
}
