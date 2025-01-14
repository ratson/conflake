{
  config,
  src,
  lib,
  inputs,
  conflake,
  flakePath,
  moduleArgs,
  ...
}:

let
  inherit (builtins) isList;
  inherit (lib) mkOption mkOrder optionalAttrs;
  inherit (lib.types) listOf oneOf str;
  inherit (conflake.types) nullable;

  rootConfig = config;
in
{
  options = {
    description = mkOption {
      type = nullable str;
      default =
        if (config.srcEntries."flake.nix" or "") == "regular" then
          (import flakePath).description or null
        else
          null;
    };

    license = mkOption {
      type = nullable (oneOf [
        str
        (listOf str)
      ]);
      default = null;
    };
  };

  config.final =
    { config, ... }:
    {
      config.withOverlays = mkOrder 10 (
        final: prev:
        let
          inherit (config) mkSystemArgs' outputs;
          inherit (prev.stdenv.hostPlatform) system;
          inherit (rootConfig) description license systems;

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
    };
}
