{ self, nixpkgs, ... }@inputs:

let
  inherit (builtins) attrNames;
  inherit (nixpkgs) lib;

  test = flake: test: assert test flake; true;

  conflake = self;
  conflake' = conflake ./. inputs;
in
{
  call-functor = test
    (conflake' {
      outputs.test = true;
    })
    (f: f.test);

  module-with-args = test
    (conflake' ({ ... }: { outputs.test = true; }))
    (f: f.test);

  conflake-arg = test
    (conflake' ({ conflake, ... }: {
      outputs = { inherit conflake; };
    }))
    (f: f.conflake ? mkOutputs);

  inputs-arg = test
    (conflake' ({ inputs, ... }: {
      outputs = { inherit inputs; };
    }))
    (f: f.inputs ? nixpkgs);

  inputs'-arg = test
    (conflake' {
      systems = [ "x86_64-linux" ];
      inputs.a.attr.x86_64-linux = true;
      perSystem = { inputs', ... }: { test = inputs'.a.attr && true; };
    })
    (f: f.test.x86_64-linux);

  lib-arg = test
    (conflake' ({ lib, ... }: {
      outputs = { inherit lib; };
    }))
    (f: f.lib ? fix);

  devShell = test
    (conflake' {
      devShell = { pkgs, ... }: pkgs.mkShell {
        inputsFrom = [ pkgs.hello ];
        packages = [ pkgs.cowsay ];
        shellHook = ''
          echo Welcome to example shell!
        '';
        env.TEST_VAR = "test value";
        stdenv = pkgs.clangStdenv;
      };
    })
    (f: lib.isDerivation f.devShells.x86_64-linux.default);

  # devShell-pkgs-arg = test
  #   (conflake' {
  #     devShell = { pkgs, ... }: {
  #       inputsFrom = [ pkgs.hello ];
  #       packages = [ pkgs.cowsay ];
  #       shellHook = ''
  #         echo Welcome to example shell!
  #       '';
  #       env.TEST_VAR = "test value";
  #       stdenv = pkgs.clangStdenv;
  #     };
  #   })
  #   (f: lib.isDerivation f.devShells.x86_64-linux.default);

  moduleArgs-add = test
    (conflake' {
      _module.args.test-val = true;
      outputs = { test-val, ... }: {
        test = test-val;
      };
    })
    (f: f.test);

  nixosConfigurations = test
    (conflake' ({ lib, ... }: {
      nixosConfigurations.test = {
        system = "x86_64-linux";
        modules = [{ system.stateVersion = "24.11"; }];
      };
    }))
    (f: f ? nixosConfigurations.test.config.system.build.toplevel);

  nixosConfigurations-manual = test
    (conflake' ({ lib, ... }: {
      nixosConfigurations.test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [{ system.stateVersion = "24.11"; }];
      };
    }))
    (f: f ? nixosConfigurations.test.config.system.build.toplevel);

  nixosConfigurations-manualWithProp = test
    (conflake' ({ lib, config, ... }: {
      nixosConfigurations.test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          config.argsModule
          ({ inputs, inputs', ... }: {
            system.stateVersion = "24.11";
            environment.variables = {
              TEST1 = inputs.nixpkgs.legacyPackages.x86_64-linux.hello;
              TEST2 = inputs'.nixpkgs.legacyPackages.hello;
            };
          })
        ];
      };
    }))
    (f: (f ? nixosConfigurations.test.config.system.build.toplevel)
      && (f.nixosConfigurations.test.config.environment.variables.TEST1 ==
      f.nixosConfigurations.test.config.environment.variables.TEST2));

  nixosModule = test
    (conflake' {
      nixosModule = _: { };
    })
    (f: f ? nixosModules.default);

  nixosModules = test
    (conflake' {
      nixosModules.test = _: { };
    })
    (f: f ? nixosModules.test);

  overlays = test
    (conflake' {
      overlay = final: prev: { testValue = "hello"; };
      overlays.cool = final: prev: { testValue = "cool"; };
    })
    (f:
      ((lib.fix (self: f.overlays.default self { })) ==
      { testValue = "hello"; })
      && ((lib.fix (self: f.overlays.cool self { })) ==
      { testValue = "cool"; }));

  overlay-merge = test
    (conflake' {
      imports = [
        { overlay = final: prev: { testValue = "hello"; }; }
        { overlay = final: prev: { testValue2 = "hello2"; }; }
      ];
    })
    (f: ((lib.fix (self: f.overlays.default self { })) ==
      { testValue = "hello"; testValue2 = "hello2"; }));

  overlays-merge = test
    (conflake' {
      imports = [
        { overlays.test = final: prev: { testValue = "hello"; }; }
        { overlays.test = final: prev: { testValue2 = "hello2"; }; }
      ];
    })
    (f: ((lib.fix (self: f.overlays.test self { })) ==
      { testValue = "hello"; testValue2 = "hello2"; }));

  packages = test
    (conflake' {
      pname = "pkg1";
      packages = {
        default = { stdenv, ... }:
          stdenv.mkDerivation {
            name = "pkg1";
            src = ./.;
            installPhase = "echo true > $out";
          };
        pkg2 = { stdenv, pkg1, pkg3, ... }:
          stdenv.mkDerivation {
            name = "hello-world";
            src = ./.;
            nativeBuildInputs = [ pkg1 pkg3 ];
            installPhase = "echo true > $out";
          };
        pkg3 = { stdenv, ... }:
          stdenv.mkDerivation {
            name = "hello-world";
            src = ./.;
            installPhase = "echo true > $out";
          };
      };
    })
    (f:
      (import f.packages.x86_64-linux.default)
      && (import f.packages.x86_64-linux.pkg2)
      && (import f.packages.x86_64-linux.pkg3)
      && (
        let
          pkgs' = nixpkgs.legacyPackages.x86_64-linux.extend f.overlays.default;
        in
        (pkgs' ? pkg1) && (pkgs' ? pkg2) && (pkgs' ? pkg3)
      )
      # && (f ? checks.x86_64-linux.packages-default)
      # && (f ? checks.x86_64-linux.packages-pkg2)
      # && (f ? checks.x86_64-linux.packages-pkg3)
    );

  package-overlay-no-default = test
    (conflake' {
      package = { stdenv }:
        stdenv.mkDerivation {
          name = "pkg1";
          src = ./.;
          installPhase = "echo true > $out";
        };
    })
    (f: !((nixpkgs.legacyPackages.x86_64-linux.extend f.overlays.default)
      ? default));

  template = test
    (conflake' {
      template = {
        path = ./test;
        description = "test template";
      };
    })
    (f: f.templates.default == {
      path = ./test;
      description = "test template";
    });

  template-module = test
    (conflake' {
      template = { inputs, ... }: {
        path = ./test;
        description = "test template";
      };
    })
    (f: f.templates.default == {
      path = ./test;
      description = "test template";
    });

  templates = test
    (conflake' {
      templates.test-template = {
        path = ./test;
        description = "test template";
      };
    })
    (f: f.templates.test-template == {
      path = ./test;
      description = "test template";
    });

  templates-welcomeText = test
    (conflake' {
      templates.test-template = {
        path = ./test;
        description = "test template";
        welcomeText = "hi";
      };
    })
    (f: f.templates.test-template == {
      path = ./test;
      description = "test template";
      welcomeText = "hi";
    });

  systems = test
    (conflake' {
      systems = [ "i686-linux" "armv7l-linux" ];
      perSystem = _: { test = true; };
    })
    (f: (attrNames f.test) == [ "armv7l-linux" "i686-linux" ]);

  homeModule = test
    (conflake' {
      homeModule = _: { };
    })
    (f: f ? homeModules.default);

  homeModules = test
    (conflake' {
      homeModules.test = _: { };
    })
    (f: f ? homeModules.test);

  default-nixpkgs = test
    (conflake' ({ inputs, ... }: {
      outputs = { inherit inputs; };
    }))
    (f: f.inputs ? nixpkgs.lib);

  nixos-example = test
    (conflake ../examples/nixos inputs { })
    (f: f.nixosConfigurations ? vm.config.system.build.toplevel
      && f.nixosModules ? default
      && f.homeModules ? default);

  packages-example = test
    (conflake ../examples/packages inputs { })
    (f: f.packages.x86_64-linux ? greet
      && f.devShells.x86_64-linux ? default);

  self-outputs = test
    self
    (f: f ? __functor
      && f ? lib.conflake);
}
