inputs:

let
  inherit (inputs.nixpkgs) lib;
  inherit (lib)
    evalModules
    fix
    mkOptionDefault
    setDefaultModuleLocation
    ;

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
              finalInputs = {
                nixpkgs = mkOptionDefault inputs.nixpkgs;
                conflake = mkOptionDefault inputs.self;
              };
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

  conflake = (import ./lib/default.nix { inherit lib; }).extend (_: _: { inherit mkOutputs; });
in
conflake
