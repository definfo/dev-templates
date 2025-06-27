{
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
    inputs@{
      flake-parts,
      ...
    }:
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
          lib,
          ...
        }:
        let
          # Use Python 3.13 from nixpkgs
          python = pkgs.python313;

          # Unfree packages
          /*
            cudaVersion = "12_8";
            pkgs-unfree = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
              config.cudaSupport = true;
            };
            inherit (pkgs-unfree.linuxPackages) nvidia_x11;
            inherit (pkgs-unfree."cudaPackages_${cudaVersion}")
              cudatoolkit
              cuda_cudart
              cuda_nvrtc
              cudnn
              nccl
              cutensor
              cusparselt
              ;
          */
        in
        {
          # https://flake.parts/options/treefmt-nix.html
          # Example: https://github.com/nix-community/buildbot-nix/blob/main/nix/treefmt/flake-module.nix
          treefmt = {
            projectRootFile = "flake.nix";
            settings.global.excludes = [ ];

            programs = {
              autocorrect = {
                enable = true;
                includes = [
                  "*.py"
                  "*.ipynb"
                  "*.md"
                ];
              };
              nixfmt.enable = true;
              ruff-format.enable = true;
            };
          };

          # https://flake.parts/options/git-hooks-nix.html
          # Example: https://github.com/cachix/git-hooks.nix/blob/master/template/flake.nix
          pre-commit.settings.hooks = {
            commitizen.enable = true;
            eclint.enable = true;
            markdownlint.enable = true;
            ruff.enable = true;
            treefmt.enable = true;
          };

          # This devShell adds Python and CUDA toolchain.
          /*
            devShells.cuda = pkgs.mkShell rec {
              inputsFrom = [
                config.treefmt.build.devShell
                config.pre-commit.devShell
                ];

              shellHook = ''
                unset PYTHONPATH

                # CUDA-related
                export CUDA_PATH=${cudatoolkit}
                export LD_LIBRARY_PATH="${lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1}:${nvidia_x11}/lib:${lib.makeLibraryPath packages}:$LD_LIBRARY_PATH"
                export EXTRA_LDFLAGS="-L/lib -L${nvidia_x11}/lib"
                export EXTRA_CCFLAGS="-I/usr/include"

                echo 1>&2 "Welcome to the development shell!"
              '';

              packages =
                [
                  python
                  cudatoolkit
                  cuda_cudart
                  cuda_nvrtc
                  cudnn
                  nccl
                  cutensor
                  cusparselt
                  nvidia_x11
                ]
                ++ (with pkgs; [
                  libGLU
                  libGL
                  xorg.libXi
                  xorg.libXmu
                  freeglut
                  xorg.libXv
                  xorg.libXrandr
                  binutils
                  uv
                ]);

              env = {
                # Force uv to use Python interpreter from venv
                UV_PYTHON = python.interpreter;

                # Prevent uv from downloading managed Python's
                UV_PYTHON_DOWNLOADS = "never";
              };
            };
          */

          # It is of course perfectly OK to keep using an impure virtualenv workflow and only use uv2nix to build packages.
          # This devShell simply adds Python and undoes the dependency leakage done by Nixpkgs Python infrastructure.
          devShells.impure = pkgs.mkShell {
            inputsFrom = [
              config.treefmt.build.devShell
              config.pre-commit.devShell
            ];

            shellHook = ''
              unset PYTHONPATH
              echo 1>&2 "Welcome to the development shell!"
            '';

            packages = [
              python
              pkgs.uv
            ];

            env =
              {
                # Force uv to use Python interpreter from venv
                UV_PYTHON = python.interpreter;

                # Prevent uv from downloading managed Python's
                UV_PYTHON_DOWNLOADS = "never";
              }
              // lib.optionalAttrs pkgs.stdenv.isLinux {
                # Python libraries often load native shared objects using dlopen(3).
                # Setting LD_LIBRARY_PATH makes the dynamic library loader aware of libraries without using RPATH for lookup.
                LD_LIBRARY_PATH = lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1;
              };
          };
        };
    };
}
