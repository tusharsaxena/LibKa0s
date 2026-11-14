#!/usr/bin/env python3
"""Generate the waypoint arrow's art: five looks, every one tintable to any color.

    waypoint_arrow.py          write LibKa0s/media/waypoint/*.tga
    waypoint_arrow.py --check  regenerate in memory and compare with the files on disk (exit 1 on drift)

THE SAME BARGAIN AS bar_textures.py AND glass_textures.py BESIDE IT: every value that decides what
the art looks like is a named constant here, and the art is what this file writes, so the two cannot
drift. It is also the license answer: nothing is traced or sampled. Every pixel is computed below
from the geometry of the owner's mockup of 2026-11-14 (the Skill Master round-8 design canvas, top
artboard, "Waypoint arrow: five 3D looks"), a 48-unit SVG box whose numbers are copied here as they
are drawn there: the chevron M24 4 L40 40 L24 31 L8 40 Z, its 1.2 stroke in #1a1410, and each
look's overlays. The art is MIT, as the rest of the library.

HOW A LOOK TAKES ANY COLOR. A texture tinted with SetVertexColor is multiplied by the tint, so a
white pixel draws the tint and a gray one a darker tint; a multiply can never draw lighter than the
tint. The mockup lights faces with white overlays, so every look is two layers:

  * the BODY, white where it takes the color, gray where the color is shaded (a value the multiply
    reaches exactly: an overlay of black at opacity a over the color is the color times 1 - a), black
    where it is shadow. Tinted with the far/near color.
  * the OVERLAY, drawn over the body untinted: the white highlights, the black shading the body
    does not carry, and the outline in its own color. Straight alpha, so the client's BLEND draws
    exactly the SVG's `fill-opacity` over the tinted body.

WHAT IT WRITES (uncompressed coordinates, RLE 32-bit TGA, top-left origin, as bar_textures.py):

    arrow-fill.tga         128x128  the chevron, white. The body of flat, ridge, raised and faceted
                                    (rotated with SetRotation, so the art is drawn pointing up).
    flat-overlay.tga       128x128  the outline alone.
    ridge-overlay.tga      128x128  the lit left half (white 0.30), the shaded right half (black
                                    0.32), the outline.
    raised-overlay.tga     128x128  the tip-to-tail light (a vertical gradient over the chevron's
                                    box: white 0.45, clear at the middle, black 0.35), the bright
                                    rim on the leading edges (white 0.55, 0.8 wide), the outline.
    raised-shadow.tga      128x128  the drop shadow: the chevron in black 0.5, blurred (sigma 1.2),
                                    on a 64-unit canvas so the blur is never cut when it turns. It
                                    is NOT offset here: the widget anchors it down and right of the
                                    arrow (SHADOW_OFFSET), so the light stays put while the arrow
                                    turns.
    faceted-overlay.tga    128x128  four facets meeting at a peak (24, 23): white 0.38, white 0.08,
                                    black 0.18, black 0.42, then the outline.
    ground-body.tga        512x512  the arrow lying on the ground, as an ANGLE SHEET: 72 frames,
    ground-overlay.tga     512x512  one per 5 degrees counter-clockwise from straight ahead, in 8
                                    columns by 9 rows of 64x44 cells, frame k at column k % 8, row
                                    k // 8 (the sheet's last 116 rows unused). A tilted image
                                    cannot be turned with SetRotation, so the widget picks a frame
                                    with SetTexCoord. The body carries the soft shadow under the
                                    arrow (black 0.45, sigma 1.4, which does not turn), the side
                                    wall (the color times 0.45, 3.5 units under the top) and the
                                    top face (its right half the color times 0.82); the overlay the
                                    top's lit left half (white 0.25) and its 1.4 outline.

THE GROUND TRANSFORM, per the mockup: a point of the chevron is moved by translate(-24, -22),
turned, squashed to 0.55 of its height, then moved by translate(24, 26); the wall is the same face
3.5 units lower. The mockup turns with SVG's rotate(+35), which is clockwise on a y-down screen; a
frame here turns COUNTER-clockwise by its angle (frame 18 points left), because that is the sense
of the widget's rotation (and of Texture:SetRotation), so the frame is the mockup's rotate(-angle).

Each cell maps the screen-unit box x -1 .. 49, y 12 .. 46.375 (50 x 34.375 units: the widest turn of
the top, the wall and the shadow, with margin) onto its 64x44 texels, 1.28 texels a unit. The rotated
looks map the 48-unit box onto 128 texels; the shadow maps -8 .. 56.

TRANSPARENT PIXELS. Under a tinted layer they are white with zero alpha, as glass_textures.py
explains (the client filters between an edge pixel and its clear neighbor, and a white neighbor
keeps the edge the tint's color). Under an overlay they carry the color of the nearest drawn pixel,
for the same reason.

Requires Pillow and NumPy. No network, and no input files.
"""

