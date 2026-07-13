"""Regenerate favicon and Open Graph derivatives from the project app icon."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "docs" / "assets"
APP_ICON = ASSETS / "app-icon.png"
NAVY = (6, 21, 52)


def main() -> None:
    icon = Image.open(APP_ICON).convert("RGB")
    icon.resize((64, 64), Image.Resampling.LANCZOS).save(ASSETS / "favicon.png", optimize=True)

    canvas = Image.new("RGB", (1200, 630), NAVY)
    social_icon = icon.resize((520, 520), Image.Resampling.LANCZOS)
    canvas.paste(social_icon, ((1200 - 520) // 2, (630 - 520) // 2))
    canvas.save(ASSETS / "og-image.png", optimize=True)
    print("generated docs/assets/favicon.png and docs/assets/og-image.png")


if __name__ == "__main__":
    main()
