"""Generate the GitHub情报站 brand icon for desktop and mobile targets.

Run: python tools/generate_app_icon.py
"""
import math
from PIL import Image, ImageDraw, ImageOps
import os

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_PATH = os.path.join(ROOT_DIR, "assets", "brand", "app_icon_source.png")
OUT_DIR = os.path.join(
    ROOT_DIR,
    "windows", "runner", "resources",
)
TMP_DIR = os.path.join(
    ROOT_DIR,
    "build", "icons",
)
os.makedirs(TMP_DIR, exist_ok=True)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


INK = (0x10, 0x18, 0x28)
TEAL_DARK = (0x0F, 0x76, 0x6E)
CYAN = (0x67, 0xE8, 0xF9)
CYAN_GLOW = (0x22, 0xD3, 0xEE)
WHITE = (0xFF, 0xFF, 0xFF)


def _draw_icon(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    r = int(size * 0.24)
    # Diagonal-ish gradient background via horizontal bands.
    steps = 64
    for i in range(steps):
        t = i / max(1, steps - 1)
        c = lerp(INK, TEAL_DARK, t)
        y0 = int(size * i / steps)
        y1 = int(size * (i + 1) / steps) + 1
        draw.rectangle([(0, y0), (size, y1)], fill=c + (255,))
    # Rounded mask
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [(0, 0), (size - 1, size - 1)], radius=r, fill=255
    )
    rounded = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rounded.paste(img, (0, 0), mask)

    draw = ImageDraw.Draw(rounded)

    # Radar arcs, low contrast.
    radar_center = (size * 0.34, size * 0.68)
    radar_w = max(1, int(size * 0.035))
    for scale in (0.34, 0.56, 0.78):
        rr = size * scale
        box = [
            radar_center[0] - rr,
            radar_center[1] - rr,
            radar_center[0] + rr,
            radar_center[1] + rr,
        ]
        draw.arc(box, start=-60, end=30, fill=WHITE + (24,), width=radar_w)

    # Trend trajectory. A simple polyline renders crisply in ICO sizes.
    p0 = (size * 0.20, size * 0.68)
    p_mid = (size * 0.42, size * 0.55)
    p3 = (size * 0.58, size * 0.42)
    p6 = (size * 0.84, size * 0.22)
    points = [p0, p_mid, p3, p6]

    draw.line(
        points,
        fill=CYAN + (255,),
        width=max(1, int(size * 0.105)),
    )

    # Nodes.
    for node in (p0, p3):
        glow_r = size * 0.075
        core_r = size * 0.038
        draw.ellipse(
            [
                node[0] - glow_r,
                node[1] - glow_r,
                node[0] + glow_r,
                node[1] + glow_r,
            ],
            fill=CYAN_GLOW + (74,),
        )
        draw.ellipse(
            [
                node[0] - core_r,
                node[1] - core_r,
                node[0] + core_r,
                node[1] + core_r,
            ],
            fill=WHITE + (255,),
        )

    # Star endpoint.
    star_center = (size * 0.82, size * 0.22)
    outer = size * 0.12
    inner = size * 0.044
    star = []
    for i in range(8):
        angle = -math.pi / 2 + i * math.pi / 4
        radius = outer if i % 2 == 0 else inner
        star.append(
            (
                star_center[0] + radius * math.cos(angle),
                star_center[1] + radius * math.sin(angle),
            )
        )
    draw.polygon(star, fill=WHITE + (255,))

    return rounded


def draw_icon(size):
    scale = 4
    large = _draw_icon(size * scale)
    return large.resize((size, size), Image.Resampling.LANCZOS)


def render_icon(size):
    if os.path.exists(SRC_PATH):
        source = Image.open(SRC_PATH).convert("RGBA")
        return ImageOps.fit(
            source,
            (size, size),
            method=Image.Resampling.LANCZOS,
            centering=(0.5, 0.5),
        )
    return draw_icon(size)


def save_png(path, size):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    render_icon(size).save(path, format="PNG")
    print(f"wrote {path}")


def main():
    preview_png_path = os.path.join(TMP_DIR, "app_icon.png")
    save_png(preview_png_path, 512)

    resource_png_path = os.path.join(OUT_DIR, "app_icon.png")
    save_png(resource_png_path, 512)

    # Build .ico with multiple sizes for crisp rendering.
    sizes = [16, 24, 32, 48, 64, 128, 256]
    images = [render_icon(s) for s in sizes]
    ico_path = os.path.join(OUT_DIR, "app_icon.ico")
    images[0].save(
        ico_path,
        format="ICO",
        sizes=[(s, s) for s in sizes],
        append_images=images[1:],
    )
    print(f"wrote {ico_path}")

    android_icons = {
        "mipmap-mdpi/ic_launcher.png": 48,
        "mipmap-hdpi/ic_launcher.png": 72,
        "mipmap-xhdpi/ic_launcher.png": 96,
        "mipmap-xxhdpi/ic_launcher.png": 144,
        "mipmap-xxxhdpi/ic_launcher.png": 192,
    }
    android_root = os.path.join(ROOT_DIR, "android", "app", "src", "main", "res")
    for rel_path, size in android_icons.items():
        save_png(os.path.join(android_root, rel_path), size)

    ios_icons = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    ios_root = os.path.join(
        ROOT_DIR, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset"
    )
    for filename, size in ios_icons.items():
        save_png(os.path.join(ios_root, filename), size)

    macos_icons = {
        "app_icon_16.png": 16,
        "app_icon_32.png": 32,
        "app_icon_64.png": 64,
        "app_icon_128.png": 128,
        "app_icon_256.png": 256,
        "app_icon_512.png": 512,
        "app_icon_1024.png": 1024,
    }
    macos_root = os.path.join(
        ROOT_DIR, "macos", "Runner", "Assets.xcassets", "AppIcon.appiconset"
    )
    for filename, size in macos_icons.items():
        save_png(os.path.join(macos_root, filename), size)


if __name__ == "__main__":
    main()
