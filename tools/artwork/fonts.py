#!/usr/bin/env python3
"""Fetch, pin and build the OFL faces the skins draw with, into LibKa0s/media/fonts/.

    fonts.py --fetch    download the upstream files, pinned by commit, into tools/artwork/.cache/fonts/
    fonts.py --build    write the shipped TTFs and their license files from the cache

THIS FILE IS THE PROVENANCE RECORD for every face in `media/fonts/` but JetBrains Mono, which came
with the library from Mythic Meters (see `lib.FONTS` in LibKa0s/Media.lua). It names the upstream
repository, the commit each file is pinned to, the SHA-256 of what that commit serves, and the one
transformation applied, so a reader can rebuild the bytes that ship and check them against the
commit rather than take them on trust.

WHAT SHIPS, AND FROM WHERE (all SIL Open Font License 1.1, from google/fonts' ofl/ folder):

    Inter-Regular.ttf, Inter-SemiBold.ttf              inter, Inter[opsz,wght].ttf, INSTANCED
    Nunito-Regular.ttf, Nunito-SemiBold.ttf            nunito, Nunito[wght].ttf, INSTANCED
    Vollkorn-Regular.ttf, Vollkorn-Bold.ttf            vollkorn, Vollkorn[wght].ttf, INSTANCED
    Bitter-Regular.ttf, Bitter-Bold.ttf                bitter, Bitter[wght].ttf, INSTANCED
    Philosopher-Regular.ttf, Philosopher-Bold.ttf      philosopher, static files, unchanged
    FiraSans-Regular.ttf, FiraSans-SemiBold.ttf        firasans, static files, unchanged
    AtkinsonHyperlegible-Regular.ttf, -Bold.ttf        atkinsonhyperlegible, static files, unchanged

    and one license file per family beside them, `<Family>-OFL.txt`: upstream's OFL.txt verbatim,
    an instanced family's with a provenance note above it.

WHY SOME ARE INSTANCED. Upstream publishes those four as variable fonts only, and the WoW client is
not known to honor a variable axis, so a variable file would draw its default instance whatever
weight was asked for (Bitter's and Nunito's default is their thinnest). `fontTools.varLib.instancer`
pins each axis (weight, and Inter's optical size at its text end, 14) and drops the variation
tables, which gives a static face; the name table is then rewritten to name the weight, so the file
does not claim to be the instance it was cut from. The OFL allows a modified version under the same
license. None of the four reserves its family name (Bitter reserves only "Bitter Pro"), so the
names stay.

WHY THESE: the owner's round-5 notes of 2026-10-28 (Ka0sAddonsCommonTasks
docs/2026-10-28-SKIN_ROUND5/): every skin has a face of its own, its titles in the same family as
its body. Inter is Obsidian's (the modern face its mockup named), Nunito Glass's (rounded, as its
corners are), Vollkorn Azeroth's (a dark old-style book face for the parchment), Bitter Ember's (a
sturdy slab), Philosopher WoW Midnight's, Fira Sans WoW Forever's and Atkinson Hyperlegible High
Contrast's. Ka0s Default and WoW Default draw the client's own Friz Quadrata. Barlow and Cinzel,
the 2026-10-25 run's faces, left the payload in the same round. Atkinson has no Cyrillic; the other
six cover it, so Media.lua registers them for ruRU too.

Requires Python 3 and fontTools (`sudo apt install python3-fonttools`; see DEPENDENCIES.md), and
network access for --fetch. Run it with `-I`: the cache holds other people's files.
"""

import argparse
import hashlib
import os
import shutil
import sys
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, os.pardir, os.pardir))
OUT = os.path.join(ROOT, "LibKa0s", "media", "fonts")
CACHE = os.path.join(HERE, ".cache", "fonts")

RAW = "https://raw.githubusercontent.com/google/fonts/%s/ofl/%s/%s"

