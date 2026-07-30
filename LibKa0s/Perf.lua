-- LibKa0s-Perf-1.0 — a repeatable A/B performance capture for World of Warcraft addons.
--
-- The value here is not the bucket counter. It is the PROTOCOL: two combat-gated measurement
-- windows over the same fight, differing only in whether the host addon is inert, with load order
-- and shared-frame ownership held fixed. WoW's own Addon Profiler cannot answer "is this cost even
-- ours?", because it bills a shared library's dispatch frame to whichever addon created it — so
-- enabling and disabling addons moves the blame around. Suspending changes only whether the host's
-- code runs.
--
-- Every instance owns its own frames. A lib-level shared frame would reproduce that exact
-- attribution pathology: the measuring instrument corrupting the attribution it exists to fix.
--
-- Depends on LibStub and nothing else, deliberately — no Ace3, so the lib is adoptable by addons
-- that are not on the Ace substrate.

local MAJOR, MINOR = "LibKa0s-Perf-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.MAJOR, lib.MINOR = MAJOR, MINOR

-- Record schema emitted by BuildRecord. See docs/record-schema.md.
lib.SCHEMA = 2

-- Default depth of the SavedVariables capture ring. Small on purpose: these are diagnostic
-- snapshots read by hand, not telemetry.
lib.DEFAULT_RING = 10

-- ── JSON encoding ──────────────────────────────────────────────────────────────────────────
--
-- Hand-rolled because Lua has none built in and the addon vendors no JSON library for one
-- diagnostic path. The data is flat, finite and entirely ours, so the general-purpose hazards
-- (cycles, sparse arrays, NaN) cannot arise from BuildRecord's output.
--
-- Object keys are emitted SORTED. Lua's pairs() order is unspecified and varies between runs, so
-- unsorted output would make two otherwise-identical captures diff as different files.

local function encodeNumber(v)
    if v ~= v or v == math.huge or v == -math.huge then return "0" end   -- NaN / inf → 0
    if v == math.floor(v) and math.abs(v) < 1e15 then
        return ("%d"):format(v)
    end
    return ("%.4f"):format(v)
end

local ESCAPES = {
    ['"'] = '\\"', ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
    ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t",
}

local function encodeString(v)
    local out = v:gsub('[%c"\\]', function(c)
        return ESCAPES[c] or ("\\u%04x"):format(c:byte())
    end)
    return '"' .. out .. '"'
end

local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = tostring(k) end
    table.sort(keys)
    return keys
end

