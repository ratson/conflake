inputs:

let
  inherit (builtins) attrNames isAttrs isPath mapAttrs readDir;
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;
  inherit (lib) all composeManyExtensions evalModules filter
    findFirst fix genAttrs getValues hasSuffix isDerivation isFunction isList
    isStringLike mkDefault mkOptionType pathExists pipe
    removePrefix removeSuffix singleton warn;
  inherit (lib.types) coercedTo defaultFunctor functionTo listOf
    optionDescriptionPhrase;
  inherit (lib.options) mergeEqualOption mergeOneOption;

  baseModules = import ./modules/module-list.nix;

  mkOutputs = {
    __functor = self: src: root: (evalModules {
      modules = baseModules ++ self.extraModules ++ [
        { inputs.nixpkgs = mkDefault nixpkgs; }
        { inputs.conflake = mkDefault inputs.self; }
        { _module.args = { inherit src conflake; }; }
        root
      ];
      specialArgs = {
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
    inherit autoImport autoImportArgs importDir mkOutputs selectAttr types;
  };

  types = rec {
    overlay = mkOptionType {
      name = "overlay";
      description = "nixpkgs overlay";
      descriptionClass = "noun";
      check = isFunction;
      merge = _: defs: composeManyExtensions (getValues defs);
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

    function = mkOptionType {
      name = "function";
      description = "function";
      descriptionClass = "noun";
      check = isFunction;
      merge = mergeOneOption;
    };

    drv = mkOptionType {
      name = "drv";
      description = "derivation";
      descriptionClass = "noun";
      check = isDerivation;
      merge = mergeOneOption;
    };

    stringLike = mkOptionType {
      name = "stringLike";
      description = "string-convertible value";
      descriptionClass = "noun";
      check = isStringLike;
      merge = mergeEqualOption;
    };

    module = mkOptionType {
      name = "module";
      description = "module";
      descriptionClass = "noun";
      check = x: isPath x || isFunction x || isAttrs x;
      merge = _: defs: { imports = getValues defs; };
    };

    fileset = mkOptionType {
      name = "fileset";
      description = "fileset";
      descriptionClass = "noun";
      check = x: isPath x || x._type or null == "fileset";
    };

    optListOf = elemType: coercedTo elemType singleton (listOf elemType);

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

    optCallWith = args: elemType: coercedTo function (x: x args) elemType;

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

  autoImport = dir: name: warn
    ("The autoImport function is deprecated. " +
      "All options are now automatically auto-loaded.")
    (if isList name
    then findFirst (x: x != null) null (map (autoImport dir) name)
    else
      if pathExists (dir + "/${name}.nix")
      then import (dir + "/${name}.nix")
      else if pathExists (dir + "/${name}/default.nix")
      then import (dir + "/${name}")
      else if pathExists (dir + "/${name}")
      then importDir (dir + "/${name}")
      else null);

  autoImportArgs = dir: args: name: warn
    ("The autoImportArgs function is deprecated. " +
      "Wrap the target type in conflake.types.optCallWith instead.")
    (
      let v = autoImport dir name; in
      if isFunction v then v args else v
    );

  selectAttr = attr: mapAttrs (_: v: v.${attr} or { });
in
conflake
