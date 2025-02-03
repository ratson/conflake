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
    flip
    functionArgs
    getFiles
    getValues
    id
    isDerivation
    isFunction
    isStringLike
    last
    mergeAttrs
    mergeDefinitions
    mkOption
    mkOptionType
    pipe
    setFunctionArgs
    showFiles
    showOption
    singleton
    types
    zipAttrsWith
    ;
  inherit (lib.types)
    bool
    coercedTo
    defaultFunctor
    either
    lazyAttrsOf
    lines
    listOf
    nonEmptyListOf
    nonEmptyStr
    nullOr
    optionDescriptionPhrase
    package
    raw
    str
    submodule
    uniq
    unspecified
    ;
  inherit (lib.options) mergeOneOption;
  inherit (lib') callMustWith callWith mkCheck;
  inherit (lib'.debug) mkTestFromList;
in
fix (
  types':
  let
    inherit (types')
      check
      coercedTo'
      devShell
      drv
      function
      functionTo
      matcher
      nonFunction
      nullable
      optFunctionTo
      optListOf
      outputsValue
      overlay
      path
      pathTree
      stringLike
      test
      ;
  in
  {
    bundler = functionTo unspecified;

    bundlers = optFunctionTo (lazyAttrsOf types'.bundler);

    check =
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
          loc: defs:
          { pkgs, config }:
          let
            coerceFunc = mkCheck (last loc) pkgs src;
            targetType = coercedTo' stringLike coerceFunc drv;
          in
          pipe defs [
            (map (fn: {
              inherit (fn) file;
              value =
                if isFunction fn.value then
                  pipe fn.value [
                    (callMustWith pkgs)
                    (callWith config.systemArgsFor.${pkgs.stdenv.hostPlatform.system})
                    (callWith { inherit pkgs; })
                    (f: f { })
                  ]
                else
                  fn.value;
            }))
            (mergeDefinitions loc targetType)
            (x: x.mergedValue)
          ];
      };

    checks = src: optFunctionTo (lazyAttrsOf (check src));

    coercedTo' =
      coercedType: coerceFunc: finalType:
      mergeAttrs (coercedTo coercedType coerceFunc finalType) {
        merge =
          loc: defs:
          let
            coerceVal = val: if finalType.check val then val else coerceFunc val;
          in
          finalType.merge loc (map (def: def // { value = coerceVal def.value; }) defs);
      };

    devShell = pipe (lazyAttrsOf (optFunctionTo unspecified)) [
      (freeformType: {
        inherit freeformType;

        options = {
          stdenv = mkOption {
            type = optFunctionTo package;
            default = { pkgs }: pkgs.stdenv;
          };

          overrideShell = mkOption {
            internal = true;
            type = nullable package;
            default = null;
          };
        };
      })
      submodule
      (coercedTo package (p: {
        overrideShell = p;
      }))
      optFunctionTo
      (coercedTo (functionTo unspecified) (
        fn: pkgs:
        let
          val = pkgs.callPackage fn { };
        in
        if (functionArgs fn == { }) || !(package.check val) then fn pkgs else val
      ))
    ];

    devShells = lazyAttrsOf devShell;

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

    formatters = optFunctionTo (lazyAttrsOf str);

    function = mkOptionType {
      name = "function";
      description = "function";
      descriptionClass = "noun";
      check = isFunction;
      merge = mergeOneOption;
    };

    /**
      Like `lib.types.functionTo`, but keep `functionArgs`
      instead of turn it to be `{}`.
    */
    functionTo = flip pipe [
      types.functionTo
      (
        super:
        mergeAttrs super {
          merge =
            loc: defs:
            let
              fargs = pipe defs [
                (map (def: def.value))
                (map functionArgs)
                (zipAttrsWith (_: all id))
              ];
              f = super.merge loc defs;
            in
            if fargs == { } then f else setFunctionArgs f fargs;
        }
      )
    ];

    inputs = lazyAttrsOf raw;

    legacyPackages = functionTo (lazyAttrsOf (either (lazyAttrsOf raw) raw));

    loader = functionTo unspecified;

    matcher = pipe (functionTo bool) [
      (coercedTo (either path str) (
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
      ))
    ];

    matchers = listOf matcher;

    module = mkOptionType {
      name = "module";
      description = "module";
      descriptionClass = "noun";
      check = x: isPath x || isFunction x || isAttrs x;
      merge = _: defs: { imports = getValues defs; };
    };

    nonFunction = mkOptionType {
      name = "nonFunction";
      description = "non-function";
      descriptionClass = "noun";
      check = x: !isFunction x;
      merge = mergeOneOption;
    };

    /**
      `lib.types.nullOr`'s merge function requires definitions
      to all be null or all be non-null.

      It was being used where the intent was that null be used as a
      value representing unset, and as such the merge should return null
      if all definitions are null and ignore nulls otherwise.

      This adds a type with that merge semantics.
    */
    nullable =
      elemType:
      mergeAttrs (nullOr elemType) {
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

    package = optFunctionTo types.package;

    packages = optFunctionTo (lazyAttrsOf types'.package);

    path = types.path // {
      check = isPath;
    };

    pathTree = lazyAttrsOf (either path pathTree);

    perSystem = functionTo types'.outputs;

    optCallWith = args: elemType: coercedTo function (x: x args) elemType;

    optFunctionTo = elemType: coercedTo nonFunction (x: _: x) (functionTo elemType);

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

    stringLike = str // {
      name = "stringLike";
      description = "string-convertible value";
      check = isStringLike;
    };

    systems = pipe (uniq (listOf nonEmptyStr)) [
      (coercedTo types.package import)
    ];

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

    test = pipe (lazyAttrsOf raw) [
      (coercedTo (nonEmptyListOf raw) mkTestFromList)
    ];

    tests = lazyAttrsOf test;
  }
)
