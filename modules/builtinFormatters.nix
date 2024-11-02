{ config, lib, ... }:

let
  inherit (lib) mkDefault mkEnableOption mkIf;
in
{
  options.conflake.builtinFormatters =
    mkEnableOption "default formatters" //
    { default = config.formatter == null; };

  config = mkIf config.conflake.builtinFormatters {
    devShell.packages = pkgs: [
      pkgs.nixpkgs-fmt
      pkgs.nodePackages.prettier
    ];

    formatters = pkgs:
      let
        nixpkgs-fmt = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
        prettier = "${pkgs.nodePackages.prettier}/bin/prettier --write";
      in
      {
        "*.nix" = mkDefault nixpkgs-fmt;
        "*.md" = mkDefault prettier;
        "*.json" = mkDefault prettier;
        "*.yaml" = mkDefault prettier;
        "*.yml" = mkDefault prettier;
      };
  };
}
