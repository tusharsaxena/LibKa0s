#!/usr/bin/env python3
"""skin_gallery.py: crop in-game skin screenshots to their window and build a showcase collage.

Takes one screenshot per Ka0s skin of the same addon window, crops each to the window (the game world
around it removed), and writes the crops plus one showcase image: every skin in a grid, labeled, for a
quick look at all of them at once.

The skins, their order and their labels come from LibKa0s/SkinDefs.lua (its register() calls), so a new
or renamed skin needs no change here. Run it again whenever a skin changes or is added.

Usage:
  python3 tools/skin_gallery.py --title "Ka0s Loot History" --out docs/skins/screenshots/<date>/LootHistory \\
      shot1.png shot2.png ...          # one per skin, in SkinDefs order
  python3 tools/skin_gallery.py --title "..." --out DIR --dir SHOTS/   # SHOTS/<skin key>.png, any order

Options:
  --cols N      showcase columns (default 3)
  --tile W      showcase tile width in px (default 640)
  --no-crop     keep each screenshot as it is (already cropped)
  --skins KEYS  comma-separated subset of skin keys, in the order the screenshots are given

Writes <out>/NN-<key>.png (the crops) and <out>/showcase.png. Needs Python 3, Pillow and NumPy.
"""
import argparse
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SKINDEFS = os.path.join(ROOT, "LibKa0s", "SkinDefs.lua")
LABEL_FONT = os.path.join(ROOT, "LibKa0s", "media", "fonts", "Inter-SemiBold.ttf")

EDGE_DIFF = 40        # summed RGB step between neighbors that counts as an edge
EDGE_SHARE = 0.55     # share of a line's span that must step at once for it to be the window's edge


def skins():
    """[(key, label)] in registration order, read from SkinDefs.lua."""
    with open(SKINDEFS, encoding="utf-8") as f:
        src = f.read()
    # Ka0s Default registers through lib:RegisterSkin{ key = ..., label = ... }; the rest through the
    # file's register("key", "Label", ...) helper. Both, in the order they appear.
    pat = re.compile(r'^register\("([^"]+)",\s*"([^"]+)"|RegisterSkin\(\{\s*key\s*=\s*"([^"]+)",\s*'
                     r'label\s*=\s*"([^"]+)"', re.M)
    return [(m[0] or m[2], m[1] or m[3]) for m in pat.findall(src)]


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


def showcase(tiles, labels, title, cols, tile_w):
    """A grid of the crops, each under its skin's name, with the addon's title on top."""
    scale = [tile_w / t.width for t in tiles]
    tile_h = max(round(t.height * s) for t, s in zip(tiles, scale))
    pad, cap, head = 16, 30, 56
    rows = -(-len(tiles) // cols)
    W = cols * tile_w + (cols + 1) * pad
    H = head + rows * (cap + tile_h + pad) + pad
    out = Image.new("RGB", (W, H), (14, 14, 18))
    d = ImageDraw.Draw(out)
    try:
        f_title, f_cap = ImageFont.truetype(LABEL_FONT, 26), ImageFont.truetype(LABEL_FONT, 17)
    except OSError:
        f_title = f_cap = ImageFont.load_default()
    d.text((pad, 16), f"{title} — every Ka0s skin", font=f_title, fill=(255, 209, 0))
    for i, (t, label) in enumerate(zip(tiles, labels)):
        r, c = divmod(i, cols)
        x = pad + c * (tile_w + pad)
        y = head + r * (cap + tile_h + pad)
        d.text((x, y + 4), label, font=f_cap, fill=(230, 230, 235))
        out.paste(t.convert("RGB").resize((tile_w, round(t.height * tile_w / t.width)), Image.LANCZOS),
                  (x, y + cap))
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("shots", nargs="*", help="screenshots, one per skin, in SkinDefs order")
    p.add_argument("--dir", help="a folder of <skin key>.png screenshots instead")
    p.add_argument("--title", required=True, help="the addon's name, for the showcase heading")
    p.add_argument("--out", required=True, help="the folder the crops and showcase.png go to")
    p.add_argument("--cols", type=int, default=3)
    p.add_argument("--tile", type=int, default=640)
    p.add_argument("--no-crop", action="store_true")
    p.add_argument("--skins", help="comma-separated skin keys, when not every skin is shot")
    args = p.parse_args()

    known = skins()
    if args.skins:
        want = args.skins.split(",")
        labels = dict(known)
        missing = [k for k in want if k not in labels]
        if missing:
            sys.exit(f"unknown skin keys: {', '.join(missing)}")
        order = [(k, labels[k]) for k in want]
    else:
        order = known
    if args.dir:
        pairs = [(k, l, os.path.join(args.dir, k + ".png")) for k, l in order]
        pairs = [x for x in pairs if os.path.exists(x[2])]
    else:
        if len(args.shots) != len(order):
            sys.exit(f"{len(args.shots)} screenshots for {len(order)} skins "
                     f"({', '.join(k for k, _ in order)}); pass --skins to name a subset")
        pairs = [(k, l, s) for (k, l), s in zip(order, args.shots)]
    if not pairs:
        sys.exit("no screenshots")

    os.makedirs(args.out, exist_ok=True)
    tiles, labels = [], []
    for n, (key, label, path) in enumerate(pairs, 1):
        im = Image.open(path)
        im = im if args.no_crop else crop_window(im)
        im = im.convert("RGB")
        dest = os.path.join(args.out, f"{n:02d}-{key}.png")
        im.save(dest, optimize=True)
        print(f"{dest}  {im.width}x{im.height}")
        tiles.append(im)
        labels.append(label)
    dest = os.path.join(args.out, "showcase.png")
    showcase(tiles, labels, args.title, args.cols, args.tile).save(dest, optimize=True)
    print(dest)


if __name__ == "__main__":
    main()
