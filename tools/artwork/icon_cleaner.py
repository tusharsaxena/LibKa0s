#!/usr/bin/env python3
"""Turn Open Iconic's PNGs into the 32-bit TGAs the Ka0s addons draw their icons from.

Adapted from ../PanelMaster/tools/artwork/artwork_cleaner.py, which does the right KIND of work
and the wrong amount of it: that tool exists for full-panel backdrops and letterboxes onto a
1024x1024 canvas, which would swallow a 64px glyph. What survives from it is the pipeline's shape
and two stages that matter at any size; what goes is the upscaler and the background keying.

    icon_cleaner.py --fetch      download the sources into tools/artwork/.cache/ (needs `gh`)
    icon_cleaner.py --build      convert the cache into media/textures/icons/*.tga
    icon_cleaner.py              both, in that order

WHY THIS TOOL EXISTS AT ALL, rather than a checked-in binary somebody once made:

    The provenance question is the whole point. An icon in a repo with no record of where it came
    from cannot be relicensed, cannot be regenerated at a different size, and cannot be replaced
    when it turns out to be wrong. This file IS the record -- the upstream repo, the licence, the
    exact file names and every transformation applied, in the one place that cannot drift from the
    art because it is what produces it.

WHAT IT DOES TO EACH ICON, in order:

    recolour   black -> white, alpha untouched
    solidify   push opaque colour outward under the transparent pixels
    fit        centre on a square power-of-two canvas, never crop
    normalize  force every fully-transparent pixel to (0,0,0,0)
    save       32-bit RLE TGA

Requires Pillow and numpy. No network beyond `gh api`, and no upscaler.
"""

import argparse
import base64
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, os.pardir, os.pardir))
CACHE = os.path.join(HERE, ".cache")
# THE PAYLOAD, not a repo-level media folder. These TGAs ship inside LibKa0s/ and are vendored
# into every consumer with the rest of the library; a path that wrote anywhere else would produce
# art nothing loads. This moved with the tool from Mythic Meters, where the destination was that
# addon's own media/textures/icons/ -- and the first run here quietly rebuilt 68 files into a
# repo-root media/ nobody would ever have shipped.
OUT = os.path.join(ROOT, "LibKa0s", "media", "icons")

# ---------------------------------------------------------------------------
# The source
# ---------------------------------------------------------------------------
#
# Open Iconic, MIT, 223 marks designed to stay legible down to 8px -- which is the property that
# matters here, because these are drawn at 18.
#
# CHOSEN BECAUSE IT SHIPS RASTER. Every other set considered (Feather, Lucide, Tabler, Bootstrap,
# Phosphor, Font Awesome) ships SVG only, and this machine has no rasteriser: no ImageMagick, no
# Inkscape, no rsvg, no cairosvg. A set that needs converting before it can be converted is not a
# set we can use.
REPO = "iconic/open-iconic"

# THE SIZE SUFFIX IS NOT THE PIXEL COUNT. The base icon is 8px, so `-8x` is the 64px render, not a
# 8px one. Getting this wrong is a 404 rather than a wrong-sized icon, which is at least loud.
SUFFIX = "-8x"

