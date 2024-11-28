# nixosConfigurations

The `nixosConfigurations` attribute lets you set outputs for NixOS systems and
home-manager users.

It should be set to an attribute set. Each value should be a set of
`nixpkgs.lib.nixosSystem` args, the result of calling `nixpkgs.lib.nixosSystem`,
or a function that takes `moduleArgs` and returns one of the prior.

When using a set of `nixpkgs.lib.nixosSystem` args, NixOS modules will have
access to a `flake` module arg equivalent to `moduleArgs` plus `inputs'` and
`outputs'`. Conflake's pkgs attributes, `withOverlays`, and `packages` will
also be available in the NixOS instance's pkgs, and Conflake's
`nixpkgs.config` will apply to it as well.

## Usage

For example:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. ({ lib, config, ... }: {
      nixosConfigurations.test-system = {
        system = "x86_64-linux";
        modules = [{ system.stateVersion = "24.05"; }];
      };
    });
}
```
