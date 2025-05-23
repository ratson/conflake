{ lib, lib' }:

let
  inherit (builtins)
    all
    head
    isAttrs
    isPath
    isString
    length
    match
    storeDir
    ;
  inherit (lib)
    composeManyExtensions
    filter
    fix
    flip
    functionArgs
    getExe
    getFiles
    getValues
    id
    isDerivation
    isFunction
    isStringLike
    mergeAttrs
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
    enum
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
  inherit (lib') callWith;
  inherit (lib'.debug) mkTestFromList;

  isStorePath = s: match "${storeDir}/[^.][^ \n]*" s != null;

  mkApp =
    s:
    { name, pkgs }:
    {
      program = if isStorePath s then s else "${pkgs.writeShellScript "app-${name}" s}";
    };
in
fix (
  types':
  let
    inherit (types')
      check
      function
      functionTo
      loader
      matcher
      nonFunction
      nullable
      optCallWith
      optFunctionTo
      optListOf
      optPkgs
      outputsValue
      path
      pathTree
      stringLike
      test
      ;
  in
  {
    app = pipe "app" [
      (default: {
        options = {
          type = mkOption {
            inherit default;
            type = enum [ default ];
          };
          program = mkOption {
            type = types.pathInStore // {
              check = isStorePath;
            };
          };
        };
      })
      submodule
      optFunctionTo
      (coercedTo (optFunctionTo unspecified) (
        value:
        let
          f' =
            { name, pkgs, ... }@args:
            let
              value' = callWith args value { };
            in
            if isStringLike value' then mkApp value' { inherit name pkgs; } else value';
          fargs = functionArgs value // (functionArgs f');
        in
        if isFunction value then setFunctionArgs f' fargs else value
      ))
      (coercedTo stringLike mkApp)
    ];

    apps = optPkgs (lazyAttrsOf types'.app);

    bundler = function;

    bundlers = optPkgs (lazyAttrsOf types'.bundler);

    check = pipe types'.package [
      (coercedTo (optFunctionTo str) (
        value: if isString value then lib'.loaders.mkCheck { } value else value
      ))
    ];

    checks = optPkgs (lazyAttrsOf check);

    devShell = pipe unspecified [
      optPkgs
      lazyAttrsOf
      (freeformType: {
        inherit freeformType;

        options = {
          stdenv = mkOption {
            type = optFunctionTo package;
            default = { pkgs, ... }: pkgs.stdenv;
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
    ];

    drv = types.package // {
      name = "drv";
      description = "derivation";
      check = isDerivation;
    };

    fileset = mkOptionType {
      name = "fileset";
      description = "fileset";
      descriptionClass = "noun";
      check = x: isPath x || x._type or null == "fileset";
    };

    formatters = pipe str [
      optPkgs
      (coercedTo types.package getExe)
      lazyAttrsOf
      optPkgs
    ];

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

          substSubModules = m: types'.functionTo (super.nestedTypes.elemType.substSubModules m);
        }
      )
    ];

    inputs = lazyAttrsOf raw;

    loader = functionTo unspecified;

    loaders = lazyAttrsOf loader;

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

    package = optPkgs types.package;

    path = types.path // {
      check = isPath;
    };

    pathTree = lazyAttrsOf (either path pathTree);

    optCallWith =
      args:
      flip pipe [
        (coercedTo function (x: x args))
      ];

    optFunctionTo = flip pipe [
      functionTo
      (coercedTo nonFunction (x: _: x))
    ];

    optListOf = elemType: coercedTo elemType singleton (listOf elemType);

    optPkgs = flip pipe [
      functionTo
      (coercedTo unspecified (f: if functionArgs f == { } then { pkgs, ... }: f pkgs else f))
      (coercedTo nonFunction (x: _: x))
    ];

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

    stringLike = str // {
      name = "stringLike";
      description = "string-convertible value";
      check = isStringLike;
    };

    systems = pipe (uniq (listOf nonEmptyStr)) [
      (coercedTo types.package import)
    ];

    templateModule = submodule (
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

    template =
      args:
      pipe types'.templateModule [
        (optCallWith args)
      ];

    templates =
      args:
      pipe (lazyAttrsOf (types'.template args)) [
        (optCallWith args)
      ];

    test = pipe (lazyAttrsOf raw) [
      (coercedTo (nonEmptyListOf raw) mkTestFromList)
    ];

    tests = pipe test [
      lazyAttrsOf
      optListOf
      optFunctionTo
    ];
  }
)
