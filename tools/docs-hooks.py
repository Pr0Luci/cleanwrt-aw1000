"""Adds generated/packages.md to the site from the build seed, in memory, on every build,
so the package list on the site cannot drift from what the image is built with.

Nothing is written into docs/: a file written there would make `mkdocs serve` rebuild
forever."""
import html
import os
import re

from mkdocs.structure.files import File


def _page(seed):
    section = "Other"
    groups = {}
    order = []
    with open(seed, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            m = re.match(r"^# ── (.+?) ─+", line)
            if m:
                section = m.group(1).strip()
                continue
            m = re.match(r"^CONFIG_PACKAGE_([A-Za-z0-9._+-]+)=y$", line)
            if m:
                if section not in groups:
                    groups[section] = []
                    order.append(section)
                groups[section].append(m.group(1))

    total = sum(len(v) for v in groups.values())
    lines = [
        "# Full package list",
        "",
        "This page is generated from the build seed (`configs/arcadyan_aw1000.seed`) every time the",
        "site is built, so it always matches the image. It lists the packages the seed selects by",
        f"name ({total} entries). Their dependencies are pulled in automatically and are not listed;",
        "the exact content of a release is in its package manifest (see [Releases](../releases.md)).",
        "",
    ]
    for name in order:
        pk = sorted(set(groups[name]))
        lines += [f"## {name}", "", f"{len(pk)} packages", "", "| Package |", "|---|"]
        lines += [f"| `{p}` |" for p in pk]
        lines.append("")
    return "\n".join(lines)


def on_files(files, config, **kwargs):
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    content = _page(os.path.join(root, "configs", "arcadyan_aw1000.seed"))
    files.append(File.generated(config, "generated/packages.md", content=content))
    return files


def on_post_page(output, page, config, **kwargs):
    """Link-preview tags (Open Graph and Twitter card), so a shared link shows a picture and text."""
    base = config["site_url"]
    if page.is_homepage:
        title = f"{config['site_name']}: OpenWrt for the Arcadyan AW1000"
    else:
        title = f"{page.title} - {config['site_name']}"
    desc = page.meta.get("description") or config["site_description"]
    url = base + (page.url or "")
    image = base + "assets/img/social.png"
    tags = [
        ("property", "og:type", "website"),
        ("property", "og:site_name", config["site_name"]),
        ("property", "og:title", title),
        ("property", "og:description", desc),
        ("property", "og:url", url),
        ("property", "og:image", image),
        ("property", "og:image:width", "1200"),
        ("property", "og:image:height", "630"),
        ("name", "twitter:card", "summary_large_image"),
        ("name", "twitter:title", title),
        ("name", "twitter:description", desc),
        ("name", "twitter:image", image),
    ]
    meta = "".join(
        f'<meta {k}="{v}" content="{html.escape(c, quote=True)}">\n' for k, v, c in tags
    )
    return output.replace("</head>", meta + "</head>", 1)
