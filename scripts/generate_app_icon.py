#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw, ImageFilter

DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(DIR)
SOURCE_IMAGE = os.path.join(PROJECT_DIR, 'docs', 'icons', 'concept_c_minimal_graphite.jpg')
OUTPUT_ICNS = os.path.join(PROJECT_DIR, 'Resources', 'AppIcon.icns')
ICONSET_DIR = '/tmp/AppIcon.iconset'

def main():
    if not os.path.exists(SOURCE_IMAGE):
        print(f"Error: Source image not found at {SOURCE_IMAGE}")
        return

    src = Image.open(SOURCE_IMAGE).convert('RGBA')

    # Center of squircle in the master concept render
    cx, cy = 511, 513
    s = 680
    left = cx - s // 2
    top = cy - s // 2
    cropped = src.crop((left, top, left + s, top + s))

    # macOS standard icon squircle size (824 x 824 in 1024 x 1024)
    target_size = 824
    resized = cropped.resize((target_size, target_size), Image.Resampling.LANCZOS)

    # 4x super-sampled squircle mask (corner radius 185)
    mask_scale = 4
    large = target_size * mask_scale
    mask_img = Image.new('L', (large, large), 0)
    d = ImageDraw.Draw(mask_img)
    d.rounded_rectangle((0, 0, large, large), radius=int(185 * mask_scale), fill=255)
    mask = mask_img.resize((target_size, target_size), Image.Resampling.LANCZOS)
    resized.putalpha(mask)

    # 1024 x 1024 final canvas with macOS dock elevation shadow
    final = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    shadow_img = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow_img)
    sd.rounded_rectangle((100, 100 + 20, 100 + target_size, 100 + 20 + target_size), radius=185, fill=(0, 0, 0, 110))
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(radius=26))

    final.alpha_composite(shadow_img)
    final.alpha_composite(resized, (100, 90))

    # Generate multi-resolution iconset
    os.makedirs(ICONSET_DIR, exist_ok=True)
    sizes = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]

    for name, sz in sizes:
        icon = final.resize((sz, sz), Image.Resampling.LANCZOS)
        icon.save(os.path.join(ICONSET_DIR, name))

    os.system(f"iconutil -c icns {ICONSET_DIR} -o '{OUTPUT_ICNS}'")
    print(f"Generated {OUTPUT_ICNS}")

if __name__ == '__main__':
    main()
