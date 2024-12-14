{
  #region outputs
  outputs =
    { conflake, ... }@inputs:
    conflake ./. {
      inherit inputs;

      tests = {
        test-add = {
          expr = 1 + 1;
          expected = 2;
        };
      };
    };
  #endregion outputs

  inputs = {
    conflake = {
      url = "../..";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
}