# What each icon draws. The KEY is the SEMANTIC name -- what the mark means to a Ka0s addon -- so a
# later decision to swap which upstream glyph an icon uses is one line here and nothing else
# anywhere. Two names may point at one glyph (`add` and `expand` are both `plus`) and that is
# deliberate: they mean different things, they are documented differently, and an addon reaching for
# "add" should not have to know that the file it wants is called `expand`.
#
# THIS SET IS FOR THE WHOLE COLLECTION, not just this addon. The first eleven are what Mythic
# Meters' own header strip draws; everything after them is the shared vocabulary every Ka0s panel
# keeps needing -- and the reason they are built here today is that this is where the tool already
# lives. The tool and the art belong in LibKa0s, and should move there together, because THIS FILE
# IS THE PROVENANCE RECORD: split it from the art and the art becomes a folder of binaries nobody
# can regenerate, relicense or resize.
#
# TWO MARKS DELIBERATELY ABSENT, both because Open Iconic has no glyph for them and a hand-drawn
# substitute would be the one icon in the set that looks foreign:
#
#   save    the set has no floppy. `hard-drive` reads as storage rather than save, so `confirm`
#           (the check) carries the meaning instead.
#   hidden  there is no crossed-out eye. `eye` drawn DIMMED is the hidden state, the same way the
#           padlock's two states are told apart -- except the padlock ships two glyphs and this
#           does not.
GLYPHS = {
    # ── the window header strip ──────────────────────────────────────────────
    "close":     "x",
    "minimise":  "minus",
    "expand":    "plus",
    "lock":      "lock-locked",
    "unlock":    "lock-unlocked",
    "settings":  "cog",
    "segment":   "menu",
    "reset":     "reload",
    "export":    "data-transfer-download",
    "sort-up":   "caret-top",
    "sort-down": "caret-bottom",

    # ── core actions ─────────────────────────────────────────────────────────
    # `clipboard` rather than `copywriting`: Open Iconic ships no two-sheets copy mark, and
    # copywriting is a pen on paper that reads as "edit" beside the pencil.
    "copy":      "clipboard",
    "clear":     "trash",
    "add":       "plus",
    "edit":      "pencil",
    "confirm":   "check",
    # A CIRCLED X, where `close` is a bare one. "Cancel this action" and "close this window" are
    # different answers to different questions, and a panel that draws one mark for both teaches
    # players that the × sometimes throws their work away.
    "cancel":    "circle-x",
    "search":    "magnifying-glass",
    "undo":      "action-undo",
    "redo":      "action-redo",
    # The mirror of `export`: one arrow down, one arrow up, so a pair of buttons reads as a pair.
    "import":    "data-transfer-upload",

    # ── status and feedback ──────────────────────────────────────────────────
    "info":      "info",
    "warning":   "warning",
    "help":      "question-mark",
    "ban":       "ban",
    "bug":       "bug",

    # ── state ────────────────────────────────────────────────────────────────
    "pin":       "pin",
    "eye":       "eye",
    "star":      "star",

    # ── layout ───────────────────────────────────────────────────────────────
    "move":             "move",
    "resize":           "resize-both",
    "fullscreen-enter": "fullscreen-enter",
    "fullscreen-exit":  "fullscreen-exit",
    "grid":             "grid-three-up",
    "list":             "list",
    "layers":           "layers",

    # ── navigation ───────────────────────────────────────────────────────────
    # Chevrons, where the sort arrows are carets: a caret is a sort direction and a chevron is a
    # step. Upstream calls the vertical pair top/bottom; up/down is what a caller means.
    "chevron-left":  "chevron-left",
    "chevron-right": "chevron-right",
    "chevron-up":    "chevron-top",
    "chevron-down":  "chevron-bottom",

    # ── data ─────────────────────────────────────────────────────────────────
    "chart":       "bar-chart",
    "graph":       "graph",
    "spreadsheet": "spreadsheet",
    "timer":       "timer",
    "clock":       "clock",


    # ── arrows: the up/down family, every weight the set offers ─────────────
    "arrow-up":          "arrow-top",
    "arrow-down":        "arrow-bottom",
    "arrow-thick-up":    "arrow-thick-top",
    "arrow-thick-down":  "arrow-thick-bottom",
    "arrow-circle-up":   "arrow-circle-top",
    "arrow-circle-down": "arrow-circle-bottom",
    "collapse-up":       "collapse-up",
    "collapse-down":     "collapse-down",
    "expand-up":         "expand-up",
    "expand-down":       "expand-down",
    "align-top":         "vertical-align-top",
    "align-bottom":      "vertical-align-bottom",

    # ── arrows: the marks that draw TWO of them ─────────────────────────────
    # Read as a relationship rather than a direction -- ordering, swapping,
    # moving between two places -- which is a different question from "which way".
    "sort-asc":  "sort-ascending",
    "sort-desc": "sort-descending",
    "transfer":  "transfer",
    "elevator":  "elevator",

    # ── talking ─────────────────────────────────────────────────────────────
    # Two marks, and they are not interchangeable: `chat` is two overlapping
    # bubbles (a conversation, a channel), `speech-bubble` is one (a line said,
    # a tooltip, a note).
    "chat":          "chat",
    "speech-bubble": "comment-square",


    # ── arrows: left and right, matching the up/down family above ───────────
    "arrow-left":         "arrow-left",
    "arrow-right":        "arrow-right",
    "arrow-thick-left":   "arrow-thick-left",
    "arrow-thick-right":  "arrow-thick-right",
    "arrow-circle-left":  "arrow-circle-left",
    "arrow-circle-right": "arrow-circle-right",
    "caret-left":         "caret-left",
    "caret-right":        "caret-right",
    "expand-left":        "expand-left",
    "expand-right":       "expand-right",

    # ── text alignment ──────────────────────────────────────────────────────
    # TWO FAMILIES, AND THEY ARE NOT THE SAME MARK. `align-*` draws ragged
    # lines that show the alignment; `justify-*` draws blocked lines. Both are
    # upstream, both were asked for, and neither substitutes for the other in a
    # toolbar that offers both.
    "align-left":    "align-left",
    "align-center":  "align-center",
    "align-right":   "align-right",
    "justify-left":   "justify-left",
    "justify-center": "justify-center",
    "justify-right":  "justify-right",

    # ── layout, continued ───────────────────────────────────────────────────
    # `grid` above is the three-up. These two carry their upstream names so the
    # density is in the name rather than in a table somebody has to go and read.
    "grid-two-up":   "grid-two-up",
    "grid-four-up":  "grid-four-up",
    "resize-height": "resize-height",
    "resize-width":  "resize-width",

    # ── status and state, continued ─────────────────────────────────────────
    "circle-check": "circle-check",
    "task":         "task",
    "thumb-up":     "thumb-up",
    "thumb-down":   "thumb-down",
    "heart":        "heart",
    "bookmark":     "bookmark",

    # ── place and navigation ────────────────────────────────────────────────
    # `location` is the paper plane (send, go there), `map-marker` the dropped
    # pin (a place on a map). `pin` above is the pushpin (keep this here).
    "home":          "home",
    "location":      "location",
    "map-marker":    "map-marker",
    "external-link": "external-link",
    "link-intact":   "link-intact",

    # ── tools and devices ───────────────────────────────────────────────────
    "wrench":   "wrench",
    "terminal": "terminal",
    "monitor":  "monitor",
    "video":    "video",
    "aperture": "aperture",
    "zoom-in":  "zoom-in",
    "zoom-out": "zoom-out",

    # ── sound ───────────────────────────────────────────────────────────────
    "volume-high": "volume-high",
    "volume-low":  "volume-low",
    "volume-off":  "volume-off",

    # ── documents and labels ────────────────────────────────────────────────
    "document": "document",
    "tag":      "tag",
    "tags":     "tags",

    # ── session ─────────────────────────────────────────────────────────────
    "account-login":  "account-login",
    "account-logout": "account-logout",

    # ── entities ─────────────────────────────────────────────────────────────
    "person": "person",
    "people": "people",
    "target": "target",
    "shield": "shield",
}

