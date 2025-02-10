{
  outputs =
    {
      conflake,
      home-manager,
      nixpkgs,
      self,
      ...
    }@inputs:
    conflake ./. {
      inherit inputs;

      nixpkgs.overlays = [
        (final: _: { broken = final.lib.trace "fix broken package" final.hello; })
      ];
    };

  inputs = {
    conflake = {
      url = "../..";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
}
