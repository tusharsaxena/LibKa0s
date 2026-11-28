#!/usr/bin/env python3
"""Tests for tools/seeds/classseeds.py: tiny fixture tables, invented ids, no network.

Each case writes its own fixture repo (a small LibKa0s/VerdictClassData.lua holding both lists and a
LibKa0s/VerdictFacts.lua, CRLF like the real ones) and fixture CSVs, frozen into a bundle's raw/ the
way `derive` freezes them, and drives the CLI through `--replay`.

    python3 -m pytest -q tools/seeds
    python3 -m unittest discover -s tools/seeds      (without pytest)

Ported from Drop Watcher's tools/seeds/test_seeds.py (LibKa0s#109): the class-list half, with the
writer now exercised on the library's own file instead of a rebound fixture flavor.

Mutation-checked 2026-11-28, then restored: dropping the unruled refusal from plan_apply fails
test_apply_refuses_while_unruled; a writer that aligns every continuation after `set(` fails the
three Writer cases on the continuation indent.
"""

from __future__ import annotations

import gzip
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

import classseeds as S  # noqa: E402

FACTS = "IR.GEAR_CLASSES = { [2] = true, [4] = true }\n"

# Both lists in one file, as LibKa0s/VerdictClassData.lua carries them, in its 2-space layout
# (a wrapped entry's continuation is the file's own indent, not aligned after `set(`).
RETAIL_SEED = """local RETAIL = { STAT_GATE = "hard" }
RETAIL.CLASS_ID = {
  WARRIOR = 1, ROGUE = 4, MAGE = 8,
}
RETAIL.ARMOR = {
  WARRIOR = A.PLATE, ROGUE = A.LEATHER, MAGE = A.CLOTH,
}
-- a comment with a brace { that the block reader must skip
RETAIL.WEAPONS = {
  WARRIOR     = set(W.AXE_1H, W.SWORD_2H),
  ROGUE       = set(W.DAGGER, W.WAND),
  MAGE        = set(W.STAFF),
}
RETAIL.SPECS = {
  [71]   = spec("WARRIOR", STR),             -- Arms
  [72]   = spec("WARRIOR", STR, "DT"),       -- Fury
  [259]  = spec("ROGUE", AGI, "D"),          -- Mutilate
  [62]   = spec("MAGE", INT, "O"),           -- Arcane (the fixture's)
}
RETAIL.SPEC_INDEX = {
  [71] = 1, [72] = 2, [259] = 1, [62] = 1,
}
"""

FOREVER_SEED = """local FOREVER = { STAT_GATE = "soft", ARMOR_LOWER_OK = true, ARMOR_LEVEL = 40, PAWN_BY_TREE = true }
FOREVER.CLASS_ID = {
  WARRIOR = 1, ROGUE = 4, MAGE = 8,
}
FOREVER.ARMOR = {
  WARRIOR = A.PLATE, ROGUE = A.LEATHER, MAGE = A.CLOTH,
}
FOREVER.ARMOR_EARLY = { WARRIOR = A.MAIL }
FOREVER.WEAPONS = {
  WARRIOR = set(W.AXE_1H),
  ROGUE   = set(W.DAGGER),
  MAGE    = set(W.STAFF),
}
FOREVER.RELIC = { MAGE = A.IDOL }
FOREVER.SPECS = {
  ["WARRIOR:1"] = tree("WARRIOR", 1, STR, "DS"),        -- Arms
  ["ROGUE:1"]   = tree("ROGUE", 1, AGI, "D"),           -- Assassination
  ["MAGE:1"]    = tree("MAGE", 1, INT, "O"),            -- Arcane
  ["MAGE:2"]    = tree("MAGE", 2, INT, nil, 2, 3),      -- Flame: the fixture's
}
"""

SRCI_HEAD = "ID,SkillID,ClassMask,Flags,Availability,MinLevel,SkillTierID,RaceMasks_0,RaceMasks_1"


