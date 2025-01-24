{
  config,
  lib,
  options,
  conflake,
  conflake',
  src,
  ...
}:

let
  inherit (builtins)
    attrNames
    attrValues
    hasAttr
    isAttrs
    isPath
    length
    mapAttrs
    ;
  inherit (lib)
    filterAttrs
    flatten
    flip
    genAttrs
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    pipe
    types
    ;
  inherit (lib.path) subpath;
  inherit (lib.types)
    lazyAttrsOf
    listOf
    functionTo
    nonEmptyListOf
    nullOr
    str
    ;

  cfg = config.nixDir;

  loadable = conflake'.filterLoadable options;

  loadableNames = pipe loadable [
    attrNames
    (map cfg.namesFor)
    flatten
  ];
in
{
  options.nixDir = {
    enable = mkEnableOption "nixDir" // {
      default = true;
    };
    src = mkOption {
      type = conflake.types.path;
      default = src + /nix;
    };
    aliases = mkOption {
      type = lazyAttrsOf (listOf str);
      default = { };
    };
    loaders = mkOption {
      type = types.lazyAttrsOf conflake.types.loader;
      default = { };
    };
    matchers = mkOption {
      type = lazyAttrsOf conflake.types.matcher;
      default = { };
    };
    depth = mkOption {
      internal = true;
      readOnly = true;
      type = types.int;
      default = pipe cfg.src [
        (lib.path.removePrefix src)
        subpath.components
        length
      ];
    };
    finalMatchers = mkOption {
      internal = true;
      readOnly = true;
      type = lazyAttrsOf conflake.types.matcher;
    };
    namesFor = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo (nonEmptyListOf str);
      default = name: [ name ] ++ (cfg.aliases.${name} or [ ]);
    };
    tree = mkOption {
      internal = true;
      readOnly = true;
      type = nullOr conflake.types.pathTree;
      default = config.src.get cfg.src;
    };
  };

  config = {
    nixDir = {
      finalMatchers = mkMerge [
        cfg.matchers
        (pipe cfg.aliases [
          (filterAttrs (k: _: hasAttr k cfg.matchers))
          (mapAttrs (k: flip genAttrs (_: cfg.matchers.${k})))
          attrValues
          mkMerge
        ])
      ];

      loaders = pipe loadableNames [
        (map (name: {
          ${name} = mkDefault config.loaderDefault;
        }))
        mkMerge
      ];

      matchers = pipe loadableNames [
        (map (name: {
          ${name} = mkDefault ({ depth, ... }: depth <= 2);
        }))
        mkMerge
      ];
    };

    loaders = pipe loadable [
      (mapAttrs (k: _: cfg.loaders.${k}))
      (mapAttrs (
        attr: f:
        pipe attr [
          cfg.namesFor
          (map (
            name:
            let
              args = {
                inherit name;
              };
              dirArgs = args // {
                node = cfg.tree.${name} or null;
                path = cfg.src + /${name};
                type = "directory";
              };
              fileArgs = args // {
                node = cfg.tree.${name + ".nix"} or null;
                path = cfg.src + /${name + ".nix"};
                type = "regular";
              };
            in
            [
              (mkIf (isPath fileArgs.node) (args: f (args // fileArgs)))
              (mkIf (isAttrs dirArgs.node) (args: f (args // dirArgs)))
            ]
          ))
          mkMerge
        ]
      ))
    ];

    matchers =
      [ cfg.src ]
      ++ (pipe cfg.finalMatchers [
        (mapAttrs (
          k: f:
          { depth, path, ... }@args:
          let
            root = cfg.src + /${k};
            args' = args // {
              inherit root;
              depth = depth - cfg.depth - 1;
            };
          in
          lib.path.hasPrefix root path && f args'
        ))
        attrValues
      ]);
  };
}
