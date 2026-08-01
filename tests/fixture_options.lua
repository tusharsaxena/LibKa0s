-- A throwaway host for LibKa0s-Options-1.0: a schema, a settings store, an AceGUI handle and a
-- recorder.
--
-- A THIRD fixture rather than a parameterisation of fixture_slash.lua, and the reason is the row
-- shape. The slash fixture's rows are chosen to reach the parser and formatter branches — a clamped
-- number, an enum, an empty string, a colour — and carry no `group`, `label`, `order`, `solo` or
-- `skipRender`, because the dispatcher never reads one. Every branch THIS module has is in exactly
-- those fields. Bolting them onto the slash rows would either mutate a table two suites share or
-- leave each fixture carrying the other's dead weight, so the two stay separate and each says what
-- it is for.
--
-- The schema is shaped to exercise the flow engine: two pages, three groups, a `solo` pivot, a
-- `skipRender` row the host draws itself, a `disabledIf` pair, an explicit `sorting`, an
-- `EditBox`-controlled string, and an odd row count in one group so a `pairWith` partner has a lone
-- row to attach to.

local T = _G.LK_TEST
local Fixture = {}

Fixture.PAGES = { "general", "bar" }

local function buildRows()
  return {
    -- general ────────────────────────────────────────────────────────────────────────────────
    { path = "locked", page = "general", group = "Master", order = 10, type = "bool",
      label = "Lock Position", desc = "When locked, nothing can be dragged.", default = false },
    { path = "showOnlyInCombat", page = "general", group = "Master", order = 20, type = "bool",
      label = "Show only in combat", desc = "Hide outside combat.", default = false },
    -- The third row of an odd group: left alone on its own row, which is what makes it a valid
    -- pairWith site. A fourth row here would silently disarm that case.
    { path = "showTooltips", page = "general", group = "Master", order = 30, type = "bool",
      label = "Show tooltips", default = true },
    -- string + no `values` list, declared as a free-text row. The fifth widget type (spec §5.2),
    -- which no AbsorbTracker row uses — so this fixture is the only thing that covers it.
    --
    -- Ordered FIRST in its group, ahead of the solo row below, and that is deliberate: a solo row
    -- that leads its group is flushed by the group's own Section heading anyway, so a maker that
    -- ignored `solo` entirely would still leave it alone on its line and the assertion could not
    -- fail. A non-solo row in front of it is what makes the flush observable.
    { path = "profileName", page = "general", group = "Performance", order = 5, type = "string",
      label = "Profile label", dialogControl = "EditBox", default = "" },
    { path = "throttleWindow", page = "general", group = "Performance", order = 10,
      type = "number", label = "Update throttle", desc = "Seconds between repaints.",
      default = 0.2, min = 0.05, max = 1, step = 0.05, fmt = "%.2f sec", solo = true },

    -- bar ────────────────────────────────────────────────────────────────────────────────────
    { path = "barWidth", page = "bar", group = "Size", order = 10, type = "number",
      label = "Bar Width", desc = "Width in pixels.", default = 200,
      min = 50, max = 500, step = 1, fmt = "%d px" },
    -- `min` is deliberately NOT a multiple of `step`. Snapping is specified as relative to the
    -- row's minimum, and with a min that divides evenly by the step the two implementations agree
    -- on every input — so a range like 10/1 leaves the distinction untestable.
    { path = "barHeight", page = "bar", group = "Size", order = 20, type = "number",
      label = "Bar Height", default = 25, min = 15, max = 105, step = 10 },
    { path = "barTexture", page = "bar", group = "Fill", order = 10, type = "string",
      label = "Bar Texture", default = "Blizzard", dialogControl = "LSM30_Statusbar",
      values = { Blizzard = true, Smooth = true, Aluminium = true }, solo = true },
    -- Deliberately does NOT declare hasAlpha: it is the row that proves the default is true. A
    -- default nothing asserts is a default nothing protects, which is how the old `false` survived.
    { path = "barColor", page = "bar", group = "Fill", order = 20, type = "color",
      label = "Bar Color", default = { r = 1, g = 1, b = 1, a = 1 },
      tooltip = "The bar's fill colour.",
      disabledIf = "useClassColor" },
    -- And the other side of it: a row opting out, which the old reader could not express — an
    -- absent field and a declared false were indistinguishable.
    { path = "borderColor", page = "bar", group = "Fill", order = 25, type = "color",
      label = "Border Color", default = { r = 0, g = 0, b = 0, a = 1 }, hasAlpha = false },
    { path = "useClassColor", page = "bar", group = "Fill", order = 30, type = "bool",
      label = "Use Class Color", default = false },
    -- An explicit order that is NOT the alphabetical one. That matters: an enum whose declared
    -- order happens to sort alphabetically (NONE / OUTLINE / THICKOUTLINE, say) makes the
    -- `sorting` assertion pass whether or not the implementation honours it.
    { path = "anchor", page = "bar", group = "Fill", order = 40, type = "string",
      label = "Anchor", default = "CENTER",
      values = { TOP = true, CENTER = true, BOTTOM = true },
      sorting = { "TOP", "CENTER", "BOTTOM" } },
    -- The OTHER enum shape: the Ka0s options schema's ordered array of { value =, text = }, where
    -- POSITION is the order and `sorting` is meaningless. Declared so that alphabetical and
    -- declared order disagree, for the same reason `anchor` above declares its `sorting` that way.
    { path = "growth", page = "bar", group = "Fill", order = 45, type = "string",
      label = "Growth", default = "RIGHT",
      values = { { value = "RIGHT", text = "Right" }, { value = "LEFT", text = "Left" } } },
    -- Kept in the schema so a reset still reaches it, but never drawn by the flow engine — the
    -- host renders it bespoke. Group-less on purpose: RenderRows emits a group's heading BEFORE it
    -- checks skipRender, so a named group here would draw an empty heading over nothing.
    { path = "mirror", page = "bar", order = 50, type = "bool", skipRender = true,
      label = "Use same styling as Player", default = true },

    -- units ──────────────────────────────────────────────────────────────────────
    -- A FILTERED page: two rows that differ only by `unit`. Without a filter dimension the
    -- difference between RenderSchema (one filter value) and RestoreDefaults (all of them) is
    -- structurally unobservable, and the deliberate asymmetry between them cannot be pinned.
    { path = "unitPlayerScale", page = "units", unit = "player", group = "Scale", order = 10,
      type = "number", label = "Player scale", default = 1, min = 0.5, max = 2, step = 0.1 },
    { path = "unitTargetScale", page = "units", unit = "target", group = "Scale", order = 20,
      type = "number", label = "Target scale", default = 1, min = 0.5, max = 2, step = 0.1 },
  }
