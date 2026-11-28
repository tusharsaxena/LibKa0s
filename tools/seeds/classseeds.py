#!/usr/bin/env python3
"""tools/seeds/classseeds.py -- re-validate LibKa0s-Verdict-1.0's class lists against a wago.tools build.

WHAT THIS IS
    LibKa0s/VerdictClassData.lua hand-curates one class list per client (clients-5): the class
    ids, the armor each class's loot comes in, the weapon subclasses it can use, its specs (Retail)
    or talent trees (Forever), and on Forever the relic and the level-40 armor switch.
    LibKa0s/VerdictFacts.lua names the item classes that are gear (IR.GEAR_CLASSES). None of it
    turns red when a patch moves it. This tool re-checks every one of those rows against ONE pinned
    build of the client's own DB2 data on wago.tools (clients-10: product `wow` for Retail, `wowf`
    for Forever, never one filtered from the other) and turns what it finds into CANDIDATES and
    FLAGS, each of which needs a ruling recorded as data. A ruling is keyed by what it ruled on,
    never by build, so a re-run on a later build shows only what is new.

    Its flavors are `retail-classes` and `forever-classes`. The kit's client name sets are
    tools/seeds/libseeds.py's `retail` and `forever`, a different source (Ketho's branches), with
    their own rulings files and bundles; the two tools import nothing from each other.

    Candidates (key `<group>:<subject>`, ruled accept or reject):
        weapon:<CLASS>:<SUB>   the build grants the class the weapon skill line of a subclass its
                               WEAPONS set lacks (SkillRaceClassInfo). `apply` inserts an accepted one.
        class:<CLASS>          a playable class of the build that CLASS_ID lacks        (hand)
        spec:<id>              Retail: a class's spec (ChrSpecialization) SPECS lacks    (hand)
        tree:<CLASS>:<n>       Forever: a class's talent tree (TalentTab) SPECS lacks    (hand)
        titanGrip:<id>         Retail: a spec the build gives Titan's Grip, unflagged    (hand)
        relic:<CLASS>          Forever: a class whose ArmorTypeMask has a relic, RELIC lacks (hand)
        dualWield:<CLASS>      Forever: a class with the Dual Wield skill, no tree flagged D (hand)
        armorEarly:<CLASS>     Forever: a class whose armor switches at a level, not in ARMOR_EARLY (hand)
    A `hand` candidate is never written by the tool: once accepted, `apply` refuses until the file
    carries it by hand and a re-derive (--replay) stops proposing it.

    Flags (key `shipped:<kind>:<subject>`, ruled keep, fix or remove), over every shipped row:
        class-id         the class id is not the build's ChrClasses row for that file token
        armor            ARMOR is not the heaviest armor skill line the class has
        armor-early / armor-level / armor-lower   Forever's level-40 switch and lighter types
        weapon-unlisted  WEAPONS holds a subclass the build grants no skill line for (`remove` is
                         the one flag ruling `apply` writes)
        spec-missing / spec-class / spec-name / spec-index / spec-stat   Retail's spec rows
        tree-missing / tree-name   Forever's talent-tree rows
        titan-grip / shield / dual-wield / relic   a flag the build does not back
        enum             a GEAR_CLASSES id the build's ItemClass does not name Weapon or Armor
    `fix` means a hand edit is owed: `apply` refuses while one is raised, as for a hand candidate.

    What DB2 cannot say is left to the file and the item's own spec list: the loot-relevance rule
    (WEAPONS leaves out a skill no loot of the class's stat drops for, the file's "a warrior's
    bow"), the off-hand flag, Retail's dual wield (spec-granted by passives the skill tables do not
    carry), the Pawn index. The contract, docs/validate-seeds.md, is the procedure and the precedent.

THE STEPS
    python3 tools/seeds/classseeds.py status [--flavor retail-classes|forever-classes]
    python3 tools/seeds/classseeds.py derive --flavor F --bundle docs/seed-research/<date>-F --date <date> [--build V] [--replay]
    python3 tools/seeds/classseeds.py check  --bundle B
    python3 tools/seeds/classseeds.py rule   --tsv <scratch>/rulings.tsv --bundle B
    python3 tools/seeds/classseeds.py report --bundle B --date <date>
    python3 tools/seeds/classseeds.py apply  --bundle B --date <date>

    `derive` pins one build (the live one of the flavor's product, or --build), downloads each table
    once into ${XDG_CACHE_HOME:-~/.cache}/ka0s-seeds/wago/ (outside the checkout, as libseeds.py's
    cache is), freezes the gzipped tables it read into the bundle's raw/ and writes SOURCES.md and
    candidates.json. `--replay` re-derives from raw/ alone, with no network. The rulings live in
    tools/seeds/<flavor>_rulings.json, and `rule` is their only writer. `check` exits 1 while
    anything is unruled. `report` writes RULINGS.md. `apply` refuses while anything is unruled or a
    hand edit is owed, writes only the flavor's WEAPONS set in LibKa0s/VerdictClassData.lua, keeps
    the file's line endings and layout (its indent and a wrapped entry's continuation indent), and a
    second run changes nothing. A changed WEAPONS set is a payload edit: the run that applies one
    bumps the file's CLASSDATA_MINOR (docs/validate-seeds.md). The date is always an argument; the
    tool never reads the clock.

    Ported from Drop Watcher's tools/seeds/seeds.py (LibKa0s#109), the class-list half; the
    Constants fallback literals and the profession names stay with Drop Watcher, whose files they are.

Python 3.8+ and its standard library only.
"""

from __future__ import annotations

import argparse
import csv
import gzip
import json
import os
import re
import shutil
import sys
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
RESEARCH = REPO / "docs" / "seed-research"

BUILDS_URL = "https://wago.tools/api/builds"
CSV_URL = "https://wago.tools/db2/{table}/csv?build={build}"
# wago.tools answers HTTP 403 to urllib's default agent (clients-10): identify the tool.
USER_AGENT = "LibKa0s-seed-check"
DOWNLOAD_CHUNK = 1 << 20
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
NEWLINE = "\r\n"  # .gitattributes pins the working tree CRLF (`* text=auto eol=crlf`)
CACHE = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "ka0s-seeds" / "wago"

# The tables each flavor reads, and why. Only these are frozen into a bundle's raw/.
COMMON_TABLES = (
    ("ChrClasses", "ID and Filename (the class tokens); ArmorTypeMask (armor and relic subclasses)"),
    ("ChrSpecialization", "a class's specs: ID, ClassID, OrderIndex, Name_lang, PrimaryStatPriority"),
    ("SkillLine", "the armor and weapon skill lines' names (the coverage gate)"),
    ("SkillRaceClassInfo", "SkillID x ClassMask (with MinLevel): which class has which proficiency"),
    ("SkillLineAbility", "the proficiency spells per skill line and ClassMask, a second witness"),
    ("ItemClass", "item class ids and names, for IR.GEAR_CLASSES"),
)
# Both lists live in one file; a flavor reads the list its prefix names, and `apply` writes that
# list's WEAPONS block alone.
CLASS_DATA = "LibKa0s/VerdictClassData.lua"
FACTS = "LibKa0s/VerdictFacts.lua"

