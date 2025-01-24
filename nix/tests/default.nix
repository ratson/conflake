{
  lib,
  inputs,
  ...
}:

let
  inherit (builtins)
    attrNames
    deepSeq
    isList
    mapAttrs
    tryEval
    ;
  inherit (lib)
    const
    fix
    flip
    isDerivation
    pipe
    ;
  inherit (inputs) nixpkgs self;
  inherit (self.lib) prefixAttrs;

  fixtures = {
    empty = ./_fixtures/empty;
    editorconfig = ./_fixtures/editorconfig;
  };

  test = flake: test: {
    expr = test flake;
    expected = true;
  };

  conflake =
    src: m:
    self src {
      imports = [ m ];
      inputs = lib.mkDefault inputs;
    };

  conflake' = conflake fixtures.empty;

  conflakeExample = s: conflake ../../examples/${s};

  mkTests = flip pipe [
    (prefixAttrs "test-")
    (mapAttrs builtins.traceVerbose)
  ];
in
mkTests {
  call-conflake = [
    (conflake' { outputs.test = true; })
    (x: x.test)
    true
  ];

  explicit-mkOutputs = [
    (self.lib.mkOutputs fixtures.empty {
      inherit inputs;
      outputs.test = true;
    })
    (x: x.test)
    true
  ];

  module-with-args = [
    (conflake' (
      { lib, config, ... }:
      {
        outputs.test = true;
      }
    ))
    (x: x.test)
    true
  ];

  src-arg = [
    (conflake ./test-path (
      { src, ... }:
      {
        outputs = {
          inherit src;
        };
      }
    ))
    (x: x.src)
    ./test-path
  ];

  lib-arg = [
    (conflake' (
      { lib, ... }:
      {
        outputs = {
          inherit lib;
        };
      }
    ))
    (x: x.lib ? fix)
    true
  ];

  config-arg = [
    (conflake' (
      { config, ... }:
      {
        lib = {
          a = true;
        };
        outputs = {
          inherit config;
        };
      }
    ))
    (x: x.config.lib.a)
    true
  ];

  options-arg = test (conflake' (
    { options, ... }:
    {
      outputs = {
        inherit options;
      };
    }
  )) (f: f.options ? package && f.options ? overlays);

  conflake-arg = test (conflake' (
    { conflake, ... }:
    {
      outputs = {
        inherit conflake;
      };
    }
  )) (f: f.conflake ? mkOutputs);

  inputs-arg = test (conflake' (
    { inputs, ... }:
    {
      inputs.test = true;
      outputs = {
        inherit inputs;
      };
    }
  )) (f: f.inputs.test);

  moduleArgs-arg = [
    (conflake' (
      { inputs, ... }:
      {
        _module.args = {
          username = "user";
        };
        outputs =
          { username, ... }:
          {
            test = username;
          };
      }
    ))
    (x: x.test)
    "user"
  ];

  overridden-nixpkgs = test (conflake' (
    { inputs, ... }:
    {
      inputs.nixpkgs = nixpkgs // {
        testValue = true;
      };
      outputs = {
        inherit inputs;
      };
    }
  )) (f: f.inputs.nixpkgs.testValue);

  outputs-arg = test (conflake' (
    { outputs, ... }:
    {
      lib.test = true;
      outputs.test = outputs.lib.test;
    }
  )) (f: f.test);

  moduleArgs = [
    (conflake' (
      { moduleArgs, ... }:
      {
        outputs = {
          inherit moduleArgs;
        };
      }
    ))
    (x: attrNames x.moduleArgs)
    [
      "config"
      "conflake"
      "conflake'"
      "extendModules"
      "inputs"
      "lib"
      "moduleArgs"
      "moduleType"
      "modulesPath"
      "options"
      "outputs"
      "specialArgs"
      "src"
    ]
  ];

  moduleArgs-add = test (conflake' {
    _module.args.test-val = true;

    outputs =
      { test-val, ... }:
      {
        test = test-val;
      };
  }) (f: f.test);

  extra-pkgs-vals = [
    (conflake' {
      package =
        {
          src,
          inputs,
          outputs,
          conflake,
          inputs',
          outputs',
          defaultMeta,
          writeText,
        }:
        writeText "test" "";
    })
    (x: x.packages.x86_64-linux.default.name)
    "test"
  ];

  inputs' = test (conflake' {
    systems = [ "x86_64-linux" ];
    inputs.a.attr.x86_64-linux = true;
    perSystem =
      { inputs', ... }:
      {
        test = inputs'.a.attr && true;
      };
  }) (f: f.test.x86_64-linux);

  outputs' = test (conflake' {
    systems = [ "x86_64-linux" ];
    outputs.attr.x86_64-linux = true;
    perSystem =
      { outputs', ... }:
      {
        test = outputs'.attr && true;
      };
  }) (f: f.test.x86_64-linux);

  systems = [
    (conflake' {
      systems = [
        "i686-linux"
        "armv7l-linux"
      ];
      perSystem = _: { test = true; };
    })
    (x: x.test)
    attrNames
    [
      "armv7l-linux"
      "i686-linux"
    ]
  ];

  all-flakes-systems = [
    (conflake' (
      { lib, ... }:
      {
        systems = lib.systems.flakeExposed;
        perSystem = _: { test = true; };
      }
    ))
    (x: deepSeq x.test x.test.x86_64-linux)
    true
  ];

  all-linux-systems = [
    (conflake' (
      { lib, ... }:
      {
        systems = lib.intersectLists lib.systems.doubles.linux lib.systems.flakeExposed;
        perSystem = _: { test = true; };
      }
    ))
    (x: deepSeq x.test x.test.x86_64-linux)
    true
  ];

  outputs = test (conflake' {
    outputs.example.test = true;
  }) (f: f.example.test);

  outputs-fn = test (conflake' {
    outputs =
      { inputs, ... }:
      {
        example.test = true;
      };
  }) (f: f.example.test);

  outputs-handled-attr = test (conflake' {
    outputs.overlays.test = final: prev: { testVal = true; };
  }) (f: (nixpkgs.legacyPackages.x86_64-linux.extend f.overlays.test).testVal);

  perSystem = {
    expr = pipe null [
      (const (conflake' {
        perSystem =
          { src, ... }:
          {
            test.a.b.c = true;
          };
      }))
      (x: x.test)
      attrNames
    ];
    expected = [
      "aarch64-darwin"
      "aarch64-linux"
      "armv6l-linux"
      "armv7l-linux"
      "i686-linux"
      "powerpc64le-linux"
      "riscv64-linux"
      "x86_64-darwin"
      "x86_64-freebsd"
      "x86_64-linux"
    ];
  };

  withOverlays = test (conflake' {
    withOverlays = final: prev: { testValue = "true"; };
    package = { writeText, testValue }: writeText "test" "${testValue}";
  }) (f: import f.packages.x86_64-linux.default);

  withOverlays-multiple = test (conflake' {
    withOverlays = [
      (final: prev: { testValue = "tr"; })
      (final: prev: { testValue2 = "ue"; })
    ];
    package =
      {
        writeText,
        testValue,
        testValue2,
      }:
      writeText "test" "${testValue}${testValue2}";
  }) (f: import f.packages.x86_64-linux.default);

  package-no-named-args = test (conflake' {
    package = pkgs: pkgs.hello;
  }) (f: f.packages.aarch64-linux.default.pname == "hello");

  package-prevent-recursion = test (conflake' {
    package = { hello }: hello;
  }) (f: f.packages.aarch64-linux.default.pname == "hello");

  package = [
    (conflake' {
      package =
        { stdenv }:
        stdenv.mkDerivation {
          pname = "pkg1";
          version = "0.0.1";
          src = fixtures.empty;
          installPhase = "echo true > $out";
        };
    })
    (f: [
      (import f.packages.x86_64-linux.default)
      (f ? packages.aarch64-linux.default)
      ((nixpkgs.legacyPackages.x86_64-linux.extend f.overlays.default) ? pkg1)
      (f ? checks.x86_64-linux.packages-default)
      (f ? checks.aarch64-linux.packages-default)
    ])
    [
      true
      true
      true
      true
      true
    ]
  ];

  packages = [
    (conflake' {
      packages = {
        default =
          { stdenv }:
          stdenv.mkDerivation {
            name = "pkg1";
            src = fixtures.empty;
            installPhase = "echo true > $out";
          };
        pkg2 =
          {
            stdenv,
            pkg1,
            pkg3,
          }:
          stdenv.mkDerivation {
            name = "hello-world";
            src = fixtures.empty;
            nativeBuildInputs = [
              pkg1
              pkg3
            ];
            installPhase = "echo true > $out";
          };
        pkg3 =
          { stdenv }:
          stdenv.mkDerivation {
            name = "hello-world";
            src = fixtures.empty;
            installPhase = "echo true > $out";
          };
      };
    })
    (f: [
      (import f.packages.x86_64-linux.default)
      (import f.packages.x86_64-linux.pkg2)
      (import f.packages.x86_64-linux.pkg3)
      (
        let
          pkgs' = nixpkgs.legacyPackages.x86_64-linux.extend f.overlays.default;
        in
        (pkgs' ? pkg1) && (pkgs' ? pkg2) && (pkgs' ? pkg3)
      )
      (f ? checks.x86_64-linux.packages-default)
      (f ? checks.x86_64-linux.packages-pkg2)
      (f ? checks.x86_64-linux.packages-pkg3)
    ])
    [
      true
      true
      true
      true
      true
      true
      true
    ]
  ];

  package-overlay-no-default = [
    (conflake' {
      package =
        { stdenv }:
        stdenv.mkDerivation {
          name = "pkg1";
          src = fixtures.empty;
          installPhase = "echo true > $out";
        };
    })
    (x: nixpkgs.legacyPackages.x86_64-linux.extend x.overlays.default)
    (x: x ? default)
    false
  ];

  packages-refer-default-as-default = [
    (conflake' {
      packages = {
        default =
          { stdenv }:
          stdenv.mkDerivation {
            name = "pkg1";
            src = fixtures.empty;
            installPhase = "echo true > $out";
          };
        pkg2 =
          { stdenv, default }:
          stdenv.mkDerivation {
            name = "hello-world";
            src = fixtures.empty;
            installPhase = "cat ${default} > $out";
          };
      };
    })
    (x: import x.packages.x86_64-linux.pkg2)
    true
  ];

  packages-refer-default-as-name = [
    (conflake' {
      packages = {
        default =
          { stdenv }:
          stdenv.mkDerivation {
            name = "pkg1";
            src = fixtures.empty;
            installPhase = "echo true > $out";
          };
        pkg2 =
          { stdenv, pkg1 }:
          stdenv.mkDerivation {
            name = "hello-world";
            src = fixtures.empty;
            installPhase = "cat ${pkg1} > $out";
          };
      };
    })
    (x: import x.packages.x86_64-linux.pkg2)
    true
  ];

  packages-fn-has-system = [
    (conflake' {
      packages =
        { system, ... }:
        (
          if system == "x86_64-linux" then
            {
              default =
                { stdenv }:
                stdenv.mkDerivation {
                  name = "pkg1";
                  src = fixtures.empty;
                  installPhase = "echo true > $out";
                };
            }
          else
            { }
        );
    })
    (x: [
      (import x.packages.x86_64-linux.default)
      (x.packages.aarch64-linux ? default)
    ])
    [
      true
      false
    ]
  ];

  legacyPackages-set-pkgs = [
    (conflake' {
      inputs = {
        inherit nixpkgs;
      };
      legacyPackages = pkgs: pkgs;
    })
    (x: x.legacyPackages.x86_64-linux.hello)
    nixpkgs.legacyPackages.x86_64-linux.hello
  ];

  legacyPackages-set-nixpkgs = [
    (conflake' {
      inputs = {
        inherit nixpkgs;
      };
      legacyPackages = pkgs: nixpkgs.legacyPackages.${pkgs.system};
    })
    (x: x.legacyPackages.x86_64-linux.hello)
    nixpkgs.legacyPackages.x86_64-linux.hello
  ];

  legacyPackages-set-attrs = [
    (conflake' {
      inputs = {
        inherit nixpkgs;
      };
      legacyPackages = pkgs: { };
    })
    (x: x.legacyPackages.x86_64-linux)
    { }
  ];

  legacyPackages-emacsPackages-empty = [
    (conflake' {
      legacyPackages = pkgs: {
        emacsPackages = { };
      };
      package =
        {
          emacs,
          emacsPackagesFor,
          extraPackages ? epkgs: [ ],
          overrides ? final: prev: { },
          ...
        }:
        let
          emacsPackages = (emacsPackagesFor emacs).overrideScope overrides;
          finalEmacs = emacsPackages.emacsWithPackages extraPackages;
        in
        finalEmacs;
    })
    (x: [
      (attrNames x.legacyPackages.x86_64-linux)
      (lib.hasPrefix "emacs-with-packages-" x.packages.x86_64-linux.default.name)
    ])
    [
      [ "emacsPackages" ]
      true
    ]
  ];

  devShell = test (conflake' {
    devShell = {
      inputsFrom = pkgs: [ pkgs.emacs ];
      packages = pkgs: [ pkgs.coreutils ];
      shellHook = ''
        echo Welcome to example shell!
      '';
      env.TEST_VAR = "test value";
      stdenv = pkgs: pkgs.clangStdenv;
      hardeningDisable = [ "all" ];
    };
  }) (f: isDerivation f.devShells.x86_64-linux.default);

  devShell-empty = test (conflake' {
    disabledModules = [ "presets/formatters.nix" ];
    devShell = { };
  }) (f: isDerivation f.devShells.x86_64-linux.default);

  devShell-pkgDef = test (conflake' {
    devShell = { mkShell }: mkShell { };
  }) (f: isDerivation f.devShells.x86_64-linux.default);

  devShell-pkgDef-empty = test (conflake' {
    disabledModules = [ "presets/formatters.nix" ];
    devShell = { mkShell }: mkShell { };
  }) (f: isDerivation f.devShells.x86_64-linux.default);

  devShell-pkgs-arg = test (conflake' {
    devShell = pkgs: {
      inputsFrom = [ pkgs.emacs ];
      packages = [ pkgs.coreutils ];
      shellHook = ''
        echo Welcome to example shell!
      '';
      env.TEST_VAR = "test value";
      stdenv = pkgs.clangStdenv;
    };
  }) (f: isDerivation f.devShells.x86_64-linux.default);

  devShell-pkgs-arg-set = test (conflake' {
    devShell =
      {
        emacs,
        coreutils,
        clangStdenv,
        ...
      }:
      {
        inputsFrom = [ emacs ];
        packages = [ coreutils ];
        shellHook = ''
          echo Welcome to example shell!
        '';
        env.TEST_VAR = "test value";
        stdenv = clangStdenv;
      };
  }) (f: isDerivation f.devShells.x86_64-linux.default);

  devShell-pkg = test (conflake' (
    { inputs, ... }:
    {
      systems = [ "x86_64-linux" ];
      devShell = inputs.nixpkgs.legacyPackages.x86_64-linux.hello;
    }
  )) (f: isDerivation f.devShells.x86_64-linux.default);

  devShell-pkg-fn = test (conflake' {
    devShell = pkgs: pkgs.hello;
  }) (f: isDerivation f.devShells.x86_64-linux.default);

  devShell-buildInputs = test (conflake' {
    devShell.buildInputs = pkgs: [ pkgs.hello ];
  }) (f: isDerivation f.devShells.x86_64-linux.default);

  devShells = [
    (conflake' {
      devShell.inputsFrom = pkgs: [ pkgs.emacs ];
      devShells = {
        shell1 = { mkShell }: mkShell { };
        shell2 = {
          packages = pkgs: [ pkgs.emacs ];
        };
        shell3 = pkgs: { packages = [ pkgs.emacs ]; };
        shell4 =
          { emacs, ... }:
          {
            packages = [ emacs ];
          };
      };
    })
    (x: [
      (isDerivation x.devShells.x86_64-linux.default)
      (isDerivation x.devShells.x86_64-linux.shell1)
      (isDerivation x.devShells.x86_64-linux.shell2)
      (isDerivation x.devShells.x86_64-linux.shell3)
      (isDerivation x.devShells.x86_64-linux.shell4)
    ])
    [
      true
      true
      true
      true
      true
    ]
  ];

  devShells-override = test (conflake' {
    devShells.default = { mkShellNoCC }: mkShellNoCC { };
  }) (f: f ? devShells.x86_64-linux.default);

  devShells-import = [
    (conflake' (
      { config, ... }:
      {
        devShell.inputsFrom = pkgs: [ pkgs.emacs ];
        devShells.shell1 = pkgs: { imports = [ (config.devShell pkgs) ]; };
      }
    ))
    (x: [
      (isDerivation x.devShells.x86_64-linux.default)
      (isDerivation x.devShells.x86_64-linux.shell1)
    ])
    [
      true
      true
    ]
  ];

  overlay = [
    (conflake' {
      overlay = final: prev: { testValue = "hello"; };
    })
    (x: fix (self: x.overlays.default self { }))
    { testValue = "hello"; }
  ];

  overlays = [
    (conflake' {
      overlay = final: prev: { testValue = "hello"; };
      overlays.cool = final: prev: { testValue = "cool"; };
    })
    (x: [
      (fix (self: x.overlays.default self { }))
      (fix (self: x.overlays.cool self { }))
    ])
    [
      { testValue = "hello"; }
      { testValue = "cool"; }
    ]
  ];

  overlay-empty = [
    (conflake' { overlay = final: prev: { }; })
    (x: x.overlays.default { } { })
    attrNames
    [ ]
  ];

  overlay-merge = [
    (conflake' {
      imports = [
        { overlay = final: prev: { testValue = "hello"; }; }
        { overlay = final: prev: { testValue2 = "hello2"; }; }
      ];
    })
    (x: fix (self: x.overlays.default self { }))
    {
      testValue = "hello";
      testValue2 = "hello2";
    }
  ];

  overlays-merge = [
    (conflake' {
      imports = [
        { overlays.test = final: prev: { testValue = "hello"; }; }
        { overlays.test = final: prev: { testValue2 = "hello2"; }; }
      ];
    })
    (x: fix (self: x.overlays.test self { }))
    {
      testValue = "hello";
      testValue2 = "hello2";
    }
  ];

  checks = [
    (conflake' {
      checks = {
        test-fail = pkgs: "exit 1";
        test-success = pkgs: pkgs.hello;
      };
    })
    (x: [
      ((x ? checks.x86_64-linux.test-fail) && (isDerivation x.checks.x86_64-linux.test-success))
      ((x ? checks.x86_64-linux.test-success) && (isDerivation x.checks.x86_64-linux.test-success))
    ])
    [
      true
      true
    ]
  ];

  app = [
    (conflake' {
      app = {
        type = "app";
        program = "${nixpkgs.legacyPackages.x86_64-linux.hello}/bin/hello";
      };
    })
    (x: x.apps.x86_64-linux.default)
    {
      type = "app";
      program = "${nixpkgs.legacyPackages.x86_64-linux.hello}/bin/hello";
    }
  ];

  app-fn = [
    (conflake' {
      app = pkgs: {
        type = "app";
        program = "${pkgs.hello}/bin/hello";
      };
    })
    (x: x.apps.x86_64-linux.default)
    {
      type = "app";
      program = "${nixpkgs.legacyPackages.x86_64-linux.hello}/bin/hello";
    }
  ];

  app-string = [
    (conflake' {
      inputs = {
        inherit nixpkgs;
      };
      app = "${nixpkgs.legacyPackages.x86_64-linux.hello}/bin/hello";
    })
    (x: x.apps.x86_64-linux.default)
    {
      type = "app";
      program = "${nixpkgs.legacyPackages.x86_64-linux.hello}/bin/hello";
    }
  ];

  app-string-fn = [
    (conflake' {
      inputs = {
        inherit nixpkgs;
      };
      app = pkgs: "${pkgs.hello}/bin/hello";
    })
    (x: x.apps.x86_64-linux.default)
    {
      type = "app";
      program = "${nixpkgs.legacyPackages.x86_64-linux.hello}/bin/hello";
    }
  ];

  apps = [
    (conflake' {
      inputs = {
        inherit nixpkgs;
      };
      apps = {
        emacs = pkgs: "${pkgs.emacs}/bin/emacs";
        bash = pkgs: {
          type = "app";
          program = "${pkgs.bash}/bin/bash";
        };
      };
    })
    (x: x.apps.x86_64-linux)
    {
      emacs = {
        type = "app";
        program = "${nixpkgs.legacyPackages.x86_64-linux.emacs}/bin/emacs";
      };
      bash = {
        type = "app";
        program = "${nixpkgs.legacyPackages.x86_64-linux.bash}/bin/bash";
      };
    }
  ];

  apps-fn = [
    (conflake' {
      inputs = {
        inherit nixpkgs;
      };
      apps =
        { emacs, bash, ... }:
        {
          emacs = "${emacs}/bin/emacs";
          bash = {
            type = "app";
            program = "${bash}/bin/bash";
          };
        };
    })
    (x: x.apps.x86_64-linux)
    {
      emacs = {
        type = "app";
        program = "${nixpkgs.legacyPackages.x86_64-linux.emacs}/bin/emacs";
      };
      bash = {
        type = "app";
        program = "${nixpkgs.legacyPackages.x86_64-linux.bash}/bin/bash";
      };
    }
  ];

  template = [
    (conflake' {
      template = {
        path = ./test;
        description = "test template";
      };
    })
    (x: x.templates.default)
    {
      path = ./test;
      description = "test template";
    }
  ];

  template-fn = [
    (conflake' {
      template =
        { inputs, ... }:
        {
          path = ./test;
          description = "test template";
        };
    })
    (x: x.templates.default)
    {
      path = ./test;
      description = "test template";
    }
  ];

  templates = [
    (conflake' {
      templates.test-template = {
        path = ./test;
        description = "test template";
      };
    })
    (x: x.templates.test-template)
    {
      path = ./test;
      description = "test template";
    }
  ];

  templates-welcomeText = [
    (conflake' {
      templates.test-template = {
        path = ./test;
        description = "test template";
        welcomeText = "hi";
      };
    })
    (x: x.templates.test-template)
    {
      path = ./test;
      description = "test template";
      welcomeText = "hi";
    }
  ];

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

  formatters-fn = [
    (conflake' {
      formatters =
        { rustfmt, ... }:
        {
          "*.rs" = "${rustfmt}";
        };
    })
    (x: x.formatter.x86_64-linux)
    isDerivation
    true
  ];

  formatters-no-devshell = [
    (conflake' {
      devShell = lib.mkForce null;
      formatters =
        { rustfmt, ... }:
        {
          "*.rs" = "${rustfmt}";
        };
    })
    (x: x.formatter.x86_64-linux)
    isDerivation
    true
  ];

  bundler = [
    (conflake' {
      bundler = x: x;
    })
    (x: x.bundlers.x86_64-linux.default nixpkgs.legacyPackages.x86_64-linux.hello)
    nixpkgs.legacyPackages.x86_64-linux.hello
  ];

  bundler-fn = [
    (conflake' {
      bundler = pkgs: x: pkgs.hello;
    })
    (x: x.bundlers.x86_64-linux.default nixpkgs.legacyPackages.x86_64-linux.emacs)
    nixpkgs.legacyPackages.x86_64-linux.hello
  ];

  bundlers = [
    (conflake' {
      bundlers = {
        hello = x: x;
      };
    })
    (x: x.bundlers.x86_64-linux.hello nixpkgs.legacyPackages.x86_64-linux.hello)
    nixpkgs.legacyPackages.x86_64-linux.hello
  ];

  bundlers-fn = [
    (conflake' {
      bundlers =
        { hello, ... }:
        {
          hello = x: hello;
        };
    })
    (x: x.bundlers.x86_64-linux.hello nixpkgs.legacyPackages.x86_64-linux.emacs)
    nixpkgs.legacyPackages.x86_64-linux.hello
  ];

  nixosConfigurations = test (conflake' (
    { lib, ... }:
    {
      nixosConfigurations.test = {
        system = "x86_64-linux";
        modules = [ { system.stateVersion = "24.05"; } ];
      };
    }
  )) (f: f ? nixosConfigurations.test.config.system.build.toplevel);

  nixosConfigurations-manual = test (conflake' (
    { lib, ... }:
    {
      nixosConfigurations.test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ { system.stateVersion = "24.05"; } ];
      };
    }
  )) (f: f ? nixosConfigurations.test.config.system.build.toplevel);

  nixosConfigurations-manualWithProp = [
    (conflake' (
      { lib, config, ... }:
      {
        nixosConfigurations.test = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            (
              { pkgs, ... }:
              {
                system.stateVersion = "24.05";
                environment.variables = {
                  TEST1 = config.finalInputs.nixpkgs.legacyPackages.x86_64-linux.hello;
                  TEST2 = config.finalInputs.nixpkgs.legacyPackages.${pkgs.system}.hello;
                };
              }
            )
          ];
        };
      }
    ))
    (x: [
      (x ? nixosConfigurations.test.config.system.build.toplevel)
      (
        x.nixosConfigurations.test.config.environment.variables.TEST1
        == x.nixosConfigurations.test.config.environment.variables.TEST2
      )
    ])
    [
      true
      true
    ]
  ];

  nixosModule = test (conflake' {
    nixosModule = { inputs, inputs', ... }: { };
  }) (f: f ? nixosModules.default);

  nixosModules = test (conflake' {
    nixosModules.test = _: { };
  }) (f: f ? nixosModules.test);

  homeModule = test (conflake' {
    homeModule = _: { };
  }) (f: f ? homeModules.default);

  homeModules = test (conflake' {
    homeModules.test = _: { };
  }) (f: f ? homeModules.test);

  conflakeModule = test (conflake' {
    conflakeModule = _: { };
  }) (f: f ? conflakeModules.default);

  conflakeModules = test (conflake' {
    conflakeModules.test = _: { };
  }) (f: f ? conflakeModules.test);

  lib = [
    (conflake' {
      lib.addFive = x: x + 5;
    })
    (f: f.lib.addFive 4)
    9
  ];

  functor = [
    (conflake' {
      outputs.testvalue = 5;
      functor = self: x: x + self.testvalue;
    })
    (f: f 4)
    9
  ];

  meta = [
    (conflake' {
      description = "aaa";
      license = "AGPL-3.0-only";
      packages.test =
        { writeTextFile, defaultMeta }:
        writeTextFile {
          name = "test";
          text = "";
          meta = defaultMeta;
        };
    })
    (f: [
      f.packages.x86_64-linux.test.meta.description
      f.packages.x86_64-linux.test.meta.license.spdxId
    ])
    [
      "aaa"
      "AGPL-3.0-only"
    ]
  ];

  meta-license-attrname = [
    (conflake' {
      license = "agpl3Only";
      packages.test =
        { writeTextFile, defaultMeta }:
        writeTextFile {
          name = "test";
          text = "";
          meta = defaultMeta;
        };
    })
    (f: f.packages.x86_64-linux.test.meta.license.spdxId)
    "AGPL-3.0-only"
  ];

  meta-licenses = [
    (conflake' {
      license = [
        "agpl3Only"
        "AGPL-3.0-or-later"
      ];
      packages.test =
        { writeTextFile, defaultMeta }:
        writeTextFile {
          name = "test";
          text = "";
          meta = defaultMeta;
        };
    })
    (f: f.packages.x86_64-linux.test.meta.license)
    isList
    true
  ];

  modulesPath = [
    (conflake' {
      disabledModules = [
        "config/functor.nix"
        "config/nixDir.nix"
      ];
      functor = _: _: true;
    })
    tryEval
    (x: x.success)
    false
  ];

  tests-empty = [
    (conflake' { tests = { }; })
    (x: x.checks.x86_64-linux.tests)
    isDerivation
    true
  ];

  tests-list = [
    (conflake' {
      tests = {
        test-list = [
          1
          1
        ];
      };
    })
    (x: x.checks.x86_64-linux.tests)
    isDerivation
    true
  ];

  tests-fn = [
    (conflake' {
      tests = { lib, ... }: { };
    })
    (x: x.checks.x86_64-linux.tests)
    isDerivation
    true
  ];

  presets-disable = [
    (conflake' {
      presets.enable = false;
    })
    { }
  ];

  presets-checks-editorconfig = [
    (conflake fixtures.editorconfig { })
    (x: x ? checks.x86_64-linux.editorconfig)
    true
  ];

  presets-checks-editorconfig-disabled = [
    (conflake fixtures.editorconfig {
      presets.checks.editorconfig.enable = false;
    })
    (x: x ? checks.x86_64-linux.editorconfig)
    false
  ];

  self-outputs = [
    inputs.self
    (x: [
      (x ? __functor)
      (x ? lib.mkOutputs)
      (attrNames x.templates.default)
      (x.templates.default.description != "default")
    ])
    [
      true
      true
      [
        "description"
        "path"
      ]
      true
    ]
  ];

  empty-flake = [
    (conflake' {
      disabledModules = [ "presets/default.nix" ];
    })
    { }
  ];

  default-nixpkgs = [
    (conflake' (
      { inputs, ... }:
      {
        outputs = {
          inherit inputs;
        };
      }
    ))
    (f: f.inputs ? nixpkgs.lib)
    true
  ];

  extend-mkOutputs = [
    (self.lib.mkOutputs.extend [
      {
        inherit inputs;
        outputs.test = true;
      }
    ])
    (extended: extended fixtures.empty { })
    (x: x.test)
    true
  ];

  extend-mkOutputs-nested = [
    (self.lib.mkOutputs.extend [
      {
        inherit inputs;
        outputs.test = true;
      }
    ])
    (extended: extended.extend [ { outputs.test2 = true; } ])
    (extended2: extended2.extend [ { outputs.test3 = true; } ])
    (extended3: extended3 fixtures.empty { })
    (x: [
      x.test
      x.test2
      x.test3
    ])
    [
      true
      true
      true
    ]
  ];

  demo-example = [
    (conflakeExample "demo" { })
    (f: attrNames f.overlays)
    [ "default" ]
  ];

  nixos-example = [
    (conflakeExample "nixos" { })
    (f: [
      (attrNames f.nixosConfigurations)
      (f.nixosConfigurations ? vm.config.system.build.toplevel)
      (attrNames f.nixosModules)
      (attrNames f.homeModules)
      (f.lib ? greeting.hi)
      f.lib.hello-world
    ])
    [
      [
        "vm"
        "vm-dir"
      ]
      true
      [
        "default"
        "greet"
        "hallo"
      ]
      [
        "default"
        "greet"
      ]
      true
      "Hello, World!"
    ]
  ];

  packages-example = [
    (conflakeExample "packages" { })
    (x: [
      (x.legacyPackages.x86_64-linux ? emacsPackages.greet)
      (attrNames x.packages.x86_64-linux)
      (attrNames x.devShells.x86_64-linux)
    ])
    [
      true
      [
        "default"
        "greet"
        "hei"
      ]
      [
        "default"
      ]
    ]
  ];
}
