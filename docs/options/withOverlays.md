# withOverlays

This allows you to apply overlays to the Nixpkgs instance used for building
packages and calling perSystem.

It can be set to either a list of overlays or a single overlay.

## Usage

For example, to apply the Emacs overlay and change the Zig version, you can set the option as follows:

```nix
{
  inputs = {
    conflake.url = "github:ratson/conflake";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };
  outputs = { conflake, emacs-overlay, ... }:
    conflake ./. {
      withOverlays = [
        emacs-overlay.overlays.default
        (final: prev: { zig = final.zig_0_9; })
      ];
    };
}
```

You can use the values from the overlays with other options:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      withOverlays = final: prev: { testValue = "hi"; };

      package = { writeShellScript, testValue }:
        writeShellScript "test" "echo ${testValue}";
    };
}
```
