# outputs

The `outputs` option allows you to directly configure flake outputs. This should
be used for porting or for configuring output attrs not otherwise supported by
Conflake.

The option value may be an attrset or a function that takes `moduleArgs` and
returns and attrset.

# Usage

It can be used to configure any output.

For example, to add a `example.test` output to your flake you could do the following:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      outputs = {
        example.test = "hello";
      };
    };
}
```

With the above, `nix eval .#example.test` will output "hello".
