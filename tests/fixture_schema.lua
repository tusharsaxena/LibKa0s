-- tests/fixture_schema.lua — the fixture constructors the LibKa0s-Schema-1.0 suites share:
-- tests/test_schema.lua (the major, the reference stub, the path primitives, the registry and the
-- shape check) and tests/test_schema_write.lua (the write seam, defaults, the bulk bracket and the
-- profile reset's count).
--
-- Moved out of tests/test_schema.lua, unchanged, when issue #38 split that suite by pipeline stage.
-- One copy rather than two, for the reason tests/fixture_ids.lua gives: a fixture that drifted
-- between the suites would make one suite's case prove something another's does not. Why every
-- case builds its own fixture rather than sharing one is tests/test_schema.lua's header.
--
-- Loaded as `dofile("tests/fixture_schema.lua")`, which answers a table of the constructors:
-- `newRecorder`, `spies`, `onChangeSpy`, `newFlat`,
-- `rowAt`, `newInstance`, `newClosure`, `sortedKeys`.

local T = _G.LK_TEST

local Schema = T.schema

--- A recorder: one ordered log shared by every spy a fixture installs.
local function newRecorder()
  local rec = { log = {}, chat = {}, debugLines = {}, resolves = 0 }
  function rec.add(entry) rec.log[#rec.log + 1] = entry end
  function rec.joined() return table.concat(rec.log, ",") end
  function rec.count(prefix)
    local n = 0
    for _, e in ipairs(rec.log) do
      if e:sub(1, #prefix) == prefix then n = n + 1 end
    end
    return n
  end
  return rec
end

--- The host spies every descriptor carries. `debug` formats the line the way a host's sink would,
--- so a case can assert on the line a player would read.
local function spies(rec, d)
  d.debug = function(tag, fmt, ...)
    local line = ("[%s] " .. fmt):format(tag, ...)
    rec.debugLines[#rec.debugLines + 1] = line
    rec.add("debug")
  end
  d.announce = function(row, path, _, rid)
    rec.add("announce:" .. path)
    rec.lastAnnounce = { row = row, path = path, rid = rid }
  end
  d.print = function(line) rec.chat[#rec.chat + 1] = line end
  return d
end

local function onChangeSpy(rec, path)
  return function(value, rid)
    rec.add("onChange:" .. path)
    rec.lastOnChange = { value = value, rid = rid }
  end
end

--- F-flat: a flat profile store, a nested per-unit path, a validated number, a color table, a
--- sessionOnly closure row and the inverted minimap row whose storage is the GLOBAL store.
local function newFlat(overrides)
  local rec = newRecorder()
  local fx = { rec = rec, console = false }
  fx.db = {
    profile = {
      enabled = true, scale = 1, color = { r = 1, g = 1, b = 1, a = 1 },
      units = { player = { width = 200 } },
    },
    global = { minimap = { hide = false } },
  }
  fx.defaults = {
    profile = {
      enabled = true, scale = 1, color = { r = 1, g = 1, b = 1, a = 1 },
      units = { player = { width = 200 } },
    },
    global = { minimap = { hide = false } },
  }
  fx.rows = {
    { path = "enabled", type = "bool", page = "general", group = "General", default = true,
      onChange = onChangeSpy(rec, "enabled") },
    { path = "scale", type = "number", page = "general", group = "General", default = 1,
      validate = function(v)
        if type(v) ~= "number" then return false, "not a number" end
        if v < 0.5 or v > 2 then return false, "out of range" end
        return true
      end,
      onChange = onChangeSpy(rec, "scale") },
    { path = "color", type = "color", page = "general", group = "Look",
      default = { r = 1, g = 1, b = 1, a = 1 }, onChange = onChangeSpy(rec, "color") },
    { path = "units.player.width", type = "number", page = "units", group = "Player",
      default = 200, onChange = onChangeSpy(rec, "units.player.width") },
    { path = "debugConsole", type = "bool", page = "general", group = "Debug", default = false,
      sessionOnly = true,
      get = function() return fx.console end,
      set = function(v) fx.console = v end,
      onChange = onChangeSpy(rec, "debugConsole") },
    { path = "minimap", type = "bool", page = "general", group = "General", default = true,
      get = function() return not fx.db.global.minimap.hide end,
      set = function(v) fx.db.global.minimap.hide = not v end,
      onChange = onChangeSpy(rec, "minimap") },
  }
  local d = spies(rec, {
    rows = fx.rows,
    resolveRoot = function()
      rec.resolves = rec.resolves + 1
      return fx.db.profile, 1
    end,
  })
  for k, v in pairs(overrides or {}) do d[k] = v end
  fx.d = d
  fx.S = Schema:New(d)
  return fx.S, fx
end

local function rowAt(fx, path)
  for _, row in ipairs(fx.rows) do
    if row.path == path then return row end
  end
end

--- F-instance: the path is rooted at a runtime instance (a container, a meter window). The first
--- segment names the kind and is consumed by the resolver, so `first` is 2.
local function newInstance()
  local rec = newRecorder()
  local fx = { rec = rec, active = 1 }
  fx.members = { [1] = { width = 100 }, [2] = { width = 150 } }
  fx.rows = {
    { path = "member.width", type = "number", page = "members", group = "Size", default = 100,
      validate = function(v, rid)
        rec.add("validate:" .. tostring(rid))
        return type(v) == "number" and v > 0, "must be positive"
      end,
      onChange = onChangeSpy(rec, "member.width") },
  }
  local d = spies(rec, {
    rows = fx.rows,
    resolveRoot = function(_, id)
      local target = id or fx.active
      local m = fx.members[target]
      if not m then return nil, "no member" end
      return m, 2, target
    end,
  })
  fx.S = Schema:New(d)
  return fx.S, fx
end

--- F-closure: PrettyChat's shape. Every row stores through its own closure, there is no
--- resolveRoot at all, and `set` clears to absence when handed the default.
local function newClosure()
  local rec = newRecorder()
  local fx = { rec = rec, store = {} }
  fx.rows = {
    { path = "chat.color", type = "string", page = "chat", group = "Colors", default = "ff0000",
      get = function() return fx.store.color or "ff0000" end,
      set = function(v) if v == "ff0000" then fx.store.color = nil else fx.store.color = v end end },
    { path = "chat.prefix", type = "string", page = "chat", group = "Text", default = "abc",
      get = function() return fx.store.prefix or "abc" end,
      set = function(v) fx.store.prefix = type(v) == "string" and v:lower() or v end },
  }
  fx.S = Schema:New(spies(rec, { rows = fx.rows }))
  return fx.S, fx
end

local function sortedKeys(t)
  local out = {}
  for k in pairs(t) do out[#out + 1] = k end
  table.sort(out)
  return table.concat(out, ",")
end

return {
  newRecorder = newRecorder,
  spies = spies,
  onChangeSpy = onChangeSpy,
  newFlat = newFlat,
  rowAt = rowAt,
  newInstance = newInstance,
  newClosure = newClosure,
  sortedKeys = sortedKeys,
}
