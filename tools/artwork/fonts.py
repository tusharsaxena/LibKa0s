#!/usr/bin/env python3
"""Fetch, pin and build the faces the skins draw with, into LibKa0s/media/fonts/.

    fonts.py --fetch    download the upstream files, pinned by commit or by hash, into tools/artwork/.cache/fonts/
    fonts.py --build    write the shipped TTFs and their license files from the cache

THIS FILE IS THE PROVENANCE RECORD for every face in `media/fonts/` but JetBrains Mono, which came
with the library from Mythic Meters (see `lib.FONTS` in LibKa0s/Media.lua). `media/fonts/FONTS.md` is
the reader's record of the same facts: each face's copyright and license, and the ruling it ships on.
It is written by hand; nothing here generates it. This file names where each file
came from, the commit or archive it is pinned to, the SHA-256 of what that source serves, the terms
it ships under and the one transformation applied, if any, so a reader can rebuild the bytes that
ship and check them against the source rather than take them on trust.

WHAT SHIPS, AND FROM WHERE. From google/fonts' ofl/ folder, SIL Open Font License 1.1:

    Nunito-Regular.ttf, Nunito-SemiBold.ttf            nunito, Nunito[wght].ttf, INSTANCED
    Vollkorn-Regular.ttf, Vollkorn-Bold.ttf            vollkorn, Vollkorn[wght].ttf, INSTANCED
    Bitter-Regular.ttf, Bitter-Bold.ttf                bitter, Bitter[wght].ttf, INSTANCED
    Philosopher-Regular.ttf, Philosopher-Bold.ttf      philosopher, static files, unchanged
    FiraSans-Medium.ttf, FiraSans-SemiBold.ttf         firasans, static files, unchanged
    AtkinsonHyperlegible-Regular.ttf, -Bold.ttf        atkinsonhyperlegible, static files, unchanged

    and one license file per family beside them, `<Family>-OFL.txt`: upstream's OFL.txt verbatim,
    an instanced family's with a provenance note above it.

From an archive the author distributes (ARCHIVES below), under the terms the archive carries:

    Prototype-Regular.ttf, Prototype.txt               dafont.com/prototype.font, both unchanged

    Prototype is NOT under the OFL. Its own name table says "Copyright 2001, free for personal use,
    freely distributed with Prototype.txt", and Prototype.txt asks "Please include this Prototype.txt
    file with any redistribution", so it ships byte for byte beside the face, under its own name.
    The owner ruled on 2026-10-30 to ship it on those terms (Ka0sAddonsCommonTasks
    docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/DECISIONS.md, D-01): the addons are free and the face
    is freely distributed with its text. The file is byte-identical to the copy in the owner's
    SharedMedia pack (SHA-256 ce7f544c...).

    Expressway-EULA.pdf, Expressway-EULA-Guide.html    dafont.com/expressway.font, the PDF unchanged,
                                                       the guide with CRLF line endings

From the owner's own SharedMedia pack (LOCALS below), on an owner ruling:

    Expressway-Bold.ttf                                SharedMedia_MyMedia/font/Ka0s Expressway.ttf,
                                                       unchanged

From the add-ons in the owner's WoW install (LOCALS below), on the owner's rulings of 2026-10-31
(Ka0sAddonsCommonTasks docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES, D-02, D-04, D-05), all unchanged:

    SegoeUI-Regular.ttf, -Bold, -Semilight, -Semibold  Sorted/Textures/segoeui, segoeuib, segoeuisl, seguisb
    OpenSans-Regular.ttf, -Bold, -CondBold, -Light,    Sorted/Textures/OpenSans-*
      -Semibold
    FrizQuadrataTT-Regular.ttf                         DialogueUI/Fonts/frizqt__.ttf
    Emblem-Regular.ttf                                 AbstractFramework/Media/Fonts/Emblem.ttf
    DorisPP-Bold.ttf                                   SharedMedia/fonts/doris_pp/DorisPP.ttf
    AvantGarde-Regular.ttf                             EllesmereUI/media/fonts/Avant Garde Naowh.ttf

    OpenSans-Apache-2.0.txt                            the Apache 2.0 text the five faces' name tables
                                                       cite, from the system's common-licenses copy

    Open Sans is Apache 2.0. Segoe UI (Microsoft), Friz Quadrata (ITC), Emblem (Weatherly Systems),
    Doris PP (Ares Software) and Avant Garde (ParaType) carry no license that allows this and ship
    only on those rulings; none has a license file, so `media/fonts/FONTS.md` quotes each notice.
    Friz is taken from DialogueUI because the owner's client Fonts/FRIZQT__.TTF is Prototype's bytes
    (D-01). Emblem is AbstractFramework's 233-glyph copy, over ChonkyCharacterSheet's 232.

EXPRESSWAY SHIPS ON THE OWNER'S RULING, AGAINST ITS TERMS. LK-01 withheld it. The archive dafont.com
serves (https://dl.dafont.com/dl/?f=expressway, fetched 2026-10-30, SHA-256
56574302a007ef70c3e28c1e9b25135e37d85ea6c5245c6c49afdcfc4938db93) holds `expressway rg.otf` (6.100,
SHA-256 4e93119560e815cb27eb3099f824470346163f474ac6344110443f2ffab20bf2, OS/2 fsType 4: preview and
print embedding only) with the Typodermic Desktop EULA 2026 and its quick guide. The guide lists
"Embedding in an app, game, plug-in, program, or software product" as needing another license, and
forbids "Do not give, sell, upload, sublicense, or otherwise share the font software", "Do not
modify, rename, convert ..." and "Do not include the font in open-source or publicly available
software where the font could be redistributed". The free desktop license covers static artwork
only, so a vendored copy in every addon on CurseForge is outside it; the owner's pack copy (Bold,
2.100, Ray Larabie) says "(c) 2005 Typodermic. Do not distribute." in its own name table.

The owner was shown that evidence and ruled on 2026-10-30: "Ship it anyways." (Ka0sAddonsCommonTasks
docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/plan-data/ADDENDUM-01.md, item LK-A1.) That ruling
overrides the EULA finding above, and it is the only ground the face ships on. What ships is the
pack's Bold 2.100, the face the owner's client already draws (SHA-256 06a21061...), not the archive's
Regular 6.100: it is the cut the owner chose from, and the sizes are measured on it. The archive's
EULA and its quick guide ship beside it as the record of the terms the ruling overrode; the font
file itself is not taken from the archive. The pack's key, "Ka0s Expressway", is the LSM key, so a
stored pick keeps resolving to the same bytes. Its cmap has the whole Russian alphabet.

WHY INSTANCED. Upstream publishes three of the families as variable fonts only, and the WoW client is
not known to honor a variable axis, so a variable file would draw its default instance whatever
weight was asked for (Bitter's and Nunito's default is their thinnest). `fontTools.varLib.instancer`
pins each axis (weight) and drops the variation
tables, which gives a static face; the name table is then rewritten to name the weight, so the file
does not claim to be the instance it was cut from. The OFL allows a modified version under the same
license. None of the three reserves its family name (Bitter reserves only "Bitter Pro"), so the
names stay. Fira Sans, Philosopher, Atkinson, Prototype and Expressway are copied unchanged: Fira reserves its
name, so its bytes are never instanced or renamed.

WHY THESE: the owner's round-5 notes of 2026-10-28 (Ka0sAddonsCommonTasks
docs/2026-10-28-SKIN_ROUND5/): every skin has a face of its own, its titles in the same family as
its body. Nunito is Glass's (rounded, as its
corners are), Vollkorn Azeroth's (a dark old-style book face for the parchment), Bitter Ember's (a
sturdy slab), Philosopher WoW Midnight's, Fira Sans WoW Forever's (Medium for body text since the
owner's 2026-10-30 notes, SemiBold for titles and HUD) and Atkinson Hyperlegible High Contrast's.
Ka0s Default draws Prototype and Obsidian Expressway (2026-10-30), WoW Default the client's Friz
Quadrata. On 2026-10-31 the owner moved WoW Midnight to Segoe UI, Azeroth to Open Sans, Ember to
Emblem, High Contrast to Doris PP, Glass to Avant Garde and WoW Default to the shipped Friz, and ruled
that every older face stays in the payload whether or not a skin names it. Barlow and Cinzel, the
2026-10-25 run's faces, left the payload in round 5; Oxanium, Ka0s
Default's stand-in for Prototype from 2026-10-28, Fira Sans Regular, and Inter, Obsidian's from round
5 until Expressway, left on 2026-10-30 (Media minor 10), no skin naming them any more. Atkinson,
Prototype, Friz, Emblem and Doris PP have no Cyrillic; the other families cover it, so Media.lua
registers them for ruRU too.

Requires Python 3 and fontTools (`sudo apt install python3-fonttools`; see DEPENDENCIES.md), and
network access for --fetch, and for every LOCALS face the owner's files at the path it records (on
any other machine, place those files in the cache by hand; each SHA-256 is checked either way). Run it with
`-I`: the cache holds other people's files. An archive is read with `zipfile` and only the members
named below are taken out, by name, so nothing in it runs and no path inside it is written.
"""

