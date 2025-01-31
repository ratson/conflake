{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (builtins) match storeDir;
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
    ;
  inherit (lib.types)
    coercedTo
    enum
    lazyAttrsOf
    optionDescriptionPhrase
    pathInStore
    submoduleWith
    ;
  inherit (conflake.types)
    nullable
    optFunctionTo
    stringLike
    ;

  cfg = config.apps;

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
      type = nullable appType;
      default = null;
    };

    apps = mkOption {
      type = nullable (optFunctionTo (lazyAttrsOf appType));
      default = null;
    };
  };

  config = mkMerge [
    (mkIf (config.app != null) {
      apps.default = config.app;
    })

    (mkIf (cfg != null) {
      outputs.apps = config.callSystemsWithAttrs cfg;
    })
  ];
}
