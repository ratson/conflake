{ config, inputs, lib, conflake, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib) foldAttrs genAttrs mergeAttrs mkOption;
  inherit (lib.types) functionTo lazyAttrsOf listOf nonEmptyStr raw uniq;
  inherit (conflake.types) optListOf outputs overlay;

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

    perSystem = mkOption {
      type = functionTo outputs;
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
