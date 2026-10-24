#!/usr/bin/env python3
"""Generate the Glass skin's rounded-corner art: a nine-slice fill and a backdrop border.

    glass_textures.py          write LibKa0s/media/textures/glass-fill.tga and glass-border.tga

THE SAME BARGAIN AS bar_textures.py BESIDE IT: every value that decides what the art looks like is a
named constant here, and the art is what this file writes, so the two cannot drift. It is also the
license answer. Nothing is traced or sampled: every pixel is the coverage of a circle, computed
below. The Glass skin's look (translucency and rounded corners, radius 8) comes from the 2026-10-25
mockups in docs/skins/; EllesmereUI's art, which inspired the family, is not used or copied.

WHAT IT WRITES (white, uncompressed 32-bit TGA, alpha carries the shape; tint with SetVertexColor
or SetBackdropBorderColor):

    glass-fill.tga     32x32. A rounded rectangle filling the canvas, corner radius 8. A
                       ONE-FILE NINE-SLICE: draw it with SetTextureSliceMargins(8, 8, 8, 8) and the
                       stretched slice mode, so the corners stay 8x8 at any frame size. LSM
                       background "Ka0s Glass".

    glass-border.tga   256x32. A 1px rounded outline in the client's BACKDROP EDGE-FILE layout, so
                       it works wherever an LSM border does: SetBackdrop{ edgeFile = ..., edgeSize =
                       8 } draws a 1px line with radius-8 corners that sits exactly on glass-fill's
                       edge. LSM border "Ka0s Glass".

THE EDGE-FILE LAYOUT, as Blizzard_SharedXML/Backdrop.lua reads it (backdropPieceSetup): eight square
cells left to right -- left edge, right edge, top edge, bottom edge, then the top-left, top-right,
bottom-left and bottom-right corners. Two things in that table decide the drawing:

  * The client samples each cell INSET by 1/16 of its size on every side (texcoords 0.0078125 into
    a 1/8-wide cell horizontally, 0.0625 vertically). In a 32px cell that is 2px, so the drawn
    "logical" cell is the inner 28x28 and the outer 2px is a bleed band, filled with the nearest
    logical value so filtering never pulls in a stray edge.
  * The top and bottom edges are stored ROTATED: the top edge's outer side is its cell's LEFT
    column and the bottom edge's outer side its cell's RIGHT column, exactly like the left and right
    edges. The edge cells repeat along y, so every row of them is identical, bleed rows included.

At edgeSize 8 a 28px logical cell is drawn 8px wide, so the stroke is 28/8 = 3.5 source pixels for
a 1px line, and the corner's outer radius is the whole logical cell: radius 8 drawn.

WHY TRANSPARENT PIXELS ARE WHITE HERE, where bar_textures.py makes them black: these edges are
antialiased curves, and the client filters between an edge pixel and its transparent neighbor. Under
straight (non-premultiplied) alpha a black neighbor darkens that blend into a gray fringe on every
corner; a white one keeps the curve the tint's own color as it fades.

Requires Pillow and NumPy. No network, and no input files.
"""

import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, os.pardir, os.pardir))
OUT = os.path.join(ROOT, "LibKa0s", "media", "textures")

# The fill: 32x32, power of two, radius 8 -- a quarter of the canvas, so the four corners meet a
# 16x16 solid center that the stretched slice mode scales.
FILL_SIZE = 32
RADIUS = 8

# The border: eight 32px cells, the client's 1/16 sampling inset, and the drawn edge size the
# stroke is sized for.
CELL = 32
INSET = CELL // 16                 # 2px of bleed on every side of a cell
LOGICAL = CELL - 2 * INSET         # 28: what the client draws at edgeSize
EDGE_SIZE = 8                      # the edgeSize glass-border is drawn at
STROKE = LOGICAL / EDGE_SIZE       # 3.5 source px = a 1px line at EDGE_SIZE

# Antialiasing: each pixel is the mean coverage of SS x SS sample points.
SS = 8


def _samples():
    """Sample offsets inside one pixel, centered."""
    return (np.arange(SS) + 0.5) / SS


def _coverage(width, height, inside):
    """Mean of inside(x, y) over SS x SS points per pixel; x, y are float pixel-space arrays."""
    off = _samples()
    xs = (np.arange(width)[:, None] + off[None, :]).reshape(-1)
    ys = (np.arange(height)[:, None] + off[None, :]).reshape(-1)
    gx, gy = np.meshgrid(xs, ys)
    hit = inside(gx, gy).astype(np.float64)
    return hit.reshape(height, SS, width, SS).mean(axis=(1, 3))


def _rgba(alpha):
    """White everywhere, the shape in alpha (see the docstring on the transparent pixels)."""
    a = np.zeros(alpha.shape + (4,), dtype=np.uint8)
    a[..., 0:3] = 255
    a[..., 3] = np.clip(np.rint(alpha * 255.0), 0, 255).astype(np.uint8)
    return a


def fill():
    """glass-fill: a rounded rectangle covering the canvas, corner radius RADIUS."""
    s = float(FILL_SIZE)

    def inside(x, y):
        # Distance from the nearest corner's circle center, clamped so the straight runs count.
        cx = np.clip(x, RADIUS, s - RADIUS)
        cy = np.clip(y, RADIUS, s - RADIUS)
        return (x - cx) ** 2 + (y - cy) ** 2 <= RADIUS ** 2

    return _rgba(_coverage(FILL_SIZE, FILL_SIZE, inside))


def _cell(kind):
    """One edge-file cell. `kind` names it; logical coordinates run 0..LOGICAL, y downward."""
    L = float(LOGICAL)
    inner = L - STROKE

    def logical(v):
        return np.clip(v - INSET, 0.0, L)   # the bleed band repeats the nearest logical value

    def ring(cx, cy):
        def inside(x, y):
            d = np.hypot(logical(x) - cx, logical(y) - cy)
            return (d >= inner) & (d <= L)
        return inside

    shapes = {
        # Edges: the outer side is the LEFT column for left and top, the RIGHT for right and bottom.
        "left": lambda x, y: logical(x) < STROKE,
        "top": lambda x, y: logical(x) < STROKE,
        "right": lambda x, y: logical(x) > L - STROKE,
        "bottom": lambda x, y: logical(x) > L - STROKE,
        # Corners, drawn unrotated: each arc is centered on the cell's INNER corner.
        "topleft": ring(L, L),
        "topright": ring(0.0, L),
        "bottomleft": ring(L, 0.0),
        "bottomright": ring(0.0, 0.0),
    }
    return _coverage(CELL, CELL, shapes[kind])


ORDER = ("left", "right", "top", "bottom", "topleft", "topright", "bottomleft", "bottomright")


def border():
    """glass-border: the eight cells, side by side, in the order Backdrop.lua reads them."""
    return _rgba(np.concatenate([_cell(k) for k in ORDER], axis=1))


def write(name, array):
    path = os.path.join(OUT, name + ".tga")
    # Uncompressed (Pillow's TGA default), 32-bit with alpha.
    Image.fromarray(array, "RGBA").save(path)
    return path


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, array in (("glass-fill", fill()), ("glass-border", border())):
        path = write(name, array)
        h, w = array.shape[:2]
        print("  %-14s %dx%d  %d bytes" % (name, w, h, os.path.getsize(path)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