def srci(rows):
    """`(skill, classMask[, minLevel[, raceMask]])` -> SkillRaceClassInfo rows."""
    out = [SRCI_HEAD]
    for i, row in enumerate(rows, 1):
        skill, mask = row[0], row[1]
        level = row[2] if len(row) > 2 else 0
        race = row[3] if len(row) > 3 else -1
        out.append("%d,%d,%d,128,1,%d,0,%d,0" % (i, skill, mask, level, race))
    return "\n".join(out) + "\n"


SKILL_LINE = "DisplayName_lang,ID,CategoryID\n" + "\n".join(
    "%s,%d,6" % (name if "," not in name else '"%s"' % name, sid)
    for sid, (name, _k, _t, _f) in S.SKILL_LINES.items()) + "\n"
COMMON = {
    "SkillLine": SKILL_LINE,
    "SkillLineAbility": "ID,SkillLine,Spell,ClassMask\n1,173,1180,136\n",
    "ItemClass": "ID,ClassName_lang,ClassID\n3,Weapon,2\n5,Armor,4\n",
}
RETAIL_TABLES = dict(COMMON, **{
    "ChrClasses": "ID,Filename,ArmorTypeMask\n1,WARRIOR,113\n4,ROGUE,37\n8,MAGE,35\n",
    "ChrSpecialization": ("ID,ClassID,OrderIndex,Name_lang,PrimaryStatPriority\n71,1,0,Arms,5\n72,1,1,Fury,5\n"
                          "73,1,2,Protection,5\n259,4,0,Assassination,3\n62,8,0,Arcane,0\n1446,1,4,Initial,5\n"),
    "SkillRaceClassInfo": srci([(415, -1), (414, 9), (293, 1, 1), (44, 1), (55, 1), (43, 1), (173, 136), (136, 128),
                                (45, 8, 0, 0)]),
    "SpecializationSpells": "ID,SpecID,SpellID\n1,72,46917\n",
})
FOREVER_TABLES = dict(COMMON, **{
    "ChrClasses": "ID,Filename,ArmorTypeMask\n1,WARRIOR,127\n4,ROGUE,39\n8,MAGE,35\n",
    "ChrSpecialization": "ID,ClassID,OrderIndex,Name_lang,PrimaryStatPriority\n1491,1,0,Warrior,0\n1488,4,0,Rogue,0\n1482,8,0,Mage,0\n",
    "SkillRaceClassInfo": srci([(415, -1), (414, 9), (413, 1), (293, 1, 40), (44, 1), (43, 1), (173, 8), (136, 128),
                                (433, 1), (118, 1, 20), (118, 8, 10), (118, 128)]),
    "TalentTab": ("ID,Name_lang,OrderIndex,ClassMask\n161,Arms,0,1\n164,Fury,1,1\n182,Assassination,0,8\n"
                  "81,Arcane,0,128\n41,Fire,1,128\n"),
})
TABLES = {"retail-classes": RETAIL_TABLES, "forever-classes": FOREVER_TABLES}
BUILD = {"retail-classes": "12.1.5.1", "forever-classes": "1.60.1.1"}


def crlf(text: str) -> bytes:
    return text.replace("\n", "\r\n").encode("utf-8")


