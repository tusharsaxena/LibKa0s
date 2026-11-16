-- tests/test_debuglog_coreskew.lua — LibKa0s-DebugLog-1.0 across a Core upgrade: the console's close
-- button comes from the Core that won the LibStub race, not a copy DebugLog took at load.
--
-- Peeled out of tests/test_debuglog.lua unchanged (LK-P3 of Ka0sAddonsCommonTasks
-- docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS, layout-§1); the forwarder itself is pinned there, in
-- "DebugLog re-exports Core's close button".

local T = _G.LK_TEST
local test, assertEqual = T.test, T.assertEqual

-- ── the close-button factory across a Core upgrade ─────────────────────────────────────────
--
-- LibStub upgrades a major IN PLACE: the `core` TABLE a module stashed at load stays the same
-- object while the functions on it are replaced. A host carrying two vendored copies can therefore
-- end up with a newer Core.lua and an unchanged DebugLog.lua — and if DebugLog copied the function
-- VALUE at file-load time, its console keeps drawing the OLD Core's button while lib.MODULES.Core
-- truthfully reports the newer minor. These load real, minor-patched copies of Core in the order
-- the client would, and assert the button came from the Core that won.

local Loader     = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local CORE_SRC = Loader.readFile("LibKa0s/Core.lua")

-- Patch a copy's minor, stamp the library so the assertion can name which copy answered, and
-- replace the factory with one whose product carries the same stamp. Every substitution is
-- counted: a pattern that silently stopped matching would turn this into a test of nothing.
local function coreCopy(tag, minor)
  local function sub(src, pattern, replacement, what)
    local out, n = src:gsub(pattern, replacement, 1)
    assertEqual(n, 1, "patching " .. what .. " in the real Core source")
    return out
  end
  -- Matched on `%d+` rather than on today's literal minor, so a routine release bump does not
  -- break a test that has nothing to do with the change.
  local src = sub(CORE_SRC, 'local MAJOR, MINOR = "LibKa0s%-Core%-1%.0", %d+',
    'local MAJOR, MINOR = "LibKa0s-Core-1.0", ' .. minor, "the Core minor")
  src = sub(src, "lib%.MAJOR, lib%.MINOR = MAJOR, MINOR",
    'lib.MAJOR, lib.MINOR = MAJOR, MINOR lib.__coreTag = "' .. tag .. '"', "the Core tag")
  return src .. '\nlib.MakeCloseButton = function() return { __coreTag = "' .. tag .. '" } end\n'
end

local function loadSkewed()
  local env = buildMocks()
  Loader.loadSource(coreCopy("OLD", 1), "OLD/Core.lua", nil, env)
  -- Loaded against the OLD Core, before the skew is introduced, because DebugLog's NEEDS_WIDGETS
  -- floor is read at ITS load and Widgets needs a Core of its own to attach to. The skew under
  -- test is Core's, not Widgets'.
  Loader.load("LibKa0s/Widgets.lua", nil, env)
  Loader.load("LibKa0s/WidgetsDropdown.lua", nil, env)
  Loader.load("LibKa0s/DebugLog.lua", nil, env)
  Loader.loadSource(coreCopy("NEW", 2), "NEW/Core.lua", nil, env)
  return env.LibStub("LibKa0s-Core-1.0"), env.LibStub("LibKa0s-DebugLog-1.0")
end

test("dbg: a newer Core loading after DebugLog supplies the console's close button", function()
  local core, dl = loadSkewed()
  assertEqual(core.__coreTag, "NEW", "the higher Core minor won the LibStub race")
  assertEqual(core.MODULES.Core, 2, "and Core's own MODULES registry reports the newer file")
  assertEqual(dl.MakeCloseButton().__coreTag, "NEW",
    "a snapshotted function value would still be drawing the OLD Core's button")
end)

test("dbg: an instance built after the upgrade draws the newer Core's button", function()
  local _, dl = loadSkewed()
  local D = dl:New({
    name = "SkewHost", title = "Skew Host", font = "Interface\\Fonts\\FRIZQT__.TTF",
    isEnabled = function() return false end, setEnabled = function() end,
  })
  assertEqual(D.MakeCloseButton().__coreTag, "NEW",
    "the per-instance re-export must inherit the forwarder, not a stale value")
end)
