{ config, inputs, lib, conflake, moduleArgs, ... }:

let
  inherit (builtins) all head isAttrs length mapAttrs;
  inherit (lib) foldAttrs genAttrs getFiles getValues mergeAttrs
    mkOption mkOptionType showFiles showOption;
  inherit (lib.types) functionTo lazyAttrsOf listOf nonEmptyStr raw uniq;
  inherit (conflake.types) optCallWith optListOf overlay;

  outputs = mkOptionType {
    name = "outputs";
    description = "output values";
    descriptionClass = "noun";
    merge = loc: defs:
      if (length defs) == 1 then (head defs).value
      else if all isAttrs (getValues defs) then
        (lazyAttrsOf outputs).merge loc defs
      else
        throw ("The option `${showOption loc}' has conflicting definitions" +
          " in ${showFiles (getFiles defs)}");
  };

  pkgsFor = genAttrs config.systems (system: import inputs.nixpkgs {
    inherit system;
    inherit (config.nixpkgs) config;
    overlays = config.withOverlays ++ [ config.packageOverlay ];
  });

  genSystems = f: genAttrs config.systems (system: f pkgsFor.${system});
in
{
  options = {
    inputs = mkOption {
      type = lazyAttrsOf raw;
    };

    systems = mkOption {
      type = uniq (listOf nonEmptyStr);
      default = [ "x86_64-linux" "aarch64-linux" ];
    };

    outputs = mkOption {
      type = optCallWith moduleArgs (lazyAttrsOf outputs);
      default = { };
    };

    perSystem = mkOption {
      type = functionTo (lazyAttrsOf outputs);
      default = _: { };
    };

    nixpkgs.config = mkOption {
      type = lazyAttrsOf raw;
      default = { };
    };

    withOverlays = mkOption {
      type = optListOf overlay;
      default = [ ];
    };
  };

  config = {
    _module.args = {
      inherit (config) inputs outputs;
      inherit pkgsFor genSystems;
    };

    outputs = foldAttrs mergeAttrs { } (map
      (system: mapAttrs
        (_: v: { ${system} = v; })
        (config.perSystem pkgsFor.${system}))
      config.systems);
  };
}