class Fixture:
    """A temporary repo, bundle and tool dir for one flavor."""

    def __init__(self, flavor: str, seed: str | None = None, tables: dict | None = None, facts: str = FACTS):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.flavor = flavor
        files = {S.CLASS_DATA: seed or (RETAIL_SEED + "\n" + FOREVER_SEED), S.FACTS: facts}
        for path, text in files.items():
            (self.root / path).parent.mkdir(parents=True, exist_ok=True)
            (self.root / path).write_bytes(crlf(text))
        self.seed = self.root / S.CLASS_DATA
        self.bundle = self.root / "docs" / "seed-research" / ("2026-11-28-" + flavor)
        raw = self.bundle / "raw"
        raw.mkdir(parents=True)
        for table, text in (tables or TABLES[flavor]).items():
            with gzip.open(raw / ("%s.csv.gz" % table), "wb") as handle:
                handle.write(crlf(text))
        self.tool = self.root / "tools" / "seeds"
        self.tool.mkdir(parents=True)

    def run(self, *argv) -> int:
        return S.main(["--repo", str(self.root), "--tool-dir", str(self.tool), *argv])

    def derive(self) -> dict:
        self.run("derive", "--flavor", self.flavor, "--bundle", str(self.bundle), "--date", "2026-11-28",
                 "--build", BUILD[self.flavor], "--replay")
        return S.load_doc(self.bundle)

    def rule(self, rows) -> None:
        tsv = self.root / "rulings.tsv"
        tsv.write_text("".join("%s\t%s\t%s\n" % row for row in rows), encoding="utf-8")
        self.run("rule", "--tsv", str(tsv), "--bundle", str(self.bundle))

    def close(self):
        self.tmp.cleanup()


def keys(doc, part):
    return sorted(row["key"] for row in doc[part])


class RetailDerive(unittest.TestCase):
    def setUp(self):
        self.fx = Fixture("retail-classes")
        self.doc = self.fx.derive()

    def tearDown(self):
        self.fx.close()

    def test_candidates(self):
        self.assertEqual(keys(self.doc, "candidates"),
                         ["spec:73", "weapon:MAGE:DAGGER", "weapon:WARRIOR:SWORD_1H"])

    def test_a_row_with_no_race_grants_nothing(self):
        self.assertNotIn("weapon:ROGUE:BOWS", keys(self.doc, "candidates"))

    def test_flags(self):
        self.assertEqual(keys(self.doc, "flags"), ["shipped:spec-name:259", "shipped:weapon-unlisted:ROGUE:WAND"])

    def test_the_other_list_in_the_same_file_is_not_read(self):
        self.assertEqual(self.doc["checked"]["CLASS_ID"], 3)
        self.assertNotIn("tree", {c["group"] for c in self.doc["candidates"]})

    def test_witness_note(self):
        row = next(c for c in self.doc["candidates"] if c["key"] == "weapon:MAGE:DAGGER")
        self.assertIn("SkillLineAbility agrees", row["notes"])
        self.assertEqual(row["apply"], "weapons")

    def test_bundle_files_are_crlf(self):
        for name in ("candidates.json", "SOURCES.md"):
            data = (self.fx.bundle / name).read_bytes()
            self.assertEqual(data.count(b"\r\n"), data.count(b"\n"), name)

    def test_seed_files_name_the_library(self):
        self.assertEqual(self.doc["seedFiles"], ["LibKa0s/VerdictClassData.lua", "LibKa0s/VerdictFacts.lua"])

    def test_check_exits_1_until_ruled(self):
        bundle = str(self.fx.bundle)
        self.assertEqual(self.fx.run("check", "--bundle", bundle), 1)
        self.fx.rule([(k, "reject" if not k.startswith("shipped:") else "keep", "fixture") for k in S.all_keys(self.doc)])
        self.assertEqual(self.fx.run("check", "--bundle", bundle), 0)

    def test_rulings_file_is_the_flavors_own(self):
        self.fx.rule([("spec:73", "reject", "fixture")])
        self.assertTrue((self.fx.tool / "retail-classes_rulings.json").exists())
        self.assertFalse((self.fx.tool / "retail_rulings.json").exists(), "the kit flavor's file is not this one's")


class GearClasses(unittest.TestCase):
    def test_a_gear_class_that_is_not_weapon_or_armor_is_flagged(self):
        fx = Fixture("retail-classes", facts="IR.GEAR_CLASSES = { [2] = true, [4] = true, [7] = true }\n")
        try:
            doc = fx.derive()
            self.assertIn("shipped:enum:GEAR_CLASSES:7", keys(doc, "flags"))
            self.assertEqual(doc["checked"]["GEAR_CLASSES"], 3)
        finally:
            fx.close()