FLAVORS = {
    "retail-classes": {"client": "retail", "product": "wow", "title": "Retail", "prefix": "RETAIL",
                       "tables": COMMON_TABLES + (
                           ("SpecializationSpells", "SpecID x SpellID: which spec has Titan's Grip"),)},
    "forever-classes": {"client": "forever", "product": "wowf", "title": "WoW Forever", "prefix": "FOREVER",
                        "tables": COMMON_TABLES + (
                            ("TalentTab", "the talent trees per class: ClassMask, OrderIndex, Name_lang"),)},
}

# The armor and weapon skill lines -> (the build's name, the C.ARMOR_SUBCLASS or C.WEAPON_SUBCLASS
# key, the flavors that have the line). A line whose name moved is a SystemExit, not a flag: every
# proficiency verdict rests on this map.
SKILL_LINES = {
    415: ("Cloth", "armor", "CLOTH", ("retail", "forever")),
    414: ("Leather", "armor", "LEATHER", ("retail", "forever")),
    413: ("Mail", "armor", "MAIL", ("retail", "forever")),
    293: ("Plate Mail", "armor", "PLATE", ("retail", "forever")),
    433: ("Shield", "shield", "SHIELD", ("retail", "forever")),
    118: ("Dual Wield", "dualWield", None, ("retail", "forever")),
    44: ("Axes", "weapon", "AXE_1H", ("retail", "forever")),
    172: ("Two-Handed Axes", "weapon", "AXE_2H", ("retail", "forever")),
    45: ("Bows", "weapon", "BOWS", ("retail", "forever")),
    46: ("Guns", "weapon", "GUNS", ("retail", "forever")),
    54: ("Maces", "weapon", "MACE_1H", ("retail", "forever")),
    160: ("Two-Handed Maces", "weapon", "MACE_2H", ("retail", "forever")),
    229: ("Polearms", "weapon", "POLEARM", ("retail", "forever")),
    43: ("Swords", "weapon", "SWORD_1H", ("retail", "forever")),
    55: ("Two-Handed Swords", "weapon", "SWORD_2H", ("retail", "forever")),
    2152: ("Warglaives", "weapon", "WARGLAIVE", ("retail",)),
    136: ("Staves", "weapon", "STAFF", ("retail", "forever")),
    473: ("Fist Weapons", "weapon", "FIST", ("retail", "forever")),
    173: ("Daggers", "weapon", "DAGGER", ("retail", "forever")),
    176: ("Thrown", "weapon", "THROWN", ("forever",)),
    226: ("Crossbows", "weapon", "CROSSBOW", ("retail", "forever")),
    228: ("Wands", "weapon", "WAND", ("retail", "forever")),
}
ARMOR_RANK = {"CLOTH": 1, "LEATHER": 2, "MAIL": 3, "PLATE": 4}
ARMOR_BY_RANK = {v: k for k, v in ARMOR_RANK.items()}
# ChrClasses.ArmorTypeMask bit -> relic subclass (C.ARMOR_SUBCLASS: Libram 7, Idol 8, Totem 9).
RELIC_BITS = {7: "LIBRAM", 8: "IDOL", 9: "TOTEM"}
# Titan's Grip's spell id, read in SpecializationSpells (the tool reads no SpellName, to keep the
# bundle small: a moved id shows as every T flag raised at once).
TITANS_GRIP_SPELL = 46917
# ChrSpecialization.PrimaryStatPriority -> the stat token (inferred from the build: every Retail
# spec row agrees with it on 12.1.5; an unlisted value is a flag, never a guess).
STAT_PRIORITY = {0: "INT", 1: "INT", 2: "AGI", 3: "AGI", 5: "STR"}
# The coverage gate: rows the build must have, chosen from the game, not from this tool's output.
SENTINELS = {"classes": {1: "WARRIOR", 4: "ROGUE", 8: "MAGE"}, "skills": (293, 43, 173, 415)}

HAND_GROUPS = ("class", "spec", "tree", "titanGrip", "relic", "dualWield", "armorEarly")
CANDIDATE_RULINGS = ("accept", "reject")
FLAG_RULINGS = ("keep", "fix", "remove")
REMOVABLE_FLAGS = ("weapon-unlisted",)
KEY_RE = re.compile(r"^(?:shipped:(?P<kind>[a-z-]+):|(?P<group>[A-Za-z]+):)(?P<subject>[A-Za-z0-9_:]+)$")


def log(msg: str) -> None:
    print(msg, file=sys.stderr, flush=True)


def write_repo_text(path: Path, text: str) -> None:
    """Write a text file with CRLF terminators, as bytes (the repo is pinned eol=crlf)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.replace("\r\n", "\n").replace("\n", NEWLINE).encode("utf-8"))


def write_json(path: Path, doc) -> None:
    write_repo_text(path, json.dumps(doc, indent=1, sort_keys=True, ensure_ascii=False) + "\n")


# ---------------------------------------------------------------------------
# wago.tools: the build pin, the cache, the bundle's raw/
# ---------------------------------------------------------------------------

def http_get(url: str, accept: str = "*/*"):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": accept})
    try:
        return urllib.request.urlopen(req, timeout=300)
    except urllib.error.HTTPError as err:
        raise SystemExit("HTTP %s fetching %s: %s" % (err.code, url, err.reason))
    except urllib.error.URLError as err:
        raise SystemExit("Could not reach %s: %s (a new run needs network access)" % (url, err.reason))


def live_build(product: str) -> str:
    """The newest build of `product` on the builds API (newest first per product)."""
    data = json.load(http_get(BUILDS_URL, accept="application/json"))
    builds = data.get(product) or []
    if not builds:
        raise SystemExit("The builds API lists no '%s' build; pass --build." % product)
    return builds[0]["version"]


def fetch_table(table: str, build: str, cache_dir: Path) -> tuple[Path, str]:
    """`(cached CSV, provenance)`: the table of `build`, streamed into the cache once. Always with
    `?build=`: without it the site serves the PTR (clients-§10)."""
    cache_dir.mkdir(parents=True, exist_ok=True)
    dest = cache_dir / ("%s-%s.csv" % (table, build))
    if dest.exists():
        return dest, "cache"
    url = CSV_URL.format(table=table, build=build)
    tmp = dest.with_suffix(".csv.part")
    log("  %-22s fetching %s" % (table, url))
    with http_get(url, accept="text/csv") as response, tmp.open("wb") as handle:
        served = response.headers.get("Date", "")
        shutil.copyfileobj(response, handle, DOWNLOAD_CHUNK)
    tmp.replace(dest)
    return dest, served


def freeze(source: Path, member: Path) -> None:
    """Gzip `source` into the bundle's raw/ (mtime 0, so a re-freeze of one build is byte-stable)."""
    member.parent.mkdir(parents=True, exist_ok=True)
    with source.open("rb") as src, member.open("wb") as raw:
        with gzip.GzipFile(filename="", mode="wb", fileobj=raw, compresslevel=9, mtime=0) as dst:
            shutil.copyfileobj(src, dst, DOWNLOAD_CHUNK)


