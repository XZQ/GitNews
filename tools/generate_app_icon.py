"""Generate the GitHub情报站 brand icon (.png + .ico).

Run: python tools/generate_app_icon.py
"""
import math
from PIL import Image, ImageDraw
import os

OUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "windows", "runner", "resources",
)
TMP_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
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


def main():
    icon_512 = draw_icon(512)
    preview_png_path = os.path.join(TMP_DIR, "app_icon.png")
    icon_512.save(preview_png_path, format="PNG")
    print(f"wrote {preview_png_path}")

    resource_png_path = os.path.join(OUT_DIR, "app_icon.png")
    icon_512.save(resource_png_path, format="PNG")
    print(f"wrote {resource_png_path}")

    # Build .ico with multiple sizes for crisp rendering.
    sizes = [16, 24, 32, 48, 64, 128, 256]
    images = [draw_icon(s) for s in sizes]
    ico_path = os.path.join(OUT_DIR, "app_icon.ico")
    images[0].save(
        ico_path,
        format="ICO",
        sizes=[(s, s) for s in sizes],
        append_images=images[1:],
    )
    print(f"wrote {ico_path}")


if __name__ == "__main__":
    main()
