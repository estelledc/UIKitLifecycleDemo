"""Regenerate the favicon and validate the tracked editorial Open Graph card."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "docs" / "assets"
APP_ICON = ASSETS / "app-icon.png"


def main() -> None:
    icon = Image.open(APP_ICON).convert("RGB")
    icon.resize((64, 64), Image.Resampling.LANCZOS).save(ASSETS / "favicon.png", optimize=True)

    social = Image.open(ASSETS / "og-image.png")
    if social.size != (1200, 630):
        raise SystemExit(f"docs/assets/og-image.png must be 1200x630, found {social.size}")
    print("generated docs/assets/favicon.png and validated docs/assets/og-image.png")


if __name__ == "__main__":
    main()
