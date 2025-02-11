import fs from "node:fs/promises";
import { replaceInFile } from "replace-in-file";
import { defineConfig } from "vitepress";
import templates from "../templates/[name].paths.ts";

const base = "/conflake/";

const hostname = `https://ratson.github.io${base}`;

async function collectNames(dir: string) {
  const files = await fs.readdir(dir);
  return files.filter((x) => x.endsWith(".md") && x !== "index.md")
    .map((x) => x.replace(/\.md$/, ""));
}

async function updateReadme(srcPath: string) {
  const s = await fs.readFile(srcPath, "utf8");
  const m = s.match(
    /<!-- #region README -->\s+(.+)<!-- #endregion README -->/s,
  );
  if (!m) return;
  let t = m[1];
  for (const [x] of t.matchAll(/\]\([^)]+\)/gs)) {
    t = t.replace(x, x.replace(".md", "").replace("(./", `(${hostname}`));
  }
  await replaceInFile({
    files: "../README.md",
    from: /(<!-- #region generated -->\s+).+(<!-- #endregion generated -->)/s,
    to: `$1${t}$2`,
  });
}

export default async () => {
  const [options, templateNames] = await Promise.all([
    collectNames("options"),
    templates.paths().then((paths) =>
      paths.map(
        (x) => x.params.name,
      )
    ),
  ]);

  return defineConfig({
    base,
    cleanUrls: true,
    lastUpdated: true,

    title: "Conflake",
    description: "conflake Config Flakes",

    markdown: {
      image: {
        lazyLoading: true,
      },
    },

    sitemap: { hostname },

    themeConfig: {
      editLink: {
        pattern: "https://github.com/ratson/conflake/edit/main/docs/:path",
        text: "Edit this page on GitHub",
      },

      nav: [
        { text: "Home", link: "/" },
        { text: "Guides", link: "/guide/getting-started" },
      ],

      search: {
        provider: "local",
      },

      sidebar: [
        {
          text: "Introduction",
          base: "/guide/",
          collapsed: false,
          items: [
            { text: "Getting Started", link: "getting-started" },
            { text: "Project Layout", link: "project-layout" },
            { text: "Writing Tests", link: "writing-tests" },
          ],
        },
        {
          text: "Options",
          base: "/options/",
          collapsed: false,
          items: options.map((x) => ({
            text: x,
            link: x,
          })),
          link: "index",
        },
        {
          text: "Templates",
          base: "/templates/",
          collapsed: false,
          items: templateNames.map((x) => ({
            text: x,
            link: x,
          })),
        },
        {
          text: "Comparision",
          base: "/compare-to/",
          collapsed: true,
          items: [
            { text: "Flakes", link: "flakes" },
            { text: "Flakelight", link: "flakelight" },
            { text: "Flake Parts", link: "flake-parts" },
          ],
        },
        {
          text: "Development",
          base: "/development/",
          collapsed: true,
          items: [
            { text: "Design Decisions", link: "design-decisions" },
          ],
        },
      ],

      socialLinks: [
        {
          icon: "github",
          link: "https://github.com/ratson/conflake/tree/main",
        },
      ],
    },

    async transformPageData(pageData) {
      switch (pageData.filePath) {
        case "index.md":
          await updateReadme(pageData.filePath);
        case "templates/[name].md":
          pageData.title = `Templates - ${pageData.params?.name}`;
      }
    },
  });
};
