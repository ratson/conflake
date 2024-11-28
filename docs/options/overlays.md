# overlays

The `overlay` and `overlays` options allow you to configure `overlays` outputs.

Multiple provided overlays for an output are merged.

The `overlay` option adds the overlay to `overlays.default`.

The `overlays` option allows you to add overlays to `overlays` outputs.

## Usage

For example, to add an overlay to `overlays.default`, do the following:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      overlay = final: prev: { testValue = "hello"; };
    };
}
```

The above results in `overlays.default` output containing testValue.

To configure other overlays:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      overlays.cool = final: prev: { testValue = "cool"; };
    };
}
```

The above results in a `overlays.cool` output.
