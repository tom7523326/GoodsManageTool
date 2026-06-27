#!/usr/bin/env python3
"""Package raw simulator screenshots for App Store Connect."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_ROOT = REPO_ROOT / "AppStoreScreenshots"
APP_ICON = REPO_ROOT / "GoodsManageTool/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

IPHONE_INPUT = Path.home() / "Documents" / "iphone截图"
IPAD_INPUT = Path.home() / "Documents" / "IPAD截图"

CAPTIONS = [
    ("01-卖货", "一键快速卖出", "选商品、记订单，出摊更高效"),
    ("02-展示", "给顾客看热销排行", "提升选购体验，促进成交"),
    ("03-订单", "每笔成交都有记录", "支持改单，自动校正库存"),
    ("04-盘账", "利润库存一眼看清", "成交额、毛利润、分商品明细"),
    ("05-库存", "进价卖价轻松管理", "进货出货，商品图片随心设"),
]

IPHONE_FILES = [
    "Simulator Screenshot - iPhone 17 Pro - 2026-06-21 at 19.15.58.png",
    "Simulator Screenshot - iPhone 17 Pro - 2026-06-21 at 19.16.17.png",
    "Simulator Screenshot - iPhone 17 Pro - 2026-06-21 at 19.25.53.png",
    "Simulator Screenshot - iPhone 17 Pro - 2026-06-21 at 19.26.01.png",
    "Simulator Screenshot - iPhone 17 Pro - 2026-06-21 at 19.26.10.png",
]

IPAD_FILES = [
    "Simulator Screenshot - iPad Pro 11-inch (M5) - 2026-06-21 at 19.30.19.png",
    "Simulator Screenshot - iPad Pro 11-inch (M5) - 2026-06-21 at 19.30.15.png",
    "Simulator Screenshot - iPad Pro 11-inch (M5) - 2026-06-21 at 19.30.21.png",
    "Simulator Screenshot - iPad Pro 11-inch (M5) - 2026-06-21 at 19.30.36.png",
    "Simulator Screenshot - iPad Pro 11-inch (M5) - 2026-06-21 at 19.30.44.png",
]

# App Store Connect required pixel sizes (exact)
OUTPUT_SETS = [
    {
        "label": "iPhone-6.7",
        "input_dir": IPHONE_INPUT,
        "files": IPHONE_FILES,
        "size": (1290, 2796),
        "portrait": True,
        "note": "iPhone 6.7 英寸",
    },
    {
        "label": "iPhone-6.5",
        "input_dir": IPHONE_INPUT,
        "files": IPHONE_FILES,
        "size": (1284, 2778),
        "portrait": True,
        "note": "iPhone 6.5 英寸（1284×2778）",
    },
    {
        "label": "iPhone-6.5-legacy",
        "input_dir": IPHONE_INPUT,
        "files": IPHONE_FILES,
        "size": (1242, 2688),
        "portrait": True,
        "note": "iPhone 6.5 英寸（1242×2688）",
    },
    {
        "label": "iPad-12.9-Landscape",
        "input_dir": IPAD_INPUT,
        "files": IPAD_FILES,
        "size": (2732, 2048),
        "portrait": False,
        "note": "iPad 12.9 英寸横屏",
    },
    {
        "label": "iPad-12.9-Portrait",
        "input_dir": IPAD_INPUT,
        "files": IPAD_FILES,
        "size": (2048, 2732),
        "portrait": True,
        "note": "iPad 12.9 英寸竖屏",
    },
]

FONT_CANDIDATES = [
    ("/System/Library/Fonts/PingFang.ttc", (5, 4, 0)),
    ("/System/Library/Fonts/STHeiti Medium.ttc", (0,)),
    ("/System/Library/Fonts/Hiragino Sans GB.ttc", (2, 1, 0)),
    ("/System/Library/Fonts/Supplemental/Arial Unicode.ttf", (0,)),
]

# Theme
DEEP_ORANGE = (180, 52, 18)
BRIGHT_ORANGE = (255, 92, 36)
WARM_GOLD = (255, 214, 96)
CREAM = (255, 248, 242)
SOFT_WHITE = (255, 252, 248)


def load_font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    index_map = {"heavy": 0, "bold": 0, "semibold": 0, "regular": 0, "medium": 0}
    for path, indices in FONT_CANDIDATES:
        font_path = Path(path)
        if not font_path.exists():
            continue
        preferred = {
            "heavy": indices[0] if len(indices) > 0 else 0,
            "bold": indices[0] if len(indices) > 0 else 0,
            "semibold": indices[1] if len(indices) > 1 else indices[0],
            "regular": indices[-1],
            "medium": indices[1] if len(indices) > 1 else indices[0],
        }
        candidates = [preferred[weight], *indices]
        for index in candidates:
            try:
                return ImageFont.truetype(str(font_path), size=size, index=index)
            except OSError:
                try:
                    return ImageFont.truetype(str(font_path), size=size)
                except OSError:
                    continue
    return ImageFont.load_default()


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lerp_color(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(lerp(c1[i], c2[i], t)) for i in range(3))


def rich_background(size: tuple[int, int]) -> Image.Image:
    width, height = size
    base = Image.new("RGB", size)
    draw = ImageDraw.Draw(base)

    for y in range(height):
        t = y / max(height - 1, 1)
        if t < 0.42:
            local = t / 0.42
            color = lerp_color(DEEP_ORANGE, BRIGHT_ORANGE, local ** 0.75)
        elif t < 0.58:
            local = (t - 0.42) / 0.16
            color = lerp_color(BRIGHT_ORANGE, (255, 145, 72), local)
        else:
            local = (t - 0.58) / 0.42
            color = lerp_color((255, 176, 118), CREAM, local ** 0.85)
        draw.line([(0, y), (width, y)], fill=color)

    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    orbs = [
        (int(width * 0.18), int(height * 0.08), int(width * 0.42), (255, 190, 90, 70)),
        (int(width * 0.82), int(height * 0.12), int(width * 0.36), (255, 110, 50, 55)),
        (int(width * 0.55), int(height * 0.28), int(width * 0.55), (255, 240, 180, 35)),
    ]
    for cx, cy, radius, color in orbs:
        glow_draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=color)
    glow = glow.filter(ImageFilter.GaussianBlur(48))
    canvas = Image.alpha_composite(base.convert("RGBA"), glow)

    accent = Image.new("RGBA", size, (0, 0, 0, 0))
    accent_draw = ImageDraw.Draw(accent)
    accent_draw.line(
        [(int(width * 0.12), int(height * 0.055)), (int(width * 0.88), int(height * 0.055))],
        fill=(255, 255, 255, 28),
        width=2,
    )
    accent_draw.line(
        [(int(width * 0.18), int(height * 0.34)), (int(width * 0.82), int(height * 0.34))],
        fill=(255, 255, 255, 16),
        width=1,
    )
    return Image.alpha_composite(canvas, accent)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def fit_image(image: Image.Image, max_width: int, max_height: int) -> Image.Image:
    ratio = min(max_width / image.width, max_height / image.height)
    new_size = (max(1, int(image.width * ratio)), max(1, int(image.height * ratio)))
    return image.resize(new_size, Image.Resampling.LANCZOS)


def text_size(text: str, font: ImageFont.ImageFont) -> tuple[int, int]:
    bbox = ImageDraw.Draw(Image.new("RGB", (1, 1))).textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0], bbox[3] - bbox[1]


def split_title(title: str) -> tuple[str, str]:
    if len(title) <= 4:
        return "", title
    if "一眼看清" in title:
        return title[:4], title[4:]
    if "都有记录" in title:
        return title[:4], title[4:]
    if "热销排行" in title:
        return title[:5], title[5:]
    if "轻松管理" in title:
        return title[:4], title[4:]
    if "快速卖出" in title:
        return title[:2], title[2:]
    mid = max(2, len(title) // 2)
    return title[:mid], title[mid:]


def draw_gradient_text(
    canvas: Image.Image,
    text: str,
    font: ImageFont.ImageFont,
    center_x: int,
    y: int,
    colors: tuple[tuple[int, int, int], tuple[int, int, int]],
) -> int:
    width, height = text_size(text, font)
    x = center_x - width // 2
    text_layer = Image.new("RGBA", (width + 8, height + 8), (0, 0, 0, 0))
    mask = Image.new("L", text_layer.size, 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.text((4, 4), text, font=font, fill=255)

    gradient = Image.new("RGBA", text_layer.size)
    grad_draw = ImageDraw.Draw(gradient)
    for gy in range(text_layer.size[1]):
        t = gy / max(text_layer.size[1] - 1, 1)
        color = lerp_color(colors[0], colors[1], t)
        grad_draw.line([(0, gy), (text_layer.size[0], gy)], fill=(*color, 255))

    text_layer = Image.composite(gradient, text_layer, mask)
    canvas.alpha_composite(text_layer, (x - 4, y - 4))
    return height


def draw_text_shadow(
    canvas: Image.Image,
    text: str,
    font: ImageFont.ImageFont,
    center_x: int,
    y: int,
    fill: tuple[int, int, int],
    *,
    stroke: int = 0,
    stroke_fill: tuple[int, int, int] | None = None,
) -> int:
    width, height = text_size(text, font)
    x = center_x - width // 2
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for offset, alpha in ((0, 8), (2, 28), (4, 42), (8, 58)):
        draw.text(
            (x + 2, y + offset),
            text,
            font=font,
            fill=(0, 0, 0, alpha),
            stroke_width=stroke,
            stroke_fill=(*stroke_fill, 120) if stroke_fill else None,
        )
    draw.text(
        (x, y),
        text,
        font=font,
        fill=fill,
        stroke_width=stroke,
        stroke_fill=stroke_fill,
    )
    return Image.alpha_composite(canvas, layer), height


def draw_brand_badge(canvas: Image.Image, center_x: int, y: int, *, portrait: bool) -> int:
    icon_size = 54 if portrait else 46
    pad_x, pad_y = 18, 12
    text = "出摊帮手"
    tag = "离线摆摊工具"
    brand_font = load_font(30 if portrait else 26, "semibold")
    tag_font = load_font(22 if portrait else 20, "medium")

    brand_w, brand_h = text_size(text, brand_font)
    tag_w, tag_h = text_size(tag, tag_font)
    gap = 14
    divider_h = max(brand_h, tag_h) - 8
    content_w = icon_size + gap + brand_w + 18 + tag_w
    badge_w = content_w + pad_x * 2
    badge_h = max(icon_size, brand_h, tag_h) + pad_y * 2
    x0 = center_x - badge_w // 2
    y0 = y

    badge = Image.new("RGBA", (badge_w, badge_h), (0, 0, 0, 0))
    badge_draw = ImageDraw.Draw(badge)
    badge_draw.rounded_rectangle(
        (0, 0, badge_w - 1, badge_h - 1),
        radius=badge_h // 2,
        fill=(255, 255, 255, 36),
    )
    badge_draw.rounded_rectangle(
        (1, 1, badge_w - 2, badge_h - 2),
        radius=badge_h // 2,
        outline=(255, 255, 255, 72),
        width=2,
    )

    if APP_ICON.exists():
        icon = Image.open(APP_ICON).convert("RGBA").resize((icon_size, icon_size), Image.Resampling.LANCZOS)
        icon_mask = rounded_mask(icon.size, icon_size // 4)
        badge.paste(icon, (pad_x, (badge_h - icon_size) // 2), icon_mask)

    text_x = pad_x + icon_size + gap
    text_y = (badge_h - brand_h) // 2
    badge_draw.text((text_x, text_y), text, font=brand_font, fill=(255, 255, 255, 245))
    divider_x = text_x + brand_w + 9
    divider_y = (badge_h - divider_h) // 2
    badge_draw.line(
        [(divider_x, divider_y), (divider_x, divider_y + divider_h)],
        fill=(255, 255, 255, 90),
        width=2,
    )
    badge_draw.text(
        (divider_x + 12, (badge_h - tag_h) // 2),
        tag,
        font=tag_font,
        fill=(255, 236, 210, 230),
    )

    canvas.alpha_composite(badge, (x0, y0))
    return badge_h


def draw_accent_bar(canvas: Image.Image, center_x: int, y: int, *, portrait: bool) -> None:
    bar_w = 120 if portrait else 96
    bar_h = 8 if portrait else 7
    layer = Image.new("RGBA", (bar_w, bar_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle((0, 0, bar_w, bar_h), radius=bar_h // 2, fill=WARM_GOLD)
    canvas.alpha_composite(layer, (center_x - bar_w // 2, y))


def draw_subtitle_pill(canvas: Image.Image, text: str, center_x: int, y: int, *, portrait: bool) -> int:
    font = load_font(34 if portrait else 30, "medium")
    pad_x, pad_y = 26, 14
    text_w, text_h = text_size(text, font)
    pill_w = text_w + pad_x * 2
    pill_h = text_h + pad_y * 2
    x0 = center_x - pill_w // 2

    pill = Image.new("RGBA", (pill_w, pill_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(pill)
    draw.rounded_rectangle(
        (0, 0, pill_w - 1, pill_h - 1),
        radius=pill_h // 2,
        fill=(255, 255, 255, 28),
        outline=(255, 255, 255, 56),
        width=2,
    )
    draw.text((pad_x, pad_y - 2), text, font=font, fill=(255, 248, 240, 245))
    canvas.alpha_composite(pill, (x0, y))
    return pill_h


def frame_screenshot(shot: Image.Image, *, portrait: bool) -> Image.Image:
    corner_radius = 44 if portrait else 36
    border = 6 if portrait else 5
    pad = 18

    framed_w = shot.width + pad * 2 + border * 2
    framed_h = shot.height + pad * 2 + border * 2
    framed = Image.new("RGBA", (framed_w, framed_h), (0, 0, 0, 0))

    glow = Image.new("RGBA", framed.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.rounded_rectangle(
        (8, 12, framed_w - 8, framed_h - 4),
        radius=corner_radius + 16,
        fill=(255, 110, 40, 90),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(22))
    framed = Image.alpha_composite(framed, glow)

    shell = Image.new("RGBA", framed.size, (0, 0, 0, 0))
    shell_draw = ImageDraw.Draw(shell)
    shell_draw.rounded_rectangle(
        (0, 0, framed_w - 1, framed_h - 1),
        radius=corner_radius + border + 8,
        fill=(255, 255, 255, 255),
    )
    shell_draw.rounded_rectangle(
        (border, border, framed_w - border - 1, framed_h - border - 1),
        radius=corner_radius + 8,
        outline=(255, 170, 96, 255),
        width=border,
    )
    framed = Image.alpha_composite(framed, shell)

    inner_mask = rounded_mask(shot.size, corner_radius)
    rounded = Image.new("RGBA", shot.size, (0, 0, 0, 0))
    rounded.paste(shot, (0, 0), inner_mask)
    framed.paste(rounded, (pad + border, pad + border), rounded)

    shadow = Image.new("RGBA", (framed_w + 80, framed_h + 80), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (28, 34, framed_w + 44, framed_h + 44),
        radius=corner_radius + 20,
        fill=(40, 16, 8, 110),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(24))

    result = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
    result.alpha_composite(shadow, (0, 0))
    result.alpha_composite(framed, (24, 18))
    return result


def compose_screenshot(
    screenshot: Image.Image,
    canvas_size: tuple[int, int],
    title: str,
    subtitle: str,
    *,
    portrait: bool,
) -> Image.Image:
    canvas = rich_background(canvas_size)
    center_x = canvas_size[0] // 2

    top_padding = 108 if portrait else 68
    y = top_padding
    y += draw_brand_badge(canvas, center_x, y, portrait=portrait) + (28 if portrait else 22)

    line1, line2 = split_title(title)
    line1_font = load_font(46 if portrait else 40, "medium")
    line2_font = load_font(98 if portrait else 82, "heavy")

    if line1:
        canvas, h1 = draw_text_shadow(
            canvas,
            line1,
            line1_font,
            center_x,
            y,
            (255, 236, 210),
            stroke=1,
            stroke_fill=(120, 40, 12),
        )
        y += h1 + 8

    title_y = y
    canvas, h2 = draw_text_shadow(
        canvas,
        line2,
        line2_font,
        center_x,
        title_y,
        SOFT_WHITE,
        stroke=3,
        stroke_fill=(150, 45, 10),
    )
    y += h2 + 10

    draw_accent_bar(canvas, center_x, y, portrait=portrait)
    y += 24

    accent = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw_gradient_text(accent, line2, line2_font, center_x, title_y, (WARM_GOLD, SOFT_WHITE))
    accent = Image.blend(Image.new("RGBA", canvas.size, (0, 0, 0, 0)), accent, 0.24)
    canvas = Image.alpha_composite(canvas, accent)

    y += draw_subtitle_pill(canvas, subtitle, center_x, y, portrait=portrait) + (34 if portrait else 26)

    horizontal_margin = 78 if portrait else 96
    bottom_margin = 72 if portrait else 56
    available_width = canvas_size[0] - horizontal_margin * 2
    available_height = canvas_size[1] - y - bottom_margin

    shot = fit_image(screenshot.convert("RGBA"), available_width, available_height)
    framed = frame_screenshot(shot, portrait=portrait)

    x = (canvas_size[0] - framed.width) // 2
    shot_y = y + max(0, (available_height - framed.height) // 2)
    canvas.alpha_composite(framed, (x, shot_y))

    return canvas.convert("RGB")


def process_set(
    input_dir: Path,
    output_dir: Path,
    filenames: list[str],
    canvas_size: tuple[int, int],
    portrait: bool,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    for filename, (slug, title, subtitle) in zip(filenames, CAPTIONS, strict=True):
        source = input_dir / filename
        if not source.exists():
            raise FileNotFoundError(f"Missing screenshot: {source}")

        screenshot = Image.open(source)
        composed = compose_screenshot(
            screenshot,
            canvas_size,
            title,
            subtitle,
            portrait=portrait,
        )
        output_path = output_dir / f"{slug}.png"
        if composed.size != canvas_size:
            composed = composed.resize(canvas_size, Image.Resampling.LANCZOS)
        composed.save(output_path, format="PNG", optimize=True)
        print(f"Saved {output_path} ({composed.size[0]}x{composed.size[1]})")


def main() -> None:
    for spec in OUTPUT_SETS:
        print(f"\n== {spec['label']} · {spec['note']} ==")
        process_set(
            spec["input_dir"],
            OUTPUT_ROOT / spec["label"],
            spec["files"],
            spec["size"],
            portrait=spec["portrait"],
        )

    print(f"\nDone. Upload files from: {OUTPUT_ROOT}")
    print("iPhone 6.5 英寸请用: AppStoreScreenshots/iPhone-6.5/")
    print("iPhone 6.7 英寸请用: AppStoreScreenshots/iPhone-6.7/")


if __name__ == "__main__":
    main()
