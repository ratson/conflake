{ config, lib, src, ... }:

let
  inherit (builtins) elem;
  inherit (lib) getExe mkDefault mkEnableOption mkIf optionals optionalString;

  hasNodejs = pkgs: elem pkgs.stdenv.hostPlatform.system pkgs.nodejs.meta.platforms;
in
{
  options.conflake.builtinFormatters =
    mkEnableOption "default formatters" //
    { default = config.formatter == null; };

  config = mkIf config.conflake.builtinFormatters {
    devShell.packages = pkgs: [
      pkgs.nixpkgs-fmt
    ] ++ optionals (hasNodejs pkgs) [
      pkgs.nodePackages.prettier
    ];

    formatters = pkgs:
      let
        nixpkgs-fmt = "${getExe pkgs.nixpkgs-fmt}";
        prettier = optionalString (hasNodejs pkgs)
          "cd ${src} && ${getExe pkgs.nodePackages.prettier} --write";
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