def iter_csv(path: Path):
    """Each row as a dict, streamed (gzip or plain); columns are read by header name."""
    if path.suffix == ".gz":
        with gzip.open(path, "rt", encoding="utf-8", newline="") as handle:
            yield from csv.DictReader(handle)
        return
    with path.open("r", encoding="utf-8", newline="") as handle:
        yield from csv.DictReader(handle)


def as_int(value) -> int:
    try:
        return int(value or 0)
    except ValueError:
        return int(float(value))


# ---------------------------------------------------------------------------
# The build's facts
# ---------------------------------------------------------------------------

class Build:
    """What one build says, read from `{table: path}`."""

    def __init__(self, paths: dict[str, Path], flavor: str):
        self.flavor = flavor
        self.classes = {}       # id -> Filename
        self.armor_mask = {}    # Filename -> ArmorTypeMask
        for r in iter_csv(paths["ChrClasses"]):
            self.classes[as_int(r["ID"])] = r["Filename"]
            self.armor_mask[r["Filename"]] = as_int(r["ArmorTypeMask"])
        self.class_id = {f: i for i, f in self.classes.items()}
        self.specs = {}         # spec id -> {class, order, name, prio}
        for r in iter_csv(paths["ChrSpecialization"]):
            cid = as_int(r["ClassID"])
            if cid in self.classes:
                self.specs[as_int(r["ID"])] = {"class": self.classes[cid], "order": as_int(r["OrderIndex"]),
                                               "name": r["Name_lang"], "prio": as_int(r["PrimaryStatPriority"])}
        self.skill_names = {as_int(r["ID"]): r["DisplayName_lang"] for r in iter_csv(paths["SkillLine"])}
        self.proficiency = {}   # skill -> {Filename: min MinLevel}; rows with no race are skipped
        for r in iter_csv(paths["SkillRaceClassInfo"]):
            skill = as_int(r["SkillID"])
            if skill not in SKILL_LINES:
                continue
            if as_int(r.get("RaceMasks_0")) == 0 and as_int(r.get("RaceMasks_1")) == 0:
                continue
            for cls in self.classes_of(as_int(r["ClassMask"])):
                have = self.proficiency.setdefault(skill, {})
                level = as_int(r["MinLevel"])
                have[cls] = min(level, have.get(cls, level))
        self.witness = {}       # skill -> {Filename} from SkillLineAbility's proficiency spells
        for r in iter_csv(paths["SkillLineAbility"]):
            skill = as_int(r["SkillLine"])
            if skill in SKILL_LINES and as_int(r["ClassMask"]):
                self.witness.setdefault(skill, set()).update(self.classes_of(as_int(r["ClassMask"])))
        self.item_class = {as_int(r["ClassID"]): r["ClassName_lang"] for r in iter_csv(paths["ItemClass"])}
        self.titan_grip = set()
        if "SpecializationSpells" in paths:
            self.titan_grip = {as_int(r["SpecID"]) for r in iter_csv(paths["SpecializationSpells"])
                               if as_int(r["SpellID"]) == TITANS_GRIP_SPELL}
        self.trees = {}         # (Filename, tree) -> name
        if "TalentTab" in paths:
            for r in iter_csv(paths["TalentTab"]):
                owners = self.classes_of(as_int(r["ClassMask"]))
                if len(owners) == 1:
                    self.trees[(owners[0], as_int(r["OrderIndex"]) + 1)] = r["Name_lang"]

    def classes_of(self, mask: int) -> list[str]:
        """The class tokens of a ClassMask (bit classID-1); -1 and other negatives are 32-bit."""
        mask &= 0xFFFFFFFF
        return [f for i, f in sorted(self.classes.items()) if i >= 1 and mask >> (i - 1) & 1]

    def has(self, skill: int, cls: str) -> bool:
        return cls in self.proficiency.get(skill, {})

    def playable(self) -> set[str]:
        """Classes with a real spec: Retail's OrderIndex 0-3 (not an `Initial` or Adventurer row),
        Forever's one class-wide spec row."""
        return {s["class"] for s in self.specs.values() if 0 <= s["order"] <= 3}


def check_sentinels(build: Build, flavor: str, sentinels=SENTINELS) -> None:
    """The coverage gate. A failure is a SystemExit: the pipeline needs fixing, not the rulings."""
    missing = ["class %d %s" % (cid, f) for cid, f in sentinels["classes"].items()
               if build.classes.get(cid) != f]
    for skill in sentinels["skills"]:
        if not build.proficiency.get(skill):
            missing.append("skill line %d has no SkillRaceClassInfo row" % skill)
    for skill, (name, _k, _t, flavors) in SKILL_LINES.items():
        have = build.skill_names.get(skill)
        if flavor in flavors and have is not None and have != name:
            missing.append("skill line %d is %r, the map says %r" % (skill, have, name))
    if missing:
        raise SystemExit("Coverage gate FAILED: %s. Fix the tool before ruling anything." % "; ".join(missing))


# ---------------------------------------------------------------------------
# The seed files
# ---------------------------------------------------------------------------

def lua_block(text: str, opener: str) -> tuple[int, int] | None:
    """`(start, end)` of the body between the `{` that ends `opener` and its matching `}`; a
    `--` comment and a string are skipped while matching."""
    at = text.find(opener)
    if at < 0:
        return None
    i = at + len(opener)
    start, depth = i, 1
    while i < len(text):
        c = text[i]
        if text.startswith("--", i):
            nl = text.find("\n", i)
            i = len(text) if nl < 0 else nl
            continue
        if c in "\"'":
            j = i + 1
            while j < len(text) and text[j] != c:
                j += 2 if text[j] == "\\" else 1
            i = j + 1
            continue
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return start, i
        i += 1
    raise SystemExit("Unbalanced braces after %r" % opener)


def block(text: str, opener: str) -> str:
    span = lua_block(text, opener)
    return text[span[0]:span[1]] if span else ""


