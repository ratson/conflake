# Design Decisions

This document attempts to describe some design choices of the project, to help
understanding why some features are developed / not developed.

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
