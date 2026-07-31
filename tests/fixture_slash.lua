-- A throwaway host for LibKa0s-Slash-1.0: a schema, a settings store, and a recorder.
--
-- The Perf fixture next door is hard-bound to `T.lib:New(d)`, so this is a second file rather than
-- a parameterisation of that one — making fixture.lua generic would touch five green perf suites
-- for the sake of tidiness.
--
-- The schema is deliberately shaped to exercise every branch the library has: a bool, a number with
-- min/max/fmt (so clamping and the " px" suffix are reachable), a string with an enum, a string
-- that is empty (the "(none)" branch), a colour, and two pages — one of which is per-unit, so the
-- host's groupKey produces "bar / player"-style headers and the other a bare page name.

local T = _G.LK_TEST
local Fixture = {}

Fixture.UNITS = { "player", "target" }

-- Every row the fixture schema carries, in declaration order. `page` and `unit` are host concepts
-- the library only ever passes back through groupKey; `type`, `fmt`, `min`, `max`, `values` and
-- `default` are the parts the library itself reads.
local function buildRows()
  local rows = {
    { path = "showOnlyInCombat", page = "general", type = "bool", default = false },
    { path = "labelText", page = "general", type = "string", values = { none = true, short = true },
      default = "none" },
    { path = "emptyLabel", page = "general", type = "string", values = { [""] = true }, default = "" },
  }
  for _, unit in ipairs(Fixture.UNITS) do
    rows[#rows + 1] = { path = "units." .. unit .. ".barWidth", page = "bar", unit = unit,
      type = "number", min = 50, max = 500, fmt = "%d px", default = 200 }
    rows[#rows + 1] = { path = "units." .. unit .. ".barColor", page = "bar", unit = unit,
      type = "color", default = { r = 1, g = 1, b = 1, a = 1 } }
    rows[#rows + 1] = { path = "units." .. unit .. ".mirror", page = "bar", unit = unit,
      type = "bool", alwaysPerUnit = true, default = false }
  end
  return rows
end

local function deepCopy(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, val in pairs(v) do out[k] = deepCopy(val) end
  return out
end

--- A fresh host. `rec.chat` captures every line the instance prints, which is why the library takes
--- `print` as a descriptor field rather than reaching for the chat frame — the seam a headless
--- harness needs is the same one a host addon needs.
function Fixture.new(overrides)
  local rec = { chat = {}, refreshed = 0 }
  local rows = buildRows()
  local byPath, store = {}, {}
  for _, row in ipairs(rows) do
    byPath[row.path] = row
    store[row.path] = deepCopy(row.default)
  end

  local d = {
    slash = "/th",
    slashAliases = { "/testhost" },
    version = function() return "1.2.3" end,
    print = function(line) rec.chat[#rec.chat + 1] = line end,

    get = function(path) return store[path] end,
    set = function(path, value) store[path] = value; rec.refreshed = rec.refreshed + 1 end,
    findRow = function(path) return byPath[path] end,
    allRows = function() return rows end,
    applyDefault = function(row) store[row.path] = deepCopy(row.default) end,

    -- Two shapes in one host, exactly as AbsorbTracker has: per-unit pages group as
    -- "<page> / <unit>", everything else as the bare page name.
    groupKey = function(row)
      if row.unit then return row.page .. " / " .. row.unit end
      return row.page
    end,
  }

  rec.commands = {
    { "help", "List available commands", function() rec.instance:PrintHelp() end },
    { "list", "List every setting and its current value", function() rec.instance:CliList() end },
    { "get", "Print a setting's current value", function(rest) rec.instance:CliGet(rest) end },
    { "set", "Set a setting", function(rest) rec.instance:CliSet(rest) end },
    { "reset", "Reset one setting to its default", function(rest) rec.instance:CliReset(rest) end },
    { "version", "Print the version", function() rec.instance:CliVersion() end },
    { "config", "Open the settings panel", function() rec.chat[#rec.chat + 1] = "opened" end },
  }
  d.commands = rec.commands
  d.aliases = { options = "config" }

  for k, v in pairs(overrides or {}) do d[k] = v end

  rec.instance = T.slash:New(d)
  rec.rows, rec.store, rec.byPath = rows, store, byPath
  return rec.instance, rec
end

--- Strip WoW colour escapes, so an assertion about wording is not also an assertion about colour.
--- The cases that mean to pin colour do so explicitly, without this.
function Fixture.plain(s)
  return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

return Fixture
