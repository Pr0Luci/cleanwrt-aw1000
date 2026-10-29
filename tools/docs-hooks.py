"""Adds generated/packages.md to the site from the build seed, in memory, on every build,
so the package list on the site cannot drift from what the image is built with.

Nothing is written into docs/: a file written there would make `mkdocs serve` rebuild
forever."""
import html
import json
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
        "---",
        'title: "Full package list of CleanWRT for the Arcadyan AW1000"',
        'description: "Every package the CleanWRT build selects for the Arcadyan AW1000, grouped by purpose and generated from the build seed so it always matches the image."',
        "---",
        "",
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


_FAQ_RE = re.compile(r'^\?\?\?\+? question "(.+)"\s*$')


def _plain(text):
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"[*`_]", "", text)
    return re.sub(r"\s+", " ", text).strip()


def on_page_markdown(markdown, page, config, files, **kwargs):
    """Collect the '??? question' blocks of a page, to publish them as FAQ structured data."""
    faq = []
    lines = markdown.split("\n")
    i = 0
    while i < len(lines):
        m = _FAQ_RE.match(lines[i])
        if not m:
            i += 1
            continue
        q = _plain(m.group(1))
        i += 1
        body = []
        while i < len(lines) and (lines[i].startswith("    ") or not lines[i].strip()):
            body.append(lines[i].strip())
            i += 1
        a = _plain(" ".join(b for b in body if b))
        if q and a:
            faq.append((q, a))
    page.meta["_faq"] = faq
    return markdown


def _ld(obj):
    return '<script type="application/ld+json">' + json.dumps(obj, ensure_ascii=False).replace("</", "<\\/") + "</script>\n"


def on_post_page(output, page, config, **kwargs):
    """Search and link-preview tags: Open Graph, Twitter card, robots, and structured data."""
    base = config["site_url"]
    name = config["site_name"]
    if page.is_homepage:
        title = f"{name}: OpenWrt for the Arcadyan AW1000"
    else:
        title = f"{page.title} - {name}"
    desc = page.meta.get("description") or config["site_description"]
    url = base + (page.url or "")
    image = base + "assets/img/social.png"
    tags = [
        ("property", "og:type", "website" if page.is_homepage else "article"),
        ("property", "og:site_name", name),
        ("property", "og:title", title),
        ("property", "og:description", desc),
        ("property", "og:url", url),
        ("property", "og:image", image),
        ("property", "og:image:width", "1200"),
        ("property", "og:image:height", "630"),
        ("property", "og:image:alt", "CleanWRT, OpenWrt for the Arcadyan AW1000"),
        ("name", "twitter:card", "summary_large_image"),
        ("name", "twitter:title", title),
        ("name", "twitter:description", desc),
        ("name", "twitter:image", image),
        ("name", "robots", "index, follow, max-image-preview:large, max-snippet:-1"),
        ("name", "theme-color", "#14b8a6"),
    ]
    extra = config.get("extra") or {}
    if extra.get("google_site_verification"):
        tags.append(("name", "google-site-verification", extra["google_site_verification"]))
    if extra.get("bing_site_verification"):
        tags.append(("name", "msvalidate.01", extra["bing_site_verification"]))
    meta = "".join(
        f'<meta {k}="{v}" content="{html.escape(c, quote=True)}">\n' for k, v, c in tags
    )

    ld = ""
    if page.is_homepage:
        ld += _ld({
            "@context": "https://schema.org",
            "@type": "WebSite",
            "name": name,
            "url": base,
            "description": config["site_description"],
        })
        ld += _ld({
            "@context": "https://schema.org",
            "@type": "SoftwareApplication",
            "name": "CleanWRT",
            "alternateName": ["CleanWRT for the Arcadyan AW1000", "AWvoice"],
            "applicationCategory": "OperatingSystem",
            "operatingSystem": "OpenWrt 25.12 on the Arcadyan AW1000 (qualcommax/ipq807x)",
            "softwareVersion": "25.12.5-rc2",
            "description": desc,
            "url": base,
            "image": image,
            "downloadUrl": "https://github.com/Pr0Luci/cleanwrt-aw1000/releases",
            "codeRepository": "https://github.com/Pr0Luci/cleanwrt-aw1000",
            "license": "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html",
            "isAccessibleForFree": True,
            "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
            "author": {"@type": "Person", "name": "Pr0Luci", "url": "https://github.com/Pr0Luci"},
        })
    else:
        ld += _ld({
            "@context": "https://schema.org",
            "@type": "BreadcrumbList",
            "itemListElement": [
                {"@type": "ListItem", "position": 1, "name": "CleanWRT", "item": base},
                {"@type": "ListItem", "position": 2, "name": page.title, "item": url},
            ],
        })
        ld += _ld({
            "@context": "https://schema.org",
            "@type": "TechArticle",
            "headline": page.title,
            "description": desc,
            "url": url,
            "image": image,
            "inLanguage": "en",
            "isPartOf": {"@type": "WebSite", "name": name, "url": base},
            "author": {"@type": "Person", "name": "Pr0Luci", "url": "https://github.com/Pr0Luci"},
        })
    faq = page.meta.get("_faq") or []
    if len(faq) >= 2:
        ld += _ld({
            "@context": "https://schema.org",
            "@type": "FAQPage",
            "mainEntity": [
                {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}}
                for q, a in faq
            ],
        })
    return output.replace("</head>", meta + ld + "</head>", 1)