# PINNED, BY COMMIT: the last google/fonts commit to touch each family's folder on the day it was
# added (Atkinson on 2026-10-25, the rest on 2026-10-28). A moving branch is not a provenance record;
# the next --fetch would quietly ship different bytes.
#
# `ship` copies a static file unchanged. `instances` cuts a static face from a variable one: the
# source file, the output file, the axis values, and the style name it is given.
FAMILIES = [
    {
        "dir": "inter", "family": "Inter",
        "sha": "0b58fb370093f9a9f4ff785d94405710b79de67c",
        "files": {
            "Inter[opsz,wght].ttf": "29160a80ff49ddcab2c97711247e08b1fab27a484a329ce8b813d820dc559031",
            "OFL.txt": "5b9321a4298cfeb6b34354164a1c3afc3db114569984c502b9b35d988fd58c57",
        },
        "license": "Inter-OFL.txt",
        "ship": [],
        "instances": [
            ("Inter[opsz,wght].ttf", "Inter-Regular.ttf", {"opsz": 14, "wght": 400}, "Regular"),
            ("Inter[opsz,wght].ttf", "Inter-SemiBold.ttf", {"opsz": 14, "wght": 600}, "SemiBold"),
        ],
    },
    {
        "dir": "nunito", "family": "Nunito",
        "sha": "8b0a1d0f5983c89bc2b93f1b5fb55f9e252744b5",
        "files": {
            "Nunito[wght].ttf": "bb55a5ca5c2042335b3991af27c4d0705d0ef41cac6164ac737fd8f2a1e85207",
            "OFL.txt": "580df76c95a1ec5ab878ceb25bb3d85c6a076804e9c970c8c6972aea775fdf65",
        },
        "license": "Nunito-OFL.txt",
        "ship": [],
        "instances": [
            ("Nunito[wght].ttf", "Nunito-Regular.ttf", {"wght": 400}, "Regular"),
            ("Nunito[wght].ttf", "Nunito-SemiBold.ttf", {"wght": 600}, "SemiBold"),
        ],
    },
    {
        "dir": "vollkorn", "family": "Vollkorn",
        "sha": "5081ec64046ff04e82233258ba3faad2545813dd",
        "files": {
            "Vollkorn[wght].ttf": "4ebef434f76f80286204840354a84db79a0dc3c87deeeb791e015b70b2ade49d",
            "OFL.txt": "53f9c99fa3d47f7d632a42ee7bab4a834a60a744f6026d676c3a223cef2b2ef3",
        },
        "license": "Vollkorn-OFL.txt",
        "ship": [],
        "instances": [
            ("Vollkorn[wght].ttf", "Vollkorn-Regular.ttf", {"wght": 400}, "Regular"),
            ("Vollkorn[wght].ttf", "Vollkorn-Bold.ttf", {"wght": 700}, "Bold"),
        ],
    },
    {
        "dir": "bitter", "family": "Bitter",
        "sha": "b6380fac8e94cdc92aa045cf44d80a7743dde8d6",
        "files": {
            "Bitter[wght].ttf": "ef2b9a711fb02f1e5823b34da1b7450e0fc76793b7d733a8b41006e24916d4a7",
            "OFL.txt": "152a1e283e23b42c4940da4c72f2f5bebaa17969cb77c76d7af05903846006f1",
        },
        "license": "Bitter-OFL.txt",
        "ship": [],
        "instances": [
            ("Bitter[wght].ttf", "Bitter-Regular.ttf", {"wght": 400}, "Regular"),
            ("Bitter[wght].ttf", "Bitter-Bold.ttf", {"wght": 700}, "Bold"),
        ],
    },
    {
        "dir": "philosopher", "family": "Philosopher",
        "sha": "8b0a1d0f5983c89bc2b93f1b5fb55f9e252744b5",
        "files": {
            "Philosopher-Regular.ttf": "e1cba0b5003b5694f1d6cc0fbe629f78362ad38a9ffd4d0cb7abfd9698a575ed",
            "Philosopher-Bold.ttf": "2277c78b95657274b949f40b64b58d18fe7bbe0ec968c104d38906ec700024ea",
            "OFL.txt": "f1e511c19c29907ff2e7a3a575e7fa4cbbf5cedf551a0044db74cf4dc52fde89",
        },
        "license": "Philosopher-OFL.txt",
        "ship": ["Philosopher-Regular.ttf", "Philosopher-Bold.ttf"],
        "instances": [],
    },
    {
        "dir": "firasans", "family": "Fira Sans",
        "sha": "e345593da2a4d596212542edbd28f2ed08fe6cbe",
        "files": {
            "FiraSans-Regular.ttf": "c29556a2719bf613ef3d5e070e40d903a8965d9c081beca1375dc1e6e0f93c23",
            "FiraSans-SemiBold.ttf": "db0321f83eb3e9f527b8af384a1b3fefdc1039cf2b06fd39b3f61492bda9561c",
            "OFL.txt": "8f24842e9174beda18a556c2ae7d54f5dc444340c19a3a9ef77e23bca366adbd",
        },
        "license": "FiraSans-OFL.txt",
        "ship": ["FiraSans-Regular.ttf", "FiraSans-SemiBold.ttf"],
        "instances": [],
    },
    {
        "dir": "atkinsonhyperlegible", "family": "Atkinson Hyperlegible",
        "sha": "95f4904fc8bcf26d3420fe315560c96417c6dec7",
        "files": {
            "AtkinsonHyperlegible-Regular.ttf":
                "7fb917c89019896d0b52ee84b7cbb3304c18cb90b19a62f5e32712bd23e97669",
            "AtkinsonHyperlegible-Bold.ttf":
                "5a3b0c8cc8ca545155150b4512a1fa248298df121c50d6557e651e61fbdab92f",
            "OFL.txt": "f32d22b3908fcad2c86a74000614ec22e6a7f66ea7e867e616026a27aebdc143",
        },
        "license": "AtkinsonHyperlegible-OFL.txt",
        "ship": ["AtkinsonHyperlegible-Regular.ttf", "AtkinsonHyperlegible-Bold.ttf"],
        "instances": [],
    },
    {
        # Ka0s Default's face (2026-10-28): a squared techno sans, the free stand-in for the
        # personal-use-only Prototype the owner first chose. SemiBold for body and HUD text, which is
        # Prototype's weight; Bold for titles.
        "dir": "oxanium", "family": "Oxanium",
        "sha": "8b0a1d0f5983c89bc2b93f1b5fb55f9e252744b5",
        "files": {
            "Oxanium[wght].ttf": "2ce01d946e1e1ffc8d7eecfffbda8623bedd63eaf811a20488c4b69af45babb0",
            "OFL.txt": "fe17c0f2581d71b4e1ea7e636e7f4877c29223e11bb1dd1a871e8c3f2a86336b",
        },
        "license": "Oxanium-OFL.txt",
        "ship": [],
        "instances": [
            ("Oxanium[wght].ttf", "Oxanium-SemiBold.ttf", {"wght": 600}, "SemiBold"),
            ("Oxanium[wght].ttf", "Oxanium-Bold.ttf", {"wght": 700}, "Bold"),
        ],
    },
]

