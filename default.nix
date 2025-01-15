inputs:

let
  inherit (builtins)
    intersectAttrs
    listToAttrs
    mapAttrs
    readDir
    ;
  inherit (inputs.nixpkgs) lib;
  inherit (lib)
    attrsToList
    evalModules
    filter
    fix
    functionArgs
    hasSuffix
    isFunction
    mkDefault
    nameValuePair
    partition
    pathIsRegularFile
    pipe
    removeSuffix
    setDefaultModuleLocation
    ;

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
      }).config.final.outputs;

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

  conflake = (import ./lib/default.nix { inherit lib; }).extend (
    _: _: {
      inherit
        callWith
        callWith'
        mkOutputs
        readNixDir
        selectAttr
        ;
    }
  );
in
conflake
