{ lib, lib' }:

let
  inherit (builtins)
    all
    head
    isAttrs
    isPath
    isString
    length
    ;
  inherit (lib)
    composeManyExtensions
    filter
    fix
    getFiles
    getValues
    last
    isDerivation
    isFunction
    isStringLike
    mergeDefinitions
    mkOption
    mkOptionType
    pipe
    showFiles
    showOption
    singleton
    types
    ;
  inherit (lib.types)
    bool
    coercedTo
    defaultFunctor
    either
    functionTo
    lazyAttrsOf
    lines
    listOf
    nonEmptyListOf
    nullOr
    optionDescriptionPhrase
    raw
    str
    submodule
    unspecified
    ;
  inherit (lib.options) mergeEqualOption mergeOneOption;
in
fix (
  types':
  let
    inherit (types')
      coercedTo'
      drv
      function
      matcher
      nullable
      optListOf
      outputsValue
      overlay
      path
      pathTree
      stringLike
      ;
  in
  {
    mkCheck =
      src:
      mkOptionType {
        name = "check";
        description = pipe drv [
          (coercedTo' stringLike (abort ""))
          (optionDescriptionPhrase (class: class == "noun" || class == "composite"))
          (targetDesc: "${targetDesc} or function that evaluates to it")
        ];
        descriptionClass = "composite";
        check = x: isFunction x || drv.check x || stringLike.check x;
        merge =
          loc: defs: pkgs:
          let
            coerceFunc = lib'.mkCheck (last loc) pkgs src;
            targetType = coercedTo' stringLike coerceFunc drv;
          in
          pipe defs [
            (map (fn: {
              inherit (fn) file;
              value = if isFunction fn.value then fn.value pkgs else fn.value;
            }))
            (mergeDefinitions loc targetType)
            (x: x.mergedValue)
          ];
      };

    coercedTo' =
      coercedType: coerceFunc: finalType:
      (coercedTo coercedType coerceFunc finalType)
      // {
        merge =
          loc: defs:
          let
            coerceVal = val: if finalType.check val then val else coerceFunc val;
          in
          finalType.merge loc (map (def: def // { value = coerceVal def.value; }) defs);
      };

    drv = mkOptionType {
      name = "drv";
      description = "derivation";
      descriptionClass = "noun";
      check = isDerivation;
      merge = mergeOneOption;
    };

    fileset = mkOptionType {
      name = "fileset";
      description = "fileset";
      descriptionClass = "noun";
      check = x: isPath x || x._type or null == "fileset";
    };

    function = mkOptionType {
      name = "function";
      description = "function";
      descriptionClass = "noun";
      check = isFunction;
      merge = mergeOneOption;
    };

    legacyPackages = lazyAttrsOf (either (lazyAttrsOf raw) raw);

    loader = functionTo unspecified;

    matcher = coercedTo (either path str) (
      value:
      {
        dir,
        path,
        root,
        ...
      }:
      pipe value [
        (x: if isString x then root + /${x} else x)
        (x: x == dir || x == path)
      ]
    ) (functionTo bool);

    matchers = listOf matcher;

    module = mkOptionType {
      name = "module";
      description = "module";
      descriptionClass = "noun";
      check = x: isPath x || isFunction x || isAttrs x;
      merge = _: defs: { imports = getValues defs; };
    };

    # `lib.types.nullOr`'s merge function requires definitions
    # to all be null or all be non-null.
    #
    # It was being used where the intent was that null be used as a
    # value representing unset, and as such the merge should return null
    # if all definitions are null and ignore nulls otherwise.
    #
    # This adds a type with that merge semantics.
    nullable =
      elemType:
      (nullOr elemType)
      // {
        name = "nullable";
        description = "nullable ${
          optionDescriptionPhrase (class: class == "noun" || class == "composite") elemType
        }";
        descriptionClass = "noun";
        merge =
          loc: defs:
          if all (def: def.value == null) defs then
            null
          else
            elemType.merge loc (filter (def: def.value != null) defs);
        substSubModules = m: nullable (elemType.substSubModules m);
        functor = (defaultFunctor "nullable") // {
          type = nullable;
          wrapped = elemType;
        };
      };

    packageDef = mkOptionType {
      name = "packageDef";
      description = "package definition";
      descriptionClass = "noun";
      check = isFunction;
      merge = mergeOneOption;
    };

    path = types.path // {
      check = isPath;
    };

    pathTree = lazyAttrsOf (either path pathTree);

    optCallWith = args: elemType: coercedTo function (x: x args) elemType;

    optFunctionTo =
      let
        nonFunction = mkOptionType {
          name = "nonFunction";
          description = "non-function";
          descriptionClass = "noun";
          check = x: !isFunction x;
          merge = mergeOneOption;
        };
      in
      elemType: coercedTo nonFunction (x: _: x) (functionTo elemType);
    optListOf = elemType: coercedTo elemType singleton (listOf elemType);

    outputs = lazyAttrsOf outputsValue;

    outputsValue = mkOptionType {
      name = "outputs";
      description = "outputs value";
      descriptionClass = "noun";
      merge =
        loc: defs:
        if (length defs) == 1 then
          (head defs).value
        else if all isAttrs (getValues defs) then
          (lazyAttrsOf outputsValue).merge loc defs
        else
          throw "The option `${showOption loc}' has conflicting definitions in ${showFiles (getFiles defs)}";
    };

    overlay = mkOptionType {
      name = "overlay";
      description = "nixpkgs overlay";
      descriptionClass = "noun";
      check = isFunction;
      merge = _: defs: composeManyExtensions (getValues defs);
    };

    overlays = optListOf overlay;

    stringLike = mkOptionType {
      name = "stringLike";
      description = "string-convertible value";
      descriptionClass = "noun";
      check = isStringLike;
      merge = mergeEqualOption;
    };

    template = submodule (
      { name, ... }:
      {
        options = {
          path = mkOption {
            type = nullOr path;
            default = null;
          };
          description = mkOption {
            type = str;
            default = name;
          };
          welcomeText = mkOption {
            type = nullOr lines;
            default = null;
          };
        };
      }
    );

    test = either (lazyAttrsOf raw) (nonEmptyListOf raw);
  }
)