def comment_name(comment: str | None) -> str:
    """The name a row's comment gives: the text before a `:` or a `(`."""
    return re.split(r"[:(]", comment or "", maxsplit=1)[0].strip()


SPEC_RE = re.compile(r'^\s*\[(\d+)\]\s*=\s*spec\("(\w+)",\s*(STR|AGI|INT)(?:,\s*"([A-Z]*)")?\),?\s*(?:--\s*(.*?))?\s*$')
TREE_RE = re.compile(r'^\s*\["(\w+):(\d+)"\]\s*=\s*tree\("(\w+)",\s*(\d+),\s*(STR|AGI|INT)'
                     r'(?:,\s*(?:"([A-Z]*)"|nil))?[^)]*\),?\s*(?:--\s*(.*?))?\s*$')


def read_class_data(path: Path, prefix: str) -> dict:
    """The list's rows: CLASS_ID, ARMOR, ARMOR_EARLY, RELIC, WEAPONS, SPECS, SPEC_INDEX and the
    list's own flags (ARMOR_LEVEL, ARMOR_LOWER_OK)."""
    text = path.read_bytes().decode("utf-8").replace("\r\n", "\n")
    head = re.search(r"local %s = \{([^}]*)\}" % prefix, text)
    if not head:
        raise SystemExit("%s: no `local %s = { ... }` list." % (path, prefix))
    level = re.search(r"ARMOR_LEVEL\s*=\s*(\d+)", head.group(1))
    out = {"ARMOR_LEVEL": int(level.group(1)) if level else None,
           "ARMOR_LOWER_OK": "ARMOR_LOWER_OK = true" in head.group(1)}
    out["CLASS_ID"] = {k: int(v) for k, v in re.findall(r"(\w+)\s*=\s*(\d+)", block(text, prefix + ".CLASS_ID = {"))}
    for name in ("ARMOR", "ARMOR_EARLY", "RELIC"):
        out[name] = dict(re.findall(r"(\w+)\s*=\s*A\.(\w+)", block(text, "%s.%s = {" % (prefix, name))))
    out["WEAPONS"] = {k: re.findall(r"W\.(\w+)", v) for k, v in
                      re.findall(r"(\w+)\s*=\s*set\(([^)]*)\)", block(text, prefix + ".WEAPONS = {"))}
    specs = {}
    for line in block(text, prefix + ".SPECS = {").split("\n"):
        m = SPEC_RE.match(line)
        if m:
            specs[int(m.group(1))] = {"class": m.group(2), "stat": m.group(3), "flags": m.group(4) or "",
                                      "comment": m.group(5) or ""}
            continue
        m = TREE_RE.match(line)
        if m:
            specs["%s:%s" % (m.group(1), m.group(2))] = {
                "class": m.group(3), "tree": int(m.group(4)), "stat": m.group(5), "flags": m.group(6) or "",
                "comment": m.group(7) or ""}
    out["SPECS"] = specs
    out["SPEC_INDEX"] = {int(k): int(v) for k, v in re.findall(r"\[(\d+)\]\s*=\s*(\d+)", block(text, prefix + ".SPEC_INDEX = {"))}
    if not out["CLASS_ID"] or not out["WEAPONS"] or not specs:
        raise SystemExit("%s: CLASS_ID, WEAPONS or SPECS did not parse; the tool and the file disagree." % path)
    return out


def read_gear_classes(facts: Path) -> list[int]:
    """IR.GEAR_CLASSES' item class ids, in file order."""
    text = facts.read_bytes().decode("utf-8")
    out = [int(v) for v in re.findall(r"\[(\d+)\]\s*=\s*true", block(text, "IR.GEAR_CLASSES = {"))]
    if not out:
        raise SystemExit("%s: IR.GEAR_CLASSES did not parse; the tool and the file disagree." % facts)
    return out


# ---------------------------------------------------------------------------
# Candidates and flags
# ---------------------------------------------------------------------------

class Findings:
    def __init__(self):
        self.candidates: list[dict] = []
        self.flags: list[dict] = []

    def candidate(self, group: str, subject: str, name: str, notes, **extra) -> None:
        row = {"key": "%s:%s" % (group, subject), "group": group, "subject": subject, "name": name,
               "notes": list(notes), "apply": "weapons" if group == "weapon" else "hand"}
        row.update(extra)
        self.candidates.append(row)

    def flag(self, kind: str, subject: str, shipped: str, build: str, notes=()) -> None:
        self.flags.append({"key": "shipped:%s:%s" % (kind, subject), "kind": kind, "subject": subject,
                           "shipped": shipped, "build": build, "notes": list(notes)})


def skill_of(token: str, flavor: str) -> int | None:
    for skill, (_n, kind, tok, flavors) in SKILL_LINES.items():
        if tok == token and kind in ("weapon", "armor", "shield") and flavor in flavors:
            return skill
    return None


def check_classes(seed: dict, db: Build, out: Findings) -> None:
    for cls, cid in sorted(seed["CLASS_ID"].items()):
        if db.classes.get(cid) != cls:
            out.flag("class-id", cls, str(cid), "%s is %s" % (cid, db.classes.get(cid) or "absent"),
                     ["the build's %s is %s" % (cls, db.class_id.get(cls, "absent"))])
    for cls in sorted(db.playable() - set(seed["CLASS_ID"])):
        out.candidate("class", cls, cls, ["ChrClasses %d" % db.class_id[cls]])


def check_armor(seed: dict, db: Build, flavor: str, out: Findings) -> None:
    for cls in sorted(seed["CLASS_ID"]):
        have = {tok: db.proficiency[s][cls] for s, (_n, k, tok, _f) in SKILL_LINES.items()
                if k == "armor" and db.has(s, cls)}
        if not have:
            out.flag("armor", cls, seed["ARMOR"].get(cls, "none"), "no armor skill line")
            continue
        top = ARMOR_BY_RANK[max(ARMOR_RANK[t] for t in have)]
        mask = db.armor_mask.get(cls, 0)
        mask_top = [ARMOR_BY_RANK[r] for r in (4, 3, 2, 1) if mask >> r & 1][:1]
        notes = ["SkillRaceClassInfo: %s" % ", ".join("%s%s" % (t, " from %d" % lv if lv > 1 else "")
                                                     for t, lv in sorted(have.items(), key=lambda x: ARMOR_RANK[x[0]])),
                 "ArmorTypeMask %d (heaviest %s)" % (mask, mask_top[0] if mask_top else "none")]
        if seed["ARMOR"].get(cls) != top or (mask_top and mask_top[0] != top):
            out.flag("armor", cls, seed["ARMOR"].get(cls, "none"), top, notes)
        if flavor != "forever":
            continue
        switch = have[top] if have[top] > 1 else 0
        early = ARMOR_BY_RANK[max(ARMOR_RANK[t] for t, lv in have.items() if lv < switch)] if switch else None
        listed = seed["ARMOR_EARLY"].get(cls)
        if switch and switch != seed["ARMOR_LEVEL"]:
            out.flag("armor-level", cls, str(seed["ARMOR_LEVEL"]), str(switch), notes)
        if listed and listed != early:
            out.flag("armor-early", cls, listed, early or "no switch", notes)
        elif early and not listed:
            out.candidate("armorEarly", cls, "%s below %d" % (early, switch), notes)
        if seed["ARMOR_LOWER_OK"]:
            lighter = [t for t, r in ARMOR_RANK.items() if r < ARMOR_RANK[top] and t not in have]
            if lighter:
                out.flag("armor-lower", cls, "lighter types wearable", "no %s line" % "/".join(lighter), notes)


