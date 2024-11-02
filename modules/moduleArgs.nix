{ config, lib, inputs, ... }@args:

let
  inherit (lib) genAttrs;

  pkgsFor = genAttrs config.systems (system: import inputs.nixpkgs {
    inherit system;
    inherit (config.nixpkgs) config;

    overlays = config.withOverlays ++ [ config.packageOverlay ];
  });

  genSystems = f: genAttrs config.systems (system: f pkgsFor.${system});
in
{
  _module.args = {
    inherit pkgsFor genSystems;
    inherit (config) inputs outputs;

    moduleArgs = args // config._module.args;
  };
}
