# apps

The `app` and `apps` options allow you to set `apps.${system}` outputs.

`apps` is an attribute set of apps or a function that takes packages and returns
an attribute set of apps. If the app value is a function, it is passed packages.
If the app value or function result is a string, it is converted to an app.

`app` sets `apps.default`.

## Usage

For example:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      apps = {
        emacs = pkgs: "${pkgs.emacs}/bin/emacs";
        bash = pkgs: { type = "app"; program = "${pkgs.bash}/bin/bash"; };
      };
    };
}
```

Alternatively, the above can be written as:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      apps = { emacs, bash, ... }: {
        emacs = "${emacs}/bin/emacs";
        bash = { type = "app"; program = "${bash}/bin/bash"; };
      };
    };
}
```
