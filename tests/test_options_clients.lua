-- tests/test_options_clients.lua -- the `clients` gate of the Options registries (WFP-LK-03).
--
-- A page, tab, row or landing section declared `clients = { "retail" }` does not exist on a Forever
-- client: nothing is built from it, so no category, no tab button, no widget out of the pool. The
-- mirror case holds for `{ "forever" }` on Retail. Each case sets the project constants itself, so
-- it proves the gate under either KA0S_KIT_CLIENT profile.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local mocks = T.mocks
local Fixture = dofile("tests/fixture_options.lua")
local bench = dofile("tests/fixture_widgets.lua")("ClientsBench").bench

local ABSENT = {}
local RETAIL  = { WOW_PROJECT_ID = 1,  WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CAMELOT = ABSENT }
local FOREVER = { WOW_PROJECT_ID = 18, WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CAMELOT = 18 }

--- Run `fn` with the project constants of `client`, restoring them afterwards.
local function on(client, fn)
  local saved = {}
  for k, v in pairs(client) do
    saved[k] = mocks[k]
    if rawequal(v, ABSENT) then mocks[k] = nil else mocks[k] = v end
  end
  local ok, err = pcall(fn)
  for k in pairs(client) do mocks[k] = saved[k] end
  if not ok then error(err, 0) end
end

