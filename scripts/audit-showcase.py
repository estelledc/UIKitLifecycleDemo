#!/usr/bin/env python3
"""Audit the static showcase, source evidence, and shared visual contract."""

from __future__ import annotations

import re
import struct
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
INDEX = DOCS / "index.html"
NOT_FOUND = DOCS / "404.html"
WORKFLOW = ROOT / ".github" / "workflows" / "pages.yml"
CANONICAL = "https://estelledc.github.io/UIKitLifecycleDemo/"


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.ids: set[str] = set()
        self.refs: list[str] = []
        self.images: list[dict[str, str]] = []
        self.h1_count = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = {key: value or "" for key, value in attrs}
        if values.get("id"):
            self.ids.add(values["id"])
        if tag == "h1":
            self.h1_count += 1
        if tag == "img":
            self.images.append(values)
        for attribute in ("href", "src"):
            if values.get(attribute):
                self.refs.append(values[attribute])


def png_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    if len(data) != 24 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValueError(f"not a valid PNG: {path}")
    return struct.unpack(">II", data[16:24])


def source_facts() -> dict[str, int]:
    guided = (ROOT / "UIKitLifecycleDemo" / "GuidedExperiment.swift").read_text(encoding="utf-8")
    logs = (ROOT / "UIKitLifecycleDemo" / "DemoLogStore.swift").read_text(encoding="utf-8")
    tests = (ROOT / "UIKitLifecycleDemoUITests" / "UIKitLifecycleDemoUITests.swift").read_text(encoding="utf-8")
    category_block = logs.split("enum DemoLogCategory", 1)[1].split("var title", 1)[0]
    return {
        "guided": len(re.findall(r"\bGuidedStep\(", guided)),
        "categories": len(re.findall(r"^\s*case\s+\w+", category_block, flags=re.MULTILINE)),
        "tests": len(re.findall(r"^\s*func\s+test\w+\(", tests, flags=re.MULTILINE)),
    }


def local_target(raw: str) -> Path | None:
    parsed = urlsplit(raw)
    if parsed.scheme or parsed.netloc or not parsed.path or parsed.path.startswith("/"):
        return None
    return (DOCS / unquote(parsed.path)).resolve()


