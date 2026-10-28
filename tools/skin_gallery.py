#!/usr/bin/env python3
"""skin_gallery.py: crop in-game skin screenshots to their window and build showcase images.

Takes one screenshot per Ka0s skin of the same addon window, crops each to the window (the game world
around it removed), and writes the crops plus two showcases of every skin at once, on a clean
background, each skin labeled with its name and its four preview swatches:

  showcase/standalone.png|.jpg  every window on its own, in a grid
  showcase/stacked.png|.jpg     the windows overlapping in two cascades, a different skin on each;
                                the right-hand cascade sits behind the left-hand one

Both are drawn at the crops' native resolution (no window is scaled down), so they are large: scale
them down for wherever they go.

The skins, their order, labels and swatches come from LibKa0s/SkinDefs.lua, so a new or renamed skin
needs no change here. Run it again whenever a skin changes or is added.

Usage:
  python3 tools/skin_gallery.py --title "Ka0s Loot History" --out ../LootHistory/docs/skins/screenshots/vN \\
      shot1.png shot2.png ...          # one per skin, in SkinDefs order
  python3 tools/skin_gallery.py --title "..." --out DIR --dir SHOTS/   # SHOTS/<skin key>.png, any order
  python3 tools/skin_gallery.py --title "..." --out DIR --from-crops   # rebuild the showcases only

Options:
  --cols N       standalone columns (default 3)
  --bg STYLE     light (default) or dark background
  --no-crop      keep each screenshot as it is (already cropped)
  --from-crops   read DIR's own NN-<key>.png crops and rebuild only the showcases
  --skins KEYS   comma-separated subset of skin keys, in the order the screenshots are given

Writes <out>/NN-<key>.png (the crops) and <out>/showcase/. Needs Python 3, Pillow and NumPy.
"""
import argparse
import glob
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

BACKGROUNDS = {       # top and bottom of the vertical gradient, then the heading and subheading colors
    "light": ((246, 247, 249), (226, 228, 233), (24, 24, 30), (110, 112, 122)),
    "dark": ((34, 35, 42), (14, 14, 18), (240, 240, 245), (150, 152, 162)),
}


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
    """A plain vertical gradient: the clean backdrop both showcases sit on."""
    top, bottom = BACKGROUNDS[style][:2]
    w, h = size
    t = np.linspace(0, 1, h)[:, None]
    col = (np.array(top)[None, :] * (1 - t) + np.array(bottom)[None, :] * t).astype(np.uint8)
    return Image.fromarray(np.repeat(col[:, None, :], w, axis=1), "RGB").convert("RGBA")


def shadow(canvas, box, unit):
    """A soft drop shadow under a window's box, so overlapping windows read as layers."""
    x0, y0, x1, y1 = box
    blur = max(4, round(unit * 1.6))
    off = round(unit * 0.5)
    pad = blur * 3
    mask = Image.new("L", (x1 - x0 + 2 * pad, y1 - y0 + 2 * pad), 0)
    ImageDraw.Draw(mask).rectangle((pad, pad, pad + x1 - x0, pad + y1 - y0), fill=150)
    mask = mask.filter(ImageFilter.GaussianBlur(blur))
    layer = Image.new("RGBA", mask.size, (0, 0, 0, 255))
    layer.putalpha(mask)
    canvas.alpha_composite(layer, (x0 - pad + off, y0 - pad + off * 2))


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


def heading(canvas, title, subtitle, style, unit, x, y):
    ink, sub = BACKGROUNDS[style][2:]
    d = ImageDraw.Draw(canvas)
    ft, fs = font(TITLE_FONT, round(unit * 3.2)), font(LABEL_FONT, round(unit * 1.5))
    d.text((x, y), title, font=ft, fill=ink)
    d.text((x, y + round(unit * 4.3)), subtitle, font=fs, fill=sub)


def subtitle(n):
    return f"{n} Ka0s skins (LibKa0s-Skin-1.0)"


def standalone(tiles, meta, title, cols, style):
    """Every window on its own, in a grid, each under its labeled name."""
    W = max(t.width for t in tiles)
    H = max(t.height for t in tiles)
    unit = max(H, W * 0.6) / 48                     # labels and heading scale with the window
    gap = round(W * 0.06)
    lab = round(unit * 3.2)
    head = round(unit * 9)
    rows = -(-len(tiles) // cols)
    size = (cols * W + (cols + 1) * gap, head + rows * (lab + H + gap) + gap)
    out = background(size, style)
    heading(out, title, subtitle(len(tiles)), style, unit, gap, round(unit * 2.5))
    f = font(LABEL_FONT, round(unit * 1.15))
    for i, (t, m) in enumerate(zip(tiles, meta)):
        r, c = divmod(i, cols)
        x = gap + c * (W + gap)
        y = head + r * (lab + H + gap) + lab
        shadow(out, (x, y, x + t.width, y + t.height), unit)
        out.alpha_composite(t.convert("RGBA"), (x, y))
        draw_label(out, m, (x, y - round(unit * 2.0) - round(unit * 0.6)), f, unit)
    return out.convert("RGB")


def overlaps(a, b):
    return a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]