def weapon_notes(db: Build, skill: int, cls: str) -> list[str]:
    level = db.proficiency.get(skill, {}).get(cls)
    notes = ["SkillRaceClassInfo %d %s%s" % (skill, db.skill_names.get(skill, "?"),
                                               " from level %d" % level if level and level > 1 else "")]
    notes.append("SkillLineAbility %s" % ("agrees" if cls in db.witness.get(skill, ()) else "has no row for the class"))
    return notes


def check_weapons(seed: dict, db: Build, flavor: str, out: Findings) -> None:
    for cls in sorted(seed["CLASS_ID"]):
        shipped = set(seed["WEAPONS"].get(cls, ()))
        for skill, (_n, kind, tok, flavors) in sorted(SKILL_LINES.items(), key=lambda x: x[1][2] or ""):
            if kind != "weapon" or flavor not in flavors:
                continue
            if db.has(skill, cls) and tok not in shipped:
                out.candidate("weapon", "%s:%s" % (cls, tok), "%s %s" % (cls, tok), weapon_notes(db, skill, cls),
                              cls=cls, token=tok)
        for tok in sorted(shipped):
            skill = skill_of(tok, flavor)
            if skill is None or not db.has(skill, cls):
                out.flag("weapon-unlisted", "%s:%s" % (cls, tok), tok, "no skill line",
                         weapon_notes(db, skill, cls) if skill else ["no %s skill line on this client" % tok])


def check_specs_retail(seed: dict, db: Build, out: Findings) -> None:
    shield = SKILL_LINE_ID("Shield")
    for sid, row in sorted(seed["SPECS"].items()):
        have = db.specs.get(sid)
        if not have:
            out.flag("spec-missing", str(sid), row["comment"], "absent")
            continue
        if have["class"] != row["class"]:
            out.flag("spec-class", str(sid), row["class"], have["class"])
        if comment_name(row["comment"]) != have["name"]:
            out.flag("spec-name", str(sid), row["comment"], have["name"])
        index = seed["SPEC_INDEX"].get(sid)
        if index != have["order"] + 1:
            out.flag("spec-index", str(sid), str(index), str(have["order"] + 1), ["ChrSpecialization.OrderIndex %d" % have["order"]])
        stat = STAT_PRIORITY.get(have["prio"])
        if stat != row["stat"]:
            out.flag("spec-stat", str(sid), row["stat"], stat or "PrimaryStatPriority %d" % have["prio"])
        if ("T" in row["flags"]) != (sid in db.titan_grip):
            if "T" in row["flags"]:
                out.flag("titan-grip", str(sid), "T", "no Titan's Grip (%d)" % TITANS_GRIP_SPELL)
            else:
                out.candidate("titanGrip", str(sid), "%s %s" % (have["name"], row["class"]),
                              ["SpecializationSpells %d" % TITANS_GRIP_SPELL])
        if "S" in row["flags"] and not db.has(shield, row["class"]):
            out.flag("shield", str(sid), "S", "no Shield skill line")
    for sid, have in sorted(db.specs.items()):
        if sid not in seed["SPECS"] and have["class"] in seed["CLASS_ID"] and 0 <= have["order"] <= 3:
            out.candidate("spec", str(sid), "%s %s" % (have["name"], have["class"]),
                          ["ChrSpecialization OrderIndex %d, PrimaryStatPriority %d" % (have["order"], have["prio"])])


def check_specs_forever(seed: dict, db: Build, out: Findings) -> None:
    shield, dual = SKILL_LINE_ID("Shield"), SKILL_LINE_ID("Dual Wield")
    for key, row in sorted(seed["SPECS"].items()):
        name = db.trees.get((row["class"], row["tree"]))
        if name is None:
            out.flag("tree-missing", key, row["comment"], "absent")
        elif comment_name(row["comment"]) != name:
            out.flag("tree-name", key, row["comment"], name)
        if "S" in row["flags"] and not db.has(shield, row["class"]):
            out.flag("shield", key, "S", "no Shield skill line")
        if "D" in row["flags"] and not db.has(dual, row["class"]):
            out.flag("dual-wield", key, "D", "no Dual Wield skill line")
    for (cls, tree), name in sorted(db.trees.items()):
        if cls in seed["CLASS_ID"] and "%s:%d" % (cls, tree) not in seed["SPECS"]:
            out.candidate("tree", "%s:%d" % (cls, tree), "%s %s" % (cls, name), ["TalentTab OrderIndex %d" % (tree - 1)])
    for cls in sorted(seed["CLASS_ID"]):
        rows = [r for r in seed["SPECS"].values() if r["class"] == cls]
        if db.has(dual, cls) and rows and not any("D" in r["flags"] for r in rows):
            level = db.proficiency[dual][cls]
            out.candidate("dualWield", cls, cls, ["SkillRaceClassInfo 118 Dual Wield%s" % (" from level %d" % level if level else ""),
                                                  "SkillLineAbility %s" % ("agrees" if cls in db.witness.get(dual, ()) else "has no row for the class")])
        mask = db.armor_mask.get(cls, 0)
        relic = [tok for bit, tok in sorted(RELIC_BITS.items()) if mask >> bit & 1]
        listed = seed["RELIC"].get(cls)
        if listed and listed not in relic:
            out.flag("relic", cls, listed, "/".join(relic) or "none", ["ArmorTypeMask %d" % mask])
        elif relic and not listed:
            out.candidate("relic", cls, "%s %s" % (cls, relic[0]), ["ArmorTypeMask %d" % mask])


def SKILL_LINE_ID(name: str) -> int:
    return next(s for s, (n, _k, _t, _f) in SKILL_LINES.items() if n == name)


def check_gear_classes(gear: list[int], db: Build, out: Findings) -> None:
    for cid in gear:
        if db.item_class.get(cid) not in ("Weapon", "Armor"):
            out.flag("enum", "GEAR_CLASSES:%d" % cid, str(cid), db.item_class.get(cid) or "absent")


