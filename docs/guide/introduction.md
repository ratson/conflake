# What is Conflake?

A batteries included, convention-based configuration framework for Nix Flakes.

## Features

- Auto-load files into `outputs` attribute set according to [project layout](./project-layout.md)
- Provide `outputs` and `perSystem` options for flexible configuration
- Handle generating per-system attributes, with
  [`nix-systems`](../options/systems.md#nix-systems) support
- Given package definitions, generates package and overlay outputs
- Enable `nix fmt` for common file types
- Easy to [write and run tests](./writing-tests.md)
- Extensible using the module system

## Why I Need This

If you are using `builtins.readDir` to manage your Nix configuration,
this project can help you minimize much of the boilerplate code.

A shared framework like this makes it easier for readers
to navigate the project's file structure.

## Trade-offs

This project introduces substantial amount of code to your project,
and any bugs could prevent your configuration from building successfully.

There is a performance overhead with extra runtime checks and module evaluations
when compared to handcrafted imports.

Running `nix flake update` without reviewing the changes
and updating your code accordingly may disrupt your project.

Adding an additional `inputs` entry may not be appropriate for flakes intended
to be used by others.

Misusing the module system can result in infinite recursion errors.

Nix files or folder that you don't want auto-loaded need to begin with `_`.