class Apply(unittest.TestCase):
    def setUp(self):
        self.fx = Fixture("retail-classes")
        self.doc = self.fx.derive()
        self.base = [("weapon:WARRIOR:SWORD_1H", "accept", "fixture"), ("weapon:MAGE:DAGGER", "accept", "fixture"),
                     ("shipped:weapon-unlisted:ROGUE:WAND", "remove", "fixture"),
                     ("shipped:spec-name:259", "keep", "fixture")]

    def tearDown(self):
        self.fx.close()

    def apply(self) -> int:
        return self.fx.run("apply", "--bundle", str(self.fx.bundle), "--date", "2026-11-28")

    def test_apply_refuses_while_unruled(self):
        before = self.fx.seed.read_bytes()
        self.fx.rule(self.base)  # spec:73 left unruled
        with self.assertRaises(SystemExit) as ctx:
            self.apply()
        self.assertIn("unruled", str(ctx.exception))
        self.assertEqual(self.fx.seed.read_bytes(), before)

    def test_apply_refuses_an_owed_hand_edit(self):
        before = self.fx.seed.read_bytes()
        self.fx.rule(self.base + [("spec:73", "accept", "fixture")])
        with self.assertRaises(SystemExit) as ctx:
            self.apply()
        self.assertIn("hand edit is owed for spec:73", str(ctx.exception))
        self.assertEqual(self.fx.seed.read_bytes(), before)

    def test_apply_writes_weapons_keeps_crlf_and_is_idempotent(self):
        self.fx.rule(self.base + [("spec:73", "reject", "fixture")])
        self.apply()
        data = self.fx.seed.read_bytes()
        self.assertEqual(data.count(b"\r\n"), data.count(b"\n"))
        text = data.decode("utf-8")
        self.assertIn("RETAIL.WEAPONS = {\r\n  WARRIOR     = set(W.AXE_1H, W.SWORD_2H, W.SWORD_1H),\r\n", text)
        self.assertIn("  ROGUE       = set(W.DAGGER),\r\n", text)
        self.assertIn("  MAGE        = set(W.STAFF, W.DAGGER),\r\n", text)
        self.assertIn("[71]   = spec(\"WARRIOR\", STR),             -- Arms\r\n", text, "the rest is untouched")
        self.assertIn(crlf(FOREVER_SEED).decode("utf-8"), text, "the other list is untouched")
        self.apply()
        self.assertEqual(self.fx.seed.read_bytes(), data, "a second apply changes nothing")
        redo = self.fx.derive()
        self.assertEqual(keys(redo, "candidates"), ["spec:73"], "applied ids are no longer proposed")

    def test_forever_apply_writes_only_the_forever_list(self):
        fx = Fixture("forever-classes")
        try:
            doc = fx.derive()
            fx.rule([(k, "accept" if k == "weapon:WARRIOR:SWORD_1H" else ("keep" if k.startswith("shipped:") else "reject"),
                      "fixture") for k in S.all_keys(doc)])
            fx.run("apply", "--bundle", str(fx.bundle), "--date", "2026-11-28")
            text = fx.seed.read_bytes().decode("utf-8")
            self.assertIn("FOREVER.WEAPONS = {\r\n  WARRIOR = set(W.AXE_1H, W.SWORD_1H),\r\n", text)
            self.assertIn("RETAIL.WEAPONS = {\r\n  WARRIOR     = set(W.AXE_1H, W.SWORD_2H),\r\n", text)
        finally:
            fx.close()