def audit() -> list[str]:
    errors: list[str] = []
    required_files = [
        INDEX,
        NOT_FOUND,
        DOCS / "assets" / "style.css",
        DOCS / "assets" / "app.js",
        DOCS / "assets" / "jx" / "VERSION",
        DOCS / "assets" / "jx" / "tokens.css",
        DOCS / "assets" / "jx" / "base.css",
        DOCS / "assets" / "jx" / "components.css",
        DOCS / "assets" / "app-icon.png",
        DOCS / "assets" / "favicon.png",
        DOCS / "assets" / "og-image.png",
        DOCS / "assets" / "uikit-list.png",
        DOCS / "assets" / "uikit-logs.png",
        DOCS / "assets" / "uikit-guide.png",
        WORKFLOW,
    ]
    for path in required_files:
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"missing or empty: {path.relative_to(ROOT)}")
    if errors:
        return errors

    html = INDEX.read_text(encoding="utf-8")
    not_found = NOT_FOUND.read_text(encoding="utf-8")
    css = (DOCS / "assets" / "style.css").read_text(encoding="utf-8")
    javascript = (DOCS / "assets" / "app.js").read_text(encoding="utf-8")
    tokens = (DOCS / "assets" / "jx" / "tokens.css").read_text(encoding="utf-8")
    components = (DOCS / "assets" / "jx" / "components.css").read_text(encoding="utf-8")
    workflow = WORKFLOW.read_text(encoding="utf-8")
    parser = PageParser()
    parser.feed(html)

    required_markers = [
        'data-guided-steps="9"',
        'data-log-categories="14"',
        'data-ui-tests="2"',
        f'<link rel="canonical" href="{CANONICAL}">',
        "先预测一次回调",
        "Real simulator output",
        "Evidence, not claims",
        "不等于已经掌握 UIKit",
        "assets/uikit-list.png",
        "assets/uikit-logs.png",
        "assets/uikit-guide.png",
        "assets/app-icon.png",
        "assets/og-image.png",
        '<meta name="theme-color" content="#f6f6f3">',
        "assets/jx/tokens.css",
        "assets/jx/base.css",
        "assets/jx/components.css",
        "This lab answers",
        "jx-proof-rail",
        "jx-footer",
        'https://estelledc.github.io/">← Jason Xun',
    ]
    for marker in required_markers:
        if marker not in html:
            errors.append(f"index.html: missing marker: {marker}")

    if parser.h1_count != 1:
        errors.append(f"index.html: expected exactly one h1, found {parser.h1_count}")
    for raw_classes in re.findall(r'class="([^"]+)"', html):
        classes = set(raw_classes.split())
        if {"jx-container", "jx-proof-rail"} <= classes:
            errors.append("index.html: jx-proof-rail must be nested inside jx-container, not composed with it")
    if not re.search(r'<div class="jx-container">\s*<ul class="jx-proof-rail"', html):
        errors.append("index.html: proof rail is missing its shared layout container")
    for image in parser.images:
        if not image.get("alt", "").strip():
            errors.append(f"index.html: image missing alt: {image.get('src', '<unknown>')}")
    for raw in parser.refs:
        if raw.startswith("#"):
            if raw[1:] not in parser.ids:
                errors.append(f"index.html: broken fragment: {raw}")
            continue
        target = local_target(raw)
        if target is not None and not target.is_file():
            errors.append(f"index.html: broken local reference: {raw}")

    facts = source_facts()
    if facts != {"guided": 9, "categories": 14, "tests": 2}:
        errors.append(f"source fact drift: {facts}")
    category_items = re.findall(r'^\s*"[A-Za-z]+",?$', javascript, flags=re.MULTILINE)
    if len(category_items) != facts["categories"]:
        errors.append(f"app.js: expected {facts['categories']} categories, found {len(category_items)}")

    image_contract = {
        DOCS / "assets" / "app-icon.png": (1024, 1024),
        DOCS / "assets" / "favicon.png": (64, 64),
        DOCS / "assets" / "og-image.png": (1200, 630),
        DOCS / "assets" / "uikit-list.png": (1206, 2622),
        DOCS / "assets" / "uikit-logs.png": (1206, 2622),
        DOCS / "assets" / "uikit-guide.png": (1206, 2622),
    }
    for path, expected in image_contract.items():
        try:
            actual = png_dimensions(path)
            if actual != expected:
                errors.append(f"{path.relative_to(ROOT)}: expected {expected}, found {actual}")
        except ValueError as error:
            errors.append(str(error))

    if (DOCS / "assets" / "jx" / "VERSION").read_text(encoding="utf-8").strip() != "2.2.0":
        errors.append("Jason DS vendor version must be 2.2.0")
    if "Jason DS · Tokens v2.2.0" not in tokens or ".jx-site-header" not in components:
        errors.append("Jason DS vendor bundle is incomplete")

    visual_contract = [
        "var(--jx-ink)",
        "var(--jx-surface)",
        "var(--jx-font-mono)",
        ".lab-hero",
        ".lab-screen-grid",
        ".lab-pipeline",
        "@media (max-width: 760px)",
        "prefers-reduced-motion: reduce",
    ]
    for marker in visual_contract:
        if marker not in css:
            errors.append(f"style.css: shared design marker missing: {marker}")
    if "transition: all" in css or "transition: all" in components:
        errors.append("style.css: transition: all is not allowed")
    screen_image_rule = re.search(r"\.lab-screen img\s*\{([^}]*)\}", css, flags=re.DOTALL)
    if screen_image_rule is None or not re.search(r"\bheight\s*:\s*auto\s*;", screen_image_rule.group(1)):
        errors.append("style.css: responsive screenshots must declare height: auto")
    for name in ("uikit-list.png", "uikit-logs.png", "uikit-guide.png"):
        tag = re.search(rf'<img\b[^>]*\bsrc="assets/{re.escape(name)}"[^>]*>', html)
        if tag is None:
            errors.append(f"index.html: missing screenshot tag: {name}")
            continue
        attributes = dict(re.findall(r'(\w+)="([^"]*)"', tag.group(0)))
        if attributes.get("width") != "1206" or attributes.get("height") != "2622":
            errors.append(f"index.html: screenshot intrinsic dimensions are missing or incorrect: {name}")

    for marker in ("runs-on: macos-15", "make build-ci", "make verify-showcase", "make public-scan"):
        if marker not in workflow:
            errors.append(f"pages workflow: missing release gate: {marker}")

    published_text = "\n".join((html, not_found, css, javascript)).lower()
    forbidden = [
        "to" + "do",
        "lorem " + "ipsum",
        "replace" + "-me",
        "/" + "us" + "ers/",
        "byte" + "dance",
        "la" + "rk",
        "og-uikit.png",
        "#061534",
        "#27c9ff",
        "#ff8b73",
    ]
    for marker in forbidden:
        if marker in published_text:
            errors.append(f"published page contains forbidden marker: {marker}")

    if not (DOCS / ".nojekyll").is_file():
        errors.append("missing docs/.nojekyll")
    if CANONICAL not in (DOCS / "sitemap.xml").read_text(encoding="utf-8"):
        errors.append("sitemap.xml: canonical URL missing")
    if "sitemap.xml" not in (DOCS / "robots.txt").read_text(encoding="utf-8"):
        errors.append("robots.txt: sitemap declaration missing")
    return errors


def main() -> int:
    errors = audit()
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    facts = source_facts()
    print(
        "OK: Jason DS 2.2.0, links, assets, release gates, and source evidence verified "
        f"({facts['guided']} guided steps, {facts['categories']} log categories, {facts['tests']} UI tests)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