import io
import math
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, os.pardir, os.pardir))
OUT = os.path.join(ROOT, "LibKa0s", "media", "waypoint")

# ── the mockup's geometry (48-unit box, y down) ────────────────────────────────────────────────

CHEVRON = [(24.0, 4.0), (40.0, 40.0), (24.0, 31.0), (8.0, 40.0)]
OUTLINE_RGB = (0x1A / 255.0, 0x14 / 255.0, 0x10 / 255.0)
OUTLINE_WIDTH = 1.2            # the rotated looks' stroke, centered on the edge
GROUND_OUTLINE_WIDTH = 1.4     # the ground look's

RIDGE = [
    ([(24, 4), (24, 31), (8, 40)], (1, 1, 1), 0.30),
    ([(24, 4), (40, 40), (24, 31)], (0, 0, 0), 0.32),
]
FACETS = [
    ([(24, 4), (8, 40), (24, 23)], (1, 1, 1), 0.38),
    ([(24, 4), (40, 40), (24, 23)], (1, 1, 1), 0.08),
    ([(8, 40), (24, 31), (24, 23)], (0, 0, 0), 0.18),
    ([(40, 40), (24, 31), (24, 23)], (0, 0, 0), 0.42),
]
RAISED_GRADIENT = [(0.0, (1, 1, 1), 0.45), (0.5, (1, 1, 1), 0.0), (1.0, (0, 0, 0), 0.35)]
RAISED_RIM = [(9.2, 38.6), (24.0, 5.6), (38.8, 38.6)]
RAISED_RIM_WIDTH, RAISED_RIM_ALPHA = 0.8, 0.55
RAISED_SHADOW_ALPHA, RAISED_SHADOW_SIGMA = 0.5, 1.2
# The widget's offset for the shadow, in units (x right, y DOWN, as the mockup's translate(1.5, 3)).
SHADOW_OFFSET = (1.5, 3.0)

GROUND_PIVOT = (24.0, 22.0)     # translate(-24 -22)
GROUND_CENTER = (24.0, 26.0)    # translate(24 26)
GROUND_SQUASH = 0.55
GROUND_WALL_DROP = 3.5
GROUND_WALL_SHADE = 0.45        # the color under black 0.55
GROUND_TOP_RIGHT_SHADE = 0.82   # the color under black 0.18
GROUND_TOP_LEFT = ([(24, 4), (24, 31), (8, 40)], (1, 1, 1), 0.25)
GROUND_TOP_RIGHT = [(24, 4), (40, 40), (24, 31)]
GROUND_SHADOW = (24.0, 36.0, 15.0, 4.5)   # ellipse cx cy rx ry
GROUND_SHADOW_ALPHA, GROUND_SHADOW_SIGMA = 0.45, 1.4

# ── the canvases ────────────────────────────────────────────────────────────────────────────────

ROT_SIZE = 128                  # texels for the 48-unit box
ROT_BOX = (0.0, 0.0, 48.0, 48.0)
SHADOW_BOX = (-8.0, -8.0, 56.0, 56.0)