def derive_findings(paths: dict[str, Path], flavor: str, repo: Path = REPO, sentinels=SENTINELS) -> tuple[dict, dict]:
    """`(findings document, counts of shipped rows checked)` for one flavor."""
    spec = FLAVORS[flavor]
    client = spec["client"]
    db = Build(paths, client)
    check_sentinels(db, client, sentinels)
    seed = read_class_data(repo / CLASS_DATA, spec["prefix"])
    gear = read_gear_classes(repo / FACTS)
    out = Findings()
    check_classes(seed, db, out)
    check_armor(seed, db, client, out)
    check_weapons(seed, db, client, out)
    (check_specs_retail if client == "retail" else check_specs_forever)(seed, db, out)
    check_gear_classes(gear, db, out)
    checked = {"CLASS_ID": len(seed["CLASS_ID"]), "ARMOR": len(seed["ARMOR"]),
               "ARMOR_EARLY": len(seed["ARMOR_EARLY"]), "RELIC": len(seed["RELIC"]),
               "WEAPONS": sum(len(v) for v in seed["WEAPONS"].values()), "SPECS": len(seed["SPECS"]),
               "SPEC_INDEX": len(seed["SPEC_INDEX"]), "GEAR_CLASSES": len(gear)}
    return {"candidates": out.candidates, "flags": out.flags}, checked


# ---------------------------------------------------------------------------
# Bundles and rulings
# ---------------------------------------------------------------------------

def rulings_path(flavor: str, tool_dir: Path = HERE) -> Path:
    return tool_dir / ("%s_rulings.json" % flavor)


def load_rulings(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}


def save_rulings(path: Path, rulings: dict) -> None:
    write_repo_text(path, json.dumps(rulings, indent=2, sort_keys=True, ensure_ascii=False) + "\n")


def load_doc(bundle: Path) -> dict:
    path = bundle / "candidates.json"
    if not path.exists():
        raise SystemExit("%s has no candidates.json: run classseeds.py derive first." % bundle)
    return json.loads(path.read_text(encoding="utf-8"))


def all_keys(doc: dict) -> list[str]:
    return [c["key"] for c in doc["candidates"]] + [f["key"] for f in doc["flags"]]


def unruled(doc: dict, rulings: dict) -> list[str]:
    return [k for k in all_keys(doc) if k not in rulings]


def set_ruling(rulings: dict, key: str, ruling: str, reason: str) -> None:
    m = KEY_RE.match(key or "")
    if not m:
        raise SystemExit("%r is not <group>:<subject> or shipped:<kind>:<subject>." % key)
    kind = m.group("kind")
    allowed = FLAG_RULINGS if kind else CANDIDATE_RULINGS
    if ruling not in allowed:
        raise SystemExit("the ruling for %s must be %s; got %r." % (key, " or ".join(allowed), ruling))
    if ruling == "remove" and kind not in REMOVABLE_FLAGS:
        raise SystemExit("%s: only a %s flag can be ruled remove; rule fix for a hand edit." % (key, "/".join(REMOVABLE_FLAGS)))
    reason = (reason or "").strip()
    if not reason or "\n" in reason:
        raise SystemExit("the reason for %s must be one non-empty line." % key)
    rulings[key] = {"ruling": ruling, "reason": reason}


def read_tsv(path: Path) -> list[tuple[str, str, str]]:
    out = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) != 3:
            raise SystemExit("%s: a ruling line is key<TAB>ruling<TAB>reason; got %r" % (path, line))
        out.append(tuple(p.strip() for p in parts))
    return out


def bundles(flavor: str, root: Path = RESEARCH) -> list[Path]:
    return sorted(p for p in root.glob("*-" + flavor) if (p / "candidates.json").exists())


def status_line(live: str, found: list[Path]) -> str:
    """`CURRENT <build> (<bundle>)`, else `NEW <build> ...`; the first word is what
    /dev-copilot:validate-seeds reads."""
    if not found:
        return "NEW %s (no bundle yet)" % live
    last = found[-1]
    built = load_doc(last)["build"]
    if built == live:
        return "CURRENT %s (%s)" % (live, last.name)
    return "NEW %s (last ruled %s, %s)" % (live, built, last.name)


def bundle_tables(flavor: str, bundle: Path, build: str, replay: bool, cache_dir: Path) -> tuple[dict, dict]:
    """`({table: raw member}, {table: provenance})`, fetched into the cache and frozen into raw/,
    or with `replay` read from raw/ alone (a missing member is fatal)."""
    paths, served = {}, {}
    for table, _why in FLAVORS[flavor]["tables"]:
        member = bundle / "raw" / ("%s.csv.gz" % table)
        if replay:
            if not member.exists():
                raise SystemExit("--replay: %s is missing raw/%s.csv.gz." % (bundle, table))
            served[table] = "replayed from raw/"
        else:
            source, served[table] = fetch_table(table, build, cache_dir)
            freeze(source, member)
        paths[table] = member
    return paths, served


def format_sources(doc: dict, flavor: str) -> str:
    spec = FLAVORS[flavor]
    lines = ["# Sources — LibKa0s class-list seed validation, %s (%s)" % (doc["date"], spec["title"]), "",
             "Generated by `tools/seeds/classseeds.py derive`. Frozen: this directory is never edited after the "
             "run, apart from the hand-written `ANALYSIS.md`.", "",
             "| Field | Value |", "| --- | --- |",
             "| Flavor | `%s` (%s, wago product `%s`) |" % (flavor, spec["title"], spec["product"]),
             "| Build | `%s` |" % doc["build"], "| Date | %s (the run's argument) |" % doc["date"],
             "| Builds API | <%s> |" % BUILDS_URL,
             "| Seed files | %s |" % ", ".join("`%s`" % f for f in doc["seedFiles"]), "",
             "## Tables", "", "| Table | Why | Served | URL |", "| --- | --- | --- | --- |"]
    for table, why in spec["tables"]:
        url = CSV_URL.format(table=table, build=doc["build"])
        lines.append("| `%s` | %s | %s | <%s> |" % (table, why, doc["served"].get(table, "") or "-", url))
    lines += ["", "The gzipped exports are in `raw/`; `classseeds.py derive --replay` re-derives this bundle from them "
              "offline. A new run needs network access to wago.tools.", "",
              "## Shipped rows checked", "", "| List | Rows |", "| --- | --- |"]
    lines += ["| %s | %d |" % (k, v) for k, v in doc["checked"].items()]
    lines += ["", "%d candidates, %d flags." % (len(doc["candidates"]), len(doc["flags"])), ""]
    return "\n".join(lines)


