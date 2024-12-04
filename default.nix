inputs:

let
  inherit (builtins)
    all
    attrNames
    functionArgs
    head
    isAttrs
    isPath
    length
    listToAttrs
    mapAttrs
    readDir
    ;
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;
  inherit (lib)
    attrsToList
    composeManyExtensions
    evalModules
    filter
    fix
    getFiles
    getValues
    hasSuffix
    isDerivation
    isFunction
    isStringLike
    mapAttrs'
    mkDefault
    mkOption
    mkOptionType
    nameValuePair
    partition
    pathIsRegularFile
    pipe
    removeSuffix
    setDefaultModuleLocation
    setFunctionArgs
    showFiles
    showOption
    singleton
    toFunction
    ;
  inherit (lib.types)
    coercedTo
    defaultFunctor
    functionTo
    lazyAttrsOf
    lines
    listOf
    nullOr
    optionDescriptionPhrase
    str
    submodule
    ;
  inherit (lib.options) mergeEqualOption mergeOneOption;

  baseModules = import ./modules/module-list.nix;

  mkOutputs = {
    __functor =
      self: src: module:
      (evalModules {
        class = "conflake";
        modules =
          baseModules
          ++ self.extraModules
          ++ [
            (setDefaultModuleLocation ./default.nix {
              inputs.nixpkgs = mkDefault nixpkgs;
              inputs.conflake = mkDefault inputs.self;
            })
            (setDefaultModuleLocation (src + /flake.nix) module)
          ];
        specialArgs = {
          inherit conflake src;

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
      mkOptionType {
        name = "nullable";
        description = "nullable ${
          optionDescriptionPhrase (class: class == "noun" || class == "composite") elemType
        }";
        descriptionClass = "noun";
        check = x: x == null || elemType.check x;
        merge =
          loc: defs:
          if all (def: def.value == null) defs then
            null
          else
            elemType.merge loc (filter (def: def.value != null) defs);
        emptyValue.value = null;
        inherit (elemType) getSubOptions getSubModules;
        substSubModules = m: nullable (elemType.substSubModules m);
        functor = (defaultFunctor "nullable") // {
          type = nullable;
          wrapped = elemType;
        };
        nestedTypes = {
          inherit elemType;
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
  };

  mkCheck =
    name: pkgs: src: cmd:
    pkgs.runCommand "check-${name}" { } ''
      pushd "${src}"
      ${cmd}
      popd
      touch $out
    '';

  mkModule =
    path:
    {
      config,
      inputs,
      outputs,
      ...
    }@flakeArgs:
    let
      inherit (config) moduleArgs;
      f = toFunction (import path);
      g =
        { pkgs, ... }@args:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          inputs' = mapAttrs (_: selectAttr system) inputs;
        in
        f (flakeArgs // moduleArgs.extra // { inherit inputs'; } // args);
    in
    if moduleArgs.enable then
      pipe f [
        functionArgs
        (
          x:
          removeAttrs x (
            [
              "conflake"
              "inputs"
              "inputs'"
              "moduleArgs"
            ]
            ++ (attrNames moduleArgs.extra)
          )
        )
        (x: x // { pkgs = true; })
        (setFunctionArgs g)
        (setDefaultModuleLocation path)
      ]
    else
      path;

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

  # Add `prefix` to keys of an attrset
  withPrefix = prefix: mapAttrs' (k: v: nameValuePair "${prefix}${k}" v);

  conflake = {
    inherit
      matchers
      mkCheck
      mkModule
      mkOutputs
      readNixDir
      selectAttr
      types
      withPrefix
      ;
  };
in
conflake
