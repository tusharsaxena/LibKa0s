-- tests/fixture_toast.lua — the bench the LibKa0s-Toast-1.0 suites share (tests/test_toast.lua and
-- tests/test_toast_stack.lua), moved out of tests/test_toast.lua unchanged when its stack cases
-- peeled to a suite of their own (FU-L2 of Ka0sAddonsCommonTasks docs/2026-11-06-FOLLOWUPS_V1_91).
--
-- Every case runs on a fresh environment with Core and Toast loaded. CreateFrame is wrapped so each
-- frame it builds records what the shell tells it (strata, mouse, scale, the anchor, the size, the
-- drag) and answers GetPoint, GetScale and IsMouseOver from that record: the kit's universal frame
-- answers those with the frame itself, which would make every placement assertion vacuous.

-- The runner's loader when there is one: this fixture is dofile'd by two suites, and a loader of its
-- own per suite would keep a compiled copy of each file it loads for the whole run (the leak gate).
local Loader = (_G.LK_TEST and _G.LK_TEST.loader) or dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local F = {}

local MAJOR = "LibKa0s-Toast-1.0"
F.MAJOR = MAJOR

--- Record what the shell sets on `f`, and answer the getters from the record.
local function instrument(f)
  f.SetFrameStrata = function(self, s) self.__strata = s end
  f.SetToplevel = function(self, v) self.__toplevel = v end
  f.SetClampedToScreen = function(self, v) self.__clamped = v end
  f.EnableMouse = function(self, v) self.__mouse = v end
  f.RegisterForDrag = function(self, b) self.__dragButton = b end
  f.SetScale = function(self, s) self.__scale = s end
  f.GetScale = function(self) return self.__scale or 1 end
  f.ClearAllPoints = function(self) self.__point = nil end
  f.SetPoint = function(self, ...) self.__point = { ... } end
  f.GetPoint = function(self)
    local p = self.__point
    if not p then return nil end
    return p[1], p[2], p[3], p[4], p[5]
  end
  f.SetSize = function(self, w, h) self.__w, self.__h = w, h end
  f.SetWidth = function(self, w) self.__w = w end
  f.SetHeight = function(self, h) self.__h = h end
  f.StartMoving = function(self) self.__moving = true end
  f.StopMovingOrSizing = function(self) self.__moving = false end
  f.IsMouseOver = function(self) return self.__over == true end
  return f
end

--- A fresh environment: Core (unless `fakeCore` registers a stand-in first) and Toast, with every
--- frame instrumented and every PlaySound and error-handler call recorded.
local function env(fakeCore)
  local m = buildMocks()
  local create = m.CreateFrame
  m.__made = {}
  m.CreateFrame = function(...)
    local f = instrument(create(...))
    m.__made[#m.__made + 1] = f
    return f
  end
  m.__sounds = {}
  m.PlaySound = function(id, channel) m.__sounds[#m.__sounds + 1] = { id = id, channel = channel } end
  m.__files = {}
  m.PlaySoundFile = function(file, channel) m.__files[#m.__files + 1] = { file = file, channel = channel } end
  m.SOUNDKIT = { RAID_WARNING = 8959, UI_EPICLOOT_TOAST = 31578 }
  m.__errors = {}
  m.geterrorhandler = function() return function(e) m.__errors[#m.__errors + 1] = e end end
  if fakeCore then fakeCore(m) else Loader.load("LibKa0s/Core.lua", nil, m) end
  Loader.load("LibKa0s/Toast.lua", nil, m)
  return m, m.LibStub(MAJOR, true)
end

--- A toast whose builder records each call; `d` overrides the descriptor's fields.
local function newToast(d, fakeCore)
  local m, Toast = env(fakeCore)
  local built = {}
  local desc = { build = function(frame, payload)
    built[#built + 1] = { frame = frame, payload = payload }
    return 300, 50
  end }
  for k, v in pairs(d or {}) do desc[k] = v end
  return Toast:New(desc), m, built, Toast
end

local function lastTimer(m)
  local live = m.__timers()
  return live[#live]
end

local function live(m) return #m.__timers() end

F.env, F.newToast, F.lastTimer, F.live = env, newToast, lastTimer, live

return F
