#!/usr/bin/env python3
"""Fetch, pin and build the OFL faces the skins draw with, into LibKa0s/media/fonts/.

    fonts.py --fetch    download the upstream files, pinned by commit, into tools/artwork/.cache/fonts/
    fonts.py --build    write the shipped TTFs and their license files from the cache

THIS FILE IS THE PROVENANCE RECORD for every face in `media/fonts/` but JetBrains Mono, which came
with the library from Mythic Meters (see `lib.FONTS` in LibKa0s/Media.lua). It names the upstream
repository, the commit each file is pinned to, the SHA-256 of what that commit serves, and the one
transformation applied, so a reader can rebuild the bytes that ship and check them against the
commit rather than take them on trust.

WHAT SHIPS, AND FROM WHERE (all SIL Open Font License 1.1, no Reserved Font Name in any of them):

    Barlow-Regular.ttf, Barlow-SemiBold.ttf      google/fonts ofl/barlow, static files, unchanged
    AtkinsonHyperlegible-Regular.ttf, -Bold.ttf  google/fonts ofl/atkinsonhyperlegible, unchanged
    Cinzel-SemiBold.ttf                          google/fonts ofl/cinzel, Cinzel[wght].ttf, INSTANCED

    and one license file per family beside them: Barlow-OFL.txt, AtkinsonHyperlegible-OFL.txt and
    Cinzel-OFL.txt, upstream's OFL.txt verbatim (Cinzel's with a provenance note above it).

WHY CINZEL IS INSTANCED. Upstream publishes Cinzel as a variable font only (wght 400-900, named
instances Regular, Bold and Black, no SemiBold), and the WoW client is not known to honor a variable
axis, so a variable file would draw its default instance, Regular, whatever weight was asked for.
`fontTools.varLib.instancer` pins wght to 600 and drops the variation tables, which gives a static
SemiBold; the name table is then rewritten to call it "Cinzel SemiBold" so the file does not claim
to be the Regular it was cut from. The OFL allows a modified version under the same license, and the
family carries no Reserved Font Name, so the name may stay. The note at the top of Cinzel-OFL.txt
says the same thing to someone who only has the vendored copy.

WHY THESE FIVE: the 2026-10-25 skinning run's spec (Ka0sAddonsCommonTasks
docs/2026-10-25-SKINNING/03_SPEC.md, R7). Barlow is the Obsidian, Glass and WoW Forever body face,
Cinzel the Azeroth, Ember and WoW Midnight title face, Atkinson Hyperlegible High Contrast's. None
of the three has Hangul or Han, and Cinzel and Atkinson have no Cyrillic, so Media.lua registers
them for western clients only.

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

# PINNED, BY COMMIT: the last google/fonts commit to touch each family's folder on 2026-10-25. A
# moving branch is not a provenance record; the next --fetch would quietly ship different bytes.
FAMILIES = [
    {
        "dir": "barlow",
        "sha": "6cdf01867df0813c2390f90dff7dc66c87f14cf7",
        "files": {
            "Barlow-Regular.ttf": "95aa02c7c43096e0dd44d787ba6216864a67157e402adab59b35572e0c1577ea",
            "Barlow-SemiBold.ttf": "86577cb32f8abe3673db53ca0f4221e6856751a4f6730c867e00f720f8bb1fc5",
            "OFL.txt": "186d750eb496a4c17a76385f82be6aea2ac1cf2de074a811d63786cf374ea73f",
        },
        "license": "Barlow-OFL.txt",
        "ship": ["Barlow-Regular.ttf", "Barlow-SemiBold.ttf"],
    },
    {
        "dir": "atkinsonhyperlegible",
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
    },
    {
        "dir": "cinzel",
        "sha": "3dd78844021e948ceb633d1dcee3f7885561b5d9",
        "files": {
            "Cinzel[wght].ttf": "f4d83d34d1f6c741193e4acf4b3dff9531e5a67b6aa65228d00a7db72a4e0f34",
            "OFL.txt": "f2b3029aba64c378bf0963b62945eee15e564fe4330b934c8f2eb058282b5e83",
        },
        "license": "Cinzel-OFL.txt",
        "ship": [],   # built by instance_cinzel() below
    },
]

# The one transformation in this file.
CINZEL_SOURCE = "Cinzel[wght].ttf"
CINZEL_OUT = "Cinzel-SemiBold.ttf"
CINZEL_WEIGHT = 600

CINZEL_NOTE = (
    "Cinzel-SemiBold.ttf is a static instance of upstream's variable Cinzel[wght].ttf at wght 600,\n"
    "made with fontTools.varLib.instancer by tools/artwork/fonts.py in the LibKa0s repository,\n"
    "which pins the source commit and records the change. Only the weight axis was fixed and the\n"
    "name table renamed to \"Cinzel SemiBold\"; no glyph was edited. It remains under the license\n"
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
        fh.write(body.encode("ascii"))


def instance_cinzel(src, dest):
    """Pin Cinzel's weight axis at CINZEL_WEIGHT and rename the result as a SemiBold."""
    from fontTools.ttLib import TTFont
    from fontTools.varLib import instancer

    font = TTFont(src, recalcTimestamp=False)
    static = instancer.instantiateVariableFont(font, {"wght": CINZEL_WEIGHT}, static=True)
    static["OS/2"].usWeightClass = CINZEL_WEIGHT
    names = static["name"]
    # 1/2 the legacy family and style (a four-style family has no SemiBold, so the weight moves into
    # the family name); 4 full; 6 PostScript; 16/17 the typographic family and style.
    for name_id, value in ((1, "Cinzel SemiBold"), (2, "Regular"), (4, "Cinzel SemiBold"),
                           (6, "Cinzel-SemiBold"), (16, "Cinzel"), (17, "SemiBold")):
        names.setName(value, name_id, 3, 1, 0x409)
    names.removeNames(nameID=3)
    names.setName("Cinzel-SemiBold;instanced by LibKa0s tools/artwork/fonts.py", 3, 3, 1, 0x409)
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
        with open(_cached(family, "OFL.txt"), "r", encoding="ascii") as fh:
            text = fh.read()
        if family["dir"] == "cinzel":
            instance_cinzel(_cached(family, CINZEL_SOURCE), os.path.join(OUT, CINZEL_OUT))
            _say("  built   %s (wght %d)" % (CINZEL_OUT, CINZEL_WEIGHT))
            text = CINZEL_NOTE + text
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
