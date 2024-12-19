inputs:

let
  inherit (builtins)
    all
    head
    intersectAttrs
    isAttrs
    isPath
    length
    listToAttrs
    mapAttrs
    readDir
    ;
  inherit (inputs.nixpkgs) lib;
  inherit (lib)
    attrsToList
    composeManyExtensions
    evalModules
    filter
    fix
    functionArgs
    getFiles
    getValues
    hasSuffix
    isDerivation
    isFunction
    isStringLike
    last
    mapAttrs'
    mergeDefinitions
    mkDefault
    mkEnableOption
    mkOption
    mkOptionType
    nameValuePair
    partition
    pathIsRegularFile
    pipe
    removeSuffix
    setDefaultModuleLocation
    showFiles
    showOption
    singleton
    ;
  inherit (lib.types)
    bool
    coercedTo
    defaultFunctor
    functionTo
    lazyAttrsOf
    lines
    listOf
    nullOr
    optionDescriptionPhrase
    raw
    str
    submodule
    ;
  inherit (lib.options) mergeEqualOption mergeOneOption;

  baseModules = import ./modules/module-list.nix;

  mkOutputs = {
    __functor =
      self: src: module:
      let
        flakePath = src + /flake.nix;
      in
      (evalModules {
        class = "conflake";
        modules =
          baseModules
          ++ self.extraModules
          ++ [
            (setDefaultModuleLocation ./default.nix {
              finalInputs = {
                nixpkgs = mkDefault inputs.nixpkgs;
                conflake = mkDefault inputs.self;
              };
            })
            (setDefaultModuleLocation flakePath module)
          ];
        specialArgs = {
          inherit conflake flakePath src;

          modulesPath = ./modules;
        };
      }).config.outputs;

    # Attributes to allow module flakes to extend mkOutputs
    extraModules = [ ];
    extend =
      (fix (
        extend': mkOutputs': modules:
        fix (
          self:
          mkOutputs'
          // {
            extraModules = mkOutputs'.extraModules ++ modules;
            extend = extend' self;
          }
        )
      ))
        mkOutputs;
  };

  matchers = {
    dir = { type, ... }: type == "directory";
    file = { type, ... }: type == "regular";
  };

  types = rec {
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
            coerceFunc = conflake.mkCheck (last loc) pkgs src;
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

    loader = submodule (
      { name, ... }:
      {
        options = {
          enable = mkEnableOption "${name} loader" // {
            default = true;
          };
          match = mkOption {
            type = functionTo bool;
            default = matchers.dir;
          };
          load = mkOption {
            type = functionTo (lazyAttrsOf raw);
            default = _: { };
          };
          loaders = mkOption {
            type = lazyAttrsOf loader;
            default = { };
          };
        };
      }
    );

    loaders = lazyAttrsOf loader;

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

    path = lib.types.path // {
      check = isPath;
    };

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

    test = lib.types.either (lazyAttrsOf raw) (lib.types.nonEmptyListOf raw);
  };

  callWith =
    autoArgs: fn: args:
    let
      f = if isFunction fn then fn else import fn;
      fargs = functionArgs f;
      allArgs = intersectAttrs fargs autoArgs // args;
    in
    f allArgs;

  callWith' =
    mkAutoArgs: fn: args:
    callWith (mkAutoArgs args) fn args;

  mkCheck =
    name: pkgs: src: cmd:
    pkgs.runCommandLocal "check-${name}" { } ''
      pushd "${src}"
      ${cmd}
      popd
      touch $out
    '';

  readNixDir =
    src:
    pipe src [
      readDir
      attrsToList
      (partition ({ name, value }: value == "regular" && hasSuffix ".nix" name))
      (x: {
        filePairs = x.right;
        dirPairs = filter (
          { name, value }: value == "directory" && pathIsRegularFile (src + /${name}/default.nix)
        ) x.wrong;
      })
      (args: {
        inherit src;
        inherit (args) dirPairs filePairs;

        toAttrs =
          f:
          pipe args.filePairs [
            (map (x: nameValuePair (removeSuffix ".nix" x.name) (f (src + /${x.name}))))
            (x: x ++ (map (x: x // { value = f (src + /${x.name}); }) args.dirPairs))
            listToAttrs
          ];
      })
    ];

  selectAttr = attr: mapAttrs (_: v: v.${attr} or { });

  conflake = {
    inherit
      callWith
      callWith'
      matchers
      mkCheck
      mkOutputs
      readNixDir
      selectAttr
      types
      ;

    inherit (inputs.self.lib.attrsets) prefixAttrs;
    inherit (inputs.self.lib.flake) mkVersion mkVersion';

    loadBlacklist = [
      "_module"
      "inputs"
      "loaders"
      "loadIgnore"
      "moduleArgs"
      "nixDir"
      "nixpkgs"
      "presets"
    ];
  };
in
conflake
