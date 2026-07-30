-- Minimal WoW-API mock set for headless unit tests. Returns a builder so each run gets a fresh,
-- isolated environment. Only what the library touches at load/test time is stubbed.

local function deepcopy(t)
  if type(t) ~= "table" then return t end
  local r = {}
  for k, v in pairs(t) do r[k] = deepcopy(v) end
  return r
end

-- A universal frame stub: any PascalCase method is a no-op returning the frame itself; other
-- (lowercase/custom) field access misses through to nil so library code can stash custom fields.
local function stubFrame()
  local f = { __shown = false, __scripts = {} }
  -- Track shown state so IsShown/Toggle behave (the debug console's visibility checkbox reads it).
  -- Every other capitalized method still no-ops through the metatable below.
  function f:Show() self.__shown = true; return self end
  function f:Hide() self.__shown = false; return self end
  function f:SetShown(v) self.__shown = not not v; return self end
  function f:IsShown() return self.__shown end
  function f:IsVisible() return self.__shown end

  -- Store handlers instead of discarding them, and expose __fire so a test can drive the lazy
  -- OnShow paths the panel depends on (the deferred body render, and EnsureDefaultsButton's
  -- first-OnShow build — options-ui-§5). A no-op SetScript made those unreachable.
  function f:SetScript(name, fn) self.__scripts[name] = fn; return self end
  function f:GetScript(name) return self.__scripts[name] end
  function f:HookScript(name, fn)
    local prev = self.__scripts[name]
    self.__scripts[name] = function(...)
      if prev then prev(...) end
      return fn(...)
    end
    return self
  end
  function f:__fire(name, ...)
    local fn = self.__scripts[name]
    if fn then return fn(self, ...) end
  end

  -- Geometry and naming must return real values, not the frame: settings/ScrollPatch.lua does
  -- arithmetic on GetHeight() and string-concatenates GetName(), both of which raise on a table.
  -- Deliberately NOT defining the setters (SetSize/SetWidth/...): tests spy on those by rawsetting
  -- a recorder and rawsetting nil to restore, which would erase an explicit definition for good.
  function f:GetName() return nil end
  function f:GetHeight() return 0 end
  function f:GetWidth() return 0 end

  -- Record RegisterUnitEvent's (event -> unit tokens) instead of no-opping it through the
  -- metatable below: core/AbsorbTracker.lua registers absorb / max-health events per unit and
  -- ONLY for units whose bar is enabled, which is only trustworthy if a test can see exactly which
  -- units each frame registered — a no-op would let a widened or dropped filter pass the whole
  -- suite silently. UnregisterAllEvents is likewise explicit: the metatable's blanket no-op would
  -- leave a disabled unit's registrations visibly in place and make the gating untestable.
  f.__unitEvents = {}
  function f:RegisterUnitEvent(event, ...) self.__unitEvents[event] = { ... }; return self end
  function f:UnregisterAllEvents() self.__unitEvents = {}; return self end

  setmetatable(f, { __index = function(_, k)
    if type(k) == "string" and k:match("^%u") then
      return function() return f end
    end
    return nil
  end })
  return f
end

return function()
  local M = {}

  -- time / string
  M.__now = 0
  M.time = os.time
  M.date = os.date
  M.GetTime = function() return M.__now end
  M.format = string.format
  -- Millisecond CPU clock backing the perf brackets (LibKa0s/Perf.lua). Driven off a settable
  -- counter rather than a real clock so a test can assert on EXACT bucket totals — a wall-clock
  -- reading would make every timing assertion flaky. Tests advance it via M.__profileMs.
  M.__profileMs = 0
  M.debugprofilestop = function() return M.__profileMs end
  M.wipe = function(t) if type(t) == "table" then for k in pairs(t) do t[k] = nil end end return t end

  -- Capture-context lookups (LibKa0s/Perf.lua). Settable so a test can assert the recorded context
  -- is the character's rather than a hard-coded string.
  M.__context = {
    name = "Testchar", realm = "Testrealm", level = 80,
    class = "Death Knight", classToken = "DEATHKNIGHT",
    spec = "Blood", zone = "Silvermoon City", subZone = "Falconwing Square",
    inInstance = false, instanceType = "none", inGroup = false, inRaid = false, groupSize = 0,
  }
  M.UnitName = function() return M.__context.name end
  M.GetRealmName = function() return M.__context.realm end
  M.UnitLevel = function() return M.__context.level end
  -- Localised name first, then the token, as the real API returns them. Without this the record's
  -- context.class silently fell through to "?" in every test that claimed to cover the context.
  M.UnitClass = function() return M.__context.class, M.__context.classToken end
  M.GetZoneText = function() return M.__context.zone end
  M.GetSubZoneText = function() return M.__context.subZone end
  M.GetSpecialization = function() return 1 end
  M.GetSpecializationInfo = function() return 250, M.__context.spec end
  M.IsInInstance = function() return M.__context.inInstance, M.__context.instanceType end
  M.IsInRaid = function() return M.__context.inRaid end
  M.IsInGroup = function() return M.__context.inGroup end
  M.GetNumGroupMembers = function() return M.__context.groupSize end

  -- UI
  M.UIParent = stubFrame()
  M.CreateFrame = function() return stubFrame() end
  M.UISpecialFrames = {}
  M.DEFAULT_CHAT_FRAME = stubFrame()

  -- Blizzard's stopwatch. Recorded rather than no-opped: which of reset/play/pause fired, and in
  -- what order, is the only observable difference between an armed window and a recording one.
  M.__stopwatch = {}
  local function sw(action) return function() M.__stopwatch[#M.__stopwatch + 1] = action end end
  M.Stopwatch_Clear, M.Stopwatch_Play, M.Stopwatch_Pause = sw("clear"), sw("play"), sw("pause")
  M.StopwatchFrame = stubFrame()

  -- Combat, settable. The sampler polls this rather than listening for PLAYER_REGEN_* (Suspend
  -- unregisters the host's event frames, so window B would never see the event fire).
  M.__inCombat = false
  M.UnitAffectingCombat = function() return M.__inCombat end

  -- Addon metadata, for the record's `interface` field.
  M.C_AddOns = { GetAddOnMetadata = function() return "120007" end }

  -- A REAL LibStub, not a lookup table: the library under test registers into it. Minor tracking
  -- is the actual LibStub contract — a lower minor must not overwrite a higher one.
  local registry, minors = {}, {}
  M.LibStub = setmetatable({
    GetLibrary = function(_, major, silent)
      if not registry[major] and not silent then error("Cannot find a library instance of " .. major) end
      return registry[major], minors[major]
    end,
    NewLibrary = function(_, major, minor)
      minor = tonumber(minor)
      if minors[major] and minors[major] >= minor then return nil end
      registry[major] = registry[major] or {}
      minors[major] = minor
      return registry[major], minors[major]
    end,
  }, { __call = function(self, major, silent) return self:GetLibrary(major, silent) end })

  return M
end
