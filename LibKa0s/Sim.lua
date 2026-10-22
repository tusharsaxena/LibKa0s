-- LibKa0s-Sim-1.0 — the in-client simulator's shell: the Compat answer seam.
--
-- ── WHY THIS IS A LIBRARY ────────────────────────────────────────────────────────────────────
--
-- Three hosts (DropWatcher today; LootHistory and BankLedger next) simulate the client the same
-- way: every client read and every outward action goes through the host's own Compat table, and
-- while a simulation runs that table answers from the simulator instead of the client. DropWatcher
-- wrote the seam first (core/SimSeam.lua); the other two would have copied it. The owner ruled the
-- seam, the session and the step machine into one major with one set of semantics (LibKa0s#54,
-- the design challenge's OWNER_SCOPE C), so a fix to "a guarded member never reaches the client"
-- is made once.
--
-- ── THE SEAM ─────────────────────────────────────────────────────────────────────────────────
--
-- Sim:NewSeam(compat, opts) wraps the host's Compat table IN PLACE, once, at file load: every
-- function member not in opts.pure becomes a closure whose idle path is one upvalue-field test,
--
--   if state.active and (g or not state.bypass) then return answer(key, live, g, ...) end
--   return live(...)
--
-- so an idle seam costs one table read per call and allocates nothing. While a bound session is
-- active, `answer` hands the call to the key's provider as provider(fallback, ...), where fallback
-- is opts.guarded[key] or the live member; with no provider, fallback(...) answers. A guarded member
-- never reaches the client while active, inside Live included, and a provider's first argument is
-- the guarded answer, never live. Idle, a guarded member calls live.
--
-- The seam's active flag is driven only by a bound session (Sim:New, the next commit of this
-- release). Until one binds, the seam is idle.
--
-- ── WHAT IT DELIBERATELY IS NOT ──────────────────────────────────────────────────────────────
--
--   * no query of the active state or of a key's guarded status on the seam (OWNER_SCOPE C.7):
--     the session answers whether it is active, and a host knows its own guarded keys;
--   * no auto-wrap metatable on the host's table (C.8): a member added or replaced after NewSeam
--     shows up in seam:Unwrapped(), and every host suite asserts that list is empty;
--   * no restriction or chat-lockdown simulation (C.9): that is host code (DropWatcher);
--   * no SavedVariables: the library never reads or writes one; session-only stores are the host's;
--   * no behavior flags: every host difference is data, a host callback with one meaning, or a
--     presentation argument.
--
-- ── PAYLOAD WEIGHT ───────────────────────────────────────────────────────────────────────────
--
-- Whole-folder vendoring ships this major into every consumer. Its file bodies only define
-- functions: no frame, timer or event registration exists until NewSeam or New is called, so a
-- host that never simulates pays parse time and nothing else.
--
-- Depends on LibStub and LibKa0s-Core-1.0. No Core member is called; the gate keeps the payload's
-- presence a single question.

local core = LibStub and LibStub("LibKa0s-Core-1.0", true)
local NEEDS_CORE = 1
if not core or (core.MINOR or 0) < NEEDS_CORE then return end   -- no NewLibrary; module absent

local MAJOR, MINOR = "LibKa0s-Sim-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.MAJOR, lib.MINOR = MAJOR, MINOR
lib.MODULES = lib.MODULES or {}
lib.MODULES.Sim = MINOR

local type, pairs, ipairs, tostring, select, error, pcall, xpcall, unpack, rawget, rawequal =
  type, pairs, ipairs, tostring, select, error, pcall, xpcall, unpack, rawget, rawequal
local sort = table.sort

-- seam -> its private state; compat -> the seam that wrapped it. Weak-keyed, so a host table that
-- is dropped takes its seam with it. Sim:New (the session) reaches a seam's state through STATE.
local STATE = setmetatable({}, { __mode = "k" })
local WRAPPED = setmetatable({}, { __mode = "k" })

--- Pack a call's answers with their count, so nil holes survive the unpack.
local function pack(...) return { n = select("#", ...), ... } end

--- The error and its stack as one string: the client's debugstack, else Lua's own traceback.
local function traceback(e)
  local msg = tostring(e)
  local ds = rawget(_G, "debugstack")
  if type(ds) == "function" then return msg .. "\n" .. tostring(ds(3)) end
  local dbg = rawget(_G, "debug")
  if type(dbg) == "table" and type(dbg.traceback) == "function" then return dbg.traceback(msg, 3) end
  return msg .. "\n(no stack available)"
end

--- Answer member `key` for an active session: its provider handed the fallback, or the fallback.
local function answer(state, key, live, g, ...)
  local fallback = g or live
  local provider = state.providers[key]
  if provider then return provider(fallback, ...) end
  return fallback(...)
end

--- One wrapped member. The idle path is the single upvalue-field test the header describes.
local function wrap(state, key, live, g)
  return function(...)
    if state.active and (g or not state.bypass) then return answer(state, key, live, g, ...) end
    return live(...)
  end
end

