#!/usr/bin/env python3
"""Generate the statusbar and underline TGAs this collection's bars are drawn with.

    bar_textures.py            write LibKa0s/media/textures/*.tga

WHY THIS IS A PROGRAM AND NOT FIFTEEN CHECKED-IN BINARIES:

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
    ka0s-default    Ka0s Default's bar: opaque, dim at the top, a highlight low down, a short lip
    matte           Obsidian's bar: flat, a lit top row and a shaded bottom row
    parchment       Azeroth's bar: a soft fall to the bottom under a 2D mottle that tiles sideways
    glass-bar       Glass's bar: a bright upper half over a darker lower half, split at the middle
    solid           High Contrast's bar: white everywhere, the tint and nothing else
    forge           Ember's bar: dark at the top, rising to a hot band low on the bar
    satin           WoW Midnight's bar: a broad soft sheen a little above the middle
    classic         WoW Forever's bar: a highlight high on the bar over a gentle fall
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
    different-shaped widget, and an addon can offer them all as one dropdown.

WHY THE ART IS WHITE:

    Identical reason to the icons: WoW tints a texture by MULTIPLYING, so white becomes any color a
    caller asks for and gray becomes a muddy version of it. The reference bar is light gray, which
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
# ka0s-default.tga -- Ka0s Default's bar
# ---------------------------------------------------------------------------

# The owner asked for a bar in the manner of the "Melli Dark" statusbar common in SharedMedia packs,
# drawn here rather than shipped, because that file's author is not recorded. What it shares with
# that look is the idea, not a pixel: dark at the top, a broad rise into a highlight low on the bar,
# and a short lip below the highlight, so the bar reads as a lit rounded edge under a dim face. Every
# value is ours.
#
# DARK BY DESIGN, unlike `gradient`: this is the bar Ka0s Default draws its data in, and its dim top
# is what gives the bar depth under a saturated tint. The highlight stops short of white so a bright
# series color does not blow out on the lit edge.
DEF_TOP = 0.47        # the dim top edge
DEF_PEAK = 0.81       # the highlight
DEF_PEAK_AT = 0.85    # where the highlight sits, as a fraction of the height from the top
DEF_BOTTOM = 0.60     # the lip's floor, at the bottom edge


def ka0s_default():
    """Ka0s Default's bar: opaque, dim at the top, a highlight low on the bar, a short lip."""
    t = np.linspace(0.0, 1.0, HEIGHT, dtype=np.float64)
    rise = np.clip(t / DEF_PEAK_AT, 0.0, 1.0)
    # A sine ease into the highlight: it leaves the top slowly and arrives without a crease.
    level = DEF_TOP + (DEF_PEAK - DEF_TOP) * np.sin(rise * np.pi / 2.0)
    # Below the highlight the lip falls on a quadratic, steepest at the very edge.
    lip = np.clip((t - DEF_PEAK_AT) / (1.0 - DEF_PEAK_AT), 0.0, 1.0)
    level = level - (DEF_PEAK - DEF_BOTTOM) * lip ** 2
    column = np.clip(np.rint(level * 255.0), 0, 255).astype(np.uint8)

    a = np.zeros((HEIGHT, WIDTH, 4), dtype=np.uint8)
    a[..., 0] = column[:, None]
    a[..., 1] = column[:, None]
    a[..., 2] = column[:, None]
    a[..., 3] = 255
    return a


# ---------------------------------------------------------------------------
# The skins' bars -- one per skin, the owner's approved mockup (SO-04, 2026-10-28)
# ---------------------------------------------------------------------------

# Every skin but WoW Default draws a bar of its own; WoW Default keeps the client's "Blizzard" bar and
# so ships nothing here. Each profile below is a brightness per row, sampled at the CENTER of the row
# -- y = (row + 0.5) / 32, 0 at the top edge and 1 at the bottom -- rather than at its top edge as
# `gradient` and `ka0s-default` are, which is how the mockup the owner approved drew them. Every one
# is opaque and gray, for the same multiply-tint reason as the rest, and every column is the same but
# Parchment's, whose mottle is the one place a bar varies along its length.


