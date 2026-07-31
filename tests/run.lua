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
local mocks = buildMocks()
Loader.loadAll({ "LibKa0s/Core.lua", "LibKa0s/Perf.lua", "LibKa0s/PerfPanel.lua" }, nil, mocks)

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
  core = mocks.LibStub("LibKa0s-Core-1.0"),
  majors = MAJORS,
}

Kit.run{
  dir = "tests/",
  suites = {
    "test_core",
    "test_perf_core", "test_perf_run", "test_perf_panel", "test_perf_command", "test_perf_isolation",
    "test_versioning",
  },
}