import argparse
import hashlib
import os
import shutil
import sys
import urllib.request
import zipfile

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
            # WoW Forever's body face (2026-10-30), from the same commit and build (4.203) as SemiBold.
            "FiraSans-Medium.ttf": "cbc1842cbed8c1d1146ba7c9db97d8f28c9bedfd25f41c5b0e1259ca48622328",
            "FiraSans-SemiBold.ttf": "db0321f83eb3e9f527b8af384a1b3fefdc1039cf2b06fd39b3f61492bda9561c",
            "OFL.txt": "8f24842e9174beda18a556c2ae7d54f5dc444340c19a3a9ef77e23bca366adbd",
        },
        "license": "FiraSans-OFL.txt",
        "ship": ["FiraSans-Medium.ttf", "FiraSans-SemiBold.ttf"],
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
]

# FACES FROM AN AUTHOR'S ARCHIVE, not under the OFL, each on a recorded owner ruling. `zip` is the
# archive's SHA-256 as fetched on the day it was added; `members` pins every file taken out of it;
# `ship` maps a member to the name it ships under, unchanged. `license` is the member that records
# the face's terms, shipped beside it verbatim. A changed archive whose members still match is only
# reported (dafont repacks archives); a changed member stops the fetch. `crlf` names the text
# members written with CRLF endings (the repo's .gitattributes pins text CRLF, so git would convert
# them anyway); every other member ships byte for byte.
ARCHIVES = [
    {
        # Ka0s Default's face (owner, 2026-10-30, D-01): the squared techno face the owner chose
        # first on 2026-10-28; Oxanium stood in for it until this ruling.
        "dir": "prototype", "family": "Prototype",
        "page": "https://www.dafont.com/prototype.font",
        "url": "https://dl.dafont.com/dl/?f=prototype",
        "zip": "8351910bb4c7500328a1d21a1be7c0c94abe3d82863616cc6da01d8a27e1798a",
        "members": {
            "Prototype.ttf": "ce7f544cfc3f02953f79d065bcd16c8cc0eb041f76fc987ae6adcc3b21005774",
            "Prototype.txt": "6f686cd8bda034cdcfe56d0f9a320f7303478027324cc68a610197b7533a924a",
        },
        "ship": {"Prototype.ttf": "Prototype-Regular.ttf", "Prototype.txt": "Prototype.txt"},
        "license": "Prototype.txt",
        "terms": "free for personal use, freely distributed with Prototype.txt",
    },
    {
        # Obsidian's face's terms (LK-A1): only the EULA and its guide are taken out. The archive's
        # `expressway rg.otf` (6.100, 4e931195...) is pinned so a changed archive is noticed, and
        # does NOT ship; the face is the owner's pack Bold (LOCALS).
        "dir": "expressway", "family": "Expressway",
        "page": "https://www.dafont.com/expressway.font",
        "url": "https://dl.dafont.com/dl/?f=expressway",
        "zip": "56574302a007ef70c3e28c1e9b25135e37d85ea6c5245c6c49afdcfc4938db93",
        "members": {
            "expressway rg.otf": "4e93119560e815cb27eb3099f824470346163f474ac6344110443f2ffab20bf2",
            "Typodermic Desktop EULA 2026.pdf":
                "e8d2e3e891a3454740e3dd9e75825878640a6cee8016f4d4ef71ab5c97774f08",
            "read-this.html": "646f854d98505f98d4b1691a6e6a95fc165db85d1e100bcc7fd2987fb9ab3424",
        },
        "ship": {"Typodermic Desktop EULA 2026.pdf": "Expressway-EULA.pdf",
                 "read-this.html": "Expressway-EULA-Guide.html"},
        "crlf": ["read-this.html"],
        "license": "Expressway-EULA.pdf",
        "terms": "the owner's ruling of 2026-10-30, \"Ship it anyways.\", over the Typodermic Desktop EULA",
    },
]