LICENSE_SRC = "ICON-LICENSE"
LICENSE_DST = "LICENSE-open-iconic.txt"

# ---------------------------------------------------------------------------
# The output
# ---------------------------------------------------------------------------

# Power of two, because WoW cannot wrap a non-power-of-two texture. 64 is the source's own size, so
# nothing is resampled in the common case -- and it leaves room to draw at 18 with the client
# downscaling, which looks better than upscaling a 16px source would.
SIZE = 64

# What a fully-transparent pixel's RGB becomes. Black, so an additive or alpha-keyed blend cannot
# find a colour hiding under a pixel nothing was supposed to draw.
TRANSPARENT = (0, 0, 0, 0)

# How far to push opaque colour outward under the transparent region. Three is plenty at this size;
# the stage exists for the downscale, not for an upscaler.
SOLIDIFY_ITERS = 3


def _say(text):
    print(text, flush=True)


# ---------------------------------------------------------------------------
# Fetch
# ---------------------------------------------------------------------------

def _gh_file(path):
    """One file out of the repo, through `gh api`.

    NOT raw.githubusercontent.com, which times out from here often enough to be useless in a
    script. The contents API returns base64 in a JSON envelope and `gh` carries the auth, so it
    is both faster and not rate-limited into uselessness.
    """
    out = subprocess.run(
        ["gh", "api", "repos/%s/contents/%s" % (REPO, path)],
        capture_output=True, text=True, timeout=120,
    )
    if out.returncode != 0:
        raise RuntimeError("gh api failed for %s: %s" % (path, out.stderr.strip()[:200]))
    return base64.b64decode(json.loads(out.stdout)["content"])


def fetch():
    os.makedirs(CACHE, exist_ok=True)
    for name, upstream in sorted(GLYPHS.items()):
        dst = os.path.join(CACHE, "%s.png" % upstream)
        if os.path.exists(dst) and os.path.getsize(dst) > 0:
            _say("  cached  %s (%s)" % (upstream, name))
            continue
        data = _gh_file("png/%s%s.png" % (upstream, SUFFIX))
        with open(dst, "wb") as fh:
            fh.write(data)
        _say("  fetched %s (%s) %d bytes" % (upstream, name, len(data)))

    lic = os.path.join(CACHE, LICENSE_DST)
    if not os.path.exists(lic):
        with open(lic, "wb") as fh:
            fh.write(_gh_file(LICENSE_SRC))
        _say("  fetched %s" % LICENSE_DST)


# ---------------------------------------------------------------------------
# Convert
# ---------------------------------------------------------------------------

def recolour_white(im):
    """Black art -> white art, alpha untouched.

    THE STAGE THAT DECIDES WHETHER THE ICONS OBEY THE PLAYER'S COLOUR SETTING. Every glyph the
    header draws today is tinted at draw time to the header's text colour, and a texture is tinted
    by MULTIPLYING -- so a white source becomes any colour asked for and a black one stays black
    whatever it is asked for. Open Iconic ships black.

    Only the RGB is touched. The antialiased edge lives entirely in the alpha channel, so writing
    a flat white under it preserves the shape exactly.
    """
    a = np.asarray(im.convert("RGBA")).copy()
    a[..., :3] = 255
    return Image.fromarray(a, "RGBA")


