# nixDir

The root directory to use to automatically load nix files to configure flake options from.

## Default

```nix
{
  src = ./nix
}
```

## Usage

```nix
conflake ./. {
  nixDir.src = ./flake;
}
```