FRAMES, STEP_DEG = 72, 5
COLS, ROWS = 8, 9
CELL_W, CELL_H = 64, 44
SHEET = 512
CELL_BOX = (-1.0, 12.0, 49.0, 46.375)

SS = 8                          # samples per texel per axis


# ── sampling ────────────────────────────────────────────────────────────────────────────────────

def grid(box, w, h):
    """Sample points (x, y) in units for a w x h texel canvas over `box`, SS x SS per texel."""
    x0, y0, x1, y1 = box
    xs = x0 + (np.arange(w * SS) + 0.5) * (x1 - x0) / (w * SS)
    ys = y0 + (np.arange(h * SS) + 0.5) * (y1 - y0) / (h * SS)
    return np.meshgrid(xs, ys)


def inside(poly, x, y):
    """Even-odd point-in-polygon for arrays of points."""
    c = np.zeros(x.shape, dtype=bool)
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        if y1 == y2:
            continue
        crosses = (y1 > y) != (y2 > y)
        xi = x1 + (y - y1) * (x2 - x1) / (y2 - y1)
        c ^= crosses & (x < xi)
    return c


def seg_dist(x, y, a, b):
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    t = np.clip(((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy), 0.0, 1.0)
    return np.hypot(x - (ax + t * dx), y - (ay + t * dy))


def stroke(points, closed, width, x, y):
    """Points within width/2 of the path: a stroke with round joins and caps."""
    n = len(points)
    last = n if closed else n - 1
    d = np.full(x.shape, np.inf)
    for i in range(last):
        d = np.minimum(d, seg_dist(x, y, points[i], points[(i + 1) % n]))
    return d <= width / 2.0


def down(premul, w, h):
    """Average SS x SS samples to one texel: (h, w, 4) premultiplied."""
    return premul.reshape(h, SS, w, SS, 4).mean(axis=(1, 3))


def over(dst, mask, rgb, alpha):
    """Composite a flat color at `alpha` over `dst` (premultiplied, per sample) where `mask`."""
    a = (mask.astype(np.float64) * alpha)[..., None]
    rgb = np.ones(mask.shape + (3,)) * np.asarray(rgb, dtype=np.float64)
    src = np.concatenate([rgb, np.ones(mask.shape + (1,))], axis=-1)
    dst *= (1.0 - a)
    dst += src * a
    return dst


def over_field(dst, mask, rgb_field, alpha_field):
    """Composite per-sample colors and alphas over `dst` where `mask`."""
    a = (mask * alpha_field)[..., None]
    src = np.concatenate([rgb_field, np.ones(mask.shape + (1,))], axis=-1)
    dst *= (1.0 - a)
    dst += src * a
    return dst


def blank(x):
    return np.zeros(x.shape + (4,))


def gaussian(img, sigma):
    """Separable gaussian blur of a 2-D array, sigma in texels, edges clamped to zero."""
    r = int(math.ceil(sigma * 3))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2)
    k /= k.sum()
    pad = np.pad(img, r)
    tmp = np.apply_along_axis(lambda v: np.convolve(v, k, mode="valid"), 1, pad)
    return np.apply_along_axis(lambda v: np.convolve(v, k, mode="valid"), 0, tmp)


def coverage(mask, w, h):
    return mask.astype(np.float64).reshape(h, SS, w, SS).mean(axis=(1, 3))


# ── output ──────────────────────────────────────────────────────────────────────────────────────

def to_tint(premul):
    """A tinted layer: straight-alpha luminance, white under every clear pixel."""
    a = premul[..., 3]
    rgb = np.where(a[..., None] > 1e-6, premul[..., :3] / np.maximum(a[..., None], 1e-6), 1.0)
    return pack(rgb, a)


