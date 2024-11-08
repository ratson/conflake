import { defineConfig } from "vitepress";

export default defineConfig({
  base: "/conflake/",
  cleanUrls: true,
  lastUpdated: true,

  title: "Conflake",
  description: "Config Flakes",

  themeConfig: {
    nav: [
      { text: "Home", link: "/" },
      { text: "Guides", link: "/guide/getting-started" },
    ],

    sidebar: [
      {
        text: "Guides",
        base: "/guide/",
        items: [
          { text: "Getting Started", link: "getting-started" },
        ],
      },
      {
        text: "References",
        base: "/reference/",
        items: [
          { text: "API", link: "api" },
        ],
      },
    ],

    socialLinks: [
      { icon: "github", link: "https://github.com/ratson/conflake" },
    ],
  },
});
