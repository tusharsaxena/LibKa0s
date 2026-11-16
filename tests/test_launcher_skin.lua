-- tests/test_launcher_skin.lua — LibKa0s-Launcher-1.0 under a host's skin: the status tooltip takes the
-- skin's tokens (minor 6, FS-L1), and the menu offers Open skin selector (minor 6, SF-F2).
--
-- Peeled out of tests/test_launcher.lua unchanged (LK-P2 of Ka0sAddonsCommonTasks
-- docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS, layout-§1); the bench is tests/fixture_launcher.lua, and the
-- broker fakes and the descriptor fixture are described in that suite's header.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local mocks = T.mocks
local lib = T.launcher

local Bench = dofile("tests/fixture_launcher.lua")
local withoutLibs, nextName, fixture, rightClick = Bench.withoutLibs, Bench.nextName, Bench.fixture, Bench.rightClick

-- ── the tooltip follows the skin (minor 6, FS-L1) ───────────────────────────────────────────────
--
-- Ka0sAddonsCommonTasks docs/2026-11-01-FULL_SKINNING, cause L1. The launcher reads its host's skin
-- on every show: `name` is the owner, since every addon registers its skin under its folder name.
-- The title takes `gtip.title`, the status and hint lines `gtip.line`, the status words `gtip.on`
-- and `gtip.off`. The library registers no skin here, so `T.mocks`' Skin major is the live one.

local SKIN_MAJOR = "LibKa0s-Skin-1.0"
local skinSeq = 0

--- A registered owner on the skin `key`; answers its name and the skin's tokens.
local function skinnedOwner(key)
  skinSeq = skinSeq + 1
  local owner = "LauncherSkinHost" .. skinSeq
  local Skin = mocks.LibStub(SKIN_MAJOR)
  Skin:RegisterOwner(owner, { get = function() return { source = "ka0s", skin = key } end })
  return owner, Skin:ResolveSkin(key)
end

--- Show the tooltip once: answers { { text, r, g, b }, ... }, one per AddLine.
local function hoverColors(L)
  local tt = { calls = {} }
  function tt:AddLine(line, r, g, b) self.calls[#self.calls + 1] = { line, r, g, b } end
  L:Object().OnTooltipShow(tt)
  return tt.calls
end

local function escapeOf(c)
  return ("|cFF%02X%02X%02X"):format(math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5),
    math.floor(c[3] * 255 + 0.5))
end

local function assertColor(call, c, what)
  assertEqual(call[2], c[1], what .. ": red")
  assertEqual(call[3], c[2], what .. ": green")
  assertEqual(call[4], c[3], what .. ": blue")
end

local function skinnedFixture(owner, extra)
  local rec = fixture(extra)
  rec.d.name = owner
  rec.d.minimap = {}
  return rec
end