NOTE = (
    "%s are static instances of upstream's variable %s, made with\n"
    "fontTools.varLib.instancer by tools/artwork/fonts.py in the LibKa0s repository, which pins\n"
    "the source commit and records the change. Only the variation axes were fixed (%s) and the\n"
    "name table renamed to name each weight; no glyph was edited. They remain under the license\n"
    "below.\n"
    "\n"
)


def _say(msg):
    sys.stdout.write(msg + "\n")


def _sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def _cached(family, name):
    return os.path.join(CACHE, family["dir"], name)


def fetch():
    for family in FAMILIES:
        os.makedirs(os.path.join(CACHE, family["dir"]), exist_ok=True)
        for name, want in family["files"].items():
            dest = _cached(family, name)
            if os.path.isfile(dest) and _sha256(dest) == want:
                _say("  cached  %s/%s" % (family["dir"], name))
                continue
            url = RAW % (family["sha"], family["dir"], name.replace("[", "%5B").replace("]", "%5D"))
            with urllib.request.urlopen(url, timeout=60) as resp, open(dest, "wb") as out:
                shutil.copyfileobj(resp, out)
            got = _sha256(dest)
            if got != want:
                os.remove(dest)
                raise SystemExit("%s: SHA-256 %s, expected %s" % (url, got, want))
            _say("  fetched %s/%s @ %s" % (family["dir"], name, family["sha"][:12]))
    return 0


