# nixpkgs.config

This allows you to pass configuration options to the Nixpkgs instance used for
building packages and calling perSystem.

## Usage

For example, to allow building broken or unsupported packages, you can set the
option as follows:

```nix
conflake ./. {
  nixpkgs.config = { allowBroken = true; allowUnsupportedSystem = true; };
};
```
