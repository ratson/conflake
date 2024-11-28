# packages

The `package` and `packages` options allow you to add packages. These are
exported in the `packages.${system}` outputs, are included in `overlays.default`,
and have build checks in `checks.${system}`.

`package` can be set to a package definition, and will set `packages.default`.

`packages` can be set to attrs of package definitions. If it is a function, it
will additionally get a `system` arg in addition to module args, to allow
conditionally including package definitions depending on the system.

By default, the `packages.default` package's name (its attribute name in
the package set and overlay) is automatically determined from the derivation's
`pname`. In order to use a different attribute name from the package pname,
to set it in cases where it cannot be automatically determined, or to speed up
uncached evaluation, the conflake `pname` option can be set.

## Usage

To set the default package, you can set the options as follows:

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
    };
}
```

The above will export `packages.${system}.default` attributes, add `pkg1` to
`overlays.default`, and export `checks.${system}.packages-default`.

You can also instead just directly set `packages.default`.

To set multiple packages, you can set the options as follows:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      packages = {
        default = { stdenv }:
          stdenv.mkDerivation {
            name = "pkg1";
            src = ./.;
            installPhase = "make DESTDIR=$out install";
          };
        pkg2 = { stdenv, pkg1, pkg3 }:
          stdenv.mkDerivation {
            name = "hello-world";
            src = ./pkg2;
            nativeBuildInputs = [ pkg1 pkg3 ];
            installPhase = "make DESTDIR=$out install";
          };
        pkg3 = { stdenv }:
          stdenv.mkDerivation {
            name = "hello-world";
            src = ./pkg3;
            installPhase = "make DESTDIR=$out install";
          };
      };
    };
}
```

The above will export `packages.${system}.default`, `packages.${system}.pkg2`,
`packages.${system}.pkg3` attributes, add `pkg1`, `pkg2`, and `pkg3` to
`overlays.default`, and export corresponding build checks.

To use the first example, but manually specify the package name:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      pname = "pkgs-attribute-name";
      package = { stdenv }:
        stdenv.mkDerivation {
          pname = "package-name";
          version = "0.0.1";
          src = ./.;
          installPhase = "make DESTDIR=$out install";
        };
    };
}
```

To add a package only for certain systems, you can take `system` as an arg as
follows:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      packages = { system, ... }: if (system == "x86_64-linux") then {
        pkg1 = { stdenv }:
          stdenv.mkDerivation {
            name = "pkg1";
            src = ./.;
            installPhase = "make DESTDIR=$out install";
          };
      } else { };
    };
}
```
