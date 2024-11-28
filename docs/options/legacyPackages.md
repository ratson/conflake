# legacyPackages

The `legacyPackages` option allows you to configure the flake's `legacyPackages`
output. It can be set to a function that takes the package set and returns the
package set to be used as the corresponding system's legacyPackages output.

## Usage

For example:

```nix
{
  inputs = {
    conflake.url = "github:ratson/conflake";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = { conflake, nixpkgs, ... }:
    conflake ./. {
      legacyPackages = pkgs: nixpkgs.legacyPackages.${pkgs.system};
    };
}
```

To export the package set used for calling package definitions and other options
that take functions passed the package set, you can do the following:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      legacyPackages = pkgs: pkgs;
    };
}
```
