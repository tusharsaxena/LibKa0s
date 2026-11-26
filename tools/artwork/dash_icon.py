#!/usr/bin/env python3
"""Draw the `dash` icon: a thick horizontal bar with rounded ends, in the fat skill-up arrow's weight.

    dash_icon.py          write LibKa0s/media/icons/dash.tga
    dash_icon.py --check  draw it in memory and compare with the file on disk (exit 1 on drift)

WHY A HAND-DRAWN MARK. Drop Watcher marks a crafting row three ways: a fat up arrow (Phosphor's
`arrow-fat-up`) for a recipe that can still skill up, a padlock for one you don't know, and a
"no skill-up" mark between them. The owner asked for that mark to be a thick dash in the arrow's
weight (owner feedback round 4, 2026-11-26). None of the three sets has one: Open Iconic's `minus`
(the window strip's minus here) is 16 of 64 tall and runs the whole canvas, edge to edge, and Phosphor's `minus`
is a 16/256 hairline. Both read as a different family beside the fat arrow at 14 px.

THE SAME BARGAIN AS bar_textures.py, glass_textures.py AND waypoint_arrow.py BESIDE IT: every value
that decides what the mark looks like is a named constant here, and the mark is what this file
writes, so the two cannot drift. Nothing is traced or sampled, so the mark is the library's own art,
MIT as the rest of the library (`LibKa0s/LICENSE`); `media/icons/CREDITS.txt` records that beside it.

THE GEOMETRY, on the 64x64 canvas every Open Iconic and Phosphor mark here is drawn on:

    width   28 px, x 18..46: the stem of `ph:arrow-fat-up` as this library ships it (its opaque
            columns are 18..45), so the dash is exactly as wide as the arrow it stands beside.
    height  14 px, y 25..39: 56/256 of the canvas, the top of the 48-56/256 band the spec asks
            for. At the 14 px Drop Watcher draws it, that is 3.06 px, so the bar stays a solid
            line at any sub-pixel offset rather than smearing into two half-lit rows.
    ends    half-circles of radius 7 (half the height), so the ends are fully round.
    center  the canvas's vertical center (y 32), where the arrow's own visual weight sits.

White with the shape in the alpha channel (Media.lua's contract: the caller's color tints it), the
transparent pixels white too so the client's filtering never draws a dark fringe on the curve
(glass_textures.py's docstring has the reason). Antialiased by 8x8 supersampling. Written as a
32-bit RLE TGA with a top-left origin, as waypoint_arrow.py writes its art; the client reads either
origin, and icon_cleaner.py's bottom-left TGAs beside it load the same way.

Requires Pillow and NumPy only. No network, and no input files.
"""

import io
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, os.pardir, os.pardir))
OUT = os.path.join(ROOT, "LibKa0s", "media", "icons", "dash.tga")

SIZE = 64          # the canvas, as every Open Iconic and Phosphor mark in media/icons/
LEFT = 18.0        # the fat arrow's stem, left edge
RIGHT = 46.0       # ... and right edge (exclusive): 28 px
HEIGHT = 14.0      # 56/256 of the canvas
CENTER_Y = 32.0    # the canvas's vertical center
SS = 8             # supersampling, per axis


def coverage():
    """Mean of the capsule's inside test over SS x SS points per pixel."""
    r = HEIGHT / 2.0
    off = (np.arange(SS) + 0.5) / SS
    xs = (np.arange(SIZE)[:, None] + off[None, :]).reshape(-1)
    ys = (np.arange(SIZE)[:, None] + off[None, :]).reshape(-1)
    gx, gy = np.meshgrid(xs, ys)
    # Distance to the capsule's spine (the segment between the two end-circle centers).
    cx = np.clip(gx, LEFT + r, RIGHT - r)
    inside = (gx - cx) ** 2 + (gy - CENTER_Y) ** 2 <= r * r
    return inside.astype(np.float64).reshape(SIZE, SS, SIZE, SS).mean(axis=(1, 3))


def dash():
    a = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    a[..., 0:3] = 255
    a[..., 3] = np.clip(np.rint(coverage() * 255.0), 0, 255).astype(np.uint8)
    return a


def tga_bytes(array):
    buf = io.BytesIO()
    Image.fromarray(array, "RGBA").save(buf, format="TGA", compression="tga_rle", orientation=1)
    return buf.getvalue()


def main(argv):
    body = tga_bytes(dash())
    if "--check" in argv:
        try:
            with open(OUT, "rb") as fh:
                disk = fh.read()
        except OSError:
            print("dash_icon: %s is missing" % OUT)
            return 1
        if disk != body:
            print("dash_icon: %s differs from what this file draws" % OUT)
            return 1
        print("dash_icon: dash.tga matches")
        return 0
    with open(OUT, "wb") as fh:
        fh.write(body)
    print("  dash.tga  %dx%d  %d bytes" % (SIZE, SIZE, len(body)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
