#!/usr/bin/env python3
"""Turn three icon sets into the 32-bit TGAs the Ka0s addons draw their icons from.

Adapted from ../PanelMaster/tools/artwork/artwork_cleaner.py, which does the right KIND of work
and the wrong amount of it: that tool exists for full-panel backdrops and letterboxes onto a
1024x1024 canvas, which would swallow a 64px glyph. What survives from it is the pipeline's shape
and two stages that matter at any size; what goes is the upscaler and the background keying.

    icon_cleaner.py --fetch      download the sources into tools/artwork/.cache/
    icon_cleaner.py --build      convert the cache into LibKa0s/media/icons/ and MediaIcons.lua
    icon_cleaner.py              both, in that order

THE THREE SETS (library-stack-8: a missing mark is added here, by the generator that made the rest):

    Open Iconic      MIT        PNG, fetched one file at a time through `gh api`
    Phosphor Fill    MIT        SVG, a shallow clone pinned to PHOSPHOR["sha"]
    Game-icons.net   CC BY 3.0  SVG, a shallow clone pinned to GAME_ICONS["sha"]

WHY THIS TOOL EXISTS AT ALL, rather than a checked-in binary somebody once made:

    The provenance question is the whole point. An icon in a repo with no record of where it came
    from cannot be relicensed, cannot be regenerated at a different size, and cannot be replaced
    when it turns out to be wrong. This file IS the record -- the upstream repo and commit, the
    license, the exact file names, the author of every CC BY mark, every filter (Phosphor's brand
    marks, Game-icons' background square) and every transformation applied, in the one place that
    cannot drift from the art because it is what produces it.

WHAT IT DOES TO EACH ICON, in order:

    render     SVG only: resvg at 64x64 (Open Iconic ships its own 64px PNG)
    key        Game-icons only: alpha from luminance, which removes the black background square
    recolor    any color -> white, alpha untouched
    solidify   push opaque color outward under the transparent pixels
    fit        center on a square power-of-two canvas, never crop
    normalize  force every fully-transparent pixel to (0,0,0,0)
    save       32-bit RLE TGA

It also writes LibKa0s/MediaIcons.lua (the generated catalog: every name past the 113 hand-written
in Media.lua), the Phosphor and Game-icons license files, and game-icons/AUTHORS.txt.

Requires Pillow, numpy and resvg-py (pip, in tools/artwork/.venv; see DEPENDENCIES.md), plus `gh`
and `git` for --fetch. Run it with the venv's python and `-I`: the cache holds other people's
repositories, and nothing in them is executed -- the SVGs are read as text and nothing else.
"""

import argparse
import base64
import io
import json
import os
import re
import shutil
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor

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
# CHOSEN FIRST BECAUSE IT SHIPS RASTER. Every other set considered (Feather, Lucide, Tabler,
# Bootstrap, Phosphor, Font Awesome) ships SVG only, and when this set was chosen the machine had no
# SVG renderer at all. resvg-py (a pip wheel, no system dependency) ended that in v1.74.0, which is
# what let Phosphor and Game-icons in below; Open Iconic keeps its own PNGs because they are the
# designer's 64px renders and re-rendering them would change art consumers already ship.
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

# THE OTHER 111 OPEN ICONIC MARKS, under their upstream names. Every upstream glyph GLYPHS does not
# already draw (223 upstream, 112 drawn by the 113 semantic keys). None of these names collides
# with a semantic key, so they go in flat and unprefixed beside the keys -- and unlike a key, the
# name IS the upstream name, because nothing chose them for a meaning.
OPEN_ICONIC_REST = [
    "audio", "audio-spectrum", "badge", "basket", "battery-empty", "battery-full", "beaker",
    "bell", "bluetooth", "bold", "bolt", "book", "box", "briefcase", "british-pound", "browser",
    "brush", "bullhorn", "calculator", "calendar", "camera-slr", "cart", "cloud",
    "cloud-download", "cloud-upload", "cloudy", "code", "collapse-left", "collapse-right",
    "command", "compass", "contrast", "copywriting", "credit-card", "crop", "dashboard", "delete",
    "dial", "dollar", "double-quote-sans-left", "double-quote-sans-right",
    "double-quote-serif-left", "double-quote-serif-right", "droplet", "eject", "ellipses",
    "envelope-closed", "envelope-open", "euro", "excerpt", "eyedropper", "file", "fire", "flag",
    "flash", "folder", "fork", "globe", "hard-drive", "header", "headphones", "image", "inbox",
    "infinity", "italic", "key", "laptop", "lightbulb", "link-broken", "list-rich", "loop",
    "loop-circular", "loop-square", "map", "media-pause", "media-play", "media-record",
    "media-skip-backward", "media-skip-forward", "media-step-backward", "media-step-forward",
    "media-stop", "medical-cross", "microphone", "moon", "musical-note", "paperclip", "phone",
    "pie-chart", "play-circle", "power-standby", "print", "project", "pulse", "puzzle-piece",
    "rain", "random", "rss", "rss-alt", "script", "share", "share-boxed", "signal", "signpost",
    "sun", "tablet", "text", "underline", "vertical-align-center", "wifi", "yen",
]

