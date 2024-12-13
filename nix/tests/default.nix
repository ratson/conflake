{
  lib,
  conflake,
  inputs,
  ...
}:

let
  inherit (lib) pipe;
in
conflake.withPrefix "test-" {
  self-outputs = {
    expr = pipe inputs.self [
      (x: [
        (x ? __functor)
        (x ? lib.mkOutputs)
        (x ? templates.default.path)
        (x.templates.default.description != "default")
      ])
    ];
    expected = [
      true
      true
      true
      true
    ];
  };

}