class Writer(unittest.TestCase):
    """The WEAPONS writer keeps the file's own layout: its line ending, its indent and, for a wrapped
    entry, its continuation indent."""

    BLOCK = ("X.WEAPONS = {\r\n"
             "  HUNTER      = set(W.AXE_1H, W.AXE_2H, W.BOWS, W.GUNS, W.CROSSBOW, W.POLEARM, W.SWORD_1H,\r\n"
             "           W.SWORD_2H, W.STAFF),\r\n"
             "  MAGE        = set(W.STAFF),\r\n"
             "}\r\n")

    def test_a_wrapped_entry_keeps_its_continuation_indent(self):
        text, log = S.edit_weapons(self.BLOCK, "X", {"HUNTER": (["FIST", "DAGGER"], [])})
        self.assertEqual(log, ["WEAPONS HUNTER: +FIST, +DAGGER"])
        self.assertIn("W.SWORD_1H,\r\n           W.SWORD_2H, W.STAFF, W.FIST, W.DAGGER),\r\n", text)
        self.assertEqual(text.count("\r\n"), text.count("\n"))

    def test_an_entry_that_comes_to_wrap_takes_the_blocks_continuation_indent(self):
        many = ["AXE_1H", "AXE_2H", "MACE_1H", "MACE_2H", "POLEARM", "SWORD_1H", "SWORD_2H", "DAGGER", "WAND"]
        text, _ = S.edit_weapons(self.BLOCK, "X", {"MAGE": (many, [])})
        entry = text[text.index("  MAGE"):text.index("}\r\n")]
        lines = entry.split("\r\n")[:-1]
        self.assertEqual(len(lines), 2, entry)
        self.assertTrue(lines[1].startswith("           W.") and not lines[1].startswith("            "), lines[1])
        self.assertTrue(all(len(line) <= S.WRAP for line in lines))

    def test_an_unchanged_entry_is_not_rewritten(self):
        text, log = S.edit_weapons(self.BLOCK, "X", {"MAGE": (["STAFF"], [])})
        self.assertEqual((text, log), (self.BLOCK, []))

    def test_a_missing_entry_is_fatal(self):
        with self.assertRaises(SystemExit):
            S.edit_weapons(self.BLOCK, "X", {"ROGUE": (["DAGGER"], [])})

    def test_wrap_aligns_after_set_without_a_continuation_indent(self):
        lines = S.format_set("    ", "HUNTER", "      ", ["AXE_1H", "AXE_2H", "BOWS", "GUNS", "CROSSBOW", "POLEARM",
                                                         "SWORD_1H", "SWORD_2H", "STAFF", "FIST", "DAGGER"])
        self.assertTrue(all(len(line) <= S.WRAP for line in lines))
        self.assertEqual(len(lines), 2)
        self.assertTrue(lines[1].startswith(" " * len("    HUNTER      = set(") + "W."))
        self.assertTrue(lines[-1].endswith("W.DAGGER),"))

    def test_the_real_file_keeps_its_layout(self):
        """On a copy of the shipped file, every entry of both lists gets one more token: each rewritten
        entry keeps its head, wraps at WRAP with its block's own continuation indent (Retail 11
        spaces, Forever 9), carries its tokens in order, and the bytes outside the two WEAPONS blocks
        do not move (mutation: an aligned continuation fails)."""
        text = (HERE.parent.parent / S.CLASS_DATA).read_bytes().decode("utf-8")
        out, seen = text, 0
        for prefix, width in (("RETAIL", 11), ("FOREVER", 9)):
            start, end = S.lua_block(out, prefix + ".WEAPONS = {")
            entries = list(S.ENTRY_RE.finditer(out[start:end]))
            self.assertEqual(S.continuation_indent(out[start:end]), " " * width, prefix)
            out, log = S.edit_weapons(out, prefix, {e.group(2): (["FAKE"], []) for e in entries})
            self.assertEqual(len(log), len(entries))
            start, end = S.lua_block(out, prefix + ".WEAPONS = {")
            for old, new in zip(entries, S.ENTRY_RE.finditer(out[start:end])):
                self.assertEqual(re.findall(r"W\.(\w+)", new.group(4)), re.findall(r"W\.(\w+)", old.group(4)) + ["FAKE"])
                self.assertEqual(new.group(1, 2, 3), old.group(1, 2, 3))
                lines = new.group(0).split("\r\n")[:-1]
                self.assertTrue(all(len(line) <= S.WRAP for line in lines), new.group(0))
                self.assertTrue(all(line.startswith(" " * width + "W.") for line in lines[1:]), new.group(0))
                seen += 1
        self.assertEqual(seen, 13 + 9)
        self.assertEqual(out.count("\r\n"), out.count("\n"))
        ra, rb = S.lua_block(text, "RETAIL.WEAPONS = {"), S.lua_block(out, "RETAIL.WEAPONS = {")
        fa, fb = S.lua_block(text, "FOREVER.WEAPONS = {"), S.lua_block(out, "FOREVER.WEAPONS = {")
        self.assertEqual(out[:rb[0]], text[:ra[0]], "the bytes before the first block do not move")
        self.assertEqual(out[rb[1]:fb[0]], text[ra[1]:fa[0]], "the bytes between the blocks do not move")
        self.assertEqual(out[fb[1]:], text[fa[1]:], "the bytes after the last block do not move")


