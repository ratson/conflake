{
  config,
  src,
  lib,
  conflake,
  genSystems,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    isFunction
    last
    mergeDefinitions
    mkIf
    mkOption
    mkOptionType
    ;
  inherit (lib.types) lazyAttrsOf optionDescriptionPhrase;
  inherit (conflake) mkCheck;
  inherit (conflake.types)
    coercedTo'
    drv
    nullable
    optFunctionTo
    stringLike
    ;

  checkType = mkOptionType {
    name = "checkType";
    description =
      let
        targetDesc = optionDescriptionPhrase (class: class == "noun" || class == "composite") (
          coercedTo' stringLike (abort "") drv
        );
      in
      "${targetDesc} or function that evaluates to it";
    descriptionClass = "composite";
    check = x: isFunction x || drv.check x || stringLike.check x;
    merge =
      loc: defs: pkgs:
      let
        targetType = coercedTo' stringLike (mkCheck (last loc) pkgs src) drv;
      in
      (mergeDefinitions loc targetType (
        map (fn: {
          inherit (fn) file;
          value = if isFunction fn.value then fn.value pkgs else fn.value;
        }) defs
      )).mergedValue;
  };
in
{
  options.checks = mkOption {
    type = nullable (optFunctionTo (lazyAttrsOf checkType));
    default = null;
  };

  config = mkIf (config.checks != null) {
    outputs.checks = genSystems (pkgs: mapAttrs (_: v: v pkgs) (config.checks pkgs));
  };
}