end

local function deepCopy(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, val in pairs(v) do out[k] = deepCopy(val) end
  return out
end

--- A fresh host. Everything the descriptor hands the library is recorded on `rec`, so a test can
--- assert what the library ASKED the host to do as well as what it drew.
function Fixture.new(overrides)
  local rec = { chat = {}, timers = {}, restoredAll = 0, opened = {}, validated = 0 }
  local rows = buildRows()
  local byPath, store = {}, {}
  for _, row in ipairs(rows) do
    byPath[row.path] = row
    store[row.path] = deepCopy(row.default)
  end

  local d = {
    parentTitle   = "Test Host",
    mainPanelName = "TestHostMainPanel",

    print = function(line) rec.chat[#rec.chat + 1] = line end,

    get = function(path) return store[path] end,
    set = function(path, value) store[path] = value end,
    applyDefault = function(row) store[row.path] = deepCopy(row.default) end,
    findRow = function(path) return byPath[path] end,
    allRows = function() return rows end,

    --- Page filter, in declaration order within a group and groups in first-seen order — the same
    --- contract AbsorbTracker's NS.SchemaForPage has, reimplemented here rather than imported so
    --- the fixture does not quietly become a second copy of the addon.
    ---
    --- The second argument is the host's own filter (a unit, in AbsorbTracker), and it is honoured
    --- here on purpose: RenderSchema passes ctx.unit and RestoreDefaults deliberately does not, so
    --- a fixture that ignored it would leave that difference unobservable either way. A row with no
    --- `unit` is unfiltered and belongs to every filter value.
    rowsForPage = function(pageKey, filter)
      local out = {}
      for _, row in ipairs(rows) do
        if row.page == pageKey and (filter == nil or row.unit == nil or row.unit == filter) then
          out[#out + 1] = row
        end
      end
      return out
    end,

    -- A one-shot queue rather than a real clock: `rec.fireTimers()` is what advances it, so the
    -- colour throttle is observable instead of timing-dependent.
    scheduleTimer = function(fn, _delay)
      rec.timers[#rec.timers + 1] = fn
      return #rec.timers
    end,

    afterRestoreAll = function() rec.restoredAll = rec.restoredAll + 1 end,
    validate        = function() rec.validated = rec.validated + 1 end,
    getLSM          = function() return rec.lsm end,
  }

  for k, v in pairs(overrides or {}) do d[k] = v end

  function rec.fireTimers()
    local queued = rec.timers
    rec.timers = {}
    for _, fn in ipairs(queued) do fn() end
  end

  rec.instance = T.options:New(d)
  rec.rows, rec.store, rec.byPath, rec.d = rows, store, byPath, d
  return rec.instance, rec
end

--- Every widget below `w`, depth first. The layout assertions read structure rather than AceGUI
--- internals, which is what lets them survive a widget-mock change.
function Fixture.flatten(w, out)
  out = out or {}
  for _, child in ipairs(w.children or {}) do
    out[#out + 1] = child
    Fixture.flatten(child, out)
  end
  return out
end

--- The Flow rows a render produced, in order. A "row" is the full-width SimpleGroup the engine
--- wraps each pair in.
function Fixture.flowRows(scroll)
  local out = {}
  for _, child in ipairs(scroll.children or {}) do
    if child.type == "SimpleGroup" and child.layout == "Flow" then out[#out + 1] = child end
  end
  return out
end

--- The Flow row holding a widget with this label, or nil.
function Fixture.rowWithLabel(scroll, label)
  for _, row in ipairs(Fixture.flowRows(scroll)) do
    for _, w in ipairs(row.children or {}) do
      if w.labelText == label then return row end
    end
  end
end

return Fixture
