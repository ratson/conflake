{
  config,
  lib,
  src,
  ...
}:

let
  inherit (builtins) elem isList listToAttrs;
  inherit (lib)
    flip
    getExe
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    nameValuePair
    optionalAttrs
    optionals
    pipe
    ;

  cfg = config.presets.formatters;

  hasNixfmt =
    pkgs:
    !elem pkgs.stdenv.hostPlatform.system [
      "armv6l-linux"
      "riscv64-linux"
      "x86_64-freebsd"
    ];

  hasNodejs = pkgs: elem pkgs.stdenv.hostPlatform.system pkgs.nodejs.meta.platforms;

  mkPrettier =
    enable: exts:
    mkIf enable {
      formatters =
        { pkgs }:
        optionalAttrs (hasNodejs pkgs) (
          pipe exts [
            (x: if isList x then x else [ x ])
            (map (flip nameValuePair (mkDefault "cd ${src} && ${getExe pkgs.nodePackages.prettier} --write")))
            listToAttrs
          ]
        );
    };
in
{
  options.presets.formatters = {
    enable = mkEnableOption "default formatters" // {
      default = config.presets.enable && config.formatter == null;
    };
    json = mkEnableOption "json formatter" // {
      default = cfg.enable;
    };
    markdown = mkEnableOption "markdown formatter" // {
      default = cfg.enable;
    };
    nix = mkEnableOption "nix formatter" // {
      default = cfg.enable;
    };
    yaml = mkEnableOption "yaml formatter" // {
      default = cfg.enable;
    };
  };

  config = mkMerge [
    (mkIf cfg.nix {
      formatters =
        { pkgs }:
        optionalAttrs (hasNixfmt pkgs) {
          "*.nix" = mkDefault (getExe pkgs.nixfmt-rfc-style);
        };
    })

    (mkPrettier cfg.json "*.json")
    (mkPrettier cfg.markdown "*.md")
    (mkPrettier cfg.yaml [
      "*.yml"
      "*.yaml"
    ])

    (mkIf config.presets.devShell.formatters (mkMerge [
      (mkIf cfg.nix {
        devShell.packages =
          { pkgs, ... }:
          optionals (hasNixfmt pkgs) [
            pkgs.nixfmt-rfc-style
          ];
      })
      (mkIf (cfg.json || cfg.markdown || cfg.yaml) {
        devShell.packages =
          { pkgs, ... }:
          optionals (hasNodejs pkgs) [
            pkgs.nodePackages.prettier
          ];
      })
    ]))
  ];
}