def _cell(text) -> str:
    return str(text or "").replace("|", "\\|")


def format_rulings(doc: dict, rulings: dict, date: str) -> str:
    tally: dict[str, int] = {}
    for key in all_keys(doc):
        r = rulings.get(key, {}).get("ruling", "unruled")
        tally[r] = tally.get(r, 0) + 1
    lines = ["# Rulings — LibKa0s class-list seed validation, %s (%s, build %s)" % (doc["date"], doc["flavor"], doc["build"]), "",
             "Generated by `tools/seeds/classseeds.py report` on %s from this bundle's `candidates.json` and "
             "`tools/seeds/%s_rulings.json`. Do not edit by hand." % (date, doc["flavor"]), "",
             "%d candidates, %d flags: %s." % (len(doc["candidates"]), len(doc["flags"]),
                                               ", ".join("%d %s" % (n, r) for r, n in sorted(tally.items())) or "none"), ""]
    missing = unruled(doc, rulings)
    if missing:
        lines += ["## Unruled — %d" % len(missing), ""] + ["- `%s`" % k for k in missing] + [""]
    lines += ["## Candidates — %d" % len(doc["candidates"]), ""]
    if doc["candidates"]:
        lines += ["| Key | What | Applied by | Evidence | Ruling | Reason |", "| --- | --- | --- | --- | --- | --- |"]
        for c in doc["candidates"]:
            r = rulings.get(c["key"], {})
            lines.append("| `%s` | %s | %s | %s | %s | %s |" % (c["key"], _cell(c["name"]), c["apply"], _cell("; ".join(c["notes"])),
                                                         r.get("ruling", "**unruled**"), _cell(r.get("reason"))))
    else:
        lines.append("None.")
    lines += ["", "## Shipped-row flags — %d" % len(doc["flags"]), ""]
    if doc["flags"]:
        lines += ["| Key | Shipped | Build | Evidence | Ruling | Reason |", "| --- | --- | --- | --- | --- | --- |"]
        for f in doc["flags"]:
            r = rulings.get(f["key"], {})
            lines.append("| `%s` | %s | %s | %s | %s | %s |" % (f["key"], _cell(f["shipped"]), _cell(f["build"]), _cell("; ".join(f["notes"])),
                                                         r.get("ruling", "**unruled**"), _cell(r.get("reason"))))
    else:
        lines.append("None.")
    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Apply: the WEAPONS sets
# ---------------------------------------------------------------------------

WRAP = 100
# One `CLASS = set(W.A, ...),` entry, wrapped or not, with its line ending: indent, class, the pad
# before `=`, the tokens.
ENTRY_RE = re.compile(r"(?m)^([ \t]*)(\w+)([ \t]*)= set\(([^)]*)\),?[ \t]*\r?\n")


def continuation_indent(text: str) -> str | None:
    """The indent of the first wrapped line (one that starts with `W.`) in `text`, else None."""
    m = re.search(r"\n([ \t]+)W\.", text)
    return m.group(1) if m else None


def format_set(indent: str, cls: str, pad: str, tokens: list[str], cont: str | None = None) -> list[str]:
    """`CLASS = set(W.A, W.B, ...),` wrapped at WRAP columns. A wrapped line starts with `cont`, the
    file's own continuation indent; without one it is aligned after `set(`."""
    head = "%s%s%s= set(" % (indent, cls, pad)
    cont = " " * len(head) if cont is None else cont
    lines, line = [], head
    for i, tok in enumerate(tokens):
        piece = "W.%s%s" % (tok, ")," if i == len(tokens) - 1 else ",")
        if line not in (head, cont) and len(line) + 1 + len(piece) > WRAP:
            lines.append(line)
            line = cont
        line += piece if line in (head, cont) else " " + piece
    lines.append(line)
    return lines


def edit_weapons(text: str, prefix: str, changes: dict[str, tuple[list[str], list[str]]]) -> tuple[str, list[str]]:
    """Apply `{CLASS: (add, remove)}` to the `prefix` list's WEAPONS block of `text`; return `(text,
    change log)`. Only the changed entries are rewritten, in the file's own line ending, indent and
    continuation indent (the entry's own, else the block's first, else aligned after `set(`)."""
    nl = "\r\n" if "\r\n" in text else "\n"
    span = lua_block(text, prefix + ".WEAPONS = {")
    if not span:
        raise SystemExit("no %s.WEAPONS block to apply to." % prefix)
    body = text[span[0]:span[1]]
    block_cont = continuation_indent(body)
    log_lines = []
    for cls, (add, remove) in sorted(changes.items()):
        m = next((e for e in ENTRY_RE.finditer(body) if e.group(2) == cls), None)
        if not m:
            raise SystemExit("%s.WEAPONS has no %s = set(...) entry to apply to." % (prefix, cls))
        tokens = re.findall(r"W\.(\w+)", m.group(4))
        new = [t for t in tokens if t not in remove] + [t for t in add if t not in tokens]
        if new == tokens:
            continue
        lines = format_set(m.group(1), cls, m.group(3), new, continuation_indent(m.group(0)) or block_cont)
        body = body[:m.start()] + nl.join(lines) + nl + body[m.end():]
        added = [t for t in add if t not in tokens]
        gone = [t for t in remove if t in tokens]
        log_lines.append("WEAPONS %s: %s" % (cls, ", ".join(["+" + t for t in added] + ["-" + t for t in gone])))
    return text[:span[0]] + body + text[span[1]:], log_lines


def plan_apply(doc: dict, rulings: dict) -> dict[str, tuple[list[str], list[str]]]:
    """`{CLASS: (add, remove)}`. Refuses while anything is unruled, or a hand edit is owed."""
    missing = unruled(doc, rulings)
    if missing:
        raise SystemExit("apply refused: %d key(s) unruled (classseeds.py check lists them)." % len(missing))
    owed = [c["key"] for c in doc["candidates"] if c["apply"] == "hand" and rulings[c["key"]]["ruling"] == "accept"]
    owed += [f["key"] for f in doc["flags"] if rulings[f["key"]]["ruling"] == "fix"]
    if owed:
        raise SystemExit("apply refused: a hand edit is owed for %s. Edit the file, re-derive with --replay, "
                         "then apply." % ", ".join(owed))
    changes: dict[str, tuple[list[str], list[str]]] = {}
    for c in doc["candidates"]:
        if c["apply"] == "weapons" and rulings[c["key"]]["ruling"] == "accept":
            changes.setdefault(c["cls"], ([], []))[0].append(c["token"])
    for f in doc["flags"]:
        if f["kind"] == "weapon-unlisted" and rulings[f["key"]]["ruling"] == "remove":
            cls, tok = f["subject"].split(":")
            changes.setdefault(cls, ([], []))[1].append(tok)
    return changes


