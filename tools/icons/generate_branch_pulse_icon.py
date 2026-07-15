"""Generate the "branch pulse" app icon for all platforms.

Renders a 1024 master with a git-branch graph: two static commits on the main
line plus one pulsing branch tip with concentric glow rings. The pulse
symbolizes live GitHub activity flowing into the app.

Outputs:
  assets/brand/app_icon_source.png          master 1024
  windows/runner/resources/app_icon.png     256
  windows/runner/resources/app_icon.ico     multi-size
  android/app/src/main/res/mipmap-*/ic_launcher.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*@*.png
"""

from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]

MASTER = 1024
SUPERSAMPLE = 4

BG_CENTER = (11, 18, 32)
BG_EDGE = (6, 10, 20)
LINE_CYAN = (56, 189, 248)
NODE_FILL = (15, 23, 42)
NODE_RING = (56, 189, 248)
PULSE_CORE = (251, 191, 36)
PULSE_GLOW = (253, 224, 71)


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def radial_background(size: int) -> Image.Image:
    """Dark navy radial gradient: lighter center, darker edges."""
    img = Image.new("RGB", (size, size), BG_EDGE)
    cx = cy = size / 2
    max_r = math.hypot(cx, cy)
    pixels = img.load()
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy)
            t = min(1.0, d / max_r)
            pixels[x, y] = lerp(BG_CENTER, BG_EDGE, t ** 1.4)
    return img


def cubic_bezier(p0, p1, p2, p3, n=96):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        x = u**3 * p0[0] + 3 * u**2 * t * p1[0] + 3 * u * t**2 * p2[0] + t**3 * p3[0]
        y = u**3 * p0[1] + 3 * u**2 * t * p1[1] + 3 * u * t**2 * p2[1] + t**3 * p3[1]
        pts.append((x, y))
    return pts


def draw_branch_graph(canvas_size: int) -> Image.Image:
    """Draw the branch+pulse graph on a transparent RGBA layer."""
    s = canvas_size / 1024
    layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    node1 = (260 * s, 620 * s)
    node2 = (540 * s, 620 * s)
    pulse = (760 * s, 300 * s)

    line_w = int(34 * s)
    node_r = int(58 * s)
    ring_w = max(6, int(10 * s))

    # Main line: node1 -> node2 (straight).
    draw.line([node1, node2], fill=LINE_CYAN + (255,), width=line_w)
    # Smooth line caps.
    for p in (node1, node2):
        draw.ellipse([p[0] - line_w / 2, p[1] - line_w / 2, p[0] + line_w / 2, p[1] + line_w / 2], fill=LINE_CYAN + (255,))

    # Branch curve: node2 -> pulse (cubic bezier bowing up-left then to pulse).
    c1 = (540 * s, 470 * s)
    c2 = (620 * s, 300 * s)
    curve = cubic_bezier(node2, c1, c2, pulse)
    draw.line(curve, fill=LINE_CYAN + (255,), width=line_w, joint="curve")

    # Static nodes: dark fill, cyan ring.
    for p in (node1, node2):
        x0, y0 = p[0] - node_r, p[1] - node_r
        x1, y1 = p[0] + node_r, p[1] + node_r
        draw.ellipse([x0, y0, x1, y1], fill=NODE_FILL + (255,), outline=LINE_CYAN + (255,), width=ring_w)

    # Pulse node: amber core with concentric glow rings.
    pulse_r = int(78 * s)
    for ring_r, alpha in [(pulse_r * 2, 28), (int(pulse_r * 1.65), 50), (int(pulse_r * 1.32), 90)]:
        glow = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gd.ellipse([pulse[0] - ring_r, pulse[1] - ring_r, pulse[0] + ring_r, pulse[1] + ring_r], fill=PULSE_GLOW + (alpha,))
        glow = glow.filter(ImageFilter.GaussianBlur(radius=int(18 * s)))
        layer.alpha_composite(glow)

    x0, y0 = pulse[0] - pulse_r, pulse[1] - pulse_r
    x1, y1 = pulse[0] + pulse_r, pulse[1] + pulse_r
    draw.ellipse([x0, y0, x1, y1], fill=PULSE_CORE + (255,), outline=(255, 255, 255, 255), width=max(5, int(8 * s)))

    # Inner highlight on pulse core (keeps it from looking flat).
    hl_r = int(pulse_r * 0.42)
    hl_cx = pulse[0] - pulse_r * 0.28
    hl_cy = pulse[1] - pulse_r * 0.32
    draw.ellipse([hl_cx - hl_r, hl_cy - hl_r, hl_cx + hl_r, hl_cy + hl_r], fill=(255, 255, 255, 110))

    return layer


def render_master() -> Image.Image:
    canvas = radial_background(MASTER * SUPERSAMPLE)
    graph = draw_branch_graph(MASTER * SUPERSAMPLE)
    canvasRGBA = canvas.convert("RGBA")
    canvasRGBA.alpha_composite(graph)
    return canvasRGBA.resize((MASTER, MASTER), Image.LANCZOS)


def save_resized(master: Image.Image, size: int, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    master.resize((size, size), Image.LANCZOS).save(path, format="PNG", optimize=True)


def save_android(master: Image.Image) -> None:
    base = ROOT / "android/app/src/main/res"
    for bucket, size in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]:
        save_resized(master, size, base / f"mipmap-{bucket}/ic_launcher.png")


def save_ios(master: Image.Image) -> None:
    folder = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    sizes = [20, 29, 40, 50, 57, 58, 60, 72, 76, 80, 87, 100, 114, 120, 128, 144, 152, 167, 180, 256, 512, 1024]
    seen = set()
    for s in sizes:
        for scale in (1, 2, 3):
            px = s * scale
            if px > 1024:
                continue
            key = (s, scale)
            if key in seen:
                continue
            seen.add(key)
            save_resized(master, px, folder / f"Icon-App-{s}x{s}@{scale}x.png")


def save_windows(master: Image.Image) -> None:
    res = ROOT / "windows/runner/resources"
    save_resized(master, 256, res / "app_icon.png")
    ico_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    master.save(res / "app_icon.ico", format="ICO", sizes=ico_sizes)


def main() -> None:
    master = render_master()
    brand = ROOT / "assets/brand"
    brand.mkdir(parents=True, exist_ok=True)
    master.save(brand / "app_icon_source.png", format="PNG", optimize=True)
    save_android(master)
    save_ios(master)
    save_windows(master)
    print("ok: 1024 master + android + ios + windows written")


if __name__ == "__main__":
    main()
