---
outline: [2, 3]
---

# systems

The `systems` option sets which systems per-system outputs should be created for.

## Default

It is default to `nixpkgs.lib.systems.flakeExposed`.

## Usage

It accepts an array of platform strings:

```nix
conflake ./. {
  systems = [ "x86_64-linux" "aarch64-linux" "i686-linux" "armv7l-linux" ];
};
```

To support all Linux systems supported by flakes, set systems as follows:

```nix
conflake ./. ({ lib, ... }: {
  systems = lib.intersectLists
    lib.systems.doubles.linux
    lib.systems.flakeExposed;
});
```

### nix-systems

It also accepts externally extensible [`nix-systems`](https://github.com/nix-systems/nix-systems):

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  inputs.systems.url = "github:nix-systems/default";
  outputs = { conflake, systems, ... }@inputs:
    conflake ./. {
      inherit inputs systems;
    };
}
```

Or without settings it explicitly,

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  inputs.systems.url = "github:nix-systems/default";
  outputs = { conflake, ... }@inputs:
    conflake ./. {
      inherit inputs;
    };
}
```
