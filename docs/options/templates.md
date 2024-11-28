# templates

The `template` and `templates` options allow you to set `templates`
outputs.

`templates` is an attribute set to template values.

`template` sets `templates.default`.

## Usage

For example:

```nix
conflake ./. {
  templates.test-template = {
    path = ./test;
    description = "test template";
  };
};
```
