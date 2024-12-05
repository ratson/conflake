{
  config,
  src,
  lib,
  outputs,
  conflake,
  mkSpecialArgs,
  moduleArgs,
  ...
}:

let
  inherit (builtins) isList pathExists;
  inherit (lib) mkOption mkOrder optionalAttrs;
  inherit (lib.types) listOf oneOf str;
  inherit (conflake) selectAttr;
  inherit (conflake.types) nullable;

  flakePath = src + /flake.nix;
in
{
  options = {
    description = mkOption {
      type = nullable str;
      default = if pathExists flakePath then (import flakePath).description or null else null;
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
      inherit (prev.stdenv.hostPlatform) system;

      specialArgs = mkSpecialArgs system;

      getLicense =
        license: final.lib.licenses.${license} or (final.lib.meta.getLicenseFromSpdxId license);
    in
    {
      inherit
        system
        moduleArgs
        src
        outputs
        conflake
        ;
      inherit (specialArgs) inputs inputs';

      outputs' = selectAttr system outputs;

      defaultMeta =
        {
          platforms = config.systems;
        }
        // optionalAttrs (config.description != null) {
          inherit (config) description;
        }
        // optionalAttrs (config.license != null) {
          license =
            if isList config.license then map getLicense config.license else getLicense config.license;
        };
    }
  );
}
