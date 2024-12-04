{
  config,
  lib,
  src,
  ...
}:

let
  inherit (builtins) elem;
  inherit (lib)
    getExe
    mkDefault
    mkEnableOption
    mkIf
    optionals
    optionalString
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
in
{
  options.presets.formatters = mkEnableOption "default formatters" // {
    default = config.formatter == null;
  };

  config = mkIf cfg {
    devShell.packages =
      pkgs:
      optionals (hasNixfmt pkgs) [
        pkgs.nixfmt-rfc-style
      ]
      ++ optionals (hasNodejs pkgs) [
        pkgs.nodePackages.prettier
      ];

    formatters =
      pkgs:
      let
        nixfmt = optionalString (hasNixfmt pkgs) "${getExe pkgs.nixfmt-rfc-style}";
        prettier = optionalString (hasNodejs pkgs) "cd ${src} && ${getExe pkgs.nodePackages.prettier} --write";
      in
      {
        "*.nix" = mkDefault nixfmt;
        "*.md" = mkDefault prettier;
        "*.json" = mkDefault prettier;
        "*.yaml" = mkDefault prettier;
        "*.yml" = mkDefault prettier;
      };
  };
}