# ---------------------------------------------------------------------------
# The SVG sets
# ---------------------------------------------------------------------------
#
# PINNED, BY COMMIT. A clone of a moving branch is not a provenance record: the next --fetch would
# silently rebuild different art under the same names. Moving a pin is a deliberate edit here,
# followed by a --build and a review of what changed.
SRC = os.path.join(CACHE, "src")

PHOSPHOR = {
    "repo": "https://github.com/phosphor-icons/core.git",
    "sha": "2b75f3ad12b420c9504ef05df8d2564a28f8500e",
    "cache": "phosphor",
    "svgs": os.path.join("assets", "fill"),   # the Fill weight: solid shapes read at 18px
    "suffix": "-fill",                         # upstream's file name carries the weight
    "license": "LICENSE",
    "out": "phosphor",
    "license_out": "LICENSE-phosphor.txt",
    "prefix": "ph:",
}

# `*-logo` marks are other companies' trademarks, not glyphs; Phosphor ships 78 of them. They are
# dropped rather than shipped, because a trademark is not MIT's to grant.
PHOSPHOR_DROP = re.compile(r"-logo$")

GAME_ICONS = {
    "repo": "https://github.com/game-icons/icons.git",
    "sha": "82d948812bfe3f269ef8f731dcdb07b08160edc4",
    "cache": "game-icons",
    "license": "license.txt",
    "out": "game-icons",
    "license_out": "LICENSE-game-icons.txt",
    "prefix": "gi:",
}

# Each subfolder of the Game-icons repo is one contributor, and CC BY attribution is per author,
# so every folder that ships needs a name to credit. These are the names upstream's license.txt
# gives. A folder not in this table fails the build rather than shipping uncredited art.
GAME_ICONS_AUTHORS = {
    "andymeneely": "Andy Meneely",
    "aussiesim": "Aussiesim",
    "carl-olsen": "Carl Olsen",
    "caro-asercion": "Caro Asercion",
    "cathelineau": "Cathelineau",
    "catsu": "Catsu",
    "darkzaitzev": "DarkZaitzev",
    "delapouite": "Delapouite",
    "faithtoken": "Faithtoken",
    "felbrigg": "Felbrigg",
    "generalace135": "GeneralAce135",
    "guard13007": "Guard13007",
    "heavenly-dog": "HeavenlyDog",
    "irongamer": "Irongamer",
    "john-colburn": "John Colburn",
    "john-redman": "John Redman",
    "kier-heyl": "Kier Heyl",
    "lorc": "Lorc",
    "lord-berandas": "Lord Berandas",
    "lucasms": "Lucas",
    "pepijn-poolman": "Pepijn Poolman",
    "pierre-leducq": "Pierre Leducq",
    "priorblue": "PriorBlue",
    "quoting": "Quoting",
    "rihlsul": "Rihlsul",
    "sbed": "Sbed",
    "seregacthtuf": "SeregaCthtuf",
    "skoll": "Skoll",
    "sparker": "Sparker",
    "spencerdub": "SpencerDub",
    "starseeker": "Starseeker",
    "viscious-speed": "Viscious Speed",
    "willdabeast": "Willdabeast",
    "zajkonur": "Zajkonur",
    "zeromancer": "Zeromancer",
}