test("launcher: an owner's tooltip lines take its skin's tokens, and a switch reaches the next show", function()
  -- red under: the launcher reading no skin, the lines keeping the client's color, the words their
  -- typed green and red, or a palette taken once rather than on the show.
  local owner, T1 = skinnedOwner("azeroth")
  local rec = skinnedFixture(owner, {
    isEnabled = function() return false end, isLocked = function() return true end,
    isTestMode = function() return true end })
  local L = lib:New(rec.d)
  L:Register()
  local calls = hoverColors(L)
  assertEqual(#calls, 6, "title, three states, two hints")
  assertColor(calls[1], T1["gtip.title"], "the title")
  for i = 2, 6 do assertColor(calls[i], T1["gtip.line"], "line " .. i) end
  assertEqual(calls[2][1], "Enabled: " .. escapeOf(T1["gtip.off"]) .. "No|r")
  assertEqual(calls[3][1], "Locked: " .. escapeOf(T1["gtip.on"]) .. "Yes|r")
  assertEqual(calls[4][1], "Test mode: " .. escapeOf(T1["gtip.on"]) .. "On|r")

  local Skin = mocks.LibStub(SKIN_MAJOR)
  Skin:SetChoice(owner, "ka0s", "ember")
  local T2 = Skin:ResolveSkin("ember")
  assertTrue(T1["gtip.title"][1] ~= T2["gtip.title"][1] or T1["gtip.title"][2] ~= T2["gtip.title"][2],
    "the bench's two skins differ")
  assertColor(hoverColors(L)[1], T2["gtip.title"], "the title after the switch")
end)

test("launcher: Ka0s Default keeps the tooltip's look to the byte", function()
  -- red under: `gtip.line` or the status tokens moving off the client's gold and the pure green and
  -- red the tooltip has always drawn. launcher-§1's green and red are the Yes and the No.
  local owner = skinnedOwner("ka0s")
  local rec = skinnedFixture(owner, { isEnabled = function() return true end,
    isLocked = function() return false end })
  local L = lib:New(rec.d)
  L:Register()
  local calls = hoverColors(L)
  local GOLD = { 1, 0.82, 0 }
  for i, call in ipairs(calls) do assertColor(call, GOLD, "line " .. i) end
  assertEqual(calls[2][1], "Enabled: |cFF00FF00Yes|r")
  assertEqual(calls[3][1], "Locked: |cFFFF0000No|r")
end)

test("launcher: the descriptor's owner names the skin where it is not the folder", function()
  -- red under: the owner field being read by nothing.
  local owner, tokens = skinnedOwner("azeroth")
  local rec = fixture{ owner = owner }
  rec.d.name, rec.d.minimap = "LauncherSkinFolder", {}
  local L = lib:New(rec.d)
  L:Register()
  assertColor(hoverColors(L)[1], tokens["gtip.title"], "the title")
end)

test("launcher: a host that is no skin owner draws what it drew, call for call", function()
  -- red under: an unregistered name reading Ka0s Default, which would color every line a host with
  -- no skin never asked to have colored. The same with the Skin major absent altogether.
  local rec = skinnedFixture("LauncherNoSkinHost", { isEnabled = function() return true end })
  local L = lib:New(rec.d)
  L:Register()
  local function check(calls)
    assertEqual(calls[2][1], "Enabled: |cFF00FF00Yes|r")
    for _, call in ipairs(calls) do
      assertNil(call[2], "no color named")
      assertNil(call[3])
      assertNil(call[4])
    end
  end
  check(hoverColors(L))
  withoutLibs({ SKIN_MAJOR }, function() check(hoverColors(L)) end)
end)

test("launcher: a skin that raises leaves the tooltip drawn, and the debug seam hears it", function()
  -- red under: reading the skin outside the launcher's `ask`, which puts a raise in the client's
  -- hover dispatch and loses the tooltip.
  local owner = skinnedOwner("azeroth")
  local rec = skinnedFixture(owner, { isEnabled = function() return true end })
  local logs = {}
  rec.d.debug = function(_, message) logs[#logs + 1] = message end
  local L = lib:New(rec.d)
  L:Register()
  local Skin = mocks.LibStub(SKIN_MAJOR)
  local token = Skin.Token
  Skin.Token = function() error("skin boom") end
  local ok, calls = pcall(hoverColors, L)
  Skin.Token = token
  assertTrue(ok, tostring(calls))
  assertEqual(calls[2][1], "Enabled: |cFF00FF00Yes|r")
  assertNil(calls[2][2], "the plain tooltip")
  assertTrue(table.concat(logs, "|"):find("tooltip: skin raised", 1, true) ~= nil)
end)

-- ── Open skin selector (minor 6, SF-F2) ─────────────────────────────────────────────────────────

test("launcher: the menu ends with Open skin selector for a skin owner that passes openSkinPicker", function()
  -- red under: drop skinEntry from buildMenu
  local owner = skinnedOwner("azeroth")
  local opened = 0
  local rec = skinnedFixture(owner, { openSkinPicker = function() opened = opened + 1 end,
    isLocked = function() return false end, toggleLock = function() end })
  local L = lib:New(rec.d)
  L:Register()
  local menu = rightClick(L)
  local texts = menu:Texts()
  assertEqual(texts[#texts], "Open skin selector", "last")
  menu:Click("Open skin selector")
  assertEqual(opened, 1)
end)

test("launcher: Open skin selector is grayed with the note while the addon is disabled", function()
  local owner = skinnedOwner("azeroth")
  local opened, on = 0, false
  local L = lib:New(skinnedFixture(owner, { openSkinPicker = function() opened = opened + 1 end,
    isEnabled = function() return on end, setEnabled = function() end }).d)
  L:Register()
  local menu = rightClick(L)
  local e = assert(menu:Find("Open skin selector"))
  assertFalse(e.enabled, "grayed")
  assertEqual(e.text, "Open skin selector (enable the addon first)")
  assertNil(menu:Click("Open skin selector"))
  assertEqual(opened, 0)
end)

test("launcher: it alone makes a menu, and a host that is no skin owner or passes nothing gets none", function()
  local owner = skinnedOwner("azeroth")
  local L = lib:New(skinnedFixture(owner, { openSkinPicker = function() end }).d)
  L:Register()
  assertEqual(table.concat(rightClick(L):Texts(), "|"), "Open settings|Open skin selector")
  local rec2 = skinnedFixture("NoSuchSkinOwner" .. nextName(), { openSkinPicker = function() end, isLocked = function() return false end,
    toggleLock = function() end })
  local L2 = lib:New(rec2.d)
  L2:Register()
  assertEqual(table.concat(rightClick(L2):Texts(), "|"), "Locked|Open settings")
  local L3 = lib:New(skinnedFixture((skinnedOwner("azeroth")), { isLocked = function() return false end, toggleLock = function() end }).d)
  L3:Register()
  assertEqual(table.concat(rightClick(L3):Texts(), "|"), "Locked|Open settings")
end)
