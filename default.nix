inputs:

let
  inherit (builtins) all attrNames head isAttrs isPath length mapAttrs readDir;
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;
  inherit (lib) composeManyExtensions evalModules filter fix
    genAttrs getFiles getValues hasSuffix isDerivation isFunction
    isStringLike mkDefault mkOptionType pathExists pipe
    removePrefix removeSuffix showFiles showOption singleton;
  inherit (lib.types) coercedTo defaultFunctor functionTo lazyAttrsOf listOf
    optionDescriptionPhrase;
  inherit (lib.options) mergeEqualOption mergeOneOption;

  baseModules = import ./modules/module-list.nix;

  mkOutputs = {
    __functor = self: src: module: (evalModules {
      modules = baseModules ++ self.extraModules ++ [
        {
          inputs.nixpkgs = mkDefault nixpkgs;
          inputs.conflake = mkDefault inputs.self;
        }
        module
      ];
      specialArgs = {
        inherit conflake src;

        modulesPath = ./modules;
      };
    }).config.outputs;

    # Attributes to allow module flakes to extend mkOutputs
    extraModules = [ ];
    extend = (fix (extend': mkOutputs': modules: fix (self: mkOutputs' // {
      extraModules = mkOutputs'.extraModules ++ modules;
      extend = extend' self;
    }))) mkOutputs;
  };

  conflake = {
    inherit importDir mkOutputs selectAttr types;
  };

  types = rec {
    coercedTo' = coercedType: coerceFunc: finalType:
      (coercedTo coercedType coerceFunc finalType) // {
        merge = loc: defs:
          let
            coerceVal = val:
              if finalType.check val then val
              else coerceFunc val;
          in
          finalType.merge loc
            (map (def: def // { value = coerceVal def.value; }) defs);
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
    nullable = elemType: mkOptionType {
      name = "nullable";
      description = "nullable ${optionDescriptionPhrase
        (class: class == "noun" || class == "composite") elemType}";
      descriptionClass = "noun";
      check = x: x == null || elemType.check x;
      merge = loc: defs:
        if all (def: def.value == null) defs then null
        else elemType.merge loc (filter (def: def.value != null) defs);
      emptyValue.value = null;
      inherit (elemType) getSubOptions getSubModules;
      substSubModules = m: nullable (elemType.substSubModules m);
      functor = (defaultFunctor "nullable") // {
        type = nullable;
        wrapped = elemType;
      };
      nestedTypes = { inherit elemType; };
    };

    packageDef = mkOptionType {
      name = "packageDef";
      description = "package definition";
      descriptionClass = "noun";
      check = isFunction;
      merge = mergeOneOption;
    };

    path = mkOptionType {
      name = "path";
      description = "path";
      descriptionClass = "noun";
      check = isPath;
      merge = mergeEqualOption;
    };

    optCallWith = args: elemType: coercedTo function (x: x args) elemType;

    optFunctionTo =
      let
        nonFunction = mkOptionType {
          name = "nonFunction";
          description = "non-function";
          descriptionClass = "noun";
          check = x: ! isFunction x;
          merge = mergeOneOption;
        };
      in
      elemType: coercedTo nonFunction (x: _: x)
        (functionTo elemType);
    optListOf = elemType: coercedTo elemType singleton (listOf elemType);

    outputs = lazyAttrsOf outputsValue;

    outputsValue = mkOptionType {
      name = "outputs";
      description = "outputs value";
      descriptionClass = "noun";
      merge = loc: defs:
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
  };

  importDir = path: genAttrs
    (pipe (readDir path) [
      attrNames
      (filter (s: s != "default.nix"))
      (filter (s: (hasSuffix ".nix" s)
        || pathExists (path + "/${s}/default.nix")))
      (map (removeSuffix ".nix"))
      (map (removePrefix "_"))
    ])
    (p: import (path +
      (if pathExists (path + "/_${p}.nix") then "/_${p}.nix"
      else if pathExists (path + "/${p}.nix") then "/${p}.nix"
      else "/${p}")));

  selectAttr = attr: mapAttrs (_: v: v.${attr} or { });
in
conflake
