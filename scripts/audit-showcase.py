"""Audit the GitHub Pages case, its links, metadata, and evidence claims."""

from __future__ import annotations

import json
import re
import struct
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
INDEX = DOCS / "index.html"
CANONICAL = "https://estelledc.github.io/UIKitLifecycleDemo/"


class ShowcaseParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.ids: set[str] = set()
        self.refs: list[str] = []
        self.h1_count = 0
        self.images: list[dict[str, str]] = []
        self.json_ld: list[str] = []
        self._json_chunks: list[str] | None = None

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
        if tag == "script" and values.get("type") == "application/ld+json":
            self._json_chunks = []

    def handle_endtag(self, tag: str) -> None:
        if tag == "script" and self._json_chunks is not None:
            self.json_ld.append("".join(self._json_chunks))
            self._json_chunks = None

    def handle_data(self, data: str) -> None:
        if self._json_chunks is not None:
            self._json_chunks.append(data)


def png_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    if len(data) != 24 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValueError(f"not a valid PNG: {path}")
    return struct.unpack(">II", data[16:24])


def source_facts() -> dict[str, int]:
    guided = (ROOT / "UIKitLifecycleDemo" / "GuidedExperiment.swift").read_text(encoding="utf-8")
    logs = (ROOT / "UIKitLifecycleDemo" / "DemoLogStore.swift").read_text(encoding="utf-8")
    ui_tests = (
        ROOT / "UIKitLifecycleDemoUITests" / "UIKitLifecycleDemoUITests.swift"
    ).read_text(encoding="utf-8")
    category_block = logs.split("enum DemoLogCategory", 1)[1].split("var title", 1)[0]
    return {
        "9": len(re.findall(r"\bGuidedStep\(", guided)),
        "14": len(re.findall(r"^\s*case\s+\w+", category_block, flags=re.MULTILINE)),
        "2": len(re.findall(r"^\s*func\s+test\w+\(", ui_tests, flags=re.MULTILINE)),
    }


def local_target(raw: str) -> Path | None:
    parsed = urlsplit(raw)
    if parsed.scheme or parsed.netloc or not parsed.path or parsed.path.startswith("/"):
        return None
    return (DOCS / unquote(parsed.path)).resolve()


