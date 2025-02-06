{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (builtins) isList mapAttrs;
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    optionalAttrs
    pipe
    removeAttrs
    types
    ;
  inherit (lib.types)
    lazyAttrsOf
    listOf
    oneOf
    str
    ;
  inherit (conflake) callWith;
  inherit (conflake.types) nullable;

  cfg = config.packages;
in
{
  options = {
    package = mkOption {
      type = nullable conflake.types.package;
      default = null;
    };

    packages = mkOption {
      type = nullable conflake.types.packages;
      default = null;
    };

    pname = mkOption {
      type = nullable str;
      default = null;
    };
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

    defaultMeta = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default =
        let
          inherit (config) description license;

          getLicense = license: lib.licenses.${license} or (lib.meta.getLicenseFromSpdxId license);
        in
        {
          platforms = config.systems;
        }
        // optionalAttrs (description != null) {
          inherit description;
        }
        // optionalAttrs (license != null) {
          license = if isList license then map getLicense license else getLicense license;
        };
    };
    finalPackages = mkOption {
      internal = true;
      readOnly = true;
      type = lazyAttrsOf (lazyAttrsOf types.package);
      default = config.genSystems (
        { pkgsCall, pkgsCall' }:
        let
          packages = pkgsCall cfg;
          packages' = mapAttrs (
            name: f:
            pipe f [
              (callWith (removeAttrs packages' [ name ]))
              (callWith { inherit name; })
              pkgsCall'
            ]
          ) packages;
        in
        packages'
      );
    };
  };

  config = mkMerge [
    (mkIf (config.package != null) {
      packages.default = config.package;
    })

    (mkIf (cfg != null) {
      outputs.packages = config.finalPackages;
    })
  ];
}