--- The labels of the buttons a primary strip drew, in order.
local function stripLabels(ctx)
  local out = {}
  for _, b in ipairs(ctx.__tabKids or {}) do
    if b.__ka0sTabTipLabel then out[#out + 1] = b.__ka0sTabTipLabel end
  end
  return table.concat(out, "|")
end

-- test_gate_page_absent_on_forever
test("options clients: a page declared retail registers no builder on Forever, and does on Retail",
function()
  for _, case in ipairs({ { FOREVER, 0 }, { RETAIL, 1 } }) do
    on(case[1], function()
      local O = Fixture.new()
      local built = 0
      O.RegisterOptionsPage("gated", "Gated", function() built = built + 1 end, { clients = { "retail" } })
      O.RegisterOptionsPage("open", "Open", function() end)
      O.CreateOptionsPanel()
      assertEqual(built, case[2], "the gated builder ran " .. case[2] .. " times")
      local keys = {}
      for _, p in ipairs(O.__pages()) do keys[#keys + 1] = p.key end
      assertEqual(table.concat(keys, "|"), case[2] == 1 and "gated|open" or "open")
    end)
  end
end)

-- test_gate_tab_absent_on_forever
test("options clients: a gated tab has no button on Forever and the strip is laid without it", function()
  on(FOREVER, function()
    local O, _, ctx = bench()
    local tabs = {
      { key = "a", label = "Alpha" },
      { key = "r", label = "Retail only", clients = { "retail" } },
      { key = "b", label = "Beta" },
    }
    local buttons = O.TabStrip(ctx, { tabs = tabs, value = "a", onSelect = function() end })
    assertEqual(#buttons, 2, "two buttons")
    assertEqual(stripLabels(ctx), "Alpha|Beta")
    assertEqual(#ctx.__tabLayout.widths, 2, "the geometry holds two widths")
    assertEqual(#tabs, 3, "the host's table is untouched")
    local subs = O.SubTabStrip(ctx, mocks.CreateFrame("Frame", nil, mocks.UIParent),
      { tabs = tabs, value = "a", onSelect = function() end })
    assertEqual(#subs, 2, "the secondary strip gates the same way")
  end)
  on(RETAIL, function()
    local O, _, ctx = bench()
    local buttons = O.TabStrip(ctx, { tabs = {
      { key = "a", label = "Alpha" }, { key = "r", label = "R", clients = { "retail" } } },
      value = "a", onSelect = function() end })
    assertEqual(#buttons, 2, "Retail keeps both")
  end)
end)

test("options clients: a gated host tab and a gated group's rows leave the tabbed page", function()
  on(FOREVER, function()
    local O, _, ctx = bench({ rowsForPage = function()
      return {
        { path = "x", page = "p", group = "Keep", order = 1, type = "bool", label = "Kept", default = false },
        { path = "y", page = "p", group = "Gone", order = 1, type = "bool", label = "Dropped",
          default = false, clients = { "retail" } },
      }
    end })
    local host = { key = "Host", label = "Host", clients = { "retail" }, render = function() end }
    local _, keys = O.RenderTabbedSchema(ctx, "p", nil, nil, { tabs = { host } })
    assertEqual(table.concat(keys, "|"), "Keep", "no Gone group tab, no Host tab")
  end)
end)

-- test_gate_row_absent_on_forever
test("options clients: a gated row acquires no widget on Forever", function()
  local function rows(gated)
    return function()
      return {
        { path = "k", page = "p", group = "G", order = 1, type = "bool", label = "Kept", default = false },
        { path = "g", page = "p", group = "G", order = 2, type = "bool", label = "Gated", default = false,
          clients = gated },
      }
    end
  end
  on(FOREVER, function()
    local base, gatedN
    do
      local O, _, ctx = bench({ rowsForPage = rows(nil) })
      local before = #O.AceGUI.__created
      O.RenderSchema(ctx, "p")
      base = #O.AceGUI.__created - before
    end
    do
      local O, _, ctx = bench({ rowsForPage = rows({ "retail" }) })
      local before = #O.AceGUI.__created
      O.RenderSchema(ctx, "p")
      gatedN = #O.AceGUI.__created - before
    end
    assertTrue(gatedN < base, "the gated row built fewer widgets: " .. gatedN .. " vs " .. base)
  end)
end)

test("options clients: a gated landing section and line are not drawn on Forever", function()
  on(FOREVER, function()
    local O, _, ctx = bench()
    O.BuildLandingPage(ctx, { sections = {
      { heading = "Shown", rows = function() return { "/shown", { text = "/no", clients = { "retail" } } } end },
      { heading = "Hidden", clients = { "retail" }, rows = function() return { "/hidden" } end },
    } })
    local joined = {}
    for _, w in ipairs(O.AceGUI.__created) do
      if w.text then joined[#joined + 1] = tostring(w.text) end
    end
    local all = table.concat(joined, "|")
    assertTrue(all:find("Shown", 1, true) ~= nil, "the open section drew")
    assertNil(all:find("Hidden", 1, true), "the gated heading did not")
    assertNil(all:find("/hidden", 1, true), "nor its line")
  end)
end)

-- test_gate_forever_only_absent_on_retail
test("options clients: a forever-only page, tab and row are absent on Retail", function()
  on(RETAIL, function()
    local O = Fixture.new()
    local built = 0
    O.RegisterOptionsPage("f", "F", function() built = built + 1 end, { clients = { "forever" } })
    O.CreateOptionsPanel()
    assertEqual(built, 0, "page")
    local O2, _, ctx = bench()
    local b = O2.TabStrip(ctx, { tabs = { { key = "a", label = "A" },
      { key = "f", label = "F", clients = { "forever" } } }, value = "a", onSelect = function() end })
    assertEqual(#b, 1, "tab")
  end)
  on(FOREVER, function()
    local O = Fixture.new()
    local built = 0
    O.RegisterOptionsPage("f", "F", function() built = built + 1 end, { clients = { "forever" } })
    O.CreateOptionsPanel()
    assertEqual(built, 1, "Forever builds its own page")
  end)
end)

test("options clients: an unknown token raises rather than hiding silently", function()
  on(RETAIL, function()
    local O = Fixture.new()
    local ok = pcall(O.RegisterOptionsPage, "x", "X", function() end, { clients = { "retial" } })
    assertFalse(ok)
  end)
end)

-- test_gate_reset_walks_only_gated_in_rows
test("options clients: the page Defaults and Reset all never write a row gated out for this client", function()
  for _, case in ipairs({ { FOREVER, "gForever", "gRetail" }, { RETAIL, "gRetail", "gForever" } }) do
    on(case[1], function()
      local calls = {}
      local O, rec = Fixture.new({ applyDefault = function(row) calls[#calls + 1] = row.path end })
      local rows = rec.d.allRows()
      rows[#rows + 1] = { path = "gRetail", page = "bar", group = "Size", order = 90, type = "bool",
        default = false, clients = { "retail" } }
      rows[#rows + 1] = { path = "gForever", page = "bar", group = "Size", order = 91, type = "bool",
        default = false, clients = { "forever" } }
      local function ran(path)
        for _, p in ipairs(calls) do if p == path then return true end end
        return false
      end
      O.RestoreDefaults("bar")
      assertTrue(ran("barWidth"), "an ungated row is reset by the page Defaults")
      assertTrue(ran(case[2]), "the row for this client is reset")
      assertFalse(ran(case[3]), "the row for the other client is not touched by the page Defaults")
      calls = {}
      O.RestoreAllDefaults()
      assertTrue(ran("barWidth"), "an ungated row is reset by Reset all")
      assertTrue(ran(case[2]), "the row for this client is reset by Reset all")
      assertFalse(ran(case[3]), "the row for the other client is not touched by Reset all")
    end)
  end
end)

-- test_gate_navrail_entries
test("options clients: a nav-rail entry for another client gets no button", function()
  for _, case in ipairs({ { FOREVER, 2 }, { RETAIL, 3 } }) do
    on(case[1], function()
      local O, _, ctx = bench()
      local buttons = O.NavRail(ctx, { entries = {
        { key = "a", label = "Alpha" },
        { key = "r", label = "Retail only", clients = { "retail" } },
        { key = "b", label = "Beta" } }, value = "a", onSelect = function() end })
      assertEqual(#buttons, case[2], "entries drawn")
    end)
  end
end)
