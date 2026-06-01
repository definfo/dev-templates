{
  description = "A Nix-flake-based Aya development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    aya-dev.url = "github:aya-prover/aya-dev";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    # See https://flake.parts/module-arguments for module arguments
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        {
          pkgs,
          system,
          ...
        }:
        let
          inherit (inputs.aya-dev.packages.${system}) ayaPackages;
        in
        {
          # https://flake.parts/options/treefmt-nix.html
          devShells.default = pkgs.mkShell {
            shellHook = ''
              echo 1>&2 "Welcome to the development shell!"
            '';

            packages = with ayaPackages; [
              # aya-minimal
              aya
            ];
          };
        };
    };
}