def audit() -> list[str]:
    errors: list[str] = []
    if not INDEX.is_file():
        return ["missing docs/index.html"]

    html = INDEX.read_text(encoding="utf-8")
    parser = ShowcaseParser()
    parser.feed(html)

    required_markers = [
        "Problem / 问题",
        "Role / Jason",
        "System / 系统",
        "Evidence / 证据",
        "Limitations / 边界",
        "Codex / AI 辅助搭建 Demo",
        "不声称仅凭阅读或运行 Demo 就能掌握 UIKit",
        f'<link rel="canonical" href="{CANONICAL}">',
        '<meta property="og:image" content="https://estelledc.github.io/UIKitLifecycleDemo/assets/og-uikit.png">',
        '<meta name="twitter:card" content="summary_large_image">',
        'class="jx-skip-link"',
        'data-theme-toggle aria-pressed="false"',
        'data-save-lab',
        'data-run-save hidden',
        'data-mechanism="delegate"',
        'data-mechanism="lifecycle"',
        'data-mechanism="target-action"',
        'data-mechanism="closure"',
        'data-save-output aria-live="polite" aria-atomic="true"',
        "2 / 2 UI TEST PASS",
        "LAST VERIFIED · 2026-07-11",
        "9.456s edit/save · 27.483s Logs/Guide",
        "JavaScript 未启用",
    ]
    for marker in required_markers:
        if marker not in html:
            errors.append(f"index.html: missing marker: {marker}")

    for destination in (
        "https://estelledc.github.io/",
        "https://estelledc.github.io/about/",
        "https://estelledc.github.io/resume/",
        "https://github.com/estelledc/UIKitLifecycleDemo",
    ):
        if destination not in html:
            errors.append(f"index.html: missing portfolio destination: {destination}")

    if parser.h1_count != 1:
        errors.append(f"index.html: expected exactly one h1, found {parser.h1_count}")
    if len(parser.json_ld) != 1:
        errors.append(f"index.html: expected one JSON-LD block, found {len(parser.json_ld)}")
    else:
        try:
            structured = json.loads(parser.json_ld[0])
            if structured.get("@context") != "https://schema.org":
                errors.append("index.html: unexpected JSON-LD context")
            graph = structured.get("@graph", [])
            person = next((item for item in graph if item.get("@type") == "Person"), {})
            if person.get("@id") != "https://estelledc.github.io/#person" or person.get("name") != "Jason Xun":
                errors.append("index.html: shared Jason Xun #person identity is missing")
        except json.JSONDecodeError as error:
            errors.append(f"index.html: invalid JSON-LD: {error}")

    for image in parser.images:
        if not image.get("alt", "").strip():
            errors.append(f"index.html: image missing alt: {image.get('src', '<unknown>')}")
        if not image.get("width") or not image.get("height"):
            errors.append(f"index.html: image missing width/height: {image.get('src', '<unknown>')}")
        if image.get("loading") not in {"eager", "lazy"}:
            errors.append(f"index.html: image missing loading strategy: {image.get('src', '<unknown>')}")
        if image.get("decoding") != "async":
            errors.append(f"index.html: image missing async decoding: {image.get('src', '<unknown>')}")

    for raw in parser.refs:
        if raw.startswith("#"):
            if raw[1:] not in parser.ids:
                errors.append(f"index.html: broken fragment: {raw}")
            continue
        target = local_target(raw)
        if target is not None and not target.is_file():
            errors.append(f"index.html: broken local reference: {raw}")

    for claimed, actual in source_facts().items():
        if int(claimed) != actual:
            errors.append(f"source fact drift: expected {claimed}, found {actual}")
        if f"<strong>{claimed}</strong>" not in html:
            errors.append(f"index.html: evidence value {claimed} is not rendered")

    image_contract = {
        DOCS / "assets" / "og-uikit.png": (1200, 630),
        DOCS / "assets" / "favicon.png": (64, 64),
        DOCS / "assets" / "uikit-list.png": (1206, 2622),
    }
    for path, expected in image_contract.items():
        if not path.is_file():
            errors.append(f"missing image asset: {path.relative_to(ROOT)}")
            continue
        try:
            actual = png_dimensions(path)
            if actual != expected:
                errors.append(f"{path.relative_to(ROOT)}: expected {expected}, found {actual}")
        except ValueError as error:
            errors.append(str(error))

    version = (DOCS / "assets" / "jx" / "VERSION").read_text(encoding="utf-8").strip()
    if version != "2.2.0":
        errors.append(f"Jason DS version is {version}, expected 2.2.0")

    css = (DOCS / "assets" / "style.css").read_text(encoding="utf-8")
    if "prefers-reduced-motion: reduce" not in css:
        errors.append("style.css: missing reduced-motion support")
    if "@media (max-width: 420px)" not in css or ".runtime-card__body { grid-template-columns: 1fr; }" not in css:
        errors.append("style.css: missing 320px Save-trace layout contract")
    for marker in (
        "transition: transform 180ms var(--jx-ease-out)",
        "@media (hover: hover) and (pointer: fine)",
        ".theme-button:active",
        ".runtime-run:active",
    ):
        if marker not in css:
            errors.append(f"style.css: interaction contract missing: {marker}")
    if "transition: all" in css:
        errors.append("style.css: transition: all is not allowed")
    if "*, *::before, *::after" in css:
        errors.append("style.css: reduced motion must not globally erase semantic feedback")
    if "focus-visible" not in (DOCS / "assets" / "jx" / "base.css").read_text(encoding="utf-8"):
        errors.append("Jason DS base: missing focus-visible styles")

    app_js = (DOCS / "assets" / "app.js").read_text(encoding="utf-8")
    for marker in (
        "activateSaveStep",
        "finishSaveTrace",
        "cancelSaveTrace",
        "scheduleSaveTimer",
        "prefers-reduced-motion: reduce",
        "const runId = cancelSaveTrace();",
        "if (runId !== saveRunId) return;",
        'saveTrace.setAttribute("aria-busy", "true")',
        'saveTrace?.removeAttribute("aria-busy")',
        'runSave.textContent = "Restart Save trace"',
        "saveTimers = saveTimers.filter",
        "SAVE_TRACE_RESET_MS = 180",
    ):
        if marker not in app_js:
            errors.append(f"app.js: progressive Save trace marker missing: {marker}")
    if "runSave.disabled" in app_js:
        errors.append("app.js: Save trace trigger must remain interruptible")

    start_trace = app_js.find("function startSaveTrace()")
    cancel_trace = app_js.find("const runId = cancelSaveTrace();", start_trace)
    immediate_status = app_js.find("saveOutput.textContent = wasRunning", start_trace)
    reduced_branch = app_js.find("if (reducedMotion.matches)", start_trace)
    schedule_trace = app_js.find("scheduleSaveTimer(", reduced_branch)
    if not (
        start_trace >= 0
        and start_trace < cancel_trace < immediate_status < reduced_branch < schedule_trace
    ):
        errors.append("app.js: restart must cancel, announce, branch reduced motion, then schedule")

    hero_image = re.search(r'<img[^>]+src="assets/uikit-list.png"[^>]*>', html)
    if not hero_image:
        errors.append("index.html: real Simulator image is missing")
    else:
        image_tag = hero_image.group(0)
        for marker in ('loading="eager"', 'decoding="async"', 'fetchpriority="high"'):
            if marker not in image_tag:
                errors.append(f"index.html: hero Simulator image missing {marker}")

    published_text = "\n".join(
        path.read_text(encoding="utf-8", errors="ignore")
        for path in DOCS.rglob("*")
        if path.is_file() and path.suffix.lower() in {".html", ".css", ".js", ".md", ".txt", ".xml"}
    )
    for private_marker in ("/Users/", "bytedance", "intern-journal"):
        if private_marker in published_text:
            errors.append(f"published docs contain private marker: {private_marker}")

    if not (DOCS / ".nojekyll").is_file():
        errors.append("missing docs/.nojekyll")
    if not (DOCS / "404.html").is_file():
        errors.append("missing docs/404.html")
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
        "OK: public case, metadata, local links, assets, and source evidence verified "
        f"({facts['9']} guided steps, {facts['14']} log categories, {facts['2']} UI tests)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
