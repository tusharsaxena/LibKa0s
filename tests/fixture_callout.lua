-- tests/fixture_callout.lua — the bench the LibKa0s-Callout-1.0 suites share.
--
-- Every case runs on a fresh environment with Core and Callout loaded, the kit's paint recorder
-- installed (so the text and the halo are distinct, recording FontStrings), and CreateFrame wrapped
-- so each frame records what the call-out tells it (strata, mouse, size, the anchor, the drag) and
-- answers GetPoint from that record. AnimationGroups are recording fakes: the kit models none, and
-- an animation nothing can observe is an animation that ships untested. `group:__finish()` fires a
-- group's OnFinished, the way the client does when it ends. Time is the kit's settable clock
-- (`m.__now`); `F.frame(m)` drives one client frame by firing the clock's OnUpdate.
--
-- Sound is recorded: `m.__files` lists every PlaySoundFile call, and a path in `m.__missing` answers
-- false, as the client does for a file that is not there. `F.tts(m, voices)` installs a recording
-- C_VoiceChat with the given voices.

local Loader = (_G.LK_TEST and _G.LK_TEST.loader) or dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")
local installPaint = dofile("tests/_kit/mock_paint.lua")

local F = {}
F.MAJOR = "LibKa0s-Callout-1.0"

-- ── AnimationGroups ──────────────────────────────────────────────────────────────────────────

local function newAnimation(group, kind)
  local a = { __kind = kind, __group = group }
  local function rec(field)
    return function(self, ...) self[field] = { ... } end
  end
  a.SetDuration = function(self, d) self.__duration = d end
  a.SetOrder = function(self, o) self.__order = o end
  a.SetSmoothing = function(self, s) self.__smoothing = s end
  a.SetScaleFrom, a.SetScaleTo, a.SetOrigin = rec("__scaleFrom"), rec("__scaleTo"), rec("__origin")
  a.SetFromAlpha = function(self, v) self.__fromAlpha = v end
  a.SetToAlpha = function(self, v) self.__toAlpha = v end
  a.SetOffset = rec("__offset")
  return a
end

local function newGroup(target)
  local g = { __target = target, __anims = {}, __plays = 0, __stops = 0, __playing = false, __scripts = {} }
  function g:CreateAnimation(kind)
    local a = newAnimation(self, kind)
    self.__anims[#self.__anims + 1] = a
    return a
  end
  function g:Play() self.__plays, self.__playing = self.__plays + 1, true end
  function g:Stop() self.__stops, self.__playing = self.__stops + 1, false end
  function g:IsPlaying() return self.__playing end
  function g:SetToFinalAlpha(v) self.__finalAlpha = v end
  function g:SetLooping(v) self.__looping = v end
  function g:SetScript(name, fn) self.__scripts[name] = fn end
  function g:__finish()
    self.__playing = false
    local fn = self.__scripts.OnFinished
    if fn then fn(self) end
  end
  local list = rawget(target, "__groups") or {}
  list[#list + 1] = g
  rawset(target, "__groups", list)
  return g
end

-- ── frames ───────────────────────────────────────────────────────────────────────────────────

--- Record what the call-out sets on `f`, and answer the getters from the record.
local function instrument(f)
  rawset(f, "SetFrameStrata", function(self, s) rawset(self, "__strata", s) end)
  rawset(f, "SetClampedToScreen", function(self, v) rawset(self, "__clamped", v) end)
  rawset(f, "SetMovable", function(self, v) rawset(self, "__movable", v) end)
  rawset(f, "EnableMouse", function(self, v) rawset(self, "__mouse", v) end)
  rawset(f, "RegisterForDrag", function(self, b) rawset(self, "__dragButton", b) end)
  rawset(f, "SetSize", function(self, w, h) rawset(self, "__w", w); rawset(self, "__h", h) end)
  rawset(f, "ClearAllPoints", function(self) rawset(self, "__point", nil) end)
  rawset(f, "SetPoint", function(self, ...) rawset(self, "__point", { ... }) end)
  rawset(f, "GetPoint", function(self)
    local p = rawget(self, "__point")
    if not p then return nil end
    return p[1], p[2], p[3], p[4], p[5]
  end)
  rawset(f, "StartMoving", function(self) rawset(self, "__moving", true) end)
  rawset(f, "StopMovingOrSizing", function(self) rawset(self, "__moving", false) end)
  rawset(f, "CreateAnimationGroup", function(self) return newGroup(self) end)
  local createFS = f.CreateFontString
  rawset(f, "CreateFontString", function(self, ...)
    local fs = createFS(self, ...)
    rawset(fs, "CreateAnimationGroup", function(region) return newGroup(region) end)
    return fs
  end)
  return f
end

--- A fresh environment: Core and Callout, every frame instrumented, every sound recorded.
--- `before(m)` runs before the files load (to install a stand-in major or a client API).
local function env(before)
  local m = buildMocks()
  installPaint(m)
  local create = m.CreateFrame
  m.__made = {}
  m.CreateFrame = function(...)
    local f = instrument(create(...))
    m.__made[#m.__made + 1] = f
    return f
  end
  m.__files, m.__missing = {}, {}
  m.PlaySoundFile = function(file, channel)
    m.__files[#m.__files + 1] = { file = file, channel = channel }
    if m.__missing[file] then return false end
    return true, #m.__files
  end
  m.__errors = {}
  m.geterrorhandler = function() return function(e) m.__errors[#m.__errors + 1] = e end end
  m.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
  if before then before(m) end
  Loader.load("LibKa0s/Core.lua", nil, m)
  Loader.load("LibKa0s/Callout.lua", nil, m)
  Loader.load("LibKa0s/CalloutSettings.lua", nil, m)
  return m, m.LibStub(F.MAJOR, true)
end

--- A call-out on a fresh environment, its settings in `db`, its debug lines in `logs`.
--- `d` overrides the descriptor's fields.
local function newCallout(d, before)
  local m, Callout = env(before)
  local db, logs = {}, {}
  local desc = { db = db, addon = "TestAddon", name = "TestCallout",
    debug = function(tag, msg) logs[#logs + 1] = { tag = tag, msg = msg } end }
  for k, v in pairs(d or {}) do desc[k] = v end
  return Callout:New(desc), m, db, logs, Callout
end

--- The call-out's frames, by their roles: the frame, its text, its halo and its clock.
local function parts(c)
  local f = c:Frame()
  local text, halo
  for _, r in ipairs({ f:GetRegions() }) do
    if r:GetDrawLayer() == "OVERLAY" then text = r elseif r:GetDrawLayer() == "BACKGROUND" then halo = r end
  end
  return f, text, halo
end

--- The clock frame: the unparented frame that carries the OnUpdate while one is armed.
local function clock(m)
  for _, f in ipairs(m.__made) do
    if rawget(f, "__groups") == nil and f:GetScript("OnUpdate") then return f end
  end
  return nil
end

--- One client frame at time `t`: the clock's OnUpdate runs, when one is armed.
local function frameAt(m, t)
  m.__now = t
  local f = clock(m)
  if f then f:__fire("OnUpdate", 0) end
end

local function tts(m, voices)
  m.__spoken = {}
  m.C_VoiceChat = {
    GetTtsVoices = function() return voices end,
    SpeakText = function(id, text, rate, volume, overlap)
      m.__spoken[#m.__spoken + 1] = { id = id, text = text, rate = rate, volume = volume, overlap = overlap }
    end,
  }
end

F.env, F.newCallout, F.parts, F.clock, F.frameAt, F.tts = env, newCallout, parts, clock, frameAt, tts

return F
