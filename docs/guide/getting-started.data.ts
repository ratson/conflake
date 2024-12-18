import { $ } from "execa";
import { defineLoader } from "vitepress";

export default defineLoader({
  async load() {
    const [templateFiles] = await Promise.all([
      ($({
        cwd: "../nix/templates/default",
      })`tree -aF --noreport .`).then((
        x,
      ) => x.stdout),
    ]);

    return { templateFiles };
  },
});
