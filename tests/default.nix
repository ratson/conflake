{ self, nixpkgs, ... }:

let
  inherit (nixpkgs) lib;

  test = flake: test: {
    expr = test flake;
    expected = true;
  };
  runTests = tests: lib.runTests (lib.mapAttrs' (k: v: lib.nameValuePair "test-${k}" v) tests);

  conflake = self;
  conflake' = conflake ./empty;
in
runTests {
  call-conflake = test (conflake' { outputs.test = true; }) (f: f.test);

  explicit-mkOutputs = test (conflake.lib.mkOutputs ./empty { outputs.test = true; }) (f: f.test);

  module-with-args = test (conflake' (
    { lib, config, ... }:
    {
      outputs.test = true;
    }
  )) (f: f.test);

  src-arg = test (conflake ./test-path (
    { src, ... }:
    {
      outputs = {
        inherit src;
      };
    }
  )) (f: f.src == ./test-path);

  lib-arg = test (conflake' (
    { lib, ... }:
    {
      outputs = {
        inherit lib;
      };
    }
  )) (f: f.lib ? fix);

  config-arg = test (conflake' (
    { config, ... }:
    {
      lib = {
        a = true;
      };
      outputs = {
        inherit config;
      };
    }
  )) (f: f.config.lib.a);

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

  moduleArgs-arg = {
    expr =
      (conflake' (
        { inputs, ... }:
        {
          moduleArgs.extra = {
            username = "user";
          };
          outputs =
            { username, ... }:
            {
              test = username;
            };
        }
      )).test;
    expected = "user";
  };

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

  moduleArgs =
    test
      (conflake' (
        { moduleArgs, ... }:
        {
          outputs = {
            inherit moduleArgs;
          };
        }
      ))
      (
        f:
        f.moduleArgs ? config
        && f.moduleArgs ? options
        && f.moduleArgs ? src
        && f.moduleArgs ? lib
        && f.moduleArgs ? conflake
        && f.moduleArgs ? inputs
        && f.moduleArgs ? outputs
        && f.moduleArgs ? pkgsFor
        && f.moduleArgs ? specialArgs
        && f.moduleArgs ? modulesPath
        && f.moduleArgs ? moduleArgs
      );

  moduleArgs-add = test (conflake' {
    _module.args.test-val = true;
    outputs =
      { test-val, ... }:
      {
        test = test-val;
      };
  }) (f: f.test);

  extra-pkgs-vals = test (conflake' {
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
  }) (f: f.packages.x86_64-linux.default.name == "test");

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

  systems =
    test
      (conflake' {
        systems = [
          "i686-linux"
          "armv7l-linux"
        ];
        perSystem = _: { test = true; };
      })
      (
        f:
        (builtins.attrNames f.test) == [
          "armv7l-linux"
          "i686-linux"
        ]
      );

  all-flakes-systems = test (conflake' (
    { lib, ... }:
    {
      systems = lib.systems.flakeExposed;
      perSystem = _: { test = true; };
    }
  )) (f: builtins.deepSeq f.test f.test.x86_64-linux);

  all-linux-systems = test (conflake' (
    { lib, ... }:
    {
      systems = lib.intersectLists lib.systems.doubles.linux lib.systems.flakeExposed;
      perSystem = _: { test = true; };
    }
  )) (f: builtins.deepSeq f.test f.test.x86_64-linux);

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
    expr =
      builtins.attrNames
        (conflake' {
          perSystem =
            { src, ... }:
            {
              test.a.b.c = true;
            };
        }).test;

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

  package =
    test
      (conflake' {
        package =
          { stdenv }:
          stdenv.mkDerivation {
            pname = "pkg1";
            version = "0.0.1";
            src = ./empty;
            installPhase = "echo true > $out";
          };
      })
      (
        f:
        (import f.packages.x86_64-linux.default)
        && (f ? packages.aarch64-linux.default)
        && ((nixpkgs.legacyPackages.x86_64-linux.extend f.overlays.default) ? pkg1)
        && (f ? checks.x86_64-linux.packages-default)
        && (f ? checks.aarch64-linux.packages-default)
      );

  packages =
    test
      (conflake' {
        packages = {
          default =
            { stdenv }:
            stdenv.mkDerivation {
              name = "pkg1";
              src = ./empty;
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
              src = ./empty;
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
              src = ./empty;
              installPhase = "echo true > $out";
            };
        };
      })
      (
        f:
        (import f.packages.x86_64-linux.default)
        && (import f.packages.x86_64-linux.pkg2)
        && (import f.packages.x86_64-linux.pkg3)
        && (
          let
            pkgs' = nixpkgs.legacyPackages.x86_64-linux.extend f.overlays.default;
          in
          (pkgs' ? pkg1) && (pkgs' ? pkg2) && (pkgs' ? pkg3)
        )
        && (f ? checks.x86_64-linux.packages-default)
        && (f ? checks.x86_64-linux.packages-pkg2)
        && (f ? checks.x86_64-linux.packages-pkg3)
      );

  package-overlay-no-default = test (conflake' {
    package =
      { stdenv }:
      stdenv.mkDerivation {
        name = "pkg1";
        src = ./empty;
        installPhase = "echo true > $out";
      };
  }) (f: !((nixpkgs.legacyPackages.x86_64-linux.extend f.overlays.default) ? default));

  packages-refer-default-as-default = test (conflake' {
    packages = {
      default =
        { stdenv }:
        stdenv.mkDerivation {
          name = "pkg1";
          src = ./empty;
          installPhase = "echo true > $out";
        };
      pkg2 =
        { stdenv, default }:
        stdenv.mkDerivation {
          name = "hello-world";
          src = ./empty;
          installPhase = "cat ${default} > $out";
        };
    };
  }) (f: (import f.packages.x86_64-linux.pkg2));

  packages-refer-default-as-name = test (conflake' {
    packages = {
      default =
        { stdenv }:
        stdenv.mkDerivation {
          name = "pkg1";
          src = ./empty;
          installPhase = "echo true > $out";
        };
      pkg2 =
        { stdenv, pkg1 }:
        stdenv.mkDerivation {
          name = "hello-world";
          src = ./empty;
          installPhase = "cat ${pkg1} > $out";
        };
    };
  }) (f: (import f.packages.x86_64-linux.pkg2));

  packages-fn-has-system = test (conflake' {
    packages =
      { system, ... }:
      (
        if system == "x86_64-linux" then
          {
            default =
              { stdenv }:
              stdenv.mkDerivation {
                name = "pkg1";
                src = ./empty;
                installPhase = "echo true > $out";
              };
          }
        else
          { }
      );
  }) (f: (import f.packages.x86_64-linux.default) && !(f.packages.aarch64-linux ? default));

  legacyPackages-set-pkgs = test (conflake' {
    inputs = {
      inherit nixpkgs;
    };
    legacyPackages = pkgs: pkgs;
  }) (f: f.legacyPackages.x86_64-linux.hello == nixpkgs.legacyPackages.x86_64-linux.hello);

  legacyPackages-set-nixpkgs = test (conflake' {
    inputs = {
      inherit nixpkgs;
    };
    legacyPackages = pkgs: nixpkgs.legacyPackages.${pkgs.system};
  }) (f: f.legacyPackages.x86_64-linux.hello == nixpkgs.legacyPackages.x86_64-linux.hello);

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
  }) (f: lib.isDerivation f.devShells.x86_64-linux.default);

  devShell-empty = test (conflake' {
    disabledModules = [ "presets/formatters.nix" ];
    devShell = { };
  }) (f: lib.isDerivation f.devShells.x86_64-linux.default);

  devShell-pkgDef = test (conflake' {
    devShell = { mkShell }: mkShell { };
  }) (f: lib.isDerivation f.devShells.x86_64-linux.default);

  devShell-pkgDef-empty = test (conflake' {
    disabledModules = [ "presets/formatters.nix" ];
    devShell = { mkShell }: mkShell { };
  }) (f: lib.isDerivation f.devShells.x86_64-linux.default);

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
  }) (f: lib.isDerivation f.devShells.x86_64-linux.default);

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
  }) (f: lib.isDerivation f.devShells.x86_64-linux.default);

  devShell-pkg = test (conflake' (
    { inputs, ... }:
    {
      systems = [ "x86_64-linux" ];
      devShell = inputs.nixpkgs.legacyPackages.x86_64-linux.hello;
    }
  )) (f: lib.isDerivation f.devShells.x86_64-linux.default);

  devShell-pkg-fn = test (conflake' {
    devShell = pkgs: pkgs.hello;
  }) (f: lib.isDerivation f.devShells.x86_64-linux.default);

  devShells =
    test
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
      (
        f:
        (lib.isDerivation f.devShells.x86_64-linux.default)
        && (lib.isDerivation f.devShells.x86_64-linux.shell1)
        && (lib.isDerivation f.devShells.x86_64-linux.shell2)
        && (lib.isDerivation f.devShells.x86_64-linux.shell3)
        && (lib.isDerivation f.devShells.x86_64-linux.shell4)
      );

  devShells-override = test (conflake' {
    devShells.default = { mkShell }: mkShell { };
  }) (f: f ? devShells.x86_64-linux.default);

  devShells-import =
    test
      (conflake' (
        { config, ... }:
        {
          devShell.inputsFrom = pkgs: [ pkgs.emacs ];
          devShells.shell1 = pkgs: { imports = [ (config.devShell pkgs) ]; };
        }
      ))
      (
        f:
        (lib.isDerivation f.devShells.x86_64-linux.default)
        && (lib.isDerivation f.devShells.x86_64-linux.shell1)
      );

  overlay = test (conflake' {
    overlay = final: prev: { testValue = "hello"; };
  }) (f: (lib.fix (self: f.overlays.default self { })) == { testValue = "hello"; });

  overlays =
    test
      (conflake' {
        overlay = final: prev: { testValue = "hello"; };
        overlays.cool = final: prev: { testValue = "cool"; };
      })
      (
        f:
        ((lib.fix (self: f.overlays.default self { })) == { testValue = "hello"; })
        && ((lib.fix (self: f.overlays.cool self { })) == { testValue = "cool"; })
      );

  overlay-merge =
    test
      (conflake' {
        imports = [
          { overlay = final: prev: { testValue = "hello"; }; }
          { overlay = final: prev: { testValue2 = "hello2"; }; }
        ];
      })
      (
        f:
        (
          (lib.fix (self: f.overlays.default self { })) == {
            testValue = "hello";
            testValue2 = "hello2";
          }
        )
      );

  overlays-merge =
    test
      (conflake' {
        imports = [
          { overlays.test = final: prev: { testValue = "hello"; }; }
          { overlays.test = final: prev: { testValue2 = "hello2"; }; }
        ];
      })
      (
        f:
        (
          (lib.fix (self: f.overlays.test self { })) == {
            testValue = "hello";
            testValue2 = "hello2";
          }
        )
      );

  checks =
    test
      (conflake' {
        checks = {
          test-fail = pkgs: "exit 1";
          test-success = pkgs: pkgs.hello;
        };
      })
      (
        f:
        (f ? checks.x86_64-linux.test-fail)
        && (lib.isDerivation f.checks.x86_64-linux.test-success)
        && (f ? checks.x86_64-linux.test-success)
        && (lib.isDerivation f.checks.x86_64-linux.test-success)
      );

  app =
    test
      (conflake' {
        app = {
          type = "app";
          program = "${nixpkgs.legacyPackages.x86_64-linux.hello}/bin/hello";
        };
      })
      (
        f:
        (
          f.apps.x86_64-linux.default == {
            type = "app";
            program = "${nixpkgs.legacyPackages.x86_64-linux.hello}/bin/hello";
          }
        )
      );

  app-fn =
    test
      (conflake' {
        app = pkgs: {
          type = "app";
          program = "${pkgs.hello}/bin/hello";
        };
      })
      (
        f:
        (
          f.apps.x86_64-linux.default == {
            type = "app";
            program = "${nixpkgs.legacyPackages.x86_64-linux.hello}/bin/hello";
          }
        )
      );

  app-string =
    test
      (conflake' {
        inputs = {
          inherit nixpkgs;
        };
        app = "${nixpkgs.legacyPackages.x86_64-linux.hello}/bin/hello";
      })
      (
        f:
        (
          f.apps.x86_64-linux.default == {
            type = "app";
            program = "${nixpkgs.legacyPackages.x86_64-linux.hello}/bin/hello";
          }
        )
      );

  app-string-fn =
    test
      (conflake' {
        inputs = {
          inherit nixpkgs;
        };
        app = pkgs: "${pkgs.hello}/bin/hello";
      })
      (
        f:
        (
          f.apps.x86_64-linux.default == {
            type = "app";
            program = "${nixpkgs.legacyPackages.x86_64-linux.hello}/bin/hello";
          }
        )
      );

  apps =
    test
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
      (
        f:
        f.apps.x86_64-linux == {
          emacs = {
            type = "app";
            program = "${nixpkgs.legacyPackages.x86_64-linux.emacs}/bin/emacs";
          };
          bash = {
            type = "app";
            program = "${nixpkgs.legacyPackages.x86_64-linux.bash}/bin/bash";
          };
        }
      );

  apps-fn =
    test
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
      (
        f:
        f.apps.x86_64-linux == {
          emacs = {
            type = "app";
            program = "${nixpkgs.legacyPackages.x86_64-linux.emacs}/bin/emacs";
          };
          bash = {
            type = "app";
            program = "${nixpkgs.legacyPackages.x86_64-linux.bash}/bin/bash";
          };
        }
      );

  template = {
    expr =
      (conflake' {
        template = {
          path = ./test;
          description = "test template";
        };
      }).templates.default;

    expected = {
      path = ./test;
      description = "test template";
    };
  };

  template-fn =
    test
      (conflake' {
        template =
          { inputs, ... }:
          {
            path = ./test;
            description = "test template";
          };
      })
      (
        f:
        f.templates.default == {
          path = ./test;
          description = "test template";
        }
      );

  templates =
    test
      (conflake' {
        templates.test-template = {
          path = ./test;
          description = "test template";
        };
      })
      (
        f:
        f.templates.test-template == {
          path = ./test;
          description = "test template";
        }
      );

  templates-welcomeText =
    test
      (conflake' {
        templates.test-template = {
          path = ./test;
          description = "test template";
          welcomeText = "hi";
        };
      })
      (
        f:
        f.templates.test-template == {
          path = ./test;
          description = "test template";
          welcomeText = "hi";
        }
      );

  formatter = test (conflake' {
    formatter = pkgs: pkgs.hello;
  }) (f: lib.isDerivation f.formatter.x86_64-linux);

  formatters = test (conflake' {
    devShell.packages = pkgs: [ pkgs.rustfmt ];
    formatters = {
      "*.rs" = "rustfmt";
    };
  }) (f: lib.isDerivation f.formatter.x86_64-linux);

  formatters-fn = test (conflake' {
    formatters =
      { rustfmt, ... }:
      {
        "*.rs" = "${rustfmt}";
      };
  }) (f: lib.isDerivation f.formatter.x86_64-linux);

  formatters-no-devshell = test (conflake' {
    devShell = lib.mkForce null;
    formatters =
      { rustfmt, ... }:
      {
        "*.rs" = "${rustfmt}";
      };
  }) (f: lib.isDerivation f.formatter.x86_64-linux);

  formatters-disable = test (conflake' {
    presets.formatters = false;
  }) (f: !f ? formatter.x86_64-linux);

  formatters-disable-only-builtin = test (conflake' {
    presets.formatters = false;
    formatters =
      { rustfmt, ... }:
      {
        "*.rs" = "rustfmt";
      };
  }) (f: f ? formatter.x86_64-linux);

  bundler =
    test
      (conflake' {
        bundler = x: x;
      })
      (
        f:
        (f.bundlers.x86_64-linux.default nixpkgs.legacyPackages.x86_64-linux.hello)
        == nixpkgs.legacyPackages.x86_64-linux.hello
      );

  bundler-fn =
    test
      (conflake' {
        bundler = pkgs: x: pkgs.hello;
      })
      (
        f:
        (f.bundlers.x86_64-linux.default nixpkgs.legacyPackages.x86_64-linux.emacs)
        == nixpkgs.legacyPackages.x86_64-linux.hello
      );

  bundlers =
    test
      (conflake' {
        bundlers = {
          hello = x: x;
        };
      })
      (
        f:
        (f.bundlers.x86_64-linux.hello nixpkgs.legacyPackages.x86_64-linux.hello)
        == nixpkgs.legacyPackages.x86_64-linux.hello
      );

  bundlers-fn =
    test
      (conflake' {
        bundlers =
          { hello, ... }:
          {
            hello = x: hello;
          };
      })
      (
        f:
        (f.bundlers.x86_64-linux.hello nixpkgs.legacyPackages.x86_64-linux.emacs)
        == nixpkgs.legacyPackages.x86_64-linux.hello
      );

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

  nixosConfigurations-manualWithProp =
    test
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
                    TEST1 = config.inputs.nixpkgs.legacyPackages.x86_64-linux.hello;
                    TEST2 = config.inputs.nixpkgs.legacyPackages.${pkgs.system}.hello;
                  };
                }
              )
            ];
          };
        }
      ))
      (
        f:
        (f ? nixosConfigurations.test.config.system.build.toplevel)
        && (
          f.nixosConfigurations.test.config.environment.variables.TEST1
          == f.nixosConfigurations.test.config.environment.variables.TEST2
        )
      );

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

  lib = test (conflake' {
    lib.addFive = x: x + 5;
  }) (f: f.lib.addFive 4 == 9);

  functor = test (conflake' {
    outputs.testvalue = 5;
    functor = self: x: x + self.testvalue;
  }) (f: f 4 == 9);

  meta =
    test
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
      (
        f:
        (f.packages.x86_64-linux.test.meta.description == "aaa")
        && (f.packages.x86_64-linux.test.meta.license.spdxId == "AGPL-3.0-only")
      );

  meta-license-attrname = test (conflake' {
    license = "agpl3Only";
    packages.test =
      { writeTextFile, defaultMeta }:
      writeTextFile {
        name = "test";
        text = "";
        meta = defaultMeta;
      };
  }) (f: f.packages.x86_64-linux.test.meta.license.spdxId == "AGPL-3.0-only");

  meta-licenses = test (conflake' {
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
  }) (f: builtins.isList f.packages.x86_64-linux.test.meta.license);

  editorconfig = test (conflake ./editorconfig { }) (f: f ? checks.x86_64-linux.editorconfig);

  editorconfig-disabled = test (conflake ./editorconfig {
    editorconfig.check = false;
  }) (f: !f ? checks.x86_64-linux.editorconfig);

  modulesPath = test (conflake' {
    disabledModules = [
      "config/functor.nix"
      "config/nixDir.nix"
    ];
    functor = _: _: true;
  }) (f: !(builtins.tryEval f).success);

  empty-flake = {
    expr = conflake' {
      disabledModules = [ "presets/formatters.nix" ];
    };
    expected = { };
  };

  default-nixpkgs = test (conflake' (
    { inputs, ... }:
    {
      outputs = {
        inherit inputs;
      };
    }
  )) (f: f.inputs ? nixpkgs.lib);

  extend-mkOutputs =
    let
      extended = conflake.lib.mkOutputs.extend [ { outputs.test = true; } ];
    in
    test (extended ./empty { }) (f: f.test);

  extend-mkOutputs-nested =
    let
      extended = conflake.lib.mkOutputs.extend [ { outputs.test = true; } ];
      extended2 = extended.extend [ { outputs.test2 = true; } ];
      extended3 = extended2.extend [ { outputs.test3 = true; } ];
    in
    test (extended3 ./empty { }) (f: f.test && f.test2 && f.test3);

  demo-example = test (conflake ../examples/demo { }) (f: f.overlays ? default);

  nixos-example = test (conflake ../examples/nixos { }) (
    f:
    f.nixosConfigurations ? vm.config.system.build.toplevel
    && f.nixosModules ? default
    && f.nixosModules ? hallo
    && f.homeModules ? default
  );

  packages-example = test (conflake ../examples/packages { }) (
    f:
    f.legacyPackages.x86_64-linux ? emacsPackages.greet
    && f.packages.x86_64-linux ? greet
    && f.devShells.x86_64-linux ? default
  );

  self-outputs = test self (
    f:
    f ? __functor
    && f ? lib.mkOutputs
    && f ? templates.default.path
    && f.templates.default.description != "default"
  );
}
