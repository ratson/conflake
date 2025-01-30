inputs:

let
  inherit (inputs.nixpkgs) lib;
  inherit (lib)
    evalModules
    fix
    mkDefault
    setDefaultModuleLocation
    ;

  baseModules = import ./modules/module-list.nix;

  mkOutputs = {
    __functor =
      self: src: module:
      let
        flakePath = src + /flake.nix;
        conflake' = ((import ./modules/lib/default.nix) { inherit lib; }).extend (
          _: _: { inherit flakePath src; }
        );
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
          inherit conflake conflake' src;

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
