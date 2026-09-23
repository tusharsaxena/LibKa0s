-- Headless test runner for LibKa0s.
-- Run from the repo root:  lua tests/run.lua
--
-- The registry, the assertions, the source loader and the universal WoW-API mock live in the shared
-- kit. This repo consumes its own kit through tests/_kit/ rather than reaching into testkit/
-- directly, so LibKa0s is a consumer on exactly the same terms as every addon: `diff -r testkit
-- tests/_kit` is the same gate here as it is downstream, and a kit change that would break a
-- consumer breaks this repo first.

local Kit        = dofile("tests/_kit/framework.lua")
local Loader     = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

-- Loader.addonName stays nil: library chunks take no arguments, unlike an addon's
-- `local addonName, NS = ...` header.
--
-- The load list is DERIVED from LibKa0s.xml rather than re-typed here. The XML is what the game
-- loads; a list typed beside it is a second copy that drifts, and a short copy does not raise —
-- it just leaves a module undefined for whichever cases never reach it. Deriving makes the two
-- impossible to disagree, and a file added to the XML with nothing on disk fails the run loudly.
-- This is the shape `testing-§10` asks every consumer for, so the reference implementation runs it
-- on itself first.
local mocks = buildMocks()
Loader.loadAll(Loader.xmlFiles("LibKa0s/LibKa0s.xml"), nil, mocks)

-- Every major this library ships and the files that make it up, in LibKa0s.xml order.
--
-- tests/test_versioning.lua iterates this instead of naming Perf's two files inline, so adding a
-- major is one row there rather than an edit scattered through the suite — and a major added to
-- the XML but forgotten here surfaces as a versioning failure instead of as silence. It is
-- declared in tests/majors.lua rather than here because tools/gen-api-members.lua reads the same
-- list to publish each major's member manifest, and cannot reach a local inside this file.
local MAJORS = dofile("tests/majors.lua")

-- Kit.expose merges `test` and the assertions in, so the key set every existing suite file reads is
-- unchanged by the move to the shared harness.
_G.LK_TEST = Kit.expose{
  mocks = mocks,
  lib = mocks.LibStub("LibKa0s-Perf-1.0"),
  media = mocks.LibStub("LibKa0s-Media-1.0"),
  widgets = mocks.LibStub("LibKa0s-Widgets-1.0"),
  core = mocks.LibStub("LibKa0s-Core-1.0"),
  env = mocks.LibStub("LibKa0s-Env-1.0"),
  lifecycle = mocks.LibStub("LibKa0s-Lifecycle-1.0"),
  pool = mocks.LibStub("LibKa0s-Pool-1.0"),
  item = mocks.LibStub("LibKa0s-Item-1.0"),
  debuglog = mocks.LibStub("LibKa0s-DebugLog-1.0"),
  slash = mocks.LibStub("LibKa0s-Slash-1.0"),
  options = mocks.LibStub("LibKa0s-Options-1.0"),
  launcher = mocks.LibStub("LibKa0s-Launcher-1.0"),
  majors = MAJORS,
}

-- The load list above is DERIVED and says so; this one is HAND-TYPED, and the difference is worth
-- a line because the file otherwise reads as though the two lists were held to the same standard.
-- What holds this one honest is `Kit.assertSuiteInventory` (`testkit/framework.lua`), which runs
-- before anything else here because `dir` is given explicitly: a suite file on disk and missing
-- from this list fails the run, and a name here with no file behind it fails it too. That is the
-- gate, not the typing — the failure mode a hand-typed list has is that a new suite is written,
-- never declared, and the run stays green over a file that never executed.
-- The two consumer facts the kit's cap gate cannot infer (`layout-§1`). `hub` is where this repo
-- keeps its engineer context and therefore its over-cap census: the root CLAUDE.md, not
-- `docs/ARCHITECTURE.md`, because a Ka0s-owned library repo has no tier model to host one. There is
-- no `exempt` set: the generated-data carve-out has no instance here, and an empty set is the
-- honest answer rather than a placeholder. It rides on the kit table because a vendored suite is
-- handed the kit and nothing else -- the same reason `test_eol.lua` and `test_prose.lua` take the
-- kit as their chunk argument rather than reading the exposed table by its consumer-chosen name.
Kit.layoutCap = { hub = "CLAUDE.md" }

Kit.run{
  dir = "tests/",
  suites = {
    "test_core", "test_env", "test_lifecycle", "test_pool", "test_item", "test_media", "test_widgets", "test_widgets_draghandle", "test_debuglog", "test_slash",
    "test_launcher",
    "test_options", "test_options_bulk", "test_options_fontpreload", "test_options_widgets",
    "test_options_tabs",
    "test_options_idsuggest", "test_options_idlist_remove", "test_options_switched", "test_options_combat", "test_options_compose",
    "test_perf_core", "test_perf_run", "test_perf_panel", "test_perf_command", "test_perf_isolation",
    "test_loader", "test_parallel", "test_kit_limits",
    "test_mock_base", "test_mock_ace", "test_mock_record",
    "test_surface_parity",
    "test_versioning", "test_kitsync", "test_prose",
    "test_register", "test_kit_inventory",
    -- Shipped in the kit, so every consumer inherits the gate instead of re-typing it; the
    -- inventory assertion goes red in any repo that vendors it and leaves it undeclared.
    -- Declared by the PAIR (basename, directory) from kit revision 25: a bare name here wires
    -- this repo's own file of that name, and the kit's copy would load nothing while the suite
    -- list went on asserting the gate was covered. `test_prose` is the one kit gate this repo
    -- does not wire, and the decline is a row in CLAUDE.md's `## Documented deviations` rather
    -- than a silence -- the inventory reads it there and reports it once, as a skip.
    { name = "test_eol", dir = "tests/_kit/" },
    { name = "test_layout_cap", dir = "tests/_kit/" },
  },
}
