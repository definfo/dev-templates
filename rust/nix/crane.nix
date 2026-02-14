{
  craneLib,
  pkgs,
  lib,
  ...
}:
rec {
  # TODO: decouple with filepath
  src = craneLib.cleanCargoSource ../.;
  commonArgs = {
    inherit src;
    strictDeps = true;

    buildInputs = lib.optionals pkgs.stdenv.isDarwin [
      # Additional darwin specific inputs can be set here
      pkgs.libiconv
    ];

    # Additional environment variables can be set directly
    # MY_CUSTOM_VAR = "some value";
  };

  # Build *just* the cargo dependencies, so we can reuse
  # all of that work (e.g. via cachix) when running in CI
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  # Build the actual crate itself, reusing the dependency
  # artifacts from above.
  my-crate = craneLib.buildPackage (
    commonArgs
    // {
      inherit cargoArtifacts;
    }
  );
}
