-- tests/test_launcher_extras.lua — LibKa0s-Launcher-1.0's `extraEntries` (minor 11, LK-81, LibKa0s#81).
--
-- An addon may add at most two entries of its own to the right-click menu: each a secondary window or
-- action it already exposes through a slash verb (Ka0s Skill Master's Journal is the one consumer, by
-- the owner's ruling of 2026-11-16). They sit after the last supplied toggle (Show window) and before
-- Open settings, in declared order, and follow the minor 7 row rule: a checkbox when the entry passes
-- `checked`, a plain button when it does not, grayed the same way either way. Gated by default.
-- The descriptor field is checked once, at `New`, raising at the host's line.
--
-- The bench is tests/fixture_launcher.lua, shared with tests/test_launcher.lua and
-- tests/test_launcher_skin.lua (Ka0sAddonsCommonTasks docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS, design
-- section 3.7, research note R4 section 2).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertErrorMatches =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertErrorMatches
local mocks = T.mocks
local lib = T.launcher

local Bench = dofile("tests/fixture_launcher.lua")
local MENU = Bench.MENU
local fixture, said, rightClick = Bench.fixture, Bench.said, Bench.rightClick

--- A host with Enabled and Show window, plus the extras `extras` builds from its state.
local function extrasHost(extras, over)
  local rec = fixture()
  rec.state = { enabled = true, window = false, journal = false }
  rec.calls = { journal = 0, reset = 0 }
  local d, st = rec.d, rec.state
  d.isEnabled = function() return st.enabled end
  d.setEnabled = function(v) st.enabled = v end
  d.isWindowShown = function() return st.window end
  d.toggleWindow = function() st.window = not st.window end
  d.extraEntries = extras(rec)
  for k, v in pairs(over or {}) do d[k] = v end
  local L = lib:New(d)
  L:Register()
  return rec, L
end

--- The Journal (a checkbox) and Reset (a button), Skill Master's shape and one action.
local function journalAndReset(rec)
  return {
    { label = "Journal", checked = function() return rec.state.journal end,
      onClick = function() rec.calls.journal = rec.calls.journal + 1; rec.state.journal = not rec.state.journal end },
    { label = "Reset bars", onClick = function() rec.calls.reset = rec.calls.reset + 1 end },
  }
end

-- ── placement ────────────────────────────────────────────────────────────────────────────────

test("launcher extras: they sit after Show window and before Open settings, in declared order", function()
  -- red under: extras appended after Open settings (the issue's literal "after Show window" read as
  -- the menu's end), or drawn in any order but the host's.
  local _, L = extrasHost(journalAndReset)
  assertEqual(table.concat(rightClick(L):Texts(), "|"), "Enabled|Show window|Journal|Reset bars|Open settings")
  local _, L2 = extrasHost(function(rec)
    local two = journalAndReset(rec)
    return { two[2], two[1] }
  end)
  assertEqual(table.concat(rightClick(L2):Texts(), "|"), "Enabled|Show window|Reset bars|Journal|Open settings")
end)

test("launcher extras: they follow Open skin selector's rule, staying above Open settings", function()
  -- With every built-in present, the extras are still the last rows before the actions.
  -- red under: extras placed between two toggles, or after the skin selector.
  local rec = fixture()
  for _, p in ipairs{ { "isEnabled", "setEnabled" }, { "isLocked", "toggleLock" },
      { "isTestMode", "toggleTestMode" }, { "isSimMode", "toggleSim" }, { "isWindowShown", "toggleWindow" } } do
    rec.d[p[1]] = function() return true end
    rec.d[p[2]] = function() end
  end
  rec.d.extraEntries = { { label = "Journal", onClick = function() end } }
  local L = lib:New(rec.d)
  L:Register()
  assertEqual(table.concat(rightClick(L):Texts(), "|"),
    "Enabled|Locked|Test mode|Sim mode|Show window|Journal|Open settings")
end)

test("launcher extras: a host with extras and no toggle still gets them, above Open settings", function()
  -- red under: extras drawn only inside the toggles' loop, so a host with none loses them.
  local rec = fixture{ extraEntries = { { label = "Journal", onClick = function() end } } }
  local L = lib:New(rec.d)
  L:Register()
  assertEqual(table.concat(rightClick(L):Texts(), "|"), "Journal|Open settings")
end)

test("launcher extras: no field, or an empty one, leaves the menu exactly as it was", function()
  -- The regression: every host on the collection today passes no extraEntries.
  -- red under: a separator, a placeholder row, or an Open settings that moved.
  local without = fixture{ isEnabled = function() return true end, setEnabled = function() end }
  local W = lib:New(without.d)
  W:Register()
  local empty = fixture{ isEnabled = function() return true end, setEnabled = function() end, extraEntries = {} }
  local E = lib:New(empty.d)
  E:Register()
  assertEqual(table.concat(rightClick(W):Texts(), "|"), "Enabled|Open settings")
  assertEqual(table.concat(rightClick(E):Texts(), "|"), "Enabled|Open settings")
end)

-- ── the row rule ─────────────────────────────────────────────────────────────────────────────

test("launcher extras: `checked` makes a checkbox whose tick is asked live; none makes a button", function()
  -- red under: a frozen tick (captured at New or at the open), or every extra drawn as one kind.
  local rec, L = extrasHost(journalAndReset)
  local menu = rightClick(L)
  local journal, reset = menu:Find("Journal"), menu:Find("Reset bars")
  assertNil(journal.button, "Journal is a checkbox")
  assertTrue(reset.button, "Reset bars is a plain button, made as Open settings is")
  assertFalse(menu:Checked("Journal"))
  rec.state.journal = true
  assertTrue(menu:Checked("Journal"), "the tick is asked at draw")
  assertFalse(menu:Checked("Reset bars"), "a button draws no tick")
end)

test("launcher extras: a click calls the host's onClick once and closes the menu", function()
  -- red under: onClick called twice (a toggle that undoes itself), not at all, or a menu left open.
  local rec, L = extrasHost(journalAndReset)
  assertEqual(rightClick(L):Click("Journal"), MENU.RESPONSE.Close)
  assertEqual(rec.calls.journal, 1)
  assertTrue(rec.state.journal)
  assertEqual(rightClick(L):Click("Reset bars"), MENU.RESPONSE.Close)
  assertEqual(rec.calls.reset, 1)
  assertEqual(rec.calls.journal, 1, "nothing else ran")
  assertEqual(rec.opened, 0, "the panel stays shut")
end)

test("launcher extras: gated by default, grayed with the note while disabled, and calling nothing", function()
  -- slash-commands-§7: a feature refuses while the addon is disabled, so its menu row grays, as
  -- Show window does.
  -- red under: ungated by default, hidden rather than grayed, or a forced click that still runs.
  local rec, L = extrasHost(journalAndReset)
  rec.state.enabled = false
  local menu = rightClick(L)
  assertEqual(table.concat(menu:Texts(), "|"), table.concat({
    "Enabled", "Show window (enable the addon first)", "Journal (enable the addon first)",
    "Reset bars (enable the addon first)", "Open settings" }, "|"))
  assertFalse(menu:Find("Journal").enabled)
  assertFalse(menu:Find("Reset bars").enabled)
  assertNil(menu:Click("Journal"), "a grayed entry cannot be clicked")
  menu:ForceClick("Journal")
  menu:ForceClick("Reset bars")
  assertEqual(rec.calls.journal + rec.calls.reset, 0, "the module's own gate holds")
  assertEqual(#rec.lines, 0, "and says nothing in chat")
end)

test("launcher extras: `gated = false` stays live while the addon is disabled", function()
  -- red under: a gate that ignores the field, which grays an action the host ruled safe when off.
  local rec, L = extrasHost(function(r)
    return { { label = "Journal", gated = false, onClick = function() r.calls.journal = r.calls.journal + 1 end } }
  end)
  rec.state.enabled = false
  local menu = rightClick(L)
  assertEqual(menu:Find("Journal").text, "Journal")
  assertTrue(menu:Find("Journal").enabled)
  menu:Click("Journal")
  assertEqual(rec.calls.journal, 1)
end)

test("launcher extras: the label is the host's plain string, through no lib.STRINGS key", function()
  -- The host localizes its own label; the library only adds its gray note, through its own keys.
  -- red under: the label looked up in lib.STRINGS or the host's L, which echoes the key back.
  local L1 = setmetatable({ MENU_NEEDS_ENABLE = "erst aktivieren" }, { __index = function(_, k) return k end })
  local rec, L = extrasHost(function()
    return { { label = "Tagebuch", onClick = function() end } }
  end, { L = L1 })
  assertEqual(rightClick(L):Find("Tagebuch").text, "Tagebuch")
  rec.state.enabled = false
  assertEqual(rightClick(L):Find("Tagebuch").text, "Tagebuch (erst aktivieren)")
end)

-- ── raising ──────────────────────────────────────────────────────────────────────────────────

test("launcher extras: a raising onClick is reported as MENU_FAILED, named by its label", function()
  -- red under: an unguarded onClick, which is a red error box in the client's menu dispatch.
  local rec, L = extrasHost(function()
    return { { label = "Journal", onClick = function() error("journal boom") end } }
  end)
  local ok, response = pcall(function() return rightClick(L):Click("Journal") end)
  assertTrue(ok)
  assertEqual(response, MENU.RESPONSE.Close, "the menu still closes")
  assertTrue(said(rec):find("menu's Journal entry raised", 1, true) ~= nil, said(rec))
  assertTrue(said(rec):find("journal boom", 1, true) ~= nil, said(rec))
end)

test("launcher extras: a raising `checked` costs its tick, not the menu", function()
  -- red under: an unguarded accessor, which opens no menu at all.
  local rec, L = extrasHost(function()
    return { { label = "Journal", checked = function() error("tick boom") end, onClick = function() end } }
  end)
  local menu = rightClick(L)
  assertEqual(#menu.entries, 4, "every entry still drawn")
  assertFalse(menu:Checked("Journal"))
  assertTrue(table.concat(rec.logs, "|"):find("tick boom", 1, true) ~= nil, "the debug seam heard it")
  assertEqual(#rec.lines, 0)
end)

-- ── per client ───────────────────────────────────────────────────────────────────────────────

local ABSENT = {}
local RETAIL  = { WOW_PROJECT_ID = 1,  WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CAMELOT = ABSENT }
local FOREVER = { WOW_PROJECT_ID = 18, WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CAMELOT = 18 }

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

test("launcher extras: an entry's `clients` builds it only on those clients", function()
  -- The extra's own declaration, what LibKa0s-Compat-1.0's ForClient takes (entryClients is keyed by
  -- the built-in toggles and does not reach an extra).
  -- red under: clients ignored, or read through entryClients.
  local function texts()
    local _, L = extrasHost(function()
      return {
        { label = "Retail only", clients = { "retail" }, onClick = function() end },
        { label = "Everywhere", onClick = function() end },
      }
    end)
    return table.concat(rightClick(L):Texts(), "|")
  end
  on(FOREVER, function()
    assertEqual(texts(), "Enabled|Show window|Everywhere|Open settings")
  end)
  on(RETAIL, function()
    assertEqual(texts(), "Enabled|Show window|Retail only|Everywhere|Open settings")
  end)
end)

-- ── the descriptor check ─────────────────────────────────────────────────────────────────────

--- A descriptor carrying `extras`, otherwise minimal.
local function withExtras(extras)
  return { name = Bench.nextName(), icon = "x", openSettings = function() end, extraEntries = extras }
end
local function fn() end

test("launcher extras: each malformed field raises at New with a named message", function()
  -- red under: a malformed entry accepted, then raising (or drawing a blank row) when the menu opens.
  local cases = {
    { "not a table",          "extraEntries must be a list",                     "Journal" },
    { "an entry not a table", "extraEntries[1] must be a table",                 { "Journal" } },
    { "no label",             "extraEntries[1].label must be a non-empty string", { { onClick = fn } } },
    { "an empty label",       "extraEntries[1].label must be a non-empty string", { { label = "", onClick = fn } } },
    { "a function label",     "extraEntries[1].label must be a non-empty string", { { label = fn, onClick = fn } } },
    { "no onClick",           "extraEntries[2].onClick must be a function",
      { { label = "A", onClick = fn }, { label = "B" } } },
    { "checked not a fn",     "extraEntries[1].checked must be nil or a function", { { label = "A", onClick = fn, checked = true } } },
    { "gated not a boolean",  "extraEntries[1].gated must be nil or a boolean",  { { label = "A", onClick = fn, gated = "no" } } },
    { "a clients typo",       "extraEntries[1].clients has invalid clients",     { { label = "A", onClick = fn, clients = { "retial" } } } },
    { "three entries",        "extraEntries holds at most 2 entries",
      { { label = "A", onClick = fn }, { label = "B", onClick = fn }, { label = "C", onClick = fn } } },
  }
  for _, c in ipairs(cases) do
    -- Not a tail call, so the host's frame is on the stack for the error to name.
    local ok, err = pcall(function() local made = lib:New(withExtras(c[3])); return made end)
    assertFalse(ok, c[1] .. " raises")
    assertTrue(tostring(err):find(c[2], 1, true) ~= nil, c[1] .. ": " .. tostring(err))
    assertTrue(tostring(err):find("test_launcher_extras.lua:", 1, true) ~= nil,
      c[1] .. " names the host's line: " .. tostring(err))
  end
  assertErrorMatches(function() lib:New(withExtras({ { label = "A", onClick = fn, clients = { "retial" } } })) end,
    'unknown client "retial"')
end)

test("launcher extras: two well-formed entries register", function()
  -- red under: a cap of one, or a check that refuses the optional fields.
  local ok = pcall(function()
    return lib:New(withExtras({
      { label = "A", onClick = fn, checked = fn, gated = false, clients = { "forever" } },
      { label = "B", onClick = fn, gated = true, clients = "both" },
    }))
  end)
  assertTrue(ok)
end)

test("launcher extras: the menu reads the list New checked, not a later edit of the host's table", function()
  -- Checked once, at New: a host that edits its descriptor afterwards cannot slip a malformed or a
  -- third entry past the check.
  -- red under: d.extraEntries read again on every open.
  local rec = fixture{ extraEntries = { { label = "Journal", onClick = function() end } } }
  local L = lib:New(rec.d)
  L:Register()
  rec.d.extraEntries[1].label = "Renamed"
  rec.d.extraEntries[2] = { label = "Second" }
  rec.d.extraEntries[3] = { label = "Third", onClick = function() end }
  assertEqual(table.concat(rightClick(L):Texts(), "|"), "Journal|Open settings")
end)

test("launcher extras: the instance gains no member", function()
  -- R9 M7: the launcher instance is parity-checked by name in nine addons, so a new member would be a
  -- stub edit in each.
  -- red under: anything published on the instance for the extras.
  local plain = lib:New(fixture().d)
  local extra = lib:New(fixture{ extraEntries = { { label = "Journal", onClick = function() end } } }.d)
  local function keys(t)
    local out = {}
    for k in pairs(t) do out[#out + 1] = tostring(k) end
    table.sort(out)
    return table.concat(out, ",")
  end
  assertEqual(keys(extra), keys(plain))
  assertNil(rawget(lib, "extraEntries"), "nor the library")
end)
