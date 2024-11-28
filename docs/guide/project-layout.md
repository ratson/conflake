# Project Layout

Instead of configuring everything in `flake.nix`, Conflake can derive `outputs` according to your project directory structure.

<script setup>
import { data } from './project-layout.data'
</script>

Considering the following directory structure, from [`examples/demo`](https://github.com/ratson/conflake/tree/main/examples/demo):

```-vue
{{ data.tree }}
```

It will result a flake output like:

::: code-group

```-vue [nix flake show]
{{ data.text }}
```

```json-vue [JSON]
{{ data.json }}
```

:::

Notice that `darwin`, `home` and `nixos` are shorthand mapping to `darwinConfigurations`, [`homeConfigurations`](../options/homeConfigurations.md) and [`nixosConfigurations`](../options/nixosConfigurations.md) respectively.
