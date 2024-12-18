import { $ } from "execa";

export default {
  async paths() {
    const { stdout } = await $`nix flake show --json`;
    const { templates } = JSON.parse(stdout) as {
      templates: Record<string, { description: string }>;
    };
    const data = (await Promise.all(
      Object.entries(templates).map(async ([k, v]) => ({
        ...v,
        name: k,
        hash: k === "default" ? "" : `#${k}`,
        tree: (await $({ cwd: `../nix/templates/${k}` })`tree -a --noreport .`)
          .stdout,
      })),
    )).map((x) => ({
      params: { name: x.name },
      content: `
${x.description}

\`\`\`shell
nix flake init -t github:ratson/conflake${x.hash}
\`\`\`

## Files

\`\`\`
${x.tree}
\`\`\`

[View on GitHub](https://github.com/ratson/conflake/tree/release/nix/templates/${x.name})
      `.trim(),
    }));
    return data;
  },
};