--- Encode a Lua value as JSON. Tables with a non-empty array part encode as arrays; every other
--- table encodes as an object with sorted keys. Unsupported types encode as null.
function lib.EncodeJSON(value)
    local t = type(value)
    if value == nil then return "null" end
    if t == "boolean" then return value and "true" or "false" end
    if t == "number" then return encodeNumber(value) end
    if t == "string" then return encodeString(value) end
    if t ~= "table" then return "null" end

    if #value > 0 then
        local parts = {}
        for i = 1, #value do parts[i] = lib.EncodeJSON(value[i]) end
        return "[" .. table.concat(parts, ",") .. "]"
    end

    local parts = {}
    for _, k in ipairs(sortedKeys(value)) do
        parts[#parts + 1] = encodeString(k) .. ":" .. lib.EncodeJSON(value[k])
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

-- ── Strings ────────────────────────────────────────────────────────────────────────────────
--
-- Every user-visible string routes through here so a host can override any of them via the
-- optional `L` table, keyed identically. Hosts on the Ka0s standard pass their NS.L; hosts that
-- are not localised pass nothing and get these.

lib.STRINGS = {
  PANEL_TITLE_SUFFIX = " \226\128\148 Perf Run",
  STEP_START    = "Start perf run",
  STEP_MEASURE_A = "Measure A (with the addon)",
  STEP_MEASURE_B = "Measure B (without the addon)",
  STEP_FINISH   = "Finish perf run",
  STEP_REPORT   = "Report",
  STEP_DUMP     = "JSON Dump",
  STEP_CANCEL   = "Cancel perf run",
}

-- ── Output ─────────────────────────────────────────────────────────────────────────────────
--
-- Perf output is deliberately NOT gated on a host debug flag, unlike a host's own debug logging.
-- That gate exists to keep the addon quiet while idle, and a perf run is explicit user action —
-- none of this executes unless someone typed the host's perf command.
--
-- The console form is stripped of colour escapes: the Copy window mirrors the buffer verbatim, and
-- colour codes in a log destined for analysis are noise. Stateless, so these live above :New()
-- alongside the JSON encoder.

local function stripColors(s)
    return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

-- 12.0 secret values raise on tostring in some paths; never let a log line error a capture.
local function safeToString(v)
  if v == nil then return "nil" end
  local t = type(v)
  if t == "string" then return v end
  if t == "number" or t == "boolean" then return tostring(v) end
  local ok, s = pcall(tostring, v)
  return ok and s or "?"
end

local function render(fmt, ...)
    if select("#", ...) == 0 then return fmt end
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = safeToString((select(i, ...))) end
    return fmt:format(unpack(parts))
end

-- ── Instances ──────────────────────────────────────────────────────────────────────────────

local function required(d, key, wanted)
  if type(d[key]) ~= wanted then
    error(("LibKa0s-Perf: descriptor.%s must be a %s"):format(key, wanted), 3)
  end
end

--- Create a perf instance for one host addon. Every instance owns its own sampler frame, bucket
--- table, FPS arms and panel — see the header on why that is non-negotiable.
function lib:New(descriptor)
  local d = descriptor or {}
  required(d, "name", "string")
  required(d, "sv", "string")
  required(d, "suspend", "function")
  required(d, "resume", "function")

  local P = {}

  -- Optional host sinks, resolved once so the hot-ish paths do not re-branch on presence.
  local noop     = function() end
  local hostLog  = type(d.log)     == "function" and d.log     or function(line) print(line) end
  local hostPrint= type(d.print)   == "function" and d.print   or function(line) print(line) end
  local showLog  = type(d.showLog) == "function" and d.showLog or noop -- luacheck: ignore (Task 5's panel)
  local onChange = type(d.onChange)== "function" and d.onChange or noop
  local L        = d.L or {}
  local function tr(key) return L[key] or self.STRINGS[key] or key end -- luacheck: ignore (Task 5's panel)

  -- Mirrored onto the instance as a convenience: call sites that hold only `NS.Perf` should not
  -- have to reach back through LibStub for the schema number or the encoder.
  P.SCHEMA     = self.SCHEMA
  P.EncodeJSON = self.EncodeJSON

  P.descriptor = d
  P.name    = d.name
  P.slash   = d.slash or ("/" .. d.name:lower())
  P.title   = d.title or d.name
  P.ringMax = tonumber(d.ring) or self.DEFAULT_RING

  -- Report order, and the declared nesting. Membership controls only PRESENTATION — Note() accepts
  -- any key, so a bracket nobody declared still records, it just does not print.
  P.BUCKET_ORDER, P.BUCKET_WITHIN = {}, {}
  for _, b in ipairs(d.buckets or {}) do
    P.BUCKET_ORDER[#P.BUCKET_ORDER + 1] = b.key
    if b.within then P.BUCKET_WITHIN[b.key] = b.within end
  end

  -- Capture running? Read directly by every bracket call site, so it must stay a plain boolean
  -- field on a plain table — no metatable, no accessor.
  P.on        = false
  P.suspended = false
  P.run       = false     -- between Start() and Stop()
  P.armed     = nil       -- window armed, waiting for combat
  P.recording = nil       -- window currently recording

  local buckets   = {}
  local completed = { active = false, suspended = false }
  local reviewed  = { report = false, dump = false }
  local fpsArms   = {
    active    = { seconds = 0, frames = 0 },
    suspended = { seconds = 0, frames = 0 },
  }

  function P.Note(key, ms)
    local b = buckets[key]
    if not b then
      b = { calls = 0, totalMs = 0, maxMs = 0 }
      buckets[key] = b
    end
    b.calls   = b.calls + 1
    b.totalMs = b.totalMs + ms
    if ms > b.maxMs then b.maxMs = ms end
  end

  function P.Reset()
    buckets   = {}
    completed = { active = false, suspended = false }
    reviewed  = { report = false, dump = false }
    fpsArms   = {
      active    = { seconds = 0, frames = 0 },
      suspended = { seconds = 0, frames = 0 },
    }
  end

  -- Test seams: expose the live tables without letting callers swap them out.
  function P.__buckets()   return buckets   end
  function P.__fpsArms()   return fpsArms   end
  function P.__completed() return completed end
  function P.__reviewed()  return reviewed  end

  --- Console only. Phase transitions and anything else worth having in the copied log.
  function P.Log(fmt, ...)
    hostLog(stripColors(render(fmt, ...)))
  end

  --- Chat AND console. For what the user must see while looking at the game rather than at the
  --- console — recording starting and ending mid-combat, above all.
  function P.Announce(fmt, ...)
    local msg = render(fmt, ...)
    hostPrint(msg)
    hostLog(stripColors(msg))
  end

  -- Something moved: repaint the panel, then let the host republish on its own bus if it cares.
  -- The panel refreshes DIRECTLY rather than via a message — it owns the state it renders, so the
  -- bus hop the addon-local version used was never load-bearing.
  local function publishState()
    if P.RefreshPanel then P.RefreshPanel() end
    onChange()
  end

  --- Note that a review action has been run, so the panel can mark it without disabling it. Called
  --- by the slash handlers, so a typed command and a click mark it identically.
  function P.MarkReviewed(key)
    if reviewed[key] == nil or reviewed[key] then return false end
    reviewed[key] = true
    publishState()
    return true
  end

  --- The run as a list of step states, for the panel to render. Lives here rather than in the panel
  --- so the progression is testable without frames, and so the panel stays a dumb renderer.
  ---
  --- Strictly linear: exactly one step is `ready` at a time. `locked` steps are not yet reachable,
  --- `busy` is armed-or-recording, `done` is finished. The slash verbs are NOT gated this way — a
  --- run that cannot complete Experiment B can still be closed with the host's finish command.
  function P.Progress()
    local aBusy = (P.armed == "active") or (P.recording == "active")
    local bBusy = (P.armed == "suspended") or (P.recording == "suspended")
    local finished = (not P.run) and (completed.active or completed.suspended)

    local a = aBusy and "busy"
        or (completed.active and "done")
        or ((P.run and not bBusy) and "ready")
        or "locked"
    local b = bBusy and "busy"
        or (completed.suspended and "done")
        or ((P.run and completed.active and not aBusy) and "ready")
        or "locked"
    local fin = (finished and "done")
        or ((P.run and completed.suspended and not bBusy) and "ready")
        or "locked"
    -- `used` is green like `done` but stays clickable: these are read-only actions worth repeating.
    local function review(key)
        if not finished then return "locked" end
        return reviewed[key] and "used" or "ready"
    end

    return {
        -- Clickable whenever there is no run in flight, so the panel is the entry point rather than
        -- something you can only reach once you already knew the command. `done` while a run is
        -- active; ready again afterwards, since starting another is the obvious next thing.
        start = P.run and "done" or "ready",
        measureA = a, measureB = b, finish = fin,
        report = review("report"), dump = review("dump"),
        -- Its own state, not "ready": it sits outside the linear progression and the panel colours
        -- it separately, so it never reads as the next step to take. Only offered while there is
        -- actually a run to abandon — after `finish` the run is saved and there is nothing left to
        -- cancel, and a live-looking button that discards nothing is just a way to worry someone.
        cancel = (P.run or P.armed or P.recording) and "cancel" or "locked",
    }
  end

  return P
end
