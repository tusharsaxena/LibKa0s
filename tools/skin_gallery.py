#!/usr/bin/env python3
"""skin_gallery.py: crop in-game skin screenshots to their window and build showcase images.

Takes one screenshot per Ka0s skin of the same addon window, crops each to the window (the game world
around it removed), and writes the crops plus seven showcases of every skin at once. Each showcase
sits on a dark background, and each skin is labeled with its name and its four preview swatches:

  showcase/standalone   every window on its own, in a grid
  showcase/fan          a hand of cards around a pivot below; the first skin flat in the centre, in front
  showcase/staircase    one cascade from the top left to the bottom right; the first skin in front
  showcase/hero         the first skin large on top, the others in a labeled grid below it
  showcase/coverflow    the first skin flat in the centre, the others turned away in perspective
  showcase/slices       one window cut into slanted bands, each band a different skin
  showcase/deck         one row fanned out to the right like a spread deck, the first skin in front

Each is written as a PNG and a JPEG, drawn at the crops' native resolution (no window is scaled
down), so they are large: scale them down for wherever they go.

The skins, their order, labels and swatches come from LibKa0s/SkinDefs.lua, so a new or renamed skin
needs no change here. Run it again whenever a skin changes or is added.

Usage:
  python3 tools/skin_gallery.py --title "Ka0s Loot History" --out ../LootHistory/media/screenshots/skins/vN \\
      shot1.png shot2.png ...          # one per skin, in SkinDefs order
  python3 tools/skin_gallery.py --title "..." --out DIR --dir SHOTS/   # SHOTS/<skin key>.png, any order
  python3 tools/skin_gallery.py --title "..." --out DIR --from-crops   # rebuild the showcases only

Options:
  --cols N         standalone columns (default 3)
  --bg STYLE       slate (default), plum or graphite
  --layouts NAMES  comma-separated subset of the showcases above (default: all of them)
  --no-crop        keep each screenshot as it is (already cropped)
  --from-crops     read DIR's own NN-<key>.png crops and rebuild only the showcases
  --skins KEYS     comma-separated subset of skin keys, in the order the screenshots are given

Writes <out>/NN-<key>.png (the crops) and <out>/showcase/. Needs Python 3, Pillow and NumPy.
"""
import argparse
import glob
import math
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SKINDEFS = os.path.join(ROOT, "LibKa0s", "SkinDefs.lua")
FONTS = os.path.join(ROOT, "LibKa0s", "media", "fonts")
LABEL_FONT = os.path.join(FONTS, "Inter-SemiBold.ttf")
TITLE_FONT = os.path.join(FONTS, "Inter-SemiBold.ttf")

EDGE_DIFF = 40        # summed RGB step between neighbors that counts as an edge
EDGE_SHARE = 0.55     # share of a line's span that must step at once for it to be the window's edge

BACKGROUNDS = {       # the lit centre, the edge, and a pattern: dark grounds a near-black window still reads on
    "slate": ((44, 52, 74), (12, 14, 22), None),
    "plum": ((58, 38, 70), (14, 10, 18), None),
    "graphite": ((48, 50, 56), (16, 17, 20), "dots"),
}
INK, SUBINK = (238, 240, 246), (150, 156, 176)


def skins():
    """[{key, label, swatches}] in registration order, read from SkinDefs.lua."""
    with open(SKINDEFS, encoding="utf-8") as f:
        src = f.read()
    # Ka0s Default registers through lib:RegisterSkin{ key = ..., label = ..., swatches = {...} }; the
    # rest through the file's register("key", "Label", "desc", { swatches }, ...) helper.
    found = []
    for m in re.finditer(r'RegisterSkin\(\{\s*key\s*=\s*"([^"]+)",\s*label\s*=\s*"([^"]+)"(.*?)\}\)', src, re.S):
        sw = re.search(r'swatches\s*=\s*\{([^}]*)\}', m.group(3))
        found.append((m.start(), m.group(1), m.group(2), sw.group(1) if sw else ""))
    for m in re.finditer(r'^register\("([^"]+)",\s*"([^"]+)",\s*"(?:[^"\\]|\\.)*",\s*\{([^}]*)\}', src, re.M):
        found.append((m.start(), m.group(1), m.group(2), m.group(3)))
    found.sort()
    return [{"key": k, "label": l, "swatches": re.findall(r'#([0-9a-fA-F]{6})', sw)}
            for _, k, l, sw in found]