class Rulings(unittest.TestCase):
    def test_remove_only_for_a_weapon_flag(self):
        with self.assertRaises(SystemExit):
            S.set_ruling({}, "shipped:spec-name:259", "remove", "x")
        rulings = {}
        S.set_ruling(rulings, "shipped:weapon-unlisted:ROGUE:WAND", "remove", "x")
        self.assertEqual(rulings["shipped:weapon-unlisted:ROGUE:WAND"]["ruling"], "remove")

    def test_bad_rulings(self):
        for key, ruling, reason in (("weapon:ROGUE:BOWS", "keep", "x"), ("shipped:enum:X:Y", "accept", "x"),
                                    ("weapon:ROGUE:BOWS", "accept", " "), ("not a key", "accept", "x")):
            with self.assertRaises(SystemExit, msg=key):
                S.set_ruling({}, key, ruling, reason)

    def test_rule_refuses_a_key_the_bundle_lacks(self):
        fx = Fixture("retail-classes")
        try:
            fx.derive()
            with self.assertRaises(SystemExit):
                fx.rule([("weapon:MAGE:BOWS", "reject", "fixture")])
        finally:
            fx.close()

    def test_the_checked_in_rulings_are_well_formed(self):
        for flavor in S.FLAVORS:
            path = S.rulings_path(flavor)
            self.assertTrue(path.exists(), path)
            data = path.read_bytes()
            self.assertEqual(data.count(b"\r\n"), data.count(b"\n"), path.name)
            for key, row in json.loads(data.decode("utf-8")).items():
                S.set_ruling({}, key, row["ruling"], row["reason"])


class ForeverDerive(unittest.TestCase):
    def test_candidates_and_flags(self):
        fx = Fixture("forever-classes")
        try:
            doc = fx.derive()
            self.assertEqual(keys(doc, "candidates"), ["dualWield:MAGE", "tree:WARRIOR:2", "weapon:WARRIOR:SWORD_1H"])
            self.assertEqual(keys(doc, "flags"), ["shipped:relic:MAGE", "shipped:tree-name:MAGE:2"])
        finally:
            fx.close()

    def test_the_level_switch(self):
        seed = FOREVER_SEED.replace("ARMOR_LEVEL = 40", "ARMOR_LEVEL = 30").replace(
            "FOREVER.ARMOR_EARLY = { WARRIOR = A.MAIL }", "FOREVER.ARMOR_EARLY = {}")
        fx = Fixture("forever-classes", seed=RETAIL_SEED + "\n" + seed)
        try:
            doc = fx.derive()
            self.assertIn("armorEarly:WARRIOR", keys(doc, "candidates"))
            self.assertIn("shipped:armor-level:WARRIOR", keys(doc, "flags"))
        finally:
            fx.close()


