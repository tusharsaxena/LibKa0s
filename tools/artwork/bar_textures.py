#!/usr/bin/env python3
"""Generate the statusbar and underline TGAs this collection's bars are drawn with.

    bar_textures.py            write LibKa0s/media/textures/*.tga

WHY THIS IS A PROGRAM AND NOT SEVEN CHECKED-IN BINARIES:

    The same argument icon_cleaner.py makes beside it. A texture in a repo with no record of where
    it came from cannot be relicensed, cannot be regenerated at another size, and cannot be
    corrected when it turns out to be a pixel out. THIS FILE IS THE RECORD -- every value that
    decides what the art looks like is a named constant here, and the art is what this file
    produces, so the two cannot drift.

    It is also the copyright answer. Nothing here is traced, sampled or copied: every pixel comes
    out of the curve below. What was taken from the textures that prompted this -- AbstractFramework's
    Bar_AF.tga and Bar_Underline.tga -- is the two facts that are not authorship at all: the canvas
    is 256x32, and an underline is a solid band at one edge of an otherwise transparent bar. A
    dimension and a functional shape are not expression; a gradient curve is, and this one is ours.

WHAT IT WRITES:

    gradient.tga    a statusbar fill: opaque, a vertical gradient, white at the top
    underline-1     transparent but for a 2px band at the BOTTOM edge
    underline-2     the same band at 2x height (4px)
    underline-4     the same band at 4x height (8px)
    overline-1/2/4  the same three, mirrored to the TOP edge

    UNDERLINE AND OVERLINE, not "bottom" and "top". The pair names where the line SITS relative to
    the bar the way type does, which is how a player reads a dropdown -- and it is what the LSM
    display names say, so the file, the key and the label all agree: `underline-2` is
    "Ka0s Underline 2".

    Every one of them is 256x32, whatever the band inside it does -- which is the whole point of the
    family. A bar frame sized to one of these is sized to all of them, so a player switching from
    `underline-1` to `underline-4` gets a thicker line in the same place rather than a
    different-shaped widget, and an addon can offer the seven as one dropdown.

WHY THE ART IS WHITE:

    Identical reason to the icons: WoW tints a texture by MULTIPLYING, so white becomes any color a
    caller asks for and grey becomes a muddy version of it. The reference bar is light grey, which
    is why it looks slightly dull under a saturated statusbar color. Ours peaks at pure white and
    the gradient lives in the falloff, so a full-saturation bar color arrives full-saturation.

Requires Pillow and numpy. No network, and no input files -- it is pure synthesis.
"""

import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, os.pardir, os.pardir))
OUT = os.path.join(ROOT, "LibKa0s", "media", "textures")

# ---------------------------------------------------------------------------
# The canvas
# ---------------------------------------------------------------------------

# 256x32, the size every statusbar texture in this collection's dependencies uses, and a power of
# two on both axes -- which WoW requires for a texture it may wrap or mipmap.
WIDTH, HEIGHT = 256, 32

# ---------------------------------------------------------------------------
# bar.tga -- the fill
# ---------------------------------------------------------------------------

# The gradient, top to bottom, as a fraction of full brightness.
#
# NOT LINEAR, AND THAT IS THE ONE AESTHETIC DECISION IN THIS FILE. A linear ramp reads as a flat
# wash: the eye responds to brightness logarithmically, so equal steps look front-loaded and the
# bottom half of the bar goes dull all at once. An eased falloff keeps the top third bright -- which
# is the part a player actually reads a bar's color from -- and spends the gradient in the lower two
# thirds, where it reads as a rounded surface rather than a fade.
BAR_TOP = 1.00      # pure white at the top edge: the tint arrives undiluted
BAR_BOTTOM = 0.58   # how far it falls by the bottom edge
BAR_EASE = 1.7      # >1 holds the top brighter for longer; 1.0 would be linear


def gradient():
    """The statusbar fill: opaque, white, brightest at the top."""
    t = np.linspace(0.0, 1.0, HEIGHT, dtype=np.float64) ** BAR_EASE
    level = BAR_TOP + (BAR_BOTTOM - BAR_TOP) * t
    # Rounded once, at the end, so the same value cannot land on two different bytes across a row.
    column = np.clip(np.rint(level * 255.0), 0, 255).astype(np.uint8)

    a = np.zeros((HEIGHT, WIDTH, 4), dtype=np.uint8)
    a[..., 0] = column[:, None]
    a[..., 1] = column[:, None]
    a[..., 2] = column[:, None]
    a[..., 3] = 255
    return a


# ---------------------------------------------------------------------------
# The underlines
# ---------------------------------------------------------------------------

# What "1" means. Two rows of thirty-two, matching the reference this family was asked to replace,
# so a swap between the two is a swap of paths and nothing else. The multipliers name themselves:
# `2` is twice this and `4` is four times it, which is why the files are numbered rather than
# measured -- a name carrying a pixel count would be wrong the moment the canvas changed.
UNIT = 2
STEPS = (1, 2, 4)


def line(rows, at_top):
    """A transparent bar with a solid white band `rows` deep at one edge.

    THE TRANSPARENT PIXELS ARE (0,0,0,0), not white-with-zero-alpha. Nothing renders the RGB under a
    transparent pixel -- until something resamples it, and the client resamples every one of these
    the moment a bar is not exactly 256 wide. A white-under-alpha canvas would bleed a halo out of
    the band's edge under that filter; black under zero alpha cannot.
    """
    a = np.zeros((HEIGHT, WIDTH, 4), dtype=np.uint8)
    band = slice(0, rows) if at_top else slice(HEIGHT - rows, HEIGHT)
    a[band, :, :] = 255
    return a


# ---------------------------------------------------------------------------
# Write
# ---------------------------------------------------------------------------

def write(name, array):
    path = os.path.join(OUT, name + ".tga")
    # RLE, matching every other TGA this collection ships. These compress hard -- an underline is
    # two colors -- and a client that reads one reads them all.
    Image.fromarray(array, "RGBA").save(path, compression="tga_rle")
    return path


def main():
    os.makedirs(OUT, exist_ok=True)
    written = [("gradient", gradient())]
    for step in STEPS:
        rows = UNIT * step
        written.append(("underline-%d" % step, line(rows, at_top=False)))
        written.append(("overline-%d" % step, line(rows, at_top=True)))

    for name, array in written:
        path = write(name, array)
        print("  %-20s %dx%d  %d bytes" % (name, WIDTH, HEIGHT, os.path.getsize(path)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