def to_overlay(premul):
    """An overlay: straight alpha, a clear pixel takes the color of the drawn pixels near it."""
    a = premul[..., 3]
    rgb = premul[..., :3] / np.maximum(a[..., None], 1e-6)
    clear = a <= 1e-6
    if clear.any() and (~clear).any():
        # Bleed: average the premultiplied color over a widening neighborhood until it reaches.
        acc, wa = premul[..., :3].copy(), a.copy()
        fill = np.zeros(rgb.shape)
        done = ~clear
        for _ in range(4):
            acc = box3(acc)
            wa = box3(wa)
            reach = (~done) & (wa > 1e-6)
            fill[reach] = acc[reach] / wa[reach][..., None]
            done |= reach
        rgb = np.where(clear[..., None], fill, rgb)
    return pack(rgb, a)


def box3(img):
    pad = [(1, 1), (1, 1)] + [(0, 0)] * (img.ndim - 2)
    p = np.pad(img, pad)
    out = np.zeros(img.shape)
    for dy in range(3):
        for dx in range(3):
            out += p[dy:dy + img.shape[0], dx:dx + img.shape[1]]
    return out


def pack(rgb, a):
    out = np.concatenate([np.clip(rgb, 0, 1), np.clip(a, 0, 1)[..., None]], axis=-1)
    return np.round(out * 255).astype(np.uint8)


def tga_bytes(array):
    buf = io.BytesIO()
    Image.fromarray(array, "RGBA").save(buf, format="TGA", compression="tga_rle", orientation=1)
    return buf.getvalue()


# ── the rotated looks ───────────────────────────────────────────────────────────────────────────

def rot_points():
    return grid(ROT_BOX, ROT_SIZE, ROT_SIZE)


def fill():
    x, y = rot_points()
    dst = over(blank(x), inside(CHEVRON, x, y), (1, 1, 1), 1.0)
    return to_tint(down(dst, ROT_SIZE, ROT_SIZE))


def outline_over(dst, x, y, width):
    return over(dst, stroke(CHEVRON, True, width, x, y), OUTLINE_RGB, 1.0)


def overlay_of(parts):
    x, y = rot_points()
    dst = blank(x)
    for poly, rgb, alpha in parts:
        dst = over(dst, inside(poly, x, y), rgb, alpha)
    dst = outline_over(dst, x, y, OUTLINE_WIDTH)
    return to_overlay(down(dst, ROT_SIZE, ROT_SIZE))


def raised_overlay():
    x, y = rot_points()
    dst = blank(x)
    ys = [p[1] for p in CHEVRON]
    t = np.clip((y - min(ys)) / (max(ys) - min(ys)), 0, 1)
    # SVG interpolates color and opacity separately between stops.
    rgb = np.zeros(x.shape + (3,))
    alpha = np.zeros(x.shape)
    for (o0, c0, a0), (o1, c1, a1) in zip(RAISED_GRADIENT, RAISED_GRADIENT[1:]):
        sel = (t >= o0) & (t <= o1)
        u = (t[sel] - o0) / (o1 - o0)
        for i in range(3):
            rgb[..., i][sel] = c0[i] + (c1[i] - c0[i]) * u
        alpha[sel] = a0 + (a1 - a0) * u
    dst = over_field(dst, inside(CHEVRON, x, y), rgb, alpha)
    dst = over(dst, stroke(RAISED_RIM, False, RAISED_RIM_WIDTH, x, y), (1, 1, 1), RAISED_RIM_ALPHA)
    dst = outline_over(dst, x, y, OUTLINE_WIDTH)
    return to_overlay(down(dst, ROT_SIZE, ROT_SIZE))


def raised_shadow():
    x, y = grid(SHADOW_BOX, ROT_SIZE, ROT_SIZE)
    cov = coverage(inside(CHEVRON, x, y), ROT_SIZE, ROT_SIZE)
    per_unit = ROT_SIZE / (SHADOW_BOX[2] - SHADOW_BOX[0])
    a = gaussian(cov, RAISED_SHADOW_SIGMA * per_unit) * RAISED_SHADOW_ALPHA
    premul = np.zeros((ROT_SIZE, ROT_SIZE, 4))
    premul[..., 3] = a
    return to_overlay(premul)


# ── the ground look ─────────────────────────────────────────────────────────────────────────────

