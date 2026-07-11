"""Generate deterministic social and favicon assets for the public case page."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "docs" / "assets"
SCREENSHOT = ASSETS / "uikit-list.png"

SANS = [
    "/System/Library/Fonts/STHeiti Medium.ttc",
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
]
SERIF = [
    "/System/Library/Fonts/Supplemental/Songti.ttc",
    "/usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc",
    "/usr/share/fonts/truetype/noto/NotoSerifCJK-Regular.ttc",
]


def font(candidates: list[str], size: int) -> ImageFont.FreeTypeFont:
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    raise RuntimeError("No CJK font found. Install Noto CJK or run this script on macOS.")


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def generate_favicon() -> None:
    icon = Image.new("RGB", (64, 64), "#0a66d6")
    draw = ImageDraw.Draw(icon)
    draw.rounded_rectangle((2, 2, 61, 61), radius=15, outline="#0757b8", width=2)
    draw.text((15, 8), "U", font=font(SANS, 40), fill="#ffffff")
    icon.save(ASSETS / "favicon.png", "PNG", optimize=True)


def generate_social_card() -> None:
    width, height = 1200, 630
    image = Image.new("RGB", (width, height), "#f4f7fb")
    draw = ImageDraw.Draw(image)
    ink = "#111827"
    muted = "#667085"
    blue = "#0a66d6"
    rule = "#d7deea"

    sans_18 = font(SANS, 18)
    sans_17 = font(SANS, 17)
    sans_26 = font(SANS, 26)
    sans_30 = font(SANS, 30)
    serif_64 = font(SERIF, 64)

    draw.rounded_rectangle((40, 38, 1160, 592), radius=22, fill="#ffffff", outline=rule, width=2)
    draw.rectangle((40, 38, 54, 592), fill=blue)
    draw.text((86, 76), "JASON / PRODUCT SYSTEMS", font=sans_18, fill=blue)
    draw.text((835, 76), "UIKIT · OBSERVABLE RUNTIME", font=sans_18, fill=muted)
    draw.line((86, 118, 1114, 118), fill=rule, width=2)

    draw.text((86, 162), "UIKit 隐式调用，", font=serif_64, fill=ink)
    draw.text((86, 236), "变成可观察的证据链", font=serif_64, fill=ink)
    draw.text((90, 333), "Predict → Run → Observe → Verify → Recap", font=sans_26, fill=muted)
    draw.text((90, 382), "09 GUIDE STEPS  ·  14 LOG CATEGORIES  ·  02 UI TEST FLOWS", font=sans_18, fill=blue)

    trace_box = (86, 436, 802, 540)
    draw.rounded_rectangle(trace_box, radius=12, fill="#0d1420")
    labels = [("001", "viewDidLoad"), ("002", "didSelectItemAt"), ("003", "saveReminder"), ("004", "onSave")]
    x = 108
    for number, label in labels:
        draw.text((x, 458), number, font=sans_18, fill="#5f7188")
        draw.text((x, 488), label, font=sans_17, fill="#d8e2ef")
        x += 168

    if not SCREENSHOT.exists():
        raise RuntimeError(f"Missing simulator screenshot: {SCREENSHOT}")
    screenshot = Image.open(SCREENSHOT).convert("RGB")
    screenshot.thumbnail((218, 474), Image.Resampling.LANCZOS)
    phone_size = (screenshot.width + 14, screenshot.height + 14)
    phone = Image.new("RGB", phone_size, "#111318")
    phone.paste(screenshot, (7, 7))
    phone_mask = rounded_mask(phone_size, 34)
    image.paste(phone, (880, 132), phone_mask)

    draw.rounded_rectangle((846, 142, 1007, 180), radius=19, fill=blue)
    draw.text((867, 148), "REAL SIMULATOR", font=sans_18, fill="#ffffff")
    draw.text((90, 557), "PURE UIKIT · SWIFT · XCODE · XCTEST", font=sans_18, fill=muted)

    image.save(ASSETS / "og-uikit.png", "PNG", optimize=True)


if __name__ == "__main__":
    ASSETS.mkdir(parents=True, exist_ok=True)
    generate_favicon()
    generate_social_card()
    print("generated docs/assets/favicon.png and docs/assets/og-uikit.png")
