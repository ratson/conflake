import { createContentLoader, type SiteConfig } from "vitepress";

const config: SiteConfig = (globalThis as any).VITEPRESS_CONFIG;

export default createContentLoader("options/*.md", {
    transform(raw) {
        return raw
            .filter((x) => !x.url.endsWith("/"))
            .map(({ url, frontmatter }) => ({
                title: url.split("/").at(-1),
                category: frontmatter.category,
                url: config.site.base.replace(/\/$/, "") + url,
            }));
    },
});
