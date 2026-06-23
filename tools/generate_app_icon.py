"""Generate the GitHub情报站 brand icon (.png + .ico).

Run: python tools/generate_app_icon.py
"""
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


BRAND_LIGHT = (0x8B, 0x73, 0xE5)
BRAND_DARK = (0x58, 0x40, 0xB5)
GREEN = (0x30, 0xA4, 0x6C)
WHITE = (0xFF, 0xFF, 0xFF)


def draw_icon(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    r = int(size * 0.22)
    # Gradient background (linear-ish via horizontal bands).
    steps = 64
    for i in range(steps):
        t = i / max(1, steps - 1)
        c = lerp(BRAND_LIGHT, BRAND_DARK, t)
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

    # "G" outline ring
    cx, cy = size / 2, size / 2
    outer_r = size * 0.30
    inner_r = size * 0.20
    stroke = max(1, int(size * 0.085))
    ring_r = (outer_r + inner_r) / 2
    draw.arc(
        [(cx - ring_r, cy - ring_r), (cx + ring_r, cy + ring_r)],
        start=-30,
        end=290,
        fill=WHITE + (255,),
        width=stroke,
    )
    # G crossbar
    bar_y = cy + inner_r * 0.05
    draw.line(
        [(cx, bar_y), (cx + inner_r * 0.85, bar_y)],
        fill=WHITE + (255,),
        width=stroke,
    )

    # Bars (analytics)
    bw = max(1, int(size * 0.085))
    gap = max(1, int(size * 0.045))
    base_y = int(size * 0.78)
    heights = [0.18, 0.30, 0.45]
    x0 = int(size * 0.22)
    bar_r = max(1, int(bw * 0.45))
    for i, h in enumerate(heights):
        x = x0 + i * (bw + gap)
        bh = int(size * h)
        draw.rounded_rectangle(
            [(x, base_y - bh), (x + bw, base_y)],
            radius=bar_r,
            fill=GREEN + (255,),
        )

    return rounded


def main():
    png_path = os.path.join(TMP_DIR, "app_icon.png")
    draw_icon(512).save(png_path, format="PNG")
    print(f"wrote {png_path}")

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
