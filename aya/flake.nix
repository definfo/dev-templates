{
  description = "A Nix-flake-based Aya development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    # TODO: switch to upstream repo
    # aya-dev.url = "github:aya-prover/aya-dev";
    aya-dev.url = "github:definfo/aya-dev/nix";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    # See https://flake.parts/module-arguments for module arguments
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
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