def _box_sum(arr):
    """Sum of each pixel's 3x3 neighbourhood, edges clamped."""
    p = np.pad(arr, ((1, 1), (1, 1), (0, 0)), mode="edge")
    return (p[:-2, :-2] + p[:-2, 1:-1] + p[:-2, 2:] +
            p[1:-1, :-2] + p[1:-1, 1:-1] + p[1:-1, 2:] +
            p[2:, :-2] + p[2:, 1:-1] + p[2:, 2:])


def solidify(im, iters=SOLIDIFY_ITERS):
    """Edge-extend opaque RGB outward into the transparent region.

    Kept from PanelMaster's tool, and kept for the same reason stated there: nothing renders the
    RGB under a transparent pixel, so nothing complains when it is arbitrary -- until a resample
    samples it. The client downscales these from 64 to 18, and its kernel reads the neighbours of
    every edge pixel including the transparent ones.

    After `recolour_white` the under-alpha RGB is already white, so this is close to a no-op today.
    It stays because the invariant it protects is "whatever is under the alpha continues the art",
    and that stops being free the moment a coloured icon is added.
    """
    a = np.asarray(im.convert("RGBA"), dtype=np.float32)
    rgb, alpha = a[..., :3], a[..., 3]
    known = (alpha > 0).astype(np.float32)[..., None]
    cur = rgb * known
    for _ in range(iters):
        if known.min() >= 1.0:
            break
        num, den = _box_sum(cur), _box_sum(known)
        newly = ((den > 0) & (known == 0))
        cur = np.where(newly, num / np.maximum(den, 1e-6), cur)
        known = ((newly | (known > 0)).astype(np.float32))
    out = np.concatenate([np.clip(cur, 0, 255), alpha[..., None]], axis=2)
    return Image.fromarray(out.astype(np.uint8), "RGBA")


def fit_square(im, size=SIZE):
    """Centre on a square power-of-two canvas. Never crop.

    A source already at `size` passes through untouched, which is the case every glyph currently
    takes -- the branch exists so a differently-sized replacement does not silently get cropped.
    """
    if im.size == (size, size):
        return im
    scale = min(size / im.width, size / im.height)
    w, h = max(1, round(im.width * scale)), max(1, round(im.height * scale))
    art = im.resize((w, h), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), TRANSPARENT)
    canvas.paste(art, ((size - w) // 2, (size - h) // 2), art)
    return canvas


def normalize_transparent(im):
    """Force every fully-transparent pixel to one defined RGB.

    Must run LAST. LANCZOS premultiplies and a paste carries its canvas colour in, so normalising
    any earlier is simply undone by the next stage.
    """
    a = np.asarray(im.convert("RGBA")).copy()
    a[a[..., 3] == 0] = TRANSPARENT
    return Image.fromarray(a, "RGBA")


def convert_one(src, dst):
    im = Image.open(src)
    im = im.convert("RGBA") if im.mode != "RGBA" else im.copy()
    im = normalize_transparent(fit_square(solidify(recolour_white(im))))
    # RLE, matching media/textures/Default.tga -- the texture this client is already known to load.
    im.save(dst, compression="tga_rle")
    return im.size


def build():
    os.makedirs(OUT, exist_ok=True)
    missing = []
    for name, upstream in sorted(GLYPHS.items()):
        src = os.path.join(CACHE, "%s.png" % upstream)
        if not os.path.exists(src):
            missing.append(upstream)
            continue
        dst = os.path.join(OUT, "%s.tga" % name)
        size = convert_one(src, dst)
        _say("  %-10s <- %-24s %dx%d  %d bytes"
             % (name, upstream, size[0], size[1], os.path.getsize(dst)))

    lic = os.path.join(CACHE, LICENSE_DST)
    if os.path.exists(lic):
        with open(lic, "rb") as fh:
            body = fh.read()
        with open(os.path.join(OUT, LICENSE_DST), "wb") as fh:
            fh.write(body)
        _say("  %s" % LICENSE_DST)

    if missing:
        _say("\nmissing sources (run --fetch): %s" % ", ".join(missing))
        return 1
    return 0


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--fetch", action="store_true", help="download sources into the cache")
    ap.add_argument("--build", action="store_true", help="convert the cache into TGAs")
    args = ap.parse_args(argv)

    both = not (args.fetch or args.build)
    if args.fetch or both:
        _say("fetching from %s ..." % REPO)
        fetch()
    if args.build or both:
        _say("building into media/textures/icons/ ...")
        return build()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