def _write_text_crlf(text, dest):
    """Upstream's text with CRLF endings, the way .gitattributes pins every text file here."""
    body = text.replace("\r\n", "\n").replace("\n", "\r\n")
    with open(dest, "wb") as fh:
        fh.write(body.encode("utf-8"))


def _axes(axes):
    return ", ".join("%s %s" % kv for kv in sorted(axes.items()))


def instance(src, dest, axes, family, style):
    """Pin every axis of `src` at `axes` and name the static result `family` `style`."""
    from fontTools.ttLib import TTFont
    from fontTools.varLib import instancer

    font = TTFont(src, recalcTimestamp=False)
    static = instancer.instantiateVariableFont(font, axes, static=True)
    static["OS/2"].usWeightClass = axes["wght"]
    bold = style == "Bold"
    # fsSelection: clear ITALIC / BOLD / REGULAR, then set the one this face is; macStyle to match.
    static["OS/2"].fsSelection = (static["OS/2"].fsSelection & ~0x61) | (0x20 if bold else 0x40)
    static["head"].macStyle = 1 if bold else 0
    names = static["name"]
    ps = family.replace(" ", "")
    # A four-style family names Regular and Bold in the legacy pair (1/2); any other weight moves into
    # the legacy family name. 4 full; 6 PostScript; 16/17 the typographic family and style.
    legacy = (family, style) if style in ("Regular", "Bold") else ("%s %s" % (family, style), "Regular")
    full = family if style == "Regular" else "%s %s" % (family, style)
    for name_id, value in ((1, legacy[0]), (2, legacy[1]), (4, full), (6, "%s-%s" % (ps, style)),
                           (16, family), (17, style)):
        names.setName(value, name_id, 3, 1, 0x409)
    names.removeNames(nameID=3)
    names.setName("%s-%s;instanced by LibKa0s tools/artwork/fonts.py" % (ps, style), 3, 3, 1, 0x409)
    names.removeNames(nameID=25)   # a variable font's PostScript-prefix record no longer applies
    static.save(dest)


def build():
    os.makedirs(OUT, exist_ok=True)
    for family in FAMILIES:
        for name, want in family["files"].items():
            path = _cached(family, name)
            if not os.path.isfile(path) or _sha256(path) != want:
                raise SystemExit("missing or changed %s (run --fetch)" % path)
        for name in family["ship"]:
            shutil.copyfile(_cached(family, name), os.path.join(OUT, name))
            _say("  copied  %s" % name)
        with open(_cached(family, "OFL.txt"), "r", encoding="utf-8") as fh:
            text = fh.read()
        for src, out, axes, style in family["instances"]:
            instance(_cached(family, src), os.path.join(OUT, out), axes, family["family"], style)
            _say("  built   %s (%s)" % (out, _axes(axes)))
        if family["instances"]:
            outs = " and ".join(i[1] for i in family["instances"])
            pinned = "; ".join("%s at %s" % (i[1], _axes(i[2])) for i in family["instances"])
            text = NOTE % (outs, family["instances"][0][0], pinned) + text
        _write_text_crlf(text, os.path.join(OUT, family["license"]))
        _say("  wrote   %s" % family["license"])
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--fetch", action="store_true", help="download the pinned upstream files")
    ap.add_argument("--build", action="store_true", help="write media/fonts/ from the cache")
    args = ap.parse_args()
    if not (args.fetch or args.build):
        ap.print_help()
        return 2
    if args.fetch:
        fetch()
    if args.build:
        build()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
