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
  compat = mocks.LibStub("LibKa0s-Compat-1.0"),
  lifecycle = mocks.LibStub("LibKa0s-Lifecycle-1.0"),
  bus = mocks.LibStub("LibKa0s-Bus-1.0"),
  schema = mocks.LibStub("LibKa0s-Schema-1.0"),
  pool = mocks.LibStub("LibKa0s-Pool-1.0"),
  item = mocks.LibStub("LibKa0s-Item-1.0"),
  glow = mocks.LibStub("LibKa0s-Glow-1.0"),
  toast = mocks.LibStub("LibKa0s-Toast-1.0"),
  skin = mocks.LibStub("LibKa0s-Skin-1.0"),
  sim = mocks.LibStub("LibKa0s-Sim-1.0"),
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

-- The consumer facts for the kit's shared diagnostics contract (debug-logging-§14). A library has
-- no slash command, so the contract runs against a fixture host built from this repo's own DebugLog
-- and Slash; see tests/fixture_diagnostics.lua.
Kit.diagnostics = dofile("tests/fixture_diagnostics.lua")(_G.LK_TEST)

Kit.run{
  dir = "tests/",
  suites = {
    "test_core", "test_core_resize", "test_env", "test_compat", "test_lifecycle", "test_lifecycle_debug", "test_bus", "test_schema", "test_schema_write", "test_schema_batch", "test_pool", "test_item", "test_glow", "test_toast", "test_media", "test_skin", "test_skin_override", "test_skin_outline", "test_skin_owner_tokens", "test_skin_remap", "test_skin_icon_border", "test_skin_stock_default", "test_skin_defs", "test_skin_width_parity", "test_skin_button_contrast", "test_skin_paint", "test_skin_paint_controls", "test_skin_eui", "test_skin_ace", "test_skin_ace_tree", "test_widgets", "test_widgets_reorderlist", "test_widgets_draghandle", "test_widgets_draghandle_place", "test_widgets_draghandle_layers", "test_widgets_linechart_math", "test_widgets_linechart", "test_widgets_autocomplete", "test_widgets_searchbox", "test_widgets_teststrip", "test_widgets_reorder", "test_widgets_skin", "test_widgets_skin_scope", "test_debuglog", "test_debuglog_copytiming", "test_debuglog_diagnostics", "test_debuglog_gates", "test_debuglog_descriptor", "test_resize_windows", "test_tool_windows_layering", "test_tool_windows_skin", "test_tool_windows_scope", "test_slash", "test_slash_parse", "test_slash_disabled", "test_slash_refusal", "test_slash_profile", "test_slash_debug",
    "test_launcher", "test_atenable",
    "test_options", "test_options_render", "test_options_bulk", "test_options_fontpreload", "test_options_widgets",
    "test_options_choicegrid", "test_options_flow", "test_options_landing",
    "test_options_ids", "test_options_idlist", "test_options_idlist_layout",
    "test_options_tabs", "test_options_tabbed",
    "test_options_nav", "test_options_drawer", "test_options_keybinds_model", "test_options_keybinds", "test_options_keybinds_sync", "test_options_appearance", "test_options_appearance_overrides", "test_options_skin_picker", "test_options_skin_picker_shared", "test_options_skin_picker_faces", "test_options_skin_picker_rows", "test_options_skin_verb",
    "test_options_idsuggest", "test_options_idsuggest_frames", "test_options_idlist_remove", "test_options_switched", "test_options_media", "test_options_combat", "test_options_combat_debug", "test_options_compose", "test_options_compose_arm", "test_options_compose_master", "test_options_compose_tooltips", "test_options_reset_tooltip", "test_options_skin", "test_options_tooltip_skin", "test_options_chrome_skin", "test_options_compose_skin", "test_options_compose_flags",
    "test_options_throttle",
    "test_perf_core", "test_perf_run", "test_perf_panel", "test_perf_command", "test_perf_budget", "test_perf_toplevel", "test_perf_isolation",
    "test_sim_seam", "test_sim_session", "test_sim_timeline", "test_sim_verbs", "test_sim_autoplay", "test_sim_panel", "test_sim_panel_controls", "test_sim_panel_render",
    "test_sim_isolation", "test_sim_stub", "test_sim_host",
    "test_loader", "test_parallel", "test_kit_limits", "test_kit_asserts", "test_kit_secrets", "test_kit_latch", "test_kit_bindings", "test_glyph_guard",
    "test_mock_base", "test_mock_ace", "test_mock_record", "test_mock_events", "test_mock_resize", "test_mock_lines", "test_mock_bindings", "test_mock_layers", "test_mock_paint",
    "test_surface_parity",
    "test_versioning", "test_kitsync", "test_prose",
    "test_register", "test_kit_inventory", "test_kit_eol", "test_kit_prose", "test_kit_runner", "test_kit_vendor_sync",
    -- Shipped in the kit, so every consumer inherits the gate instead of re-typing it; the
    -- inventory assertion goes red in any repo that vendors it and leaves it undeclared.
    -- Declared by the PAIR (basename, directory) from kit revision 25: a bare name here wires
    -- this repo's own file of that name, and the kit's copy would load nothing while the suite
    -- list went on asserting the gate was covered. `test_prose` is the one kit gate this repo
    -- does not wire, and the decline is a row in CLAUDE.md's `## Documented deviations` rather
    -- than a silence -- the inventory reads it there and reports it once, as a skip.
    { name = "test_eol", dir = "tests/_kit/" },
    { name = "test_layout_cap", dir = "tests/_kit/" },
    { name = "test_diagnostics_contract", dir = "tests/_kit/" },
    { name = "test_lizard_sighted", dir = "tests/_kit/" },
  },
}
