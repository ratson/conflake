# Writing Tests

Conflake integrates [`lib.debug.runTests`][runTests] with `nix flake check`.

Here is a minimal `outputs` to define tests,

<<< @/../examples/tests/flake.nix#outputs{6-11}

## Running Tests

Run `nix flake check` will run the `tests` with
[`lib.debug.runTests`][runTests] along side with other checks.

To run only the tests,

```shell
# Print nothing when tests passed
nix build --no-link .#checks.x86_64-linux.tests
```

[runTests]: https://nixos.org/manual/nixpkgs/stable/#function-library-lib.debug.runTests

## File-based Tests

Additionally, `nix` files under `tests/`folder will be loaded and run with`nix
flake check` too.

Each test files should define a function returning an attribute set of test cases,
e.g.

<<< @/../examples/tests/tests/default.nix

The function arguments is a combination of `pkgs`, `moduleArgs` and
`presets.checks.tests.args`.

## List Form Test

Apart from attribute set `{expr, expected}` test,
test case can be defined as a list,
which is convenient when the testing value need to be transformed
before comparing against the expected value.

<<< @/../examples/tests/tests/list.nix