def stacked(tiles, meta, title, style):
    """Two cascades of overlapping windows fanning in toward the middle, a different skin on each. The
    left cascade steps down and right, the right one down and left, and the left is drawn last, so the
    right cascade tucks in behind it. The first skin is the left cascade's front window, the second
    the right's. Each label straddles its window's top edge, at the outer corner, and stays in view:
    the right cascade is placed as far under the left as it can go with no label covered."""
    W = max(t.width for t in tiles)
    H = max(t.height for t in tiles)
    unit = max(H, W * 0.6) / 48                     # labels and heading scale with the window
    f = font(LABEL_FONT, round(unit * 1.15))
    dx, dy = round(W * 0.085), round(H * 0.13)
    inset = round(unit * 1.6)
    left = list(range(0, len(tiles), 2))[::-1]     # back to front: the front window is the first skin
    right = list(range(1, len(tiles), 2))[::-1]
    order = right + left                            # draw order: the right cascade first, behind

    def place(overlap, lift):
        spots = {}
        lfront = (len(left) - 1) * dx
        rfront = lfront + W - overlap               # the right front window's left edge
        for d, i in enumerate(right):
            back = len(right) - 1 - d
            spots[i] = (rfront + back * dx, lift + d * dy)
        for d, i in enumerate(left):
            spots[i] = (d * dx, d * dy)
        return spots

    def label_box(i, spot):
        lw, lh = label_size(meta[i], f, unit)
        x, y = spot
        # the right cascade's label keeps clear of the close button in the window's top-right corner
        lx = x + inset if i in left else x + tiles[i].width - round(unit * 3.6) - lw
        return (lx, y - lh // 2, lx + lw, y - lh // 2 + lh)

    def clear(spots):
        for n, i in enumerate(order):
            lab = label_box(i, spots[i])
            for j in order[n + 1:]:
                sx, sy = spots[j]
                if overlaps(lab, (sx, sy, sx + tiles[j].width, sy + tiles[j].height)):
                    return False
        return True

    spots = None
    for frac in [x / 100 for x in range(40, 4, -2)]:
        for lift in (-dy // 2, -dy // 4, 0, dy // 4, dy // 2):
            cand = place(round(W * frac), lift)
            if clear(cand):
                spots = cand
                break
        if spots:
            break
    spots = spots or place(0, 0)
    labels = {i: label_box(i, spots[i]) for i in order}
    minx = min(min(x for x, _ in spots.values()), min(b[0] for b in labels.values()))
    miny = min(min(y for _, y in spots.values()), min(b[1] for b in labels.values()))
    maxx = max(x + tiles[i].width for i, (x, _) in spots.items())
    maxy = max(y + tiles[i].height for i, (_, y) in spots.items())
    margin = round(W * 0.05)
    head = round(unit * 9)
    size = (maxx - minx + 2 * margin, maxy - miny + 2 * margin + head)
    out = background(size, style)
    heading(out, title, subtitle(len(tiles)), style, unit, margin, round(unit * 2.5))
    ox, oy = margin - minx, margin + head - miny
    for i in order:
        x, y = spots[i][0] + ox, spots[i][1] + oy
        shadow(out, (x, y, x + tiles[i].width, y + tiles[i].height), unit * 1.4)
        out.alpha_composite(tiles[i].convert("RGBA"), (x, y))
        b = labels[i]
        draw_label(out, meta[i], (b[0] + ox, b[1] + oy), f, unit)
    return out.convert("RGB")


def write_showcases(tiles, meta, title, out, cols, style):
    folder = os.path.join(out, "showcase")
    os.makedirs(folder, exist_ok=True)
    for name, im in (("standalone", standalone(tiles, meta, title, cols, style)),
                     ("stacked", stacked(tiles, meta, title, style))):
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
    p.add_argument("--bg", choices=sorted(BACKGROUNDS), default="light")
    p.add_argument("--no-crop", action="store_true")
    p.add_argument("--from-crops", action="store_true")
    p.add_argument("--skins", help="comma-separated skin keys, when not every skin is shot")
    args = p.parse_args()

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
        write_showcases(tiles, meta, args.title, args.out, args.cols, args.bg)
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
    write_showcases(tiles, meta, args.title, args.out, args.cols, args.bg)


if __name__ == "__main__":
    main()
