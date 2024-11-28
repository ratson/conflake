# homeConfigurations

The `homeConfigurations` attribute lets you set outputs for NixOS systems and
home-manager users.

It should be set to an attribute set. Each value should be a set of
`home-manager.lib.homeManagerConfiguration` args, the result of calling
`home-manager.lib.homeManagerConfiguration`, or a function that takes
`moduleArgs` and returns one of the prior.

When using a set of `homeManagerConfiguration` args, it is required to include
`system` (`pkgs` does not need to be included), and `inputs.home-manager` must
be set. home-manager modules will have access to a `flake` module arg equivalent
to `moduleArgs` plus `inputs'` and `outputs'`. Conflake's pkgs attributes,
`withOverlays`, and `packages` will also be available in the home-manager
instance's pkgs.

When using the result of calling `homeManagerConfiguration`, the
`config.propagationModule` value can be used as a home-manager module to gain
the above benefits.

## Usage

For example:

```nix
{
  inputs = {
    conflake.url = "github:ratson/conflake";
    home-manger.url = "github:nix-community/home-manager";
  };
  outputs = { conflake, home-manager, ... }@inputs:
    conflake ./. ({ config, ... }: {
      inherit inputs;
      homeConfigurations.username = {
        system = "x86_64-linux";
        modules = [{ home.stateVersion = "24.05"; }];
      };
    });
}
```