--- Raise unless `opts` describes a seam NewSeam can build.
local function checkOpts(compat, opts)
  if type(compat) ~= "table" then error(MAJOR .. ": NewSeam(compat, opts): compat must be a table", 3) end
  if type(opts) ~= "table" then error(MAJOR .. ": NewSeam(compat, opts): opts must be a table", 3) end
  if type(opts.name) ~= "string" or opts.name == "" then
    error(MAJOR .. ": NewSeam: opts.name must be a non-empty string", 3)
  end
  if opts.debug ~= nil and type(opts.debug) ~= "function" then
    error(MAJOR .. ": NewSeam(" .. opts.name .. "): opts.debug must be a function", 3)
  end
  if WRAPPED[compat] then
    error(MAJOR .. ": NewSeam(" .. opts.name .. "): this compat table is already wrapped", 3)
  end
end

--- The keys NewSeam wraps: every function member not in `pure`, sorted.
local function wrappableKeys(compat, pure)
  local keys = {}
  for key, member in pairs(compat) do
    if type(member) == "function" and not pure[key] then keys[#keys + 1] = key end
  end
  sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  return keys
end

--- Raise on a guarded entry that names no wrapped member or whose answer is not a function.
local function checkGuarded(name, guarded, isKey)
  for key, fn in pairs(guarded) do
    if not isKey[key] then
      error(MAJOR .. ": NewSeam(" .. name .. "): guarded key '" .. tostring(key)
        .. "' is not a wrapped member (pure, unknown or not a function)", 3)
    end
    if type(fn) ~= "function" then
      error(MAJOR .. ": NewSeam(" .. name .. "): guarded['" .. tostring(key) .. "'] must be a function", 3)
    end
  end
end

--- Write one line to the state's debug sink. A sink that raises never masks the caller's error.
local function debugLine(state, fmt, ...)
  local sink = state.debug
  if type(sink) == "function" then pcall(sink, "Sim", fmt, ...) end
end

--- seam:Live's body: run fn with bypass on, restore it on every exit, keep the original error.
local function liveCall(state, fn, ...)
  if type(fn) ~= "function" then error(MAJOR .. ": " .. state.name .. ": Live(fn): fn must be a function", 3) end
  local args, trace = pack(...), nil
  local function run() return fn(unpack(args, 1, args.n)) end
  local function onError(e) trace = traceback(e); return e end
  local was = state.bypass
  state.bypass = true
  local out = pack(xpcall(run, onError))
  state.bypass = was
  if not out[1] then
    debugLine(state, "%s: Live raised: %s", state.name, trace or tostring(out[2]))
    error(out[2], 0)
  end
  return unpack(out, 2, out.n)
end

--- The seam's four members, closed over its state. Dot-defined with an ignored self, so a
--- LibStub upgrade never matters to an instance a host already holds.
local function seamMembers(state, compat)
  local seam = {}
  function seam.SetProvider(_, key, fn)
    if not state.isKey[key] then
      error(MAJOR .. ": " .. state.name .. ": SetProvider: '" .. tostring(key)
        .. "' is not a wrapped member (pure, unknown or not a function)", 2)
    end
    if fn ~= nil and type(fn) ~= "function" then
      error(MAJOR .. ": " .. state.name .. ": SetProvider('" .. key .. "'): the provider must be a function", 2)
    end
    if fn ~= nil and state.providers[key] ~= nil then
      error(MAJOR .. ": " .. state.name .. ": SetProvider('" .. key
        .. "'): the key already has a provider; release it with nil first", 2)
    end
    state.providers[key] = fn
  end
  function seam.Live(_, fn, ...) return liveCall(state, fn, ...) end
  function seam.Keys()
    local out = {}
    for i, key in ipairs(state.keys) do out[i] = key end
    return out
  end
  function seam.Unwrapped()
    local out = {}
    for key, member in pairs(compat) do
      if type(member) == "function" and not state.pure[key] and not rawequal(state.wrappers[key], member) then
        out[#out + 1] = key
      end
    end
    sort(out, function(a, b) return tostring(a) < tostring(b) end)
    return out
  end
  return seam
end

--- Wrap the host's Compat table in place, once, and answer its seam.
--- @param compat table the host's own Compat table
--- @param opts table { name = string, pure = {[key]=true}?, guarded = {[key]=fn}?, debug = fn? }
--- @return table seam with SetProvider(key, fn), Live(fn, ...), Keys() and Unwrapped()
function lib:NewSeam(compat, opts)   -- luacheck: ignore 212/self
  checkOpts(compat, opts)
  local pure, guarded = opts.pure or {}, opts.guarded or {}
  local keys = wrappableKeys(compat, pure)
  local isKey = {}
  for _, key in ipairs(keys) do isKey[key] = true end
  checkGuarded(opts.name, guarded, isKey)

  local state = {
    name = opts.name, debug = opts.debug, active = false, bypass = false,
    pure = pure, keys = keys, isKey = isKey, providers = {}, wrappers = {},
  }
  for _, key in ipairs(keys) do
    local w = wrap(state, key, compat[key], guarded[key])
    state.wrappers[key] = w
    compat[key] = w
  end
  local seam = seamMembers(state, compat)
  STATE[seam] = state
  WRAPPED[compat] = seam
  return seam
end
