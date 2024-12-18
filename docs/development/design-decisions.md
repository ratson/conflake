# Design Decisions

This document attempts to describe some design choices of the project, helping to
understand the rationale behind the development or omission of certain features.

## Using the module system

- Validate user options
- Merge attributes into final `outptus`
- Extensible

## Straightforward mapping flake attributes to files

- No new concepts
- Predictable

## Default branch to `release`

- Minimize download size
- Keep `inputs.url` short as `github:ratson/conflake`

## Load files from `nix/`

- Indicate files under the folder are loaded by `Conflake`
- Non-Nix projects could use identical folder names for different tasks
- It can be changed if desirable