def ground_map(poly, deg, drop=0.0):
    """The mockup's ground transform of `poly`, turned `deg` COUNTER-clockwise on screen."""
    th = math.radians(deg)
    c, s = math.cos(th), math.sin(th)
    out = []
    for px, py in poly:
        dx, dy = px - GROUND_PIVOT[0], py - GROUND_PIVOT[1]
        # rotate(-deg) in SVG's y-down frame: counter-clockwise as the player sees it.
        rx, ry = dx * c + dy * s, -dx * s + dy * c
        out.append((GROUND_CENTER[0] + rx, GROUND_CENTER[1] + GROUND_SQUASH * ry + drop))
    return out


def ground_cell(deg, shadow_alpha):
    x, y = grid(CELL_BOX, CELL_W, CELL_H)
    top = ground_map(CHEVRON, deg)
    wall = ground_map(CHEVRON, deg, GROUND_WALL_DROP)
    body = blank(x)
    body = over(body, inside(wall, x, y), (GROUND_WALL_SHADE,) * 3, 1.0)
    in_top = inside(top, x, y)
    body = over(body, in_top, (1, 1, 1), 1.0)
    body = over(body, in_top & inside(ground_map(GROUND_TOP_RIGHT, deg), x, y), (GROUND_TOP_RIGHT_SHADE,) * 3, 1.0)
    body = down(body, CELL_W, CELL_H)
    # The shadow under everything, at texel resolution (it is blurred anyway).
    premul = np.zeros(body.shape)
    premul[..., 3] = shadow_alpha
    premul = body + premul * (1.0 - body[..., 3:4])

    ov = blank(x)
    poly, rgb, alpha = GROUND_TOP_LEFT
    ov = over(ov, in_top & inside(ground_map(poly, deg), x, y), rgb, alpha)
    ov = over(ov, stroke(top, True, GROUND_OUTLINE_WIDTH, x, y), OUTLINE_RGB, 1.0)
    return premul, down(ov, CELL_W, CELL_H)


def ground_shadow():
    x, y = grid(CELL_BOX, CELL_W, CELL_H)
    cx, cy, rx, ry = GROUND_SHADOW
    cov = coverage(((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0, CELL_W, CELL_H)
    per_unit = CELL_W / (CELL_BOX[2] - CELL_BOX[0])
    return gaussian(cov, GROUND_SHADOW_SIGMA * per_unit) * GROUND_SHADOW_ALPHA


def ground_sheets():
    body = np.zeros((SHEET, SHEET, 4))
    ov = np.zeros((SHEET, SHEET, 4))
    shadow = ground_shadow()
    for k in range(FRAMES):
        b, o = ground_cell(k * STEP_DEG, shadow)
        col, row = k % COLS, k // COLS
        ys, xs = slice(row * CELL_H, (row + 1) * CELL_H), slice(col * CELL_W, (col + 1) * CELL_W)
        body[ys, xs] = b
        ov[ys, xs] = o
    return to_tint(body), to_overlay(ov)


# ── main ────────────────────────────────────────────────────────────────────────────────────────

def build():
    body, ov = ground_sheets()
    return {
        "arrow-fill": fill(),
        "flat-overlay": overlay_of([]),
        "ridge-overlay": overlay_of(RIDGE),
        "raised-overlay": raised_overlay(),
        "raised-shadow": raised_shadow(),
        "faceted-overlay": overlay_of(FACETS),
        "ground-body": body,
        "ground-overlay": ov,
    }


def main(argv):
    check = "--check" in argv
    art = build()
    drift = []
    if not check:
        os.makedirs(OUT, exist_ok=True)
    for name, array in art.items():
        path = os.path.join(OUT, name + ".tga")
        data = tga_bytes(array)
        if check:
            try:
                with open(path, "rb") as f:
                    if f.read() != data:
                        drift.append(name)
            except OSError:
                drift.append(name)
            continue
        with open(path, "wb") as f:
            f.write(data)
        print("  %-18s %dx%d  %d bytes" % (name, array.shape[1], array.shape[0], len(data)))
    if drift:
        print("out of date: " + ", ".join(drift))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