def apply_bundle(doc: dict, rulings: dict, repo: Path = REPO) -> list[str]:
    """Write the ruled WEAPONS edit of the bundle's flavor into LibKa0s/VerdictClassData.lua."""
    path = repo / CLASS_DATA
    changes = plan_apply(doc, rulings)
    if not changes:
        return []
    raw = path.read_bytes().decode("utf-8")
    text, changed = edit_weapons(raw, FLAVORS[doc["flavor"]]["prefix"], changes)
    if text != raw:
        path.write_bytes(text.encode("utf-8"))
    return changed


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def _date(value: str) -> str:
    if not DATE_RE.match(value):
        raise argparse.ArgumentTypeError("a date is YYYY-MM-DD; got %r" % value)
    return value


def cmd_status(args) -> int:
    for flavor in ([args.flavor] if args.flavor else list(FLAVORS)):
        line = status_line(live_build(FLAVORS[flavor]["product"]), bundles(flavor, args.root))
        print(line if args.flavor else "%s: %s" % (flavor, line))
    return 0


def cmd_derive(args) -> int:
    flavor = args.flavor
    if args.replay:
        build = args.build or load_doc(args.bundle)["build"]
    else:
        build = args.build or live_build(FLAVORS[flavor]["product"])
    log("Deriving %s against build %s into %s" % (flavor, build, args.bundle))
    paths, served = bundle_tables(flavor, args.bundle, build, args.replay, args.cache_dir)
    found, checked = derive_findings(paths, flavor, args.repo)
    if args.replay and (args.bundle / "candidates.json").exists():
        served = load_doc(args.bundle).get("served", served)
    doc = {"flavor": flavor, "product": FLAVORS[flavor]["product"], "build": build, "date": args.date,
           "tool": "tools/seeds/classseeds.py derive", "served": served, "checked": checked,
           "seedFiles": [CLASS_DATA, FACTS]}
    doc.update(found)
    write_json(args.bundle / "candidates.json", doc)
    write_repo_text(args.bundle / "SOURCES.md", format_sources(doc, flavor))
    missing = unruled(doc, load_rulings(rulings_path(flavor, args.tool_dir)))
    log("%d candidates, %d flags, %d unruled" % (len(doc["candidates"]), len(doc["flags"]), len(missing)))
    return 0


def cmd_rule(args) -> int:
    doc = load_doc(args.bundle)
    todo = [(k, args.ruling, args.reason) for k in (args.key or ())]
    if args.tsv:
        todo += read_tsv(args.tsv)
    if not todo:
        raise SystemExit("rule needs --key (with --ruling and --reason) or --tsv.")
    known = set(all_keys(doc))
    path = rulings_path(doc["flavor"], args.tool_dir)
    rulings = load_rulings(path)
    for key, ruling, reason in todo:
        if key not in known:
            raise SystemExit("%s is not a candidate or flag in %s/candidates.json." % (key, args.bundle))
        set_ruling(rulings, key, ruling, reason)
    save_rulings(path, rulings)
    log("Recorded %d ruling(s) in %s" % (len(todo), path))
    return 0


def cmd_check(args) -> int:
    doc = load_doc(args.bundle)
    missing = unruled(doc, load_rulings(rulings_path(doc["flavor"], args.tool_dir)))
    if not missing:
        print("OK: every candidate and flag in %s is ruled." % args.bundle.name)
        return 0
    rows = {r["key"]: r for r in doc["candidates"] + doc["flags"]}
    print("%d unruled:" % len(missing))
    for key in missing:
        row = rows[key]
        print("  %s  %s" % (key, row.get("name") or "%s -> %s" % (row["shipped"], row["build"])))
    return 1


def cmd_report(args) -> int:
    doc = load_doc(args.bundle)
    write_repo_text(args.bundle / "RULINGS.md", format_rulings(doc, load_rulings(rulings_path(doc["flavor"], args.tool_dir)), args.date))
    log("Wrote %s" % (args.bundle / "RULINGS.md"))
    return 0


def cmd_apply(args) -> int:
    doc = load_doc(args.bundle)
    changed = apply_bundle(doc, load_rulings(rulings_path(doc["flavor"], args.tool_dir)), args.repo)
    for line in changed:
        log("  " + line)
    log("%d change(s) to %s %s.WEAPONS (%s)" % (len(changed), CLASS_DATA, FLAVORS[doc["flavor"]]["prefix"], args.date))
    return 0


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Re-validate LibKa0s-Verdict-1.0's class lists against a wago.tools build.",
                                     epilog="The procedure is docs/validate-seeds.md.")
    parser.add_argument("--repo", type=Path, default=REPO, help=argparse.SUPPRESS)
    parser.add_argument("--tool-dir", type=Path, default=HERE, help=argparse.SUPPRESS)
    parser.add_argument("--cache-dir", type=Path, default=CACHE, help="the per-build download cache")
    sub = parser.add_subparsers(dest="command", required=True)
    status = sub.add_parser("status", help="is there a live build newer than the newest bundle?")
    status.add_argument("--flavor", choices=sorted(FLAVORS))
    status.add_argument("--root", type=Path, default=RESEARCH, help=argparse.SUPPRESS)
    derive = sub.add_parser("derive", help="candidates and flags into the bundle's candidates.json")
    derive.add_argument("--flavor", choices=sorted(FLAVORS), required=True)
    derive.add_argument("--bundle", type=Path, required=True)
    derive.add_argument("--date", type=_date, required=True)
    derive.add_argument("--build", help="pin this build instead of the live one")
    derive.add_argument("--replay", action="store_true", help="read only the bundle's raw/, no network")
    rule = sub.add_parser("rule", help="record rulings (the only writer of the rulings file)")
    rule.add_argument("--bundle", type=Path, required=True)
    rule.add_argument("--tsv", type=Path, help="key<TAB>ruling<TAB>reason lines")
    rule.add_argument("--key", action="append")
    rule.add_argument("--ruling")
    rule.add_argument("--reason")
    for name, text in (("check", "exit 1 while anything is unruled"), ("report", "write the bundle's RULINGS.md"),
                       ("apply", "write accepted weapons and ruled removals into the flavor's WEAPONS set")):
        cmd = sub.add_parser(name, help=text)
        cmd.add_argument("--bundle", type=Path, required=True)
        if name != "check":
            cmd.add_argument("--date", type=_date, required=True)
    return parser.parse_args(argv)


def main(argv=None) -> int:
    args = parse_args(argv)
    return {"status": cmd_status, "derive": cmd_derive, "rule": cmd_rule, "check": cmd_check,
            "report": cmd_report, "apply": cmd_apply}[args.command](args)


if __name__ == "__main__":
    sys.exit(main())
