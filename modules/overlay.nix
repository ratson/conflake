{
  config,
  src,
  lib,
  inputs,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (builtins) isList isPath;
  inherit (lib) mkOption mkOrder optionalAttrs;
  inherit (lib.types) listOf oneOf str;
  inherit (conflake.types) nullable;

  flakePath = config.srcTree."flake.nix" or null;
in
{
  options = {
    description = mkOption {
      type = nullable str;
      default = if isPath flakePath then (import flakePath).description or null else null;
    };

    license = mkOption {
      type = nullable (oneOf [
        str
        (listOf str)
      ]);
      default = null;
    };
  };

  config.withOverlays = mkOrder 10 (
    final: prev:
    let
      inherit (config) mkSystemArgs' outputs;
      inherit (prev.stdenv.hostPlatform) system;
      inherit (config) description license systems;

      getLicense =
        license: final.lib.licenses.${license} or (final.lib.meta.getLicenseFromSpdxId license);
    in
    (mkSystemArgs' prev)
    // {
      inherit
        conflake
        inputs
        moduleArgs
        outputs
        src
        system
        ;

      defaultMeta =
        {
          platforms = systems;
        }
        // optionalAttrs (description != null) {
          inherit description;
        }
        // optionalAttrs (license != null) {
          license = if isList license then map getLicense license else getLicense license;
        };
    }
  );
}