def rows():
    """The row centers, top (0) to bottom (1)."""
    return (np.arange(HEIGHT, dtype=np.float64) + 0.5) / HEIGHT


def opaque(level):
    """An opaque gray bar from a brightness per row (a column) or per pixel (HEIGHT x WIDTH)."""
    level = np.asarray(level, dtype=np.float64)
    if level.ndim == 1:
        level = np.repeat(level[:, None], WIDTH, axis=1)
    # Clipped before rounding: a profile is allowed to overshoot, the byte is not.
    gray = np.rint(np.clip(level, 0.0, 1.0) * 255.0).astype(np.uint8)

    a = np.zeros((HEIGHT, WIDTH, 4), dtype=np.uint8)
    a[..., 0] = gray
    a[..., 1] = gray
    a[..., 2] = gray
    a[..., 3] = 255
    return a


# Obsidian -- "Ka0s Matte". Flat and modern: one level for the face, a single lit row at the top and a
# single shaded row at the bottom, so the bar reads as a hard-edged slab rather than a rounded one.
MATTE_FACE = 0.86     # the face, everywhere but the two edge rows
MATTE_TOP = 1.00      # the top row, the one lit edge
MATTE_BOTTOM = 0.62   # the bottom row, the one shaded edge


def matte():
    """Obsidian's bar: flat, a lit top row, a shaded bottom row."""
    level = np.full(HEIGHT, MATTE_FACE)
    level[0] = MATTE_TOP
    level[-1] = MATTE_BOTTOM
    return opaque(level)


# Azeroth -- "Ka0s Parchment". A soft fall from near-white at the top, with a mottle over it the way
# old paper is never one shade. The mottle is seeded noise, blurred into blotches: wide along the bar,
# shallow across it. THE HORIZONTAL BLUR WRAPS, so the left edge's blotches continue from the right
# edge's, and a bar wider than 256 that tiles the texture shows no seam; the vertical blur pads with
# the edge rows instead, because the top and bottom of a bar never meet.
PARCH_TOP = 0.97      # the top edge, before the mottle
PARCH_FALL = 0.20     # how far it falls by the bottom edge
PARCH_EASE = 1.3      # >1 holds the top brighter for longer
PARCH_MOTTLE = 0.06   # the mottle's peak, either side of the curve
PARCH_SEED = 77       # numpy default_rng's seed: the same mottle every run
PARCH_BLUR_W = 41     # the blotch's width along the bar, in pixels (a box, wrapping)
PARCH_BLUR_H = 9      # and its height across it (a box, edge-padded)


def box_blur(m, width, axis, wrap):
    """A centered box mean of odd `width` along `axis`: wrapping, or padded with the edge values."""
    half = width // 2
    pad = [(0, 0), (0, 0)]
    pad[axis] = (half, half)
    padded = np.pad(m, pad, mode="wrap" if wrap else "edge")
    total = np.zeros_like(m)
    for k in range(width):
        total += np.take(padded, np.arange(k, k + m.shape[axis]), axis=axis)
    return total / width


def parchment():
    """Azeroth's bar: a soft fall to the bottom under a mottle that tiles horizontally."""
    m = np.random.default_rng(PARCH_SEED).normal(size=(HEIGHT, WIDTH))
    m = box_blur(m, PARCH_BLUR_W, axis=1, wrap=True)
    m = box_blur(m, PARCH_BLUR_H, axis=0, wrap=False)
    mottle = PARCH_MOTTLE * m / np.max(np.abs(m))
    curve = PARCH_TOP - PARCH_FALL * rows() ** PARCH_EASE
    return opaque(curve[:, None] + mottle)


# Glass -- "Ka0s Glass Bar" (the name "Ka0s Glass" is already the Glass border and background). A
# pane of glass catching light: a bright upper half that dims toward the middle, then a hard step down
# into a darker lower half that brightens again toward the bottom edge, the reflection under the gloss.
GLASS_TOP = 1.00      # the top edge
GLASS_DIM = 0.12      # how far the upper half falls by the middle
GLASS_LOW = 0.70      # the lower half's level just below the middle
GLASS_RISE = 0.12     # how far the lower half rises by the bottom edge