def edge_lines(a, axis):
    """Indices i where line i differs sharply from line i-1 along most of its span (axis 0 = rows)."""
    if axis == 1:
        a = a.transpose(1, 0, 2)
    n, m = a.shape[:2]
    lo, hi = int(m * 0.1), int(m * 0.9)
    step = np.abs(a[1:, lo:hi].astype(int) - a[:-1, lo:hi].astype(int)).sum(axis=2)
    share = (step > EDGE_DIFF).mean(axis=1)
    return [i + 1 for i in np.nonzero(share >= EDGE_SHARE)[0]]


def crop_window(im):
    """The image cut to the outermost straight edges: the window's own border, the world removed."""
    a = np.asarray(im.convert("RGB"))
    h, w = a.shape[:2]
    rows, cols = edge_lines(a, 0), edge_lines(a, 1)
    top = rows[0] if rows else 0
    bottom = rows[-1] if len(rows) > 1 else h
    left = cols[0] if cols else 0
    right = cols[-1] if len(cols) > 1 else w
    # A window drawn flush with the screenshot's own edge has no step there: keep that side whole.
    if bottom - top < h * 0.5:
        top, bottom = 0, h
    if right - left < w * 0.5:
        left, right = 0, w
    return im.crop((left, top, right, bottom))


def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def background(size, style):
    """A dark ground, lit a little behind the windows and falling off to the edges."""
    inner, outer, pattern = BACKGROUNDS[style]
    w, h = size
    yy, xx = np.mgrid[0:h, 0:w]
    r = (np.sqrt(((xx - w * 0.5) / (w * 0.75)) ** 2 + ((yy - h * 0.38) / (h * 0.85)) ** 2).clip(0, 1)) ** 1.4
    a = np.array(inner)[None, None, :] * (1 - r[..., None]) + np.array(outer)[None, None, :] * r[..., None]
    im = Image.fromarray(a.astype(np.uint8), "RGB").convert("RGBA")
    if pattern == "dots":
        d = ImageDraw.Draw(im)
        step = max(18, w // 90)
        for y in range(step // 2, h, step):
            for x in range(step // 2, w, step):
                d.point((x, y), fill=(255, 255, 255, 18))
    return im


def put(canvas, img, xy, unit):
    """Paste a window with a soft drop shadow and a faint light rim, so it lifts off the ground."""
    blur = max(4, round(unit))
    alpha = img.split()[3].point(lambda v: 170 if v > 0 else 0)
    pad = blur * 3
    m = Image.new("L", (img.width + 2 * pad, img.height + 2 * pad), 0)
    m.paste(alpha, (pad, pad))
    shade = Image.new("RGBA", m.size, (0, 0, 0, 255))
    shade.putalpha(m.filter(ImageFilter.GaussianBlur(blur)))
    x, y = int(xy[0]), int(xy[1])
    canvas.alpha_composite(shade, (int(x - pad + blur * 0.3), int(y - pad + blur * 0.6)))
    canvas.alpha_composite(img, (x, y))
    rim = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(rim).rectangle((0, 0, img.width - 1, img.height - 1), outline=(255, 255, 255, 34))
    rim.putalpha(Image.fromarray(np.minimum(np.asarray(rim.split()[3]), np.asarray(img.split()[3]))))
    canvas.alpha_composite(rim, (x, y))


def label_size(skin, f, unit):
    """(w, h) of a skin's label pill: its name, then its four swatches."""
    tw = f.getbbox(skin["label"])[2]
    sq = round(unit * 0.95)
    return round(unit * 0.9) + tw + round(unit * 0.8) + len(skin["swatches"]) * (sq + 2) + round(unit * 0.7), \
        round(unit * 2.0)


def draw_label(canvas, skin, xy, f, unit):
    """A dark pill with the skin's name and its four preview swatches, edged in its accent."""
    w, h = label_size(skin, f, unit)
    x, y = xy
    accent = tuple(int(skin["swatches"][-1][i:i + 2], 16) for i in (0, 2, 4)) if skin["swatches"] else (255, 209, 0)
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle((x, y, x + w, y + h), radius=h // 2, fill=(14, 14, 18, 238), outline=accent + (255,),
                        width=max(2, round(unit * 0.12)))
    canvas.alpha_composite(layer)
    d = ImageDraw.Draw(canvas)
    tx = x + round(unit * 0.9)
    bb = f.getbbox(skin["label"])
    d.text((tx, y + (h - (bb[3] + bb[1])) / 2), skin["label"], font=f, fill=(245, 245, 248))
    sq = round(unit * 0.95)
    sx = tx + bb[2] + round(unit * 0.8)
    sy = y + (h - sq) // 2
    for hx in skin["swatches"]:
        c = tuple(int(hx[i:i + 2], 16) for i in (0, 2, 4))
        d.rectangle((sx, sy, sx + sq - 1, sy + sq - 1), fill=c, outline=(90, 90, 98))
        sx += sq + 2


def label(canvas, m, xy, unit, anchor="lt"):
    """A skin's label pill at xy; anchor is horizontal (l, m, r) then vertical (t, m, b)."""
    f = font(LABEL_FONT, round(unit * 1.15))
    w, h = label_size(m, f, unit)
    x, y = xy
    x -= {"l": 0, "m": w // 2, "r": w}[anchor[0]]
    y -= {"t": 0, "m": h // 2, "b": h}[anchor[1]]
    draw_label(canvas, m, (int(x), int(y)), f, unit)


def heading(canvas, title, n, unit, x, y):
    d = ImageDraw.Draw(canvas)
    d.text((x, y), title, font=font(TITLE_FONT, round(unit * 3)), fill=INK)
    d.text((x, y + round(unit * 4)), f"{n} Ka0s skins (LibKa0s-Skin-1.0)", font=font(LABEL_FONT, round(unit * 1.4)),
           fill=SUBINK)


def frame(tiles):
    """The common window size and the unit labels and spacing scale from."""
    W = max(t.width for t in tiles)
    H = max(t.height for t in tiles)
    return W, H, max(H, W * 0.6) / 48


def standalone(tiles, meta, title, bg, cols=3):
    """Every window on its own, in a grid, each under its label."""
    W, H, unit = frame(tiles)
    gap, lab, head = round(W * 0.06), round(unit * 3.2), round(unit * 9)
    rows = -(-len(tiles) // cols)
    c = background((cols * W + (cols + 1) * gap, head + rows * (lab + H + gap) + gap), bg)
    heading(c, title, len(tiles), unit, gap, round(unit * 2.5))
    for i, (t, m) in enumerate(zip(tiles, meta)):
        r, k = divmod(i, cols)
        x, y = gap + k * (W + gap), head + r * (lab + H + gap) + lab
        put(c, t, (x, y), unit)
        label(c, m, (x, y - round(unit * 0.6)), unit, "lb")
    return c


def fan(tiles, meta, title, bg):
    """A hand of cards around a pivot below the windows: the first skin flat in the centre and in front,
    the rest tilting away to each side, behind it. Labels ride above each window's top edge."""
    W, H, unit = frame(tiles)
    n = len(tiles)
    spread, R, head = 64, W * 1.9, unit * 9
    ranked = sorted(range(n), key=lambda k: abs(k - (n - 1) / 2))   # slots from the centre outward
    angle = {s: (k - (n - 1) / 2) * spread / max(1, n - 1) for s, k in zip(range(n), ranked)}
    half = math.radians(spread / 2)
    cw = int(2 * (R * math.sin(half) + W * 0.62) + unit * 6)
    ch = int(head + unit * 6 + H * 1.25 + R * (1 - math.cos(half)) + H * 0.35)
    c = background((cw, ch), bg)
    heading(c, title, n, unit, int(unit * 3), int(unit * 2.5))
    px, py = cw / 2, head + unit * 7 + H / 2 + R
    tops = []
    for s in sorted(range(n), key=lambda s: -abs(angle[s])):        # outermost first, the centre last
        a = math.radians(angle[s])
        rot = tiles[s].rotate(-angle[s], resample=Image.BICUBIC, expand=True)
        cx, cy = px + R * math.sin(a), py - R * math.cos(a)
        put(c, rot, (cx - rot.width / 2, cy - rot.height / 2), unit * 1.2)
        d = H / 2 + unit * 1.3
        tops.append((s, cx + d * math.sin(a), cy - d * math.cos(a)))
    for s, x, y in tops:
        label(c, meta[s], (x, y), unit * (1 if s == 0 else 0.85), "mm")
    return c


def staircase(tiles, meta, title, bg):
    """One cascade from the top left to the bottom right; the first skin lands in front."""
    W, H, unit = frame(tiles)
    n = len(tiles)
    dx, dy, head = W * 0.11, H * 0.12, unit * 9
    c = background((int(W + dx * (n - 1) + unit * 8), int(H + dy * (n - 1) + head + unit * 8)), bg)
    heading(c, title, n, unit, int(unit * 3), int(unit * 2.5))
    for d, s in enumerate(range(n - 1, -1, -1)):
        x, y = unit * 4 + d * dx, head + unit * 4 + d * dy
        put(c, tiles[s], (x, y), unit)
        label(c, meta[s], (x + unit * 1.2, y + unit * 0.9), unit * 0.9)
    return c


def hero(tiles, meta, title, bg):
    """The first skin large on top, the others in a labeled grid below it."""
    W, H, unit = frame(tiles)
    n = len(tiles)
    gap, head, cols = unit * 2.4, unit * 9, 4
    big = tiles[0].resize((int(W * 1.35), int(H * 1.35)), Image.LANCZOS)
    rows = math.ceil((n - 1) / cols)
    tw = (big.width - gap * (cols - 1)) / cols
    th = H * tw / W
    c = background((int(big.width + unit * 8),
                    int(head + unit * 3.2 + big.height + gap * 1.5 + rows * (th + unit * 3.2 + gap) + unit * 4)), bg)
    heading(c, title, n, unit, int(unit * 4), int(unit * 2.5))
    x0, y0 = unit * 4, head + unit * 3.2
    put(c, big, (x0, y0), unit * 1.4)
    label(c, meta[0], (x0, y0 - unit * 0.6), unit, "lb")
    y1 = y0 + big.height + gap * 1.5 + unit * 2.6
    for i, s in enumerate(range(1, n)):
        r, k = divmod(i, cols)
        t = tiles[s].resize((int(tw), int(th)), Image.LANCZOS)
        x, y = x0 + k * (tw + gap), y1 + r * (th + unit * 3.2 + gap)
        put(c, t, (x, y), unit * 0.8)
        label(c, meta[s], (x, y - unit * 0.5), unit * 0.85, "lb")
    return c


def perspective(src, dst):
    """The 8 PIL PERSPECTIVE coefficients mapping output corners dst back onto input corners src."""
    rows = []
    for (x, y), (u, v) in zip(dst, src):
        rows.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        rows.append([0, 0, 0, x, y, 1, -v * x, -v * y])
    return np.linalg.solve(np.array(rows, float), np.array(src, float).reshape(8)).tolist()


def tilt(img, far, depth):
    """Turn a window away from the viewer, its `far` edge (left or right) shrunk by `depth`."""
    w, h = img.size
    nw, s = int(w * (1 - depth * 0.55)), depth * h * 0.5
    dst = [(0, s), (nw, 0), (nw, h), (0, h - s)] if far == "left" else [(0, 0), (nw, s), (nw, h - s), (0, h)]
    return img.transform((nw, h), Image.PERSPECTIVE, perspective([(0, 0), (w, 0), (w, h), (0, h)], dst),
                         Image.BICUBIC)


def coverflow(tiles, meta, title, bg):
    """The first skin flat in the centre; the others turned away in perspective on both sides, smaller
    as they recede, like an album shelf. Labels under each window."""
    W, H, unit = frame(tiles)
    n = len(tiles)
    head, step = unit * 9, W * 0.22
    side = max(1, (n - 1 + 1) // 2)
    c = background((int(W + 2 * (W * 0.42 + step * (side - 1)) + unit * 8), int(H * 1.12 + head + unit * 12)), bg)
    heading(c, title, n, unit, int(unit * 3), int(unit * 2.5))
    cx, cy = c.width / 2, head + unit * 4 + H * 0.56
    items = [(k + 1, s, "left") for k, s in enumerate(range(1, n, 2))] + \
            [(k + 1, s, "right") for k, s in enumerate(range(2, n, 2))]
    for k, s, sd in sorted(items, key=lambda t: -t[0]):              # the farthest first
        sc = 0.86 - 0.05 * (k - 1)
        t = tilt(tiles[s].resize((int(W * sc), int(H * sc)), Image.LANCZOS), sd, 0.30)
        off = W * 0.5 + step * (k - 1) + t.width * 0.15
        x = cx - off - t.width * 0.85 if sd == "left" else cx + off - t.width * 0.15
        y = cy - t.height / 2
        put(c, t, (x, y), unit)
        label(c, meta[s], (x + t.width / 2, y + t.height + unit * 0.9), unit * 0.8, "mt")
    put(c, tiles[0], (cx - W / 2, cy - H / 2), unit * 1.6)
    label(c, meta[0], (cx, cy + H / 2 + unit * 0.9), unit, "mt")
    return c


def slices(tiles, meta, title, bg):
    """One window cut into slanted bands, each band a different skin, so the same controls change skin
    across it. Every crop is drawn at the first one's size, half again as large."""
    W, H, unit = frame(tiles)
    n = len(tiles)
    head = unit * 9
    W2, H2 = int(tiles[0].width * 1.5), int(tiles[0].height * 1.5)
    slant, band = H2 * 0.18, W2 / n
    out = Image.new("RGBA", (W2, H2))
    for i, t in enumerate(tiles):
        m = Image.new("L", (W2, H2), 0)
        l = i * band if i else -slant
        r = (i + 1) * band if i < n - 1 else W2 + slant
        ImageDraw.Draw(m).polygon([(l + slant / 2, 0), (r + slant / 2, 0), (r - slant / 2, H2), (l - slant / 2, H2)],
                                  fill=255)
        out.paste(t.resize((W2, H2), Image.LANCZOS), (0, 0), m)
    d = ImageDraw.Draw(out)
    for i in range(1, n):
        d.line([(i * band + slant / 2, 0), (i * band - slant / 2, H2)], fill=(255, 255, 255, 70),
               width=max(2, round(unit * 0.12)))
    c = background((int(W2 + unit * 8), int(H2 + head + unit * 11)), bg)
    heading(c, title, n, unit, int(unit * 4), int(unit * 2.5))
    x0, y0 = unit * 4, head + unit * 1.5
    put(c, out, (x0, y0), unit * 1.6)
    for i in range(n):
        foot = min(max(i * band + band / 2 - slant / 2, band * 0.45), W2 - band * 0.45)
        label(c, meta[i], (x0 + foot, y0 + H2 + unit * (1.2 if i % 2 == 0 else 3.6)), unit * 0.78, "mt")
    return c


def deck(tiles, meta, title, bg):
    """One row fanned out to the right like a spread deck: the first skin in front at the left, each next
    one a strip behind it, labeled over its strip."""
    W, H, unit = frame(tiles)
    n = len(tiles)
    head = unit * 9
    small = [t.resize((int(W * 0.85), int(H * 0.85)), Image.LANCZOS) for t in tiles]
    w, h = small[0].size
    step, lift, mid = w * 0.21, h * 0.035, (n - 1) / 2
    c = background((int(w + step * (n - 1) + unit * 8), int(h + lift * (n - 1) / 2 + head + unit * 11)), bg)
    heading(c, title, n, unit, int(unit * 4), int(unit * 2.5))
    x0, y0 = unit * 4, head + unit * 5.5
    for s in range(n - 1, -1, -1):
        x, y = x0 + s * step, y0 + abs(s - mid) * lift * 0.5
        put(c, small[s], (x, y), unit)
        lx = x + w / 2 if s == 0 else x + w - step / 2
        label(c, meta[s], (lx, y - unit * (0.5 if s % 2 == 0 else 2.6)), unit * 0.78, "mb")
    return c


LAYOUTS = {"standalone": standalone, "fan": fan, "staircase": staircase, "hero": hero,
           "coverflow": coverflow, "slices": slices, "deck": deck}


def write_showcases(tiles, meta, title, out, cols, bg, names):
    folder = os.path.join(out, "showcase")
    os.makedirs(folder, exist_ok=True)
    tiles = [t.convert("RGBA") for t in tiles]
    for name in names:
        fn = LAYOUTS[name]
        im = (fn(tiles, meta, title, bg, cols) if name == "standalone" else fn(tiles, meta, title, bg)).convert("RGB")
        png, jpg = os.path.join(folder, name + ".png"), os.path.join(folder, name + ".jpg")
        im.save(png, optimize=True)
        im.save(jpg, quality=92, subsampling=0, optimize=True)
        print(f"{png}  {im.width}x{im.height}")
        print(jpg)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("shots", nargs="*", help="screenshots, one per skin, in SkinDefs order")
    p.add_argument("--dir", help="a folder of <skin key>.png screenshots instead")
    p.add_argument("--title", required=True, help="the addon's name, for the showcase heading")
    p.add_argument("--out", required=True, help="the folder the crops and showcase/ go to")
    p.add_argument("--cols", type=int, default=3)
    p.add_argument("--bg", choices=sorted(BACKGROUNDS), default="slate")
    p.add_argument("--layouts", help="comma-separated subset of: " + ", ".join(LAYOUTS))
    p.add_argument("--no-crop", action="store_true")
    p.add_argument("--from-crops", action="store_true")
    p.add_argument("--skins", help="comma-separated skin keys, when not every skin is shot")
    args = p.parse_args()

    names = args.layouts.split(",") if args.layouts else list(LAYOUTS)
    bad = [x for x in names if x not in LAYOUTS]
    if bad:
        sys.exit(f"unknown layouts: {', '.join(bad)} (known: {', '.join(LAYOUTS)})")
    known = skins()
    by_key = {s["key"]: s for s in known}
    if args.from_crops:
        tiles, meta = [], []
        for path in sorted(glob.glob(os.path.join(args.out, "[0-9][0-9]-*.png"))):
            key = os.path.basename(path)[3:-4]
            if key not in by_key:
                sys.exit(f"{path}: no skin '{key}' in SkinDefs.lua")
            tiles.append(Image.open(path).convert("RGB"))
            meta.append(by_key[key])
        if not tiles:
            sys.exit(f"no NN-<key>.png crops in {args.out}")
        write_showcases(tiles, meta, args.title, args.out, args.cols, args.bg, names)
        return

    if args.skins:
        want = args.skins.split(",")
        missing = [k for k in want if k not in by_key]
        if missing:
            sys.exit(f"unknown skin keys: {', '.join(missing)}")
        order = [by_key[k] for k in want]
    else:
        order = known
    if args.dir:
        pairs = [(m, os.path.join(args.dir, m["key"] + ".png")) for m in order]
        pairs = [x for x in pairs if os.path.exists(x[1])]
    else:
        if len(args.shots) != len(order):
            sys.exit(f"{len(args.shots)} screenshots for {len(order)} skins "
                     f"({', '.join(m['key'] for m in order)}); pass --skins to name a subset")
        pairs = list(zip(order, args.shots))
    if not pairs:
        sys.exit("no screenshots")

    os.makedirs(args.out, exist_ok=True)
    tiles, meta = [], []
    for n, (m, path) in enumerate(pairs, 1):
        im = Image.open(path)
        im = im if args.no_crop else crop_window(im)
        im = im.convert("RGB")
        dest = os.path.join(args.out, f"{n:02d}-{m['key']}.png")
        im.save(dest, optimize=True)
        print(f"{dest}  {im.width}x{im.height}")
        tiles.append(im)
        meta.append(m)
    write_showcases(tiles, meta, args.title, args.out, args.cols, args.bg, names)


if __name__ == "__main__":
    main()