# FACES FROM THE OWNER'S OWN FILES, on a recorded owner ruling: `path` is where the owner's copy sits,
# `sha` pins its bytes, and `ship` is the name it ships under, unchanged. --fetch copies it into the
# cache when the path exists; --build reads only the cache, so the pin is checked either way. A
# `crlf` entry is a text file, written with CRLF endings the way _write_text_crlf says.
ADDONS = "/mnt/g/Games/Blizzard/World of Warcraft/_retail_/Interface/AddOns/"
LOCALS = [
    {
        # Obsidian's face (owner, 2026-10-30, "Ship it anyways."; LK-A1): Expressway Rg Bold 2.100,
        # Ray Larabie, the file the owner's SharedMedia pack registers as "Ka0s Expressway".
        "dir": "expressway", "family": "Expressway",
        "path": "/mnt/g/Games/Blizzard/World of Warcraft/_retail_/Interface/AddOns/"
                "SharedMedia_MyMedia/font/Ka0s Expressway.ttf",
        "name": "Ka0s Expressway.ttf",
        "sha": "06a2106170c2b5b736955cc749ed755f3757d103230645158f0bd5b5b91c386b",
        "ship": "Expressway-Bold.ttf",
        "license": "Expressway-EULA.pdf",
    },
    {
        "dir": "segoeui", "family": "Segoe UI",
        "path": ADDONS + "Sorted/Textures/segoeui.ttf",
        "name": "segoeui.ttf",
        "sha": "ba32a222b23d727267cf1aba4e5296fe84ce99b9d910915103fc085d7931bc88",
        "ship": "SegoeUI-Regular.ttf",
        "license": "FONTS.md",
    },
    {
        "dir": "segoeui", "family": "Segoe UI",
        "path": ADDONS + "Sorted/Textures/segoeuib.ttf",
        "name": "segoeuib.ttf",
        "sha": "1b242874a2f57529060e770ba313e027a99d40b3c36e1c7e8b2dece16ad6ed88",
        "ship": "SegoeUI-Bold.ttf",
        "license": "FONTS.md",
    },
    {
        "dir": "segoeui", "family": "Segoe UI",
        "path": ADDONS + "Sorted/Textures/segoeuisl.ttf",
        "name": "segoeuisl.ttf",
        "sha": "38a85c09ee4fc558e7739ebdd1a15a06e2846ebb787cf73b1b6476a3a5b22000",
        "ship": "SegoeUI-Semilight.ttf",
        "license": "FONTS.md",
    },
    {
        "dir": "segoeui", "family": "Segoe UI",
        "path": ADDONS + "Sorted/Textures/seguisb.ttf",
        "name": "seguisb.ttf",
        "sha": "9853283466bd43993b9813215281fb9c7090cbd8e9b5453f6d0d040622e117e2",
        "ship": "SegoeUI-Semibold.ttf",
        "license": "FONTS.md",
    },
    {
        "dir": "opensans", "family": "Open Sans",
        "path": ADDONS + "Sorted/Textures/OpenSans-Regular.ttf",
        "name": "OpenSans-Regular.ttf",
        "sha": "e64e508b2aa2880f907e470c4550980ec4c0694d103a43f36150ac3f93189bee",
        "ship": "OpenSans-Regular.ttf",
        "license": "OpenSans-Apache-2.0.txt",
    },
    {
        "dir": "opensans", "family": "Open Sans",
        "path": ADDONS + "Sorted/Textures/OpenSans-Bold.ttf",
        "name": "OpenSans-Bold.ttf",
        "sha": "5894a3649b213cf5b2d673b6e7a871815fd1d120fa68a463592f27db14eae323",
        "ship": "OpenSans-Bold.ttf",
        "license": "OpenSans-Apache-2.0.txt",
    },
    {
        "dir": "opensans", "family": "Open Sans",
        "path": ADDONS + "Sorted/Textures/OpenSans-CondBold.ttf",
        "name": "OpenSans-CondBold.ttf",
        "sha": "a859a438018739aee16c306586d91a453c208ee500c827d9e9aa063155c8a6e8",
        "ship": "OpenSans-CondBold.ttf",
        "license": "OpenSans-Apache-2.0.txt",
    },
    {
        "dir": "opensans", "family": "Open Sans",
        "path": ADDONS + "Sorted/Textures/OpenSans-Light.ttf",
        "name": "OpenSans-Light.ttf",
        "sha": "cf5f5184c1441a1660aa52526328e9d5c2793e77b6d8d3a3ad654bdb07ab8424",
        "ship": "OpenSans-Light.ttf",
        "license": "OpenSans-Apache-2.0.txt",
    },
    {
        "dir": "opensans", "family": "Open Sans",
        "path": ADDONS + "Sorted/Textures/OpenSans-Semibold.ttf",
        "name": "OpenSans-Semibold.ttf",
        "sha": "aa3b0ef53db12e3d45094030cac0e69d384e44cc5978643dd4390041cad546e2",
        "ship": "OpenSans-Semibold.ttf",
        "license": "OpenSans-Apache-2.0.txt",
    },
    {
        "dir": "friz", "family": "Friz Quadrata TT",
        "path": ADDONS + "DialogueUI/Fonts/frizqt__.ttf",
        "name": "frizqt__.ttf",
        "sha": "73de74d5d63690f29c7f97a9225edc8bd6f89e5103806af3714e4d7bfb9474e9",
        "ship": "FrizQuadrataTT-Regular.ttf",
        "license": "FONTS.md",
    },
    {
        "dir": "emblem", "family": "Emblem",
        "path": ADDONS + "AbstractFramework/Media/Fonts/Emblem.ttf",
        "name": "Emblem.ttf",
        "sha": "f7aba56028f0376ad6ad8f157f33f9ed26b33f512f1b5786754f45e8b6d3ff96",
        "ship": "Emblem-Regular.ttf",
        "license": "FONTS.md",
    },
    {
        "dir": "doris", "family": "Doris PP",
        "path": ADDONS + "SharedMedia/fonts/doris_pp/DorisPP.ttf",
        "name": "DorisPP.ttf",
        "sha": "6b1ebf2f4a879c5236d566b97b0b807c78c7588fc2e3043db6ab7f8c3d8f019c",
        "ship": "DorisPP-Bold.ttf",
        "license": "FONTS.md",
    },
    {
        "dir": "avantgarde", "family": "Avant Garde",
        "path": ADDONS + "EllesmereUI/media/fonts/Avant Garde Naowh.ttf",
        "name": "Avant Garde Naowh.ttf",
        "sha": "d4845c139f83cab952edf1b73b7a1b20ca7024c506b218a9c5a089a27d4991b6",
        "ship": "AvantGarde-Regular.ttf",
        "license": "FONTS.md",
    },
    {
        # The Apache 2.0 text (the same bytes apache.org serves as LICENSE-2.0.txt), which Open Sans's
        # name tables cite and which `Sorted/` does not carry.
        "dir": "opensans", "family": "Open Sans",
        "path": "/usr/share/common-licenses/Apache-2.0",
        "name": "Apache-2.0",
        "sha": "cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30",
        "ship": "OpenSans-Apache-2.0.txt",
        "crlf": True,
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
    for archive in ARCHIVES:
        fetch_archive(archive)
    for local in LOCALS:
        fetch_local(local)
    return 0


def fetch_local(local):
    os.makedirs(os.path.join(CACHE, local["dir"]), exist_ok=True)
    dest = _cached(local, local["name"])
    if os.path.isfile(dest) and _sha256(dest) == local["sha"]:
        _say("  cached  %s/%s" % (local["dir"], local["name"]))
        return
    if not os.path.isfile(local["path"]):
        raise SystemExit("%s: not found; copy the file to %s by hand" % (local["path"], dest))
    shutil.copyfile(local["path"], dest)
    got = _sha256(dest)
    if got != local["sha"]:
        os.remove(dest)
        raise SystemExit("%s: SHA-256 %s, expected %s" % (local["path"], got, local["sha"]))
    _say("  copied  %s/%s from %s" % (local["dir"], local["name"], local["path"]))


def _archive_path(archive):
    return os.path.join(CACHE, archive["dir"], archive["dir"] + ".zip")


def _member_bytes(archive, name):
    """One named member's bytes, read out of the cached archive without extracting anything."""
    with zipfile.ZipFile(_archive_path(archive)) as zf:
        return zf.read(name)


def _archive_ok(archive):
    path = _archive_path(archive)
    if not os.path.isfile(path):
        return False
    for name, want in archive["members"].items():
        try:
            got = hashlib.sha256(_member_bytes(archive, name)).hexdigest()
        except (KeyError, zipfile.BadZipFile):
            return False
        if got != want:
            return False
    return True


def fetch_archive(archive):
    os.makedirs(os.path.join(CACHE, archive["dir"]), exist_ok=True)
    path = _archive_path(archive)
    if _archive_ok(archive):
        _say("  cached  %s" % os.path.relpath(path, CACHE))
        return
    req = urllib.request.Request(archive["url"], headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=60) as resp, open(path, "wb") as out:
        shutil.copyfileobj(resp, out)
    if not _archive_ok(archive):
        os.remove(path)
        raise SystemExit("%s: a member's SHA-256 differs from the pinned one" % archive["url"])
    got = _sha256(path)
    if got != archive["zip"]:
        _say("  note    %s repacked (SHA-256 %s); every member still matches" % (archive["url"], got))
    _say("  fetched %s" % os.path.relpath(path, CACHE))


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
    for archive in ARCHIVES:
        if not _archive_ok(archive):
            raise SystemExit("missing or changed %s (run --fetch)" % _archive_path(archive))
        for member, out in archive["ship"].items():
            body = _member_bytes(archive, member)
            if member in archive.get("crlf", ()):
                _write_text_crlf(body.decode("utf-8"), os.path.join(OUT, out))
            else:
                with open(os.path.join(OUT, out), "wb") as fh:
                    fh.write(body)
            _say("  copied  %s (from %s)" % (out, archive["page"]))
    for local in LOCALS:
        path = _cached(local, local["name"])
        if not os.path.isfile(path) or _sha256(path) != local["sha"]:
            raise SystemExit("missing or changed %s (run --fetch)" % path)
        if local.get("crlf"):
            with open(path, "r", encoding="utf-8") as fh:
                _write_text_crlf(fh.read(), os.path.join(OUT, local["ship"]))
        else:
            shutil.copyfile(path, os.path.join(OUT, local["ship"]))
        _say("  copied  %s (from %s)" % (local["ship"], local["name"]))
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
