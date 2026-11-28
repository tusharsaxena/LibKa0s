-- tests/test_verdict_settings.lua -- LibKa0s-Verdict-1.0's settings section (VerdictSettings.lua):
-- the six comparison settings as schema rows a host registers under its own root, their defaults
-- (Ka0s Drop Watcher's defaults/Profile.lua `comparison` block), the pure halves of the weights and
-- unwanted-types editors (Drop Watcher's settings/Editors.lua, ported with the client named per
-- call), and the drawn section on a LibKa0s-Options-1.0 page, every editor write handed to the
-- host's `spec.set` as a fresh whole value. Drop Watcher's test_settings_pages Comparison and
-- editors cases, ported.
--
-- The page is tests/fixture_options.lua's host, an Options instance; the player is the spec's
-- `reads` (a mage, Arcane 62 on Retail, the Fire tree on WoW Forever), so no client mock is needed.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")

local V = T.mocks.LibStub("LibKa0s-Verdict-1.0")
local St = V.Settings

local HASTE, INT, STR = "ITEM_MOD_HASTE_RATING_SHORT", "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_STRENGTH_SHORT"

-- A host: a store keyed by path, the spec the section is handed, and what it printed.
local function host(client, over)
  local store, writes, printed = {}, {}, {}
  local reads = {
    UnitClass = function() return "Mage", "MAGE", 8 end,
    PlayerSpecID = function() return client == "forever" and 1487 or 62 end,
    PlayerTalentTree = function()
      if client == "forever" then return { index = 2, name = "Fire" } end
      return nil
    end,
    SpecName = function(id) return ({ [62] = "Arcane", [63] = "Fire", [64] = "Frost" })[id] end,
    TalentTreeNames = function()
      if client == "forever" then return { "Arcane", "Fire", "Frost" } end
      return {}
    end,
  }
  local spec = {
    root = "comparison", client = client, reads = reads,
    get = function(path) return store[path] end,
    set = function(path, v) writes[#writes + 1] = path; store[path] = v; return true end,
    print = function(line) printed[#printed + 1] = line end,
  }
  for k, v in pairs(over or {}) do spec[k] = v end
  return spec, store, writes, printed
end

local seq = 0
local function page()
  local O = Fixture.new()
  seq = seq + 1
  local ctx = O.CreatePanel("VerdictSettingsBench" .. seq, "Comparison " .. seq, {})
  return O, ctx, O.EnsureScroll(ctx)
end

local function find(scroll, wtype, label)
  for _, w in ipairs(Fixture.flatten(scroll)) do
    if w.type == wtype and (w.labelText == label or w.text == label) then return w end
  end
end

local function rowsByKey(rows)
  local out = {}
  for _, r in ipairs(rows) do out[r.key] = r end
  return out
end

-- ── the version ──────────────────────────────────────────────────────────────────────────────

test("verdict settings: VerdictSettings is at minor 2, paired on the Verdict shell's minor", function()
  assertEqual(V.MODULES.VerdictSettings, 2)
  assertEqual(V.__settingsMinor, 2)
  assertEqual(V.__settingsShellMinor, V.MINOR)
  for _, name in ipairs({ "Rows", "Section", "Tabs", "Defaults" }) do
    assertEqual(type(St[name]), "function", "lib.Settings." .. name)
  end
end)

-- ── the defaults and the rows ────────────────────────────────────────────────────────────────

test("verdict settings: the six defaults are Drop Watcher's (defaults/Profile.lua comparison)", function()
  local D = St.DEFAULTS
  assertEqual(D.scorer, "auto")
  assertEqual(D.sidegradeBand, 0)
  assertFalse(D.compareOwned)
  assertTrue(D.heirloomProtect)
  assertEqual(next(D.weights), nil)
  assertEqual(next(D.undesired), nil)
  local n = 0
  for _ in pairs(D) do n = n + 1 end
  assertEqual(n, 6)
  local a, b = St.Defaults(), St.Defaults()
  assertTrue(a.weights ~= b.weights and a.weights ~= D.weights, "Defaults() is a fresh copy each call")
  assertEqual(a.scorer, "auto")
end)

test("verdict settings: Rows answers the six rows at the host's root, in Drop Watcher's order and shape", function()
  local spec = host("retail", { page = "comparison" })
  local rows = St.Rows(spec)
  assertEqual(#rows, 6)
  local paths = {}
  for i, r in ipairs(rows) do paths[i] = r.path end
  assertEqual(table.concat(paths, ","), "comparison.scorer,comparison.sidegradeBand,comparison.compareOwned,"
    .. "comparison.heirloomProtect,comparison.weights,comparison.undesired")
  local by = rowsByKey(rows)
  assertEqual(by.scorer.type, "string"); assertEqual(by.scorer.default, "auto")
  local values = {}
  for i, v in ipairs(by.scorer.values) do values[i] = v.value .. "=" .. v.text end
  assertEqual(table.concat(values, ","), "auto=Automatic,pawn=Pawn,weights=My weights,none=None")
  assertEqual(by.scorer.label, "Score with")
  assertEqual(by.sidegradeBand.type, "number")
  assertEqual(by.sidegradeBand.min .. "," .. by.sidegradeBand.max .. "," .. by.sidegradeBand.step, "0,20,1")
  assertEqual(by.compareOwned.type, "bool"); assertFalse(by.compareOwned.default)
  assertEqual(by.heirloomProtect.label, "Protect heirlooms"); assertTrue(by.heirloomProtect.default)
  assertEqual(by.weights.type, "map"); assertTrue(by.weights.skipRender)
  assertEqual(by.undesired.type, "map"); assertTrue(by.undesired.skipRender)
  assertEqual(by.scorer.group, "Scoring"); assertEqual(by.heirloomProtect.group, "Scoring")
  assertEqual(by.weights.group, "Weights"); assertEqual(by.undesired.group, "Unwanted types")
  for _, r in ipairs(rows) do
    assertEqual(r.page, "comparison", r.path .. " carries the host's page")
    assertTrue(type(r.tooltip) == "string" and r.tooltip ~= "", r.path .. " has a tooltip")
    assertEqual(type(r.validate), "function", r.path .. " has its check")
  end
  assertTrue(by.weights.default ~= St.DEFAULTS.weights, "a map row's default is its own table")
end)

test("verdict settings: the rows' checks are Drop Watcher's", function()
  local by = rowsByKey(St.Rows(host("retail")))
  assertTrue(by.scorer.validate("pawn")); assertFalse(by.scorer.validate("best"))
  assertTrue(by.sidegradeBand.validate(20)); assertFalse(by.sidegradeBand.validate(21))
  assertFalse(by.sidegradeBand.validate(0 / 0))
  assertTrue(by.compareOwned.validate(false)); assertFalse(by.compareOwned.validate(1))
  assertTrue(by.weights.validate({ [62] = { [HASTE] = 1.5 }, ["MAGE:2"] = { [INT] = 1 } }))
  assertFalse(by.weights.validate({ [62] = { [HASTE] = "x" } }))
  assertFalse(by.weights.validate({ mage = {} }), "a key is a specID or <CLASS>:<tree>")
  assertFalse(by.weights.validate(5))
  assertTrue(by.undesired.validate({ [62] = { ["2:15"] = true } }))
  assertFalse(by.undesired.validate({ [62] = { ["2:15"] = 1 } }))
  assertFalse(by.undesired.validate({ [62] = { dagger = true } }))
end)

test("verdict settings: another root, no page, and the host's words", function()
  local L = setmetatable({ ["Score with"] = "Bewerten mit", ["Scoring"] = "Wertung" },
    { __index = function(_, k) return k end })
  local rows = St.Rows(host("retail", { root = "verdict.", L = L }))
  assertEqual(rows[1].path, "verdict.scorer", "a trailing dot is not doubled")
  assertNil(rows[1].page)
  assertEqual(rows[1].label, "Bewerten mit")
  assertEqual(rows[1].group, "Wertung")
  assertEqual(rows[2].label, "Sidegrade band", "a word the table lacks is the library's")
  assertEqual(St.Rows({})[1].path, "comparison.scorer", "the root defaults to comparison")
end)

-- ── the editors' pure halves ─────────────────────────────────────────────────────────────────

test("verdict settings: a weight write is a fresh map; 0 removes the stat and an emptied spec", function()
  local stored = { [62] = { [HASTE] = 1 } }
  local out = St.WithWeight(stored, 62, "ITEM_MOD_CRIT_RATING_SHORT", 0.5)
  assertNil(stored[62].ITEM_MOD_CRIT_RATING_SHORT, "the stored map is not touched")
  assertEqual(out[62].ITEM_MOD_CRIT_RATING_SHORT, 0.5)
  assertEqual(St.Weight(out, 62, HASTE), 1)
  assertEqual(St.Weight(out, 63, HASTE), 0, "unset reads 0")
  out = St.WithWeight(St.WithWeight(out, 62, "ITEM_MOD_CRIT_RATING_SHORT", 0), 62, HASTE, 0)
  assertNil(out[62])
  assertEqual(St.WithWeight(nil, 70, STR, 1)[70][STR], 1, "from no map")
end)

test("verdict settings: a weight slider runs -5..20 and stretches to a stored weight beyond it (LibKa0s#107)", function()
  assertEqual(St.WEIGHT_MIN .. "," .. St.WEIGHT_MAX .. "," .. St.WEIGHT_STEP, "-5,20,0.05")
  local function range(v) local lo, hi = St.WeightRange(v); return lo .. "," .. hi end
  assertEqual(range(3), "-5,20", "a value inside keeps the range")
  assertEqual(range(nil), "-5,20", "unset")
  assertEqual(range(-5), "-5,20"); assertEqual(range(20), "-5,20", "the ends are inside")
  assertEqual(range(27), "-5,27", "above: the top stretches to it")
  assertEqual(range(27.3), "-5,28", "to the whole number past it, so a step from the bottom stays whole")
  assertEqual(range(-8), "-8,20", "below: the bottom stretches to it")
  assertEqual(range(-8.4), "-9,20")
  assertEqual(range("x"), "-5,20", "not a number")
  assertEqual(range(math.huge), "-5,20", "an infinite value stretches nothing")
  assertEqual(range(-math.huge), "-5,20")
  assertEqual(range(0 / 0), "-5,20", "nor does NaN")
end)

test("verdict settings: a spec's stats are its primary stat, Stamina and the four secondaries", function()
  local fury = St.StatsFor(72, "retail")
  assertEqual(fury[1], STR)
  assertEqual(#fury, 6)
  assertEqual(#St.StatsFor(nil, "retail"), 8, "all three primaries for an unknown spec")
  assertEqual(St.StatsFor("MAGE:2", "forever")[1], INT, "a Forever tree's primary")
  assertEqual(#St.StatsFor("MAGE:2", "retail"), 8, "a Forever key on Retail's list is unknown")
  assertEqual(St.StatLabel(HASTE, {}), "Haste")
  assertEqual(St.StatLabel(HASTE, { [HASTE] = "Tempo" }), "Tempo", "the client's own GlobalString first")
end)

test("verdict settings: unwanted types are the class's weapons, then shields where a spec carries one", function()
  local C = V.C
  local keys = {}
  for _, c in ipairs(St.UndesiredChoices("PALADIN", "retail")) do keys[#keys + 1] = c.key end
  assertEqual(keys[#keys], V.SubClassKey(C.ITEM_CLASS.ARMOR, C.ARMOR_SUBCLASS.SHIELD))
  local rogue = St.UndesiredChoices("ROGUE", "retail")
  assertEqual(#rogue, 5)
  for _, c in ipairs(rogue) do assertTrue(c.key:match("^" .. C.ITEM_CLASS.WEAPON .. ":") ~= nil, c.key) end
  assertEqual(#St.UndesiredChoices("NOPE", "retail"), 0)
  assertEqual(#St.UndesiredChoices("ROGUE", "forever"), 7, "Forever's rogue: bows, guns and crossbows, no axe")
  assertEqual(St.UndesiredChoices("MAGE", "retail")[1].label, "One-handed swords")
end)

test("verdict settings: an unwanted mark is a fresh map, and the last one cleared drops the spec", function()
  local stored = {}
  local out = St.WithUndesired(stored, 62, "2:15", true)
  assertEqual(next(stored), nil, "the stored map is not touched")
  assertTrue(St.IsUndesired(out, 62, "2:15"))
  assertFalse(St.IsUndesired(out, 63, "2:15"))
  assertNil(St.WithUndesired(out, 62, "2:15", false)[62])
end)

test("verdict settings: the spec strip keeps the remembered spec, else yours, else the first", function()
  local list = St.ClassSpecs("MAGE", function(id) return id == 63 and "Fire" or nil end, "retail")
  assertEqual(#list, 3)
  assertEqual(list[2].label, "Fire")
  assertEqual(list[1].label, "62", "an unnamed spec reads its id")
  assertEqual(St.PickSpec(list, 64, 63), 64)
  assertEqual(St.PickSpec(list, 250, 63), 63)
  assertEqual(St.PickSpec(list, nil, 250), 62)
  assertNil(St.PickSpec({}, 62, 62))
end)

test("verdict settings: on Forever the strip lists your class's talent trees by name", function()
  local list = St.ClassSpecs("MAGE", St.SpecNamer(function() return "spec" end, { "Arcane", "Fire" }), "forever")
  assertEqual(#list, 3)
  assertEqual(list[1].key, "MAGE:1"); assertEqual(list[1].label, "Arcane")
  assertEqual(list[3].key, "MAGE:3"); assertEqual(list[3].label, "Talent tree 3", "a tree the client does not name")
  assertEqual(St.PickSpec(list, nil, "MAGE:2"), "MAGE:2")
  assertEqual(St.SpecNamer(function(id) return id == 62 and "Arcane" end)(62), "Arcane", "a Retail spec by its name")
end)

test("verdict settings: the import's line says what came in, or why nothing did", function()
  local text = St.ImportText({ name = "Mine", weights = { a = 1, b = 2 }, skipped = { "Dps" } }, "Arcane")
  assertEqual(text, "Imported Mine into Arcane: 2 weights. Not scored: Dps.")
  assertTrue(St.ImportText("format"):find("not a Pawn scale string", 1, true) ~= nil)
  assertEqual(St.ImportText("noSpec"), "Pick a specialization first.")
  assertTrue(St.ImportText("noStats"):find("Drop Watcher", 1, true) == nil, "the library names no addon")
end)

-- ── the reads the strip takes ────────────────────────────────────────────────────────────────

test("verdict settings: Reads.SpecName and Reads.TalentTreeNames answer their absent values", function()
  local R = V.Reads
  assertNil(R.SpecName("x"), "not a number")
  assertEqual(type(R.TalentTreeNames()), "table")
end)

-- ── the drawn section ────────────────────────────────────────────────────────────────────────

test("verdict settings: Weights draws your class's specs as a sub-strip and one slider per stat", function()
  local spec = host("retail")
  local O, ctx, scroll = page()
  St.Section(ctx, O, spec)   -- the whole section: Scoring, then Weights, then Unwanted types
  assertEqual(ctx.activeSubTab["Weights"], 62, "the strip opens on your spec")
  assertTrue(find(scroll, "Slider", "Intellect") ~= nil, "the spec's primary stat")
  assertNil(find(scroll, "Slider", "Strength"), "and not another's")
  assertTrue(find(scroll, "Slider", "Haste") ~= nil)
end)

local function weightsTab(spec)
  local O, ctx, scroll = page()
  local view = St.Section(ctx, O, spec, "weights")
  return O, ctx, scroll, view
end

test("verdict settings: a weight slider hands the whole map to spec.set, for the spec on screen", function()
  local spec, store, writes = host("retail")
  local _, ctx, scroll = weightsTab(spec)
  assertEqual(#ctx.__subTabKids, 3)
  find(scroll, "Slider", "Haste"):__fire("OnMouseUp", 1.5)
  assertEqual(writes[#writes], "comparison.weights")
  assertEqual(store["comparison.weights"][62][HASTE], 1.5)
  ctx.__subTabKids[2]:__fire("OnClick")
  assertEqual(ctx.activeSubTab["Weights"], 63)
  -- the click re-renders the page through the host's renderer; this bench has none, so draw again
  local O2, ctx2, scroll2 = page()
  ctx2.activeSubTab = { ["Weights"] = 63 }
  St.Section(ctx2, O2, spec, "weights")
  find(scroll2, "Slider", "Haste"):__fire("OnMouseUp", 0.75)
  local w = store["comparison.weights"]
  assertEqual(w[63][HASTE], 0.75)
  assertEqual(w[62][HASTE], 1.5, "the first spec's weights are kept")
end)

test("verdict settings: on Forever the strip opens on your top talent tree", function()
  local spec, store = host("forever")
  local _, ctx, scroll = weightsTab(spec)
  assertEqual(#ctx.__subTabKids, 3)
  assertEqual(ctx.activeSubTab["Weights"], "MAGE:2")
  find(scroll, "Slider", "Haste"):__fire("OnMouseUp", 1.5)
  assertEqual(store["comparison.weights"]["MAGE:2"][HASTE], 1.5)
end)

test("verdict settings: the Pawn import box replaces the spec on screen's weights and says what came in", function()
  local spec, store, _, printed = host("retail")
  store["comparison.weights"] = { [63] = { [HASTE] = 2 } }
  local _, _, scroll = weightsTab(spec)
  local box = find(scroll, "EditBox", "Import a Pawn scale")
  assertTrue(box ~= nil, "the import box")
  box:__fire("OnEnterPressed", '( Pawn: v1: "Mine": Intellect=1.2, HasteRating=0.7, Dps=4 )')
  local w = store["comparison.weights"]
  assertEqual(w[62][INT], 1.2)
  assertEqual(w[62][HASTE], 0.7)
  assertEqual(w[63][HASTE], 2, "another spec's weights are kept")
  assertTrue(printed[1]:find("Imported Mine into Arcane: 2 weights.", 1, true) ~= nil, printed[1])
  assertTrue(printed[1]:find("Not scored: Dps.", 1, true) ~= nil, printed[1])
  box:__fire("OnEnterPressed", "Intellect=9")
  assertEqual(store["comparison.weights"][62][INT], 1.2, "a string that is not Pawn's writes nothing")
  assertTrue(printed[2]:find("not a Pawn scale string", 1, true) ~= nil, printed[2])
end)

test("verdict settings: an out-of-range Pawn import shows its true values, and a slider write keeps them (LibKa0s#107)", function()
  local spec, store = host("retail")
  local _, _, scroll = weightsTab(spec)
  find(scroll, "EditBox", "Import a Pawn scale"):__fire("OnEnterPressed",
    '( Pawn: v1: "Wide": Intellect=27, HasteRating=-8, CritRating=1 )')
  local w = store["comparison.weights"]
  assertEqual(w[62][INT], 27); assertEqual(w[62][HASTE], -8)
  -- the import re-renders the page through the host's renderer; this bench has none, so draw again
  _, _, scroll = weightsTab(spec)
  local int, haste = find(scroll, "Slider", "Intellect"), find(scroll, "Slider", "Haste")
  local crit = find(scroll, "Slider", "Critical Strike")
  assertEqual(int.value, 27, "shown at its own value")
  assertEqual(int.min .. "," .. int.max, "-5,27", "not pinned at 20: the top reaches it")
  assertEqual(haste.value, -8)
  assertEqual(haste.min .. "," .. haste.max, "-8,20", "not pinned at -5: the bottom reaches it")
  assertEqual(crit.min .. "," .. crit.max, "-5,20", "a weight inside keeps the plain range")
  crit:__fire("OnMouseUp", 2)
  w = store["comparison.weights"]
  assertEqual(w[62]["ITEM_MOD_CRIT_RATING_SHORT"], 2)
  assertEqual(w[62][INT], 27, "another stat's imported weight is kept")
  assertEqual(w[62][HASTE], -8)
  int:__fire("OnMouseUp", 27)   -- a touch that lets go where it sat
  assertTrue(math.abs(store["comparison.weights"][62][INT] - 27) < 1e-9, "a touch writes back its true value")
  haste:__fire("OnMouseUp", -8)
  assertTrue(math.abs(store["comparison.weights"][62][HASTE] + 8) < 1e-9)
end)

test("verdict settings: with no spec.print the import writes and puts no unprefixed line in chat", function()
  local spec, store = host("retail", { print = false })
  local _, _, scroll = weightsTab(spec)
  local box = find(scroll, "EditBox", "Import a Pawn scale")
  local bare, saved = {}, _G.print
  _G.print = function(...) bare[#bare + 1] = table.concat({ ... }, " ") end
  local ok, err = pcall(box.__fire, box, "OnEnterPressed", '( Pawn: v1: "Mine": Intellect=1.2 )')
  _G.print = saved
  assertTrue(ok, tostring(err))
  assertEqual(store["comparison.weights"][62][INT], 1.2, "the import still writes")
  -- red under: `spec.print or print`, the bare global with no addon prefix (slash-commands-§4)
  assertEqual(#bare, 0, table.concat(bare, " | "))
end)

test("verdict settings: Unwanted types lists the class's weapon types and marks one per spec", function()
  local spec, store, writes = host("retail")
  local O, ctx, scroll = page()
  St.Section(ctx, O, spec, "undesired")
  local daggers = find(scroll, "CheckBox", "Daggers")
  assertTrue(daggers ~= nil, "a mage's daggers")
  assertNil(find(scroll, "CheckBox", "Shields"), "a mage carries no shield")
  daggers:__fire("OnValueChanged", true)
  local key = V.SubClassKey(V.C.ITEM_CLASS.WEAPON, V.C.WEAPON_SUBCLASS.DAGGER)
  assertEqual(writes[#writes], "comparison.undesired")
  assertTrue(store["comparison.undesired"][62][key] == true, "written for Arcane")
  local before = store["comparison.undesired"]
  daggers:__fire("OnValueChanged", false)
  assertNil(store["comparison.undesired"][62], "the spec's last type cleared leaves no entry")
  assertTrue(before[62][key] == true, "the write was a fresh map, the old one untouched")
end)

test("verdict settings: the whole section draws Scoring, Weights and Unwanted types, each under its heading", function()
  local spec, store, writes = host("retail")
  local O, ctx, scroll = page()
  local view = St.Section(ctx, O, spec)
  assertEqual(view.kind, "options")
  local headings = {}
  for _, w in ipairs(Fixture.flatten(scroll)) do
    if w.type == "Heading" then headings[#headings + 1] = w.text end
  end
  assertEqual(table.concat(headings, ","), "Scoring,Weights,Unwanted types")
  local scorer = find(scroll, "Dropdown", "Score with")
  assertTrue(scorer ~= nil, "Score with is the panel's dropdown")
  scorer:__fire("OnValueChanged", "weights")
  assertEqual(writes[#writes], "comparison.scorer")
  assertEqual(store["comparison.scorer"], "weights")
  find(scroll, "CheckBox", "Protect heirlooms"):__fire("OnValueChanged", false)
  assertFalse(store["comparison.heirloomProtect"])
  assertTrue(find(scroll, "CheckBox", "Daggers") ~= nil)
  assertTrue(find(scroll, "Slider", "Haste") ~= nil)
end)

test("verdict settings: Tabs answers the two editor tabs, keyed by their rows' group", function()
  local spec, store = host("retail")
  local O, ctx, scroll = page()
  local tabs = St.Tabs(O, spec)
  assertEqual(#tabs, 2)
  assertEqual(tabs[1].key, "Weights"); assertEqual(tabs[2].key, "Unwanted types")
  assertEqual(type(tabs[1].render), "function")
  tabs[2].render(ctx)
  find(scroll, "CheckBox", "Daggers"):__fire("OnValueChanged", true)
  assertTrue(next(store["comparison.undesired"][62]) ~= nil)
end)

test("verdict settings: nothing to draw into, or a helpers missing a member, builds nothing and raises nothing", function()
  local spec = host("retail")
  local O = page()
  assertNil(St.Section(nil, O, spec))
  assertNil(St.Section({}, nil, spec))
  for _, member in ipairs({ "EnsureScroll", "RenderGrid", "RenderRows", "SubTabStrip" }) do
    local O2, ctx = page()
    local lacking = setmetatable({ [member] = false }, { __index = O2 })
    assertNil(St.Section(ctx, lacking, spec), "no " .. member)
  end
  local O3, ctx3 = page()
  assertNil(St.Section(ctx3, O3, spec, "colors"), "an unknown tab")
  local none = host("retail", { reads = { UnitClass = function() return nil end } })
  local O4, ctx4 = page()
  assertTrue(St.Section(ctx4, O4, none, "weights") ~= nil, "no class: an empty tab, no error")
end)
