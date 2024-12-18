# Compare to Flakes

Nix Flakes provide a standard way to write Nix expressions.

[Documentation](https://nix.dev/concepts/flakes.html)&nbsp;
[Wiki](https://nixos.wiki/wiki/Flakes)

## Differences

Vanilla `Flakes` expects users to configure everything in `flake.nix`
and manually import any needed files.

`Conflake` builds on top of `Flakes` to offer file-based attribute loading
and practical defaults, enhancing productivity in authoring `Flakes`.

See [What is Conflake?](../guide/introduction.md) for a list of provided features.

## Migration

<!-- #region migration -->

Edit `flake.nix` to match the following format:

```nix:line-numbers {4,7-9}
{
  outputs = { conflake, ... }@inputs:
    let
      outputs = {};  # Your existing `outputs`
    in
    conflake ./. {
      inherit inputs outputs;

      presets.enable = false;
    };

  inputs.conflake.url = "github:ratson/conflake";
}
```

Line 4: Copy existing `outputs` to here.

Line 9: Optional if your `outputs` is not conflicting to the presets.

Then migrate your `outputs` to Conflake [`options`](../options/).

<!-- #endregion migration -->
