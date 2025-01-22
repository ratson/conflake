{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (builtins) mapAttrs match storeDir;
  inherit (lib)
    defaultFunctor
    fix
    isFunction
    last
    mergeDefinitions
    mkIf
    mkMerge
    mkOption
    mkOptionType
    types
    ;
  inherit (lib.types)
    coercedTo
    enum
    lazyAttrsOf
    optionDescriptionPhrase
    pathInStore
    submoduleWith
    ;
  inherit (conflake.types) nullable optFunctionTo stringLike;

  rootConfig = config;

  isStorePath = s: match "${storeDir}/[^.][^ \n]*" s != null;

  app = submoduleWith {
    modules = [
      {
        options = {
          type = mkOption {
            type = enum [ "app" ];
            default = "app";
          };
          program = mkOption {
            type = pathInStore // {
              check = isStorePath;
            };
          };
        };
      }
    ];
  };

  mkApp =
    name: pkgs: s:
    let
      s' = "${s}";
    in
    {
      program = if isStorePath s' then s' else "${pkgs.writeShellScript "app-${name}" s'}";
    };

  parameterize = value: fn: fix fn value;

  appType = parameterize app (
    self': app:
    (mkOptionType (
      fix (self: {
        name = "appType";
        description =
          let
            targetDesc = optionDescriptionPhrase (class: class == "noun" || class == "composite") (
              coercedTo stringLike (abort "") app
            );
          in
          "${targetDesc} or function that evaluates to it";
        descriptionClass = "composite";
        check = x: isFunction x || app.check x || stringLike.check x;
        merge =
          loc: defs: pkgs:
          let
            targetType = coercedTo stringLike (mkApp (last loc) pkgs) app;
          in
          (mergeDefinitions loc targetType (
            map (fn: {
              inherit (fn) file;
              value = if isFunction fn.value then fn.value pkgs else fn.value;
            }) defs
          )).mergedValue;
        inherit (app) getSubOptions getSubModules;
        substSubModules = m: self' (app.substSubModules m);
        functor = (defaultFunctor self.name) // {
          wrapped = app;
        };
        nestedTypes.coercedType = stringLike;
        nestedTypes.finalType = app;
      })
    ))
  );
in
{
  options = {
    app = mkOption {
      type = types.unspecified;
      default = null;
    };

    apps = mkOption {
      type = conflake.types.loadable;
      default = null;
    };
  };

  config.final =
    { config, ... }:
    {
      options = {
        app = mkOption {
          type = nullable appType;
          default = null;
        };

        apps = mkOption {
          type = nullable (optFunctionTo (lazyAttrsOf appType));
          default = null;
        };
      };

      config = mkMerge [
        { inherit (rootConfig) app apps; }

        (mkIf (config.app != null) {
          apps.default = config.app;
        })

        (mkIf (config.apps != null) {
          outputs.apps = config.genSystems (pkgs: mapAttrs (_: v: v pkgs) (config.apps pkgs));
        })
      ];
    };
}