def glass_bar():
    """Glass's bar: a bright upper half over a darker lower half, split at the middle."""
    y = rows()
    upper = GLASS_TOP - GLASS_DIM * (y / 0.5)
    lower = GLASS_LOW + GLASS_RISE * ((y - 0.5) / 0.5)
    return opaque(np.where(y < 0.5, upper, lower))


# High Contrast -- "Ka0s Solid". White everywhere: the bar is its tint and nothing else, because a
# gradient is a second brightness the eye has to read past, and this skin exists to remove those.
SOLID_LEVEL = 1.00


def solid():
    """High Contrast's bar: one level, white."""
    return opaque(np.full(HEIGHT, SOLID_LEVEL))


# Ember -- "Ka0s Forge". Metal out of the fire: dark at the top, rising on an eased curve toward the
# bottom, with a narrow hot band low on the bar where the glow sits.
FORGE_BASE = 0.60     # the top edge
FORGE_RISE = 0.40     # how far it rises by the bottom edge
FORGE_EASE = 1.4      # >1 keeps the top dark for longer
FORGE_GLOW = 0.10     # the hot band's peak, over the rise
FORGE_GLOW_AT = 0.86  # where the band sits, top (0) to bottom (1)
FORGE_GLOW_W = 0.06   # its half-width, as a Gaussian's scale


def forge():
    """Ember's bar: dark at the top, rising to a hot band low on the bar."""
    y = rows()
    glow = FORGE_GLOW * np.exp(-((y - FORGE_GLOW_AT) / FORGE_GLOW_W) ** 2)
    return opaque(FORGE_BASE + FORGE_RISE * y ** FORGE_EASE + glow)


# WoW Midnight -- "Ka0s Satin". Cloth under night light: one broad, soft sheen a little above the
# middle, falling off on a cosine-squared to an even floor at both edges.
SATIN_FLOOR = 0.68    # the edges
SATIN_SHEEN = 0.32    # the sheen's peak, over the floor
SATIN_AT = 0.40       # where the sheen peaks, top (0) to bottom (1)
SATIN_SPREAD = 1.1    # how broad it is: the cosine spans pi over this much of the height


def satin():
    """WoW Midnight's bar: a broad soft sheen a little above the middle."""
    phase = np.clip((rows() - SATIN_AT) * np.pi / SATIN_SPREAD, -np.pi / 2.0, np.pi / 2.0)
    return opaque(SATIN_FLOOR + SATIN_SHEEN * np.cos(phase) ** 2)


# WoW Forever -- "Ka0s Classic". The classic client's bar in spirit, not in pixels: a highlight high
# on the bar over a gentle fall to the bottom, so it reads as lit from above.
CLASSIC_BASE = 0.74   # the level the highlight sits on
CLASSIC_LIGHT = 0.26  # the highlight's peak, over the base
CLASSIC_AT = 0.18     # where the highlight sits, top (0) to bottom (1)
CLASSIC_W = 0.20      # its half-width, as a Gaussian's scale
CLASSIC_FALL = 0.10   # how far the whole bar falls by the bottom edge


def classic():
    """WoW Forever's bar: a highlight high on the bar over a gentle fall."""
    y = rows()
    light = CLASSIC_LIGHT * np.exp(-((y - CLASSIC_AT) / CLASSIC_W) ** 2)
    return opaque(CLASSIC_BASE + light - CLASSIC_FALL * y)


# Every skin's bar, by file name, in the skins' registration order.
SKIN_BARS = (
    ("matte", matte), ("parchment", parchment), ("glass-bar", glass_bar), ("solid", solid),
    ("forge", forge), ("satin", satin), ("classic", classic),
)


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
    written = [("gradient", gradient()), ("ka0s-default", ka0s_default())]
    written.extend((name, make()) for name, make in SKIN_BARS)
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
