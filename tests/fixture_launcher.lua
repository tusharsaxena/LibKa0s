-- tests/fixture_launcher.lua — the bench the LibKa0s-Launcher-1.0 suites share (tests/test_launcher.lua
-- and tests/test_launcher_skin.lua), moved out of tests/test_launcher.lua unchanged when its skin cases
-- peeled to a suite of their own (LK-P2 of Ka0sAddonsCommonTasks docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS,
-- layout-§1).
--
-- Built ONCE per process and kept on the LibDataBroker fake. Both suites dofile it, and the fakes'
-- registries, the addon-name counter and the menu mock are process-wide state the two must share: a
-- second LibStub registration would be refused, a second counter would hand a name already taken to
-- `NewDataObject`, and a second menu mock would replace the first in the environment before any case
-- runs. A suite that runs alone (a shard of its own) builds it on first use.

local mocks = _G.LK_TEST.mocks

local built = mocks.LibStub:GetLibrary("LibDataBroker-1.1", true)
if built and built.__launcherBench then return built.__launcherBench end

-- ── the two fakes ────────────────────────────────────────────────────────────────────────────
--
-- FIDELITY, not convenience. `NewDataObject` answers nil for a name already taken, exactly as the
-- real one does — that is the whole subject of one case in tests/test_launcher.lua — and `Register`
-- records the table it was handed rather than a copy of it, because "the same table" is the
-- assertion `launcher-§3` turns on.

local LDB = mocks.LibStub:NewLibrary("LibDataBroker-1.1", 1)
LDB.__objects = {}
function LDB:NewDataObject(name, tbl)
  if self.__objects[name] then return nil end
  self.__objects[name] = tbl
  return tbl
end
function LDB:GetDataObjectByName(name) return self.__objects[name] end

local ICON = mocks.LibStub:NewLibrary("LibDBIcon-1.0", 1)
ICON.__buttons = {}
function ICON:Register(name, object, db)
  self.__buttons[name] = { object = object, db = db, shown = not (db and db.hide), calls = 1 }
end
function ICON:Show(name)
  local b = self.__buttons[name]
  if b then b.shown = true end
end
function ICON:Hide(name)
  local b = self.__buttons[name]
  if b then b.shown = false end
end

--- Run `fn` with the named LibStub majors invisible, then put the registry back.
---
--- The module resolves both libraries at CALL time through the environment's `LibStub`, so swapping
--- that one field is enough and nothing has to be unloaded. `silent` is honored exactly as the
--- mock's own LibStub honors it: a non-silent lookup of a blocked major still raises, so a case
--- cannot pass because the module forgot its `, true`.
local function withoutLibs(blockedNames, fn)
  local blocked = {}
  for _, n in ipairs(blockedNames) do blocked[n] = true end
  local original = mocks.LibStub
  mocks.LibStub = setmetatable({
    GetLibrary = function(_, major, silent)
      if blocked[major] then
        if not silent then error("Cannot find a library instance of " .. tostring(major)) end
        return nil
      end
      return original:GetLibrary(major, silent)
    end,
    NewLibrary = function(_, major, minor) return original:NewLibrary(major, minor) end,
  }, { __call = function(self, major, silent) return self:GetLibrary(major, silent) end })
  local ok, err = pcall(fn)
  mocks.LibStub = original
  if not ok then error(err, 0) end
end

-- Each case takes its own addon name, because LibDataBroker's registry is process-wide in the
-- client too and a suite that shared one name would be testing the fake's reset rather than the
-- module.
local seq = 0
local function nextName()
  seq = seq + 1
  return "TestHost" .. seq
end

--- A descriptor with everything required filled in, plus a recorder for what the module reports.
local function fixture(over)
  local rec = {
    name = nextName(),
    lines = {},
    logs = {},
    opened = 0,
    left = 0,
    leftButton = nil,
    minimap = {},
  }
  local d = {
    name = rec.name,
    icon = "Interface\\AddOns\\TestHost\\media\\logos\\testhost.logo.128.tga",
    minimap = function() return rec.minimap end,
    openSettings = function() rec.opened = rec.opened + 1 end,
    print = function(line) rec.lines[#rec.lines + 1] = line end,
    debug = function(tag, message) rec.logs[#rec.logs + 1] = tag .. ": " .. message end,
  }
  for k, v in pairs(over or {}) do d[k] = v end
  rec.d = d
  return rec
end

--- Every reported line, joined, so a case can ask what was said without indexing.
local function said(rec)
  return table.concat(rec.lines, "\n")
end

-- The right click's menu (tests/test_launcher.lua's *click behavior* section reads it).
local MENU = dofile("tests/mock_menu.lua")(mocks)
local OWNER = { name = "LibDBIcon10_TestHost" }   -- the frame the client hands OnClick

--- Right-click the launcher and answer the menu the mock recorded, or nil if none opened.
local function rightClick(L)
  MENU.reset()
  L:Object().OnClick(OWNER, "RightButton")
  return MENU.last
end

local B = {
  LDB = LDB, ICON = ICON, MENU = MENU, OWNER = OWNER,
  withoutLibs = withoutLibs, nextName = nextName, fixture = fixture, said = said, rightClick = rightClick,
}
LDB.__launcherBench = B
return B