# Folders that do NOT ship, and why. Neither has an author upstream's license.txt names, and CC BY
# cannot be honored for a mark with nobody to credit. `badges` is also not an icon set at all: a
# template of white marks on a filled disc, which the luminance key would turn into a ring.
GAME_ICONS_SKIP = {
    "badges": "no credited author; a badge template on a filled disc, not a glyph",
    "various-artists": "no credited author",
}

# The statement of changes CC BY 3.0 asks for, written into the license file and AUTHORS.txt.
GAME_ICONS_CHANGES = (
    "Changes made: each SVG was rasterized to a 64x64 32-bit TGA, its black background square was "
    "removed (alpha taken from luminance), and the art was recolored white so the client can tint "
    "it. Names that collide between authors carry the author's folder name as a suffix "
    "(<name>-<author>), and names with a British spelling were respelled in US English "
    "(see US_RULES in tools/artwork/icon_cleaner.py)."
)

# ---------------------------------------------------------------------------
# Names
# ---------------------------------------------------------------------------
#
# A catalog name is written into MediaIcons.lua, which ships, so tests/test_prose.lua reads every
# one of them against localization-5's list. The lists are READ from testkit/prose_lists.lua rather
# than copied here, so this check and the gate cannot disagree, and a name that hits is respelled
# through US_RULES below -- the file on disk takes the respelled name, because the name IS the
# basename. A hit no rule fits fails the build: guessing a respelling is how a wrong word ships.
PROSE_LISTS = os.path.join(ROOT, "testkit", "prose_lists.lua")

# THE RESPELLING IS A SET OF SUFFIX RULES, not a table of word pairs, because this file is authored
# text the same gate reads: a table would have to quote every British form it maps, and quoting
# them is exactly what the gate refuses. Each rule rewrites the British SUBSTRING the gate matched
# (an entry of the published list) into its US form; a substring no rule fits fails the build.
US_RULES = [
    (re.compile(r"our$"), "or"),            # the -our family
    (re.compile(r"ould$"), "old"),          # the one -ould entry
    (re.compile(r"([bt])re$"), r"\1er"),    # the -re family (US: -ter, -ber)
    (re.compile(r"ence$"), "ense"),         # the -ence family
    (re.compile(r"ogue$"), "og"),           # the -ogue family
    (re.compile(r"dgement$"), "dgment"),    # the -dgement pair
    (re.compile(r"is$"), "iz"),             # the -is(e) verbs
    (re.compile(r"ys$"), "yz"),             # the -ys(e) verbs
    (re.compile(r"ll(ed|ing|able)$"), r"l\1"),   # a doubled l before a suffix
]


def us_spelling(british):
    """The US form of one entry of the published British list, or None when no rule fits."""
    for pattern, repl in US_RULES:
        if pattern.search(british):
            return pattern.sub(repl, british)
    return None


NAME_OK = re.compile(r"^[a-z0-9][a-z0-9-]*$")

LUA_OUT = os.path.join(ROOT, "LibKa0s", "MediaIcons.lua")

# The generated file's own minor. It moves with every released change to the file, like every other
# minor (docs/releasing.md step 2) -- and since this tool writes the file, it writes the minor too.
ICONS_MINOR = 1

# ---------------------------------------------------------------------------
# The output
# ---------------------------------------------------------------------------

# Power of two, because WoW cannot wrap a non-power-of-two texture. 64 is the source's own size, so
# nothing is resampled in the common case -- and it leaves room to draw at 18 with the client
# downscaling, which looks better than upscaling a 16px source would.
SIZE = 64

# What a fully-transparent pixel's RGB becomes. Black, so an additive or alpha-keyed blend cannot
# find a color hiding under a pixel nothing was supposed to draw.
TRANSPARENT = (0, 0, 0, 0)

# How far to push opaque color outward under the transparent region. Three is plenty at this size;
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

    for upstream in OPEN_ICONIC_REST:
        dst = os.path.join(CACHE, "%s.png" % upstream)
        if os.path.exists(dst) and os.path.getsize(dst) > 0:
            continue
        data = _gh_file("png/%s%s.png" % (upstream, SUFFIX))
        with open(dst, "wb") as fh:
            fh.write(data)
        _say("  fetched %s %d bytes" % (upstream, len(data)))

    lic = os.path.join(CACHE, LICENSE_DST)
    if not os.path.exists(lic):
        with open(lic, "wb") as fh:
            fh.write(_gh_file(LICENSE_SRC))
        _say("  fetched %s" % LICENSE_DST)

    for spec in (PHOSPHOR, GAME_ICONS):
        _clone(spec)