class Gate(unittest.TestCase):
    def test_a_missing_sentinel_class_stops_the_run(self):
        tables = dict(RETAIL_TABLES, ChrClasses="ID,Filename,ArmorTypeMask\n4,ROGUE,37\n8,MAGE,35\n")
        fx = Fixture("retail-classes", tables=tables)
        try:
            with self.assertRaises(SystemExit) as ctx:
                fx.derive()
            self.assertIn("Coverage gate FAILED", str(ctx.exception))
        finally:
            fx.close()

    def test_a_renamed_skill_line_stops_the_run(self):
        tables = dict(RETAIL_TABLES, SkillLine=SKILL_LINE.replace("Daggers,173", "Knives,173"))
        fx = Fixture("retail-classes", tables=tables)
        try:
            with self.assertRaises(SystemExit):
                fx.derive()
        finally:
            fx.close()

    def test_replay_needs_every_table(self):
        tables = dict(RETAIL_TABLES)
        del tables["SpecializationSpells"]
        fx = Fixture("retail-classes", tables=tables)
        try:
            with self.assertRaises(SystemExit) as ctx:
                fx.derive()
            self.assertIn("SpecializationSpells", str(ctx.exception))
        finally:
            fx.close()


class Pieces(unittest.TestCase):
    def test_class_masks(self):
        db = S.Build.__new__(S.Build)
        db.classes = {1: "WARRIOR", 4: "ROGUE", 8: "MAGE"}
        self.assertEqual(db.classes_of(-1), ["WARRIOR", "ROGUE", "MAGE"])
        self.assertEqual(db.classes_of(9), ["WARRIOR", "ROGUE"])
        self.assertEqual(db.classes_of(-17), ["WARRIOR", "ROGUE", "MAGE"])

    def test_status_line(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.assertEqual(S.status_line("1.0", []), "NEW 1.0 (no bundle yet)")
            bundle = root / "2026-11-28-retail-classes"
            bundle.mkdir()
            (bundle / "candidates.json").write_text(json.dumps({"build": "1.0"}), encoding="utf-8")
            found = S.bundles("retail-classes", root)
            self.assertEqual(S.status_line("1.0", found), "CURRENT 1.0 (2026-11-28-retail-classes)")
            self.assertTrue(S.status_line("2.0", found).startswith("NEW 2.0 (last ruled 1.0"))

    def test_the_bundle_globs_do_not_cross(self):
        """A class-list bundle is never the kit flavor's, and a kit bundle never this tool's."""
        import libseeds
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name in ("2026-11-28-retail", "2026-11-28-retail-classes", "2026-11-28-forever-classes"):
                (root / name).mkdir()
                (root / name / "candidates.json").write_text("{}", encoding="utf-8")
            self.assertEqual([p.name for p in libseeds.bundles("retail", root)], ["2026-11-28-retail"])
            self.assertEqual([p.name for p in S.bundles("retail-classes", root)], ["2026-11-28-retail-classes"])

    def test_the_real_seed_files_parse(self):
        repo = HERE.parent.parent
        retail = S.read_class_data(repo / S.CLASS_DATA, "RETAIL")
        forever = S.read_class_data(repo / S.CLASS_DATA, "FOREVER")
        self.assertEqual(len(retail["SPECS"]), len(retail["SPEC_INDEX"]))
        self.assertEqual(set(retail["CLASS_ID"]), set(retail["WEAPONS"]))
        self.assertEqual(set(forever["CLASS_ID"]), set(forever["WEAPONS"]))
        self.assertEqual(len(retail["CLASS_ID"]), 13)
        self.assertEqual(len(forever["CLASS_ID"]), 9)
        self.assertEqual(forever["ARMOR_LEVEL"], 40)
        self.assertEqual(S.read_gear_classes(repo / S.FACTS), [2, 4])


if __name__ == "__main__":
    unittest.main()
