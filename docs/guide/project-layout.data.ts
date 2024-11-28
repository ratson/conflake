import { $ } from "execa";
import stripAnsi from "strip-ansi";
import { defineLoader } from "vitepress";

export default defineLoader({
  async load() {
    const cwd = "../examples/demo";
    const [tree, text, json] = await Promise.all([
      ($({
        cwd: "..",
      })`tree -aF --noreport -I run.sh -I flake.lock examples/demo`).then((x) =>
        x.stdout
      ),
      ($({ cwd })`nix flake show --all-systems`).then((x) =>
        stripAnsi(x.stdout).replace(
          /^(.*:\/\/\/).+(\?[^\n]+)/,
          "$1tmp/conflake$2",
        )
      ),
      ($({ cwd })`nix flake show --all-systems --json`).then((x) =>
        JSON.parse(x.stdout)
      ),
    ]);

    return { tree, text, json };
  },
});
