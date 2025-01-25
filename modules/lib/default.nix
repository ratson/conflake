{ lib }:

let
  inherit (builtins)
    attrValues
    filter
    groupBy
    head
    isAttrs
    isPath
    mapAttrs
    ;
  inherit (lib)
    filterAttrs
    flip
    hasSuffix
    makeExtensible
    nameValuePair
    pipe
    removeSuffix
    ;
in
makeExtensible (self: {
  nameMockedPkgs = import ./nameMockedPkgs.nix;

  filterLoadable =
    options:
    pipe options [
      (flip removeAttrs self.loadBlacklist)
      (filterAttrs (_: v: !(v.internal or false)))
    ];

  loadBlacklist = [
    "_module"
    "inputs"
    "loaders"
    "loadIgnore"
    "indexIgnore"
    "matchers"
    "moduleArgs"
    "nixDir"
    "nixpkgs"
    "presets"
    "src"
    "tests"
  ];

  loadDir =
    {
      load ? import,
      ...
    }@args:
    self.loadDir' (
      {
        mkFilePair = { name, node, ... }: nameValuePair (removeSuffix ".nix" name) (load node);
      }
      // (removeAttrs args [ "load" ])
    );

  loadDir' =
    {
      root,
      tree,
      ignore ? _: false,
      mkDirValue ? self.loadDir',
      mkFilePair ? { name, node, ... }: nameValuePair name node,
      mkIgnore ? _: null,
      mkValue ? { contexts, ... }: (head contexts).content.value,
      # internal state
      depth ? 0,
      dir ? root,
      node ? tree,
      path ? root,
      ...
    }@args:
    pipe node [
      (mapAttrs (
        name: node:
        let
          args' = args // {
            inherit name node;
            depth = depth + 1;
            dir = path;
            path = dir + /${name};
            type =
              if isPath node then
                "regular"
              else if isAttrs node then
                "directory"
              else
                "unknown";
          };
          isIgnored = ignore args';
          content =
            if isIgnored then
              mkIgnore args'
            else if isAttrs node then
              nameValuePair name (mkDirValue args')
            else if isPath node && hasSuffix ".nix" name then
              mkFilePair args'
            else
              mkIgnore args';
        in
        args'
        // {
          inherit content;
        }
      ))
      attrValues
      (filter (x: x.content != null))
      (groupBy (x: x.content.name))
      (mapAttrs (name: contexts: mkValue { inherit name contexts; }))
    ];

  loadDirWithDefault =
    {
      load ? import,
      ...
    }@args:
    self.loadDir (
      {
        mkDirValue =
          { node, ... }@args:
          if isPath (node."default.nix" or null) then load node."default.nix" else self.loadDir args;
      }
      // args

    );
})
