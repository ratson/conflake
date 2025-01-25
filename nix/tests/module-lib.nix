{ conflake', ... }:

let
  inherit (conflake') loadDir loadDir' loadDirWithDefault;

  fixtures = {
    loadDirArgs = {
      root = ./.;
      tree = {
        "file.nix" = ./.;
        dir = {
          "default.nix" = ./.;
          "dir-file.nix" = ./.;
        };
      };
    };
  };
in
{
  loadDir = [
    fixtures.loadDirArgs
    (x: x // { load = _: true; })
    loadDir
    {
      dir = {
        default = true;
        dir-file = true;
      };
      file = true;
    }
  ];

  loadDir' = [
    fixtures.loadDirArgs
    loadDir'
    {
      dir = {
        "default.nix" = ./.;
        "dir-file.nix" = ./.;
      };
      "file.nix" = ./.;
    }
  ];

  loadDirWithDefault = [
    fixtures.loadDirArgs
    (x: x // { load = _: true; })
    loadDirWithDefault
    {
      dir = true;
      file = true;
    }
  ];
}