def _git(*args, cwd=None):
    out = subprocess.run(["git"] + list(args), cwd=cwd, capture_output=True, text=True,
                         timeout=900)
    if out.returncode != 0:
        raise RuntimeError("git %s failed: %s" % (" ".join(args), out.stderr.strip()[:300]))
    return out.stdout.strip()


def _clone(spec):
    """A shallow checkout of exactly the pinned commit, into .cache/src/<name>.

    Fetched BY SHA, not by branch, so what lands is the commit this file names and nothing newer.
    Nothing in the checkout is ever run -- not a script, not a hook, not a package.json -- because
    a cache of somebody else's repository is data.
    """
    dest = os.path.join(SRC, spec["cache"])
    if os.path.isdir(os.path.join(dest, ".git")):
        try:
            if _git("rev-parse", "HEAD", cwd=dest) == spec["sha"]:
                _say("  cached  %s @ %s" % (spec["cache"], spec["sha"][:12]))
                return
        except RuntimeError:
            pass
        shutil.rmtree(dest)
    os.makedirs(dest, exist_ok=True)
    _git("init", "--quiet", cwd=dest)
    _git("fetch", "--quiet", "--depth", "1", spec["repo"], spec["sha"], cwd=dest)
    _git("-c", "advice.detachedHead=false", "checkout", "--quiet", "FETCH_HEAD", cwd=dest)
    _say("  cloned  %s @ %s" % (spec["cache"], spec["sha"][:12]))


# ---------------------------------------------------------------------------
# Convert
# ---------------------------------------------------------------------------

def recolor_white(im):
    """Black art -> white art, alpha untouched.

    THE STAGE THAT DECIDES WHETHER THE ICONS OBEY THE PLAYER'S COLOR SETTING. Every glyph the
    header draws today is tinted at draw time to the header's text color, and a texture is tinted
    by MULTIPLYING -- so a white source becomes any color asked for and a black one stays black
    whatever it is asked for. Open Iconic ships black.

    Only the RGB is touched. The antialiased edge lives entirely in the alpha channel, so writing
    a flat white under it preserves the shape exactly.
    """
    a = np.asarray(im.convert("RGBA")).copy()
    a[..., :3] = 255
    return Image.fromarray(a, "RGBA")


def _box_sum(arr):
    """Sum of each pixel's 3x3 neighborhood, edges clamped."""
    p = np.pad(arr, ((1, 1), (1, 1), (0, 0)), mode="edge")
    return (p[:-2, :-2] + p[:-2, 1:-1] + p[:-2, 2:] +
            p[1:-1, :-2] + p[1:-1, 1:-1] + p[1:-1, 2:] +
            p[2:, :-2] + p[2:, 1:-1] + p[2:, 2:])


