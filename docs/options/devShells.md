# devShells

The `devShells` option allows you to set additional `devShell` outputs. The
values each shell can be set to are the same as described above for the
`devShell` option.

## Usage

For example, using the configuration options:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      devShells.testing = {
        packages = pkgs: [ pkgs.coreutils ];
        env.TEST_VAR = "in testing shell";
      };
    };
}
```

For example, using a package definition:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      devShells.testing = { mkShell, coreutils }:
        mkShell {
          packages = [ coreutils ];
          env.TEST_VAR = "in testing shell";
        };
    };
}
```

The above flakes export `devShells.${system}.testing` outputs.

## devShell

The `devShell` options allow you to configure `devShells.${system}.default`. It is
split up into options in order to enable multiple modules to contribute to its
configuration.

`devShell` can alternatively be set to a package definition or derivation, which
is then used as the default shell, overriding other options.

`devShell` can also be set to a function that takes the package set and returns
an attrSet of the devShell configuration options or a derivation.

The options available are as follows:

`devShell.packages` is a list of packages to add to the shell. It can optionally
be a function taking the package set and returning such a list.

`devShell.inputsFrom` is a list of packages whose deps should be in the shell.
It can optionally be a function taking the package set and returning such a
list.

`devShell.shellHook` is a string that provides bash code to run in shell
initialization. It can optionally be a function taking the package set and
returning such a string.

`devShell.hardeningDisable` is a list of hardening options to disable. Setting
it to `["all"]` disables all Nix hardening.

`devShell.env` is for setting environment variables in the shell. It is an
attribute set mapping variables to values. It can optionally be a function
taking the package set and returning such an attribute set.

`devShell.stdenv` is the stdenv package used for the shell. It can optionally be
a function taking the package set and returning the stdenv to use.

### Usage

For example, these can be configured as follows:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      devShell = pkgs: {
        # Include build deps of emacs
        inputsFrom = [ pkgs.emacs ];
        # Add coreutils to the shell
        packages = [ pkgs.coreutils ];
        # Add shell hook. Can be a function if you need packages
        shellHook = ''
          echo Welcome to example shell!
        '';
        # Set an environment var. `env` can be an be a function
        env.TEST_VAR = "test value";
        stdenv = pkgs.clangStdenv;
      };
    };
}
```

The above exports `devShells.${system}.default` outputs.

To add the build inputs of one of your packages, you can do as follows:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      package = { stdenv }:
        stdenv.mkDerivation {
          pname = "pkg1";
          version = "0.0.1";
          src = ./.;
          installPhase = "make DESTDIR=$out install";
        };
      devShell = {
        inputsFrom = pkgs: [ pkgs.pkg1 ];
      };
    };
}
```

To override the devShell, you can use a package definition as such:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      devShell = { mkShell, hello }: mkShell {
        packages = [ hello ];
      };
    };
}
```
