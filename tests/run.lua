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
-- major is one row here rather than an edit scattered through the suite — and a major added to the
-- XML but forgotten here surfaces as a versioning failure instead of as silence.
--
-- `paired` names a secondary file carrying the __<file>Minor / __<file>ProbeMinor guard, so the
-- pairing assertion generalises with the rest.
local MAJORS = {
  {
    major = "LibKa0s-Core-1.0",
    files = { "Core" },
    primary = "Core",
  },
  {
    major = "LibKa0s-Env-1.0",
    files = { "Env" },
    primary = "Env",
  },
  {
    major = "LibKa0s-Pool-1.0",
    files = { "Pool" },
    primary = "Pool",
  },
  {
    major = "LibKa0s-Item-1.0",
    files = { "Item" },
    primary = "Item",
  },
  {
    major = "LibKa0s-Media-1.0",
    files = { "Media" },
    primary = "Media",
  },
  {
    major = "LibKa0s-Widgets-1.0",
    files = { "Widgets" },
    primary = "Widgets",
  },
  {
    major = "LibKa0s-DebugLog-1.0",
    files = { "DebugLog" },
    primary = "DebugLog",
  },
  {
    major = "LibKa0s-Slash-1.0",
    files = { "Slash" },
    primary = "Slash",
  },
  {
    major = "LibKa0s-Options-1.0",
    files = { "Options", "OptionsWidgets", "OptionsCompose", "OptionsScroll" },
    primary = "Options",
    paired = {
      { file = "OptionsWidgets", minorField = "__widgetsMinor", probeField = "__widgetsShellMinor" },
      { file = "OptionsCompose", minorField = "__composeMinor", probeField = "__composeShellMinor" },
      { file = "OptionsScroll",  minorField = "__scrollMinor",  probeField = "__scrollShellMinor" },
    },
  },
  {
    major = "LibKa0s-Perf-1.0",
    files = { "Perf", "PerfPanel" },
    primary = "Perf",
    paired = { { file = "PerfPanel", minorField = "__panelMinor", probeField = "__panelProbeMinor" } },
  },
}

-- Kit.expose merges `test` and the assertions in, so the key set every existing suite file reads is
-- unchanged by the move to the shared harness.
_G.LK_TEST = Kit.expose{
  mocks = mocks,
  lib = mocks.LibStub("LibKa0s-Perf-1.0"),
  media = mocks.LibStub("LibKa0s-Media-1.0"),
  widgets = mocks.LibStub("LibKa0s-Widgets-1.0"),
  core = mocks.LibStub("LibKa0s-Core-1.0"),
  env = mocks.LibStub("LibKa0s-Env-1.0"),
  pool = mocks.LibStub("LibKa0s-Pool-1.0"),
  item = mocks.LibStub("LibKa0s-Item-1.0"),
  debuglog = mocks.LibStub("LibKa0s-DebugLog-1.0"),
  slash = mocks.LibStub("LibKa0s-Slash-1.0"),
  options = mocks.LibStub("LibKa0s-Options-1.0"),
  majors = MAJORS,
}

Kit.run{
  dir = "tests/",
  suites = {
    "test_core", "test_env", "test_pool", "test_item", "test_media", "test_widgets", "test_debuglog", "test_slash",
    "test_options", "test_options_widgets", "test_options_compose",
    "test_perf_core", "test_perf_run", "test_perf_panel", "test_perf_command", "test_perf_isolation",
    "test_loader", "test_parallel",
    "test_versioning", "test_kitsync", "test_prose", "test_eol",
  },
}