def solidify(im, iters=SOLIDIFY_ITERS):
    """Edge-extend opaque RGB outward into the transparent region.

    Kept from PanelMaster's tool, and kept for the same reason stated there: nothing renders the
    RGB under a transparent pixel, so nothing complains when it is arbitrary -- until a resample
    samples it. The client downscales these from 64 to 18, and its kernel reads the neighbors of
    every edge pixel including the transparent ones.

    After `recolor_white` the under-alpha RGB is already white, so this is close to a no-op today.
    It stays because the invariant it protects is "whatever is under the alpha continues the art",
    and that stops being free the moment a colored icon is added.
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
    """Center on a square power-of-two canvas. Never crop.

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

    Must run LAST. LANCZOS premultiplies and a paste carries its canvas color in, so normalizing
    any earlier is simply undone by the next stage.
    """
    a = np.asarray(im.convert("RGBA")).copy()
    a[a[..., 3] == 0] = TRANSPARENT
    return Image.fromarray(a, "RGBA")


def render_svg(path):
    """One SVG, rasterized by resvg straight to SIZE x SIZE.

    Rendered AT the target size rather than larger and downscaled: resvg antialiases the vector
    edge itself, which is better than a resample of a raster would be, and `fit_square` then passes
    the result through untouched. System fonts are skipped -- no mark in either set draws text.
    """
    import resvg_py   # imported here so --fetch and the Open Iconic build need no resvg
    with open(path, "r", encoding="utf-8") as fh:
        svg = fh.read()
    png = resvg_py.svg_to_bytes(svg_string=svg, width=SIZE, height=SIZE, skip_system_fonts=True)
    return Image.open(io.BytesIO(bytes(png))).convert("RGBA")


def alpha_from_luminance(im):
    """White art on a black square -> white art on nothing.

    Every Game-icons SVG opens with `<path d="M0 0h512v512H0z"/>`, a black square under the white
    mark. Taking the alpha from the luminance removes it however a file spells it -- a regex over
    the path would miss the one file that writes the square differently -- and keeps the mark's
    antialiased edge, which is exactly the white-to-black ramp the luminance reads.
    """
    a = np.asarray(im.convert("RGBA"), dtype=np.float32)
    lum = 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]
    a[..., 3] = np.clip(lum * a[..., 3] / 255.0, 0, 255)
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def corners_clear(im):
    """True when all four corner pixels are fully transparent -- the background-square check."""
    a = np.asarray(im)
    s = im.size[0] - 1
    return all(a[y, x, 3] == 0 for x, y in ((0, 0), (s, 0), (0, s), (s, s)))


def convert_one(src, dst, kind="png"):
    """One icon through the pipeline. `kind` is "png" (Open Iconic), "svg" (Phosphor) or
    "svg-keyed" (Game-icons, whose background is removed and then checked)."""
    if kind == "png":
        im = Image.open(src)
        im = im.convert("RGBA") if im.mode != "RGBA" else im.copy()
    else:
        im = render_svg(src)
        if kind == "svg-keyed":
            im = alpha_from_luminance(im)
    im = normalize_transparent(fit_square(solidify(recolor_white(im))))
    if kind == "svg-keyed" and not corners_clear(im):
        raise RuntimeError("%s: a corner is still opaque after the background was removed" % src)
    # RLE, matching media/textures/Default.tga -- the texture this client is already known to load.
    im.save(dst, compression="tga_rle")
    return im.size


def _convert_job(job):
    src, dst, kind = job
    convert_one(src, dst, kind)
    return dst


# ---------------------------------------------------------------------------
# Names and the catalog
# ---------------------------------------------------------------------------

def _lua_list(text, name):
    m = re.search(r"local %s = \{(.*?)\n\}" % name, text, re.S)
    if not m:
        raise RuntimeError("%s not found in %s" % (name, PROSE_LISTS))
    return re.findall(r'"([^"]+)"', m.group(1))


def load_prose_lists():
    with open(PROSE_LISTS, "r", encoding="utf-8") as fh:
        text = fh.read()
    return _lua_list(text, "BRITISH"), set(_lua_list(text, "ALLOWED"))


def prose_hits(name, british, allowed):
    """The British substrings `name` carries, read the way tests/test_prose.lua reads a line:
    ALLOWED words removed whole first, then a substring scan."""
    words = [w for w in re.split(r"[^a-z]+", name.lower()) if w and w not in allowed]
    joined = " ".join(words)
    return [b for b in british if b in joined]


def us_name(name, british, allowed):
    """`name`, respelled through US_RULES when the prose gate would reject it."""
    hits = prose_hits(name, british, allowed)
    if not hits:
        return name
    out = name
    for hit in hits:
        us = us_spelling(hit)
        if us is None:
            raise RuntimeError("%s: no US_RULES rule respells %r; add one" % (name, hit))
        out = out.replace(hit, us)
    left = prose_hits(out, british, allowed)
    if left:
        raise RuntimeError("%s: still British after respelling (%s)" % (name, left))
    return out


def phosphor_marks():
    """[(name, svg path)] for every Phosphor Fill mark that ships, sorted."""
    root = os.path.join(SRC, PHOSPHOR["cache"], PHOSPHOR["svgs"])
    marks = []
    for f in sorted(os.listdir(root)):
        if not f.endswith(PHOSPHOR["suffix"] + ".svg"):
            continue
        name = f[: -len(PHOSPHOR["suffix"] + ".svg")]
        if PHOSPHOR_DROP.search(name):
            continue
        marks.append((name, os.path.join(root, f)))
    return marks


def game_icon_marks():
    """[(name, svg path, author folder)] for every Game-icons mark that ships, sorted by name.

    A name two authors both drew takes the author's folder as a suffix on EVERY copy, not just the
    later ones, so which copy owns the bare name never depends on folder order.
    """
    root = os.path.join(SRC, GAME_ICONS["cache"])
    raw = []
    for folder in sorted(os.listdir(root)):
        path = os.path.join(root, folder)
        if not os.path.isdir(path) or folder.startswith("."):
            continue
        if folder in GAME_ICONS_SKIP:
            continue
        if folder not in GAME_ICONS_AUTHORS:
            raise RuntimeError("game-icons folder %r has no author in GAME_ICONS_AUTHORS" % folder)
        for f in sorted(os.listdir(path)):
            if f.endswith(".svg"):
                raw.append((f[:-4], os.path.join(path, f), folder))
    count = {}
    for name, _, _ in raw:
        count[name] = count.get(name, 0) + 1
    marks = []
    for name, path, folder in raw:
        marks.append((name if count[name] == 1 else "%s-%s" % (name, folder), path, folder))
    return sorted(marks)


def _packed(names, indent, width=118):
    """Names as Lua string literals of space-separated names, one per line, each under `width`."""
    lines, cur = [], ""
    for n in names:
        if cur and len(cur) + 1 + len(n) > width - len(indent) - 4:
            lines.append(cur)
            cur = n
        else:
            cur = n if not cur else cur + " " + n
    if cur:
        lines.append(cur)
    return ["%s\"%s\"," % (indent, line) for line in lines]


def write_catalog(oi_rest, ph_names, gi_by_author):
    """LibKa0s/MediaIcons.lua: the generated half of the catalog, as packed strings split at load.

    Packed rather than one name per line because `layout-1` caps a shipped file at 1500 lines and
    the catalog is ~5,600 names; ~110-character lines keep it under a third of that and still diff
    line by line when a pin moves.
    """
    out = []
    w = out.append
    w("-- LibKa0s/MediaIcons.lua — GENERATED by tools/artwork/icon_cleaner.py. Do not edit by hand:")
    w("-- change the generator and run it again (`--build`), which rewrites this file and the art.")
    w("--")
    w("-- The generated half of LibKa0s-Media-1.0's icon catalog: every name past the 113 hand-written")
    w("-- in Media.lua. The other %d Open Iconic marks (MIT, flat, unprefixed), %d Phosphor Fill marks"
      % (len(oi_rest), len(ph_names)))
    w("-- (MIT, `ph:`) and %d Game-icons.net marks (CC BY 3.0, `gi:`, grouped by author, because"
      % sum(len(v) for _, v in gi_by_author))
    w("-- attribution is per author). Appended to `ICONS` at load through `__SetGeneratedIcons`, which")
    w("-- also gives `IconAuthor` its answers. A secondary file of the Media major, paired on the shell's")
    w("-- minor like every other secondary (docs/releasing.md step 3): a host carrying a copy without")
    w("-- this file still has the 113 hand-written names, and nothing else changes.")
    w("--")
    w("-- Upstream commits: Phosphor %s, Game-icons %s." % (PHOSPHOR["sha"][:12], GAME_ICONS["sha"][:12]))
    w("")
    w("local lib = LibStub and LibStub(\"LibKa0s-Media-1.0\", true)")
    w("if not lib or type(lib.__SetGeneratedIcons) ~= \"function\" then return end")
    w("")
    w("local ICONS_MINOR = %d" % ICONS_MINOR)
    w("")
    w("if lib.__iconsMinor and lib.__iconsMinor >= ICONS_MINOR")
    w("  and lib.__iconsShellMinor == lib.MINOR then return end")
    w("lib.__iconsMinor      = ICONS_MINOR")
    w("lib.__iconsShellMinor = lib.MINOR")
    w("")
    w("lib.MODULES = lib.MODULES or {}")
    w("lib.MODULES.MediaIcons = ICONS_MINOR")
    w("")
    w("-- Open Iconic, the marks Media.lua's semantic keys do not already draw, under upstream names.")
    w("local OPEN_ICONIC = {")
    out.extend(_packed(oi_rest, "  "))
    w("}")
    w("")
    w("-- Phosphor Fill, without its `*-logo` brand marks. Each name is prefixed `ph:` at load.")
    w("local PHOSPHOR = {")
    out.extend(_packed(ph_names, "  "))
    w("}")
    w("")
    w("-- Game-icons.net, one block per author: the author's credited name, then their marks. Each")
    w("-- name is prefixed `gi:` at load.")
    w("local GAME_ICONS = {")
    for author, names in gi_by_author:
        w("  { \"%s\"," % author)
        out.extend(_packed(names, "    "))
        w("  },")
    w("}")
    w("")
    w("local names, authors = {}, {}")
    w("for _, line in ipairs(OPEN_ICONIC) do")
    w("  for name in line:gmatch(\"%S+\") do names[#names + 1] = name end")
    w("end")
    w("for _, line in ipairs(PHOSPHOR) do")
    w("  for name in line:gmatch(\"%S+\") do names[#names + 1] = \"ph:\" .. name end")
    w("end")
    w("for _, block in ipairs(GAME_ICONS) do")
    w("  local who = block[1]")
    w("  for i = 2, #block do")
    w("    for name in block[i]:gmatch(\"%S+\") do")
    w("      local full = \"gi:\" .. name")
    w("      names[#names + 1] = full")
    w("      authors[full] = who")
    w("    end")
    w("  end")
    w("end")
    w("")
    w("lib.__SetGeneratedIcons(names, authors)")
    text = "\r\n".join(out) + "\r\n"
    with open(LUA_OUT, "wb") as fh:
        fh.write(text.encode("utf-8"))
    return len(out)


def write_game_icons_texts(gi_marks, dest):
    """LICENSE-game-icons.txt (upstream's notice, the license link, the changes) and AUTHORS.txt
    (every shipped name and its author). CRLF, as `* text=auto eol=crlf` would check them out."""
    with open(os.path.join(SRC, GAME_ICONS["cache"], GAME_ICONS["license"]), "r",
              encoding="utf-8") as fh:
        upstream = fh.read().replace("\r\n", "\n").strip()
    lic = [
        "Game-icons.net icons, shipped by LibKa0s under media/icons/game-icons/.",
        "",
        "License: Creative Commons Attribution 3.0 Unported (CC BY 3.0),",
        "https://creativecommons.org/licenses/by/3.0/ -- or CC0 where the notice below says so.",
        "Source: https://game-icons.net, https://github.com/game-icons/icons at commit",
        GAME_ICONS["sha"] + ".",
        "",
        GAME_ICONS_CHANGES,
        "",
        "Every mark's author is listed in AUTHORS.txt beside this file.",
        "",
        "Upstream's notice, verbatim:",
        "",
        upstream,
    ]
    with open(os.path.join(dest, GAME_ICONS["license_out"]), "wb") as fh:
        fh.write(("\n".join(lic) + "\n").replace("\n", "\r\n").encode("utf-8"))

    lines = [
        "Icons made by the Game-icons.net authors below, CC BY 3.0 (see LICENSE-game-icons.txt).",
        "One line per shipped mark: its LibKa0s catalog name, then its author.",
        "",
        GAME_ICONS_CHANGES,
        "",
    ]
    for name, _, folder in gi_marks:
        lines.append("gi:%s\t%s" % (name, GAME_ICONS_AUTHORS[folder]))
    with open(os.path.join(dest, "AUTHORS.txt"), "wb") as fh:
        fh.write(("\r\n".join(lines) + "\r\n").encode("utf-8"))


def copy_text_crlf(src, dst):
    """Copy a text file with CRLF endings, as `* text=auto eol=crlf` checks every .txt out. Writing
    the upstream LF bytes would leave the working tree differing from the index until the next
    checkout, which reads as a modified file nobody modified."""
    with open(src, "rb") as fh:
        body = fh.read().replace(b"\r\n", b"\n").replace(b"\n", b"\r\n")
    with open(dst, "wb") as fh:
        fh.write(body)


def _clean_dir(path):
    """Empty a generated set folder of its TGAs, so a mark dropped upstream does not linger."""
    os.makedirs(path, exist_ok=True)
    for f in os.listdir(path):
        if f.endswith(".tga"):
            os.remove(os.path.join(path, f))


def build():
    os.makedirs(OUT, exist_ok=True)
    missing = []
    jobs = []

    # Open Iconic: the semantic keys, then the rest under upstream names. Flat.
    for name, upstream in sorted(GLYPHS.items()):
        src = os.path.join(CACHE, "%s.png" % upstream)
        if not os.path.exists(src):
            missing.append(upstream)
            continue
        jobs.append((src, os.path.join(OUT, "%s.tga" % name), "png"))
    for upstream in OPEN_ICONIC_REST:
        if upstream in GLYPHS:
            raise RuntimeError("%s is both a semantic key and an upstream name" % upstream)
        src = os.path.join(CACHE, "%s.png" % upstream)
        if not os.path.exists(src):
            missing.append(upstream)
            continue
        jobs.append((src, os.path.join(OUT, "%s.tga" % upstream), "png"))

    lic = os.path.join(CACHE, LICENSE_DST)
    if os.path.exists(lic):
        copy_text_crlf(lic, os.path.join(OUT, LICENSE_DST))

    if missing:
        _say("\nmissing sources (run --fetch): %s" % ", ".join(missing))
        return 1
    for spec in (PHOSPHOR, GAME_ICONS):
        if not os.path.isdir(os.path.join(SRC, spec["cache"])):
            _say("\nmissing %s checkout (run --fetch)" % spec["cache"])
            return 1

    british, allowed = load_prose_lists()

    # Phosphor Fill.
    ph_dir = os.path.join(OUT, PHOSPHOR["out"])
    _clean_dir(ph_dir)
    ph_names = []
    for name, src in phosphor_marks():
        name = us_name(name, british, allowed)
        if not NAME_OK.match(name):
            raise RuntimeError("phosphor name %r is not [a-z0-9-]" % name)
        ph_names.append(name)
        jobs.append((src, os.path.join(ph_dir, "%s.tga" % name), "svg"))
    copy_text_crlf(os.path.join(SRC, PHOSPHOR["cache"], PHOSPHOR["license"]),
                   os.path.join(ph_dir, PHOSPHOR["license_out"]))

    # Game-icons.
    gi_dir = os.path.join(OUT, GAME_ICONS["out"])
    _clean_dir(gi_dir)
    gi_marks = []
    for name, src, folder in game_icon_marks():
        name = us_name(name, british, allowed)
        if not NAME_OK.match(name):
            raise RuntimeError("game-icons name %r is not [a-z0-9-]" % name)
        gi_marks.append((name, src, folder))
        jobs.append((src, os.path.join(gi_dir, "%s.tga" % name), "svg-keyed"))
    gi_marks.sort()

    for label, names in (("phosphor", ph_names), ("game-icons", [m[0] for m in gi_marks])):
        if len(set(names)) != len(names):
            raise RuntimeError("%s: two marks share a name after respelling" % label)

    _say("  rendering %d icons ..." % len(jobs))
    with ProcessPoolExecutor() as pool:
        for i, _ in enumerate(pool.map(_convert_job, jobs, chunksize=32), 1):
            if i % 500 == 0:
                _say("    %d / %d" % (i, len(jobs)))

    write_game_icons_texts(gi_marks, gi_dir)

    by_author = {}
    for name, _, folder in gi_marks:
        by_author.setdefault(GAME_ICONS_AUTHORS[folder], []).append(name)
    gi_by_author = sorted(by_author.items())
    nlines = write_catalog(OPEN_ICONIC_REST, ph_names, gi_by_author)

    _say("  open iconic %d + %d, phosphor %d, game-icons %d; MediaIcons.lua %d lines"
         % (len(GLYPHS), len(OPEN_ICONIC_REST), len(ph_names), len(gi_marks), nlines))
    return 0


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--fetch", action="store_true", help="download sources into the cache")
    ap.add_argument("--build", action="store_true", help="convert the cache into TGAs")
    args = ap.parse_args(argv)

    both = not (args.fetch or args.build)
    if args.fetch or both:
        _say("fetching ...")
        fetch()
    if args.build or both:
        _say("building into LibKa0s/media/icons/ ...")
        return build()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
