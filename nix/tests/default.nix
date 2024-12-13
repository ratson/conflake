{
  lib,
  inputs,
  ...
}:

let
  inherit (lib) isDerivation;
  inherit (inputs) self;
  inherit (self.lib) withPrefix;

  conflake = self;
  conflake' = conflake ../../tests/empty;
in
withPrefix "test-" {
  formatter = [
    (conflake' {
      formatter = pkgs: pkgs.hello;
    })
    (x: isDerivation x.formatter.x86_64-linux)
    true
  ];

  formatters = [
    (conflake' {
      devShell.packages = pkgs: [ pkgs.rustfmt ];
      formatters = {
        "*.rs" = "rustfmt";
      };
    })
    (x: isDerivation x.formatter.x86_64-linux)
    true
  ];

  formatters-disable = [
    (conflake' {
      presets.formatters.enable = false;
    })
    (x: x ? formatter.x86_64-linux)
    false
  ];

  formatters-disable-except = [
    (conflake' {
      presets.formatters.enable = false;
      presets.formatters.nix = true;
    })
    (x: x ? formatter.x86_64-linux)
    true
  ];

  formatters-disable-all-builtin = [
    (conflake' {
      presets.formatters = {
        json = false;
        markdown = false;
        nix = false;
        yaml = false;
      };
    })
    (x: x ? formatter.x86_64-linux)
    false
  ];

  formatters-disable-only-builtin = [
    (conflake' {
      presets.formatters.enable = false;
      formatters =
        { rustfmt, ... }:
        {
          "*.rs" = "rustfmt";
        };
    })
    (x: x ? formatter.x86_64-linux)
    true
  ];

  self-outputs = [
    inputs.self
    (x: [
      (x ? __functor)
      (x ? lib.mkOutputs)
      (x ? templates.default.path)
      (x.templates.default.description != "default")
    ])
    [
      true
      true
      true
      true
    ]
  ];
}
