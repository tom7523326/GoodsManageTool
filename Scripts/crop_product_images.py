#!/usr/bin/env python3
"""
Import product header images into the app bundle.

Preferred source: ../商品头图 (manually cropped headers).
Fallback: crop from ../订单 order screenshots where available.

Output: GoodsManageTool/Resources/ProductImages/*.jpg (400x400)
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Install Pillow: pip3 install Pillow", file=sys.stderr)
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_HEADERS_DIR = REPO_ROOT.parent / "商品头图"
DEFAULT_ORDERS_DIR = REPO_ROOT.parent / "订单"
DEFAULT_OUTPUT_DIR = REPO_ROOT / "GoodsManageTool" / "Resources" / "ProductImages"

HEADER_FILES: dict[str, str] = {
    "product_camera": "特工相机.jpg",
    "product_crystal": "天然水晶.jpg",
    "product_magnet_block": "磁力方块.jpg",
    "product_game_console": "游戏机.jpg",
    "product_train": "磁力车.jpg",
    "product_pen_cat": "躲猫猫笔.jpg",
    "product_blindbox_pen": "盲盒笔.jpg",
}

# Fallback crop boxes on 1290px-wide order screenshots.
ORDER_CROP_SPECS: dict[str, tuple[str, tuple[int, int, int, int] | None]] = {
    "product_crystal": ("Weixin Image_20260621120844_138_2.png", None),
    "product_game_console": ("Weixin Image_20260621120845_139_2.png", (48, 548, 264, 764)),
    "product_train": ("Weixin Image_20260621120845_139_2.png", (48, 1380, 264, 1596)),
    "product_pen_cat": ("Weixin Image_20260621120845_139_2.png", (48, 2240, 264, 2456)),
    "product_blindbox_pen": ("Weixin Image_20260621120846_140_2.png", (48, 185, 264, 401)),
}


def to_square_400(image: Image.Image) -> Image.Image:
    image = image.convert("RGB")
    w, h = image.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    image = image.crop((left, top, left + side, top + side))
    return image.resize((400, 400), Image.Resampling.LANCZOS)


def import_header(headers_dir: Path, output_dir: Path, name: str, filename: str) -> bool:
    src = headers_dir / filename
    if not src.exists():
        return False

    image = to_square_400(Image.open(src))
    output_dir.mkdir(parents=True, exist_ok=True)
    out_path = output_dir / f"{name}.jpg"
    image.save(out_path, "JPEG", quality=92)
    print(f"OK   {name} <- {filename}")
    return True


def crop_from_order(orders_dir: Path, output_dir: Path, name: str) -> bool:
    spec = ORDER_CROP_SPECS.get(name)
    if spec is None:
        return False

    src_name, box = spec
    src_path = orders_dir / src_name
    if not src_path.exists():
        return False

    image = Image.open(src_path)
    if box is not None:
        image = image.crop(box)
    image = to_square_400(image)

    output_dir.mkdir(parents=True, exist_ok=True)
    out_path = output_dir / f"{name}.jpg"
    image.save(out_path, "JPEG", quality=92)
    print(f"OK   {name} <- order {src_name} {box or 'full'}")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description="Import product header images")
    parser.add_argument("--headers-dir", type=Path, default=DEFAULT_HEADERS_DIR)
    parser.add_argument("--orders-dir", type=Path, default=DEFAULT_ORDERS_DIR)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    args = parser.parse_args()

    ok = 0
    for name, filename in HEADER_FILES.items():
        if args.headers_dir.is_dir() and import_header(args.headers_dir, args.output_dir, name, filename):
            ok += 1
            continue
        if args.orders_dir.is_dir() and crop_from_order(args.orders_dir, args.output_dir, name):
            ok += 1
            continue
        print(f"SKIP {name}: no source in 商品头图 or 订单")

    print(f"\nGenerated {ok}/{len(HEADER_FILES)} images.")
    return 0 if ok == len(HEADER_FILES) else 1


if __name__ == "__main__":
    raise SystemExit(main())
