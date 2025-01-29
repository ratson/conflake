{
  config,
  src,
  lib,
  inputs,
  conflake,
  moduleArgs,
  outputs,
  ...
}:

let
  inherit (builtins)
    isList
    mapAttrs
    warn
    ;
  inherit (lib) mkOption mkOrder optionalAttrs;
  inherit (lib.types) listOf oneOf str;
  inherit (config) mkSystemArgs';
  inherit (conflake.types) nullable;
in
{
  options = {
    description = mkOption {
      type = nullable str;
      default = config.src.flake.description or null;
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
      inherit (config) description license systems;

      getLicense =
        license: final.lib.licenses.${license} or (final.lib.meta.getLicenseFromSpdxId license);
    in
    (mapAttrs (
      k:
      warn ''
        Usage of `pkgs.${k}` will soon be removed, use `{ pkgs, ${k}, ...}` instead.
        If you have already doing so, ignore this warnning.
      ''
    ))
      (
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
      )
  );
}
