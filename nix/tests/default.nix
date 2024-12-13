{
  lib,
  inputs,
  ...
}:

let
  inherit (lib) const isDerivation pipe;
  inherit (inputs) self;
  inherit (self.lib) withPrefix;

  conflake = self;
  conflake' = conflake ../../tests/empty;
in
withPrefix "test-" {
  formatter = {
    expr = pipe null [
      (const (conflake' {
        formatter = pkgs: pkgs.hello;
      }))
      (x: isDerivation x.formatter.x86_64-linux)
    ];
    expected = true;
  };

  formatters = {
    expr = pipe null [
      (const (conflake' {
        devShell.packages = pkgs: [ pkgs.rustfmt ];
        formatters = {
          "*.rs" = "rustfmt";
        };
      }))
      (x: isDerivation x.formatter.x86_64-linux)
    ];
    expected = true;
  };

  formatters-disable = {
    expr = pipe null [
      (const (conflake' {
        presets.formatters.enable = false;
      }))
      (x: x ? formatter.x86_64-linux)
    ];
    expected = false;
  };

  formatters-disable-except = {
    expr = pipe null [
      (const (conflake' {
        presets.formatters.enable = false;
        presets.formatters.nix = true;
      }))
      (x: x ? formatter.x86_64-linux)
    ];
    expected = true;
  };

  formatters-disable-all-builtin = {
    expr = pipe null [
      (const (conflake' {
        presets.formatters = {
          json = false;
          markdown = false;
          nix = false;
          yaml = false;
        };
      }))
      (x: x ? formatter.x86_64-linux)
    ];
    expected = false;
  };

  formatters-disable-only-builtin = {
    expr = pipe null [
      (const (conflake' {
        presets.formatters.enable = false;
        formatters =
          { rustfmt, ... }:
          {
            "*.rs" = "rustfmt";
          };
      }))
      (x: x ? formatter.x86_64-linux)
    ];
    expected = true;
  };

  self-outputs = {
    expr = pipe inputs.self [
      (x: [
        (x ? __functor)
        (x ? lib.mkOutputs)
        (x ? templates.default.path)
        (x.templates.default.description != "default")
      ])
    ];
    expected = [
      true
      true
      true
      true
    ];
  };
}
