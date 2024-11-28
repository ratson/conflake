# perSystem

The `perSystem` option allows you to directly configure per-system flake
outputs, and gives you access to packages.

## Usage

To add `example.${system}.test` outputs to your flake, you could do the
following:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = pkgs: {
        example.test = pkgs.writeShellScript "test" "echo hello";
      };
    };
}
```

The above will generate `example.x86_64-linux.test` and
`example.aarch64-linux.test` attributes.
