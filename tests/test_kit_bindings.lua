-- tests/test_kit_bindings.lua — Kit.assertBindingsXml, the shared Bindings.xml check (kit revision
-- 42, testkit/bindings_xml.lua).
--
-- WHAT IT PROVES. That a Bindings.xml shaped the way launcher-§6 asks passes, whether the commands
-- arrive as strings or as an addon's NS.BINDINGS records, and that each way of breaking the shape
-- fails naming the file: the wrong category, a header= or default= attribute, a missing or empty
-- BINDING_NAME_ global, the commands out of order, the category global not the brand, a missing
-- file and a file with no Binding at all. A Binding inside an XML comment is not a binding.
--
-- And Kit.keybindThroughTab (the same revision, with LibKa0s's OptionsKeybinds minor 2), driven
-- against a live Options instance on tests/fixture_keybinds.lua's bench: a key pressed through a
-- row's slot is bound, the outcome line comes back, and a missing row or slot fails naming
-- options-ui-§20.
--
-- Fixtures are written under os.tmpname paths and removed after each case.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local assertErrorMatches = T.assertErrorMatches

local Kit = dofile("tests/_kit/framework.lua")

local CAT = "BINDING_HEADER_LKTEST"

local GOOD = [[<Bindings>
  <!-- the launcher toggle, and a second command -->
  <Binding name="LKTEST_TOGGLE" category="BINDING_HEADER_LKTEST">
    LKTEST_Toggle()
  </Binding>
  <!-- <Binding name="LKTEST_OLD" category="ADDONS">retired</Binding> -->
  <Binding name='LKTEST_SECOND' category='BINDING_HEADER_LKTEST'/>
</Bindings>
]]

local function globals(extra)
  local g = { [CAT] = "Ka0s Test", BINDING_NAME_LKTEST_TOGGLE = "Toggle the window",
              BINDING_NAME_LKTEST_SECOND = "Do the second thing" }
  for k, v in pairs(extra or {}) do g[k] = v end
  return g
end

local function withFile(body, fn)
  local path = os.tmpname()
  local f = assert(io.open(path, "wb"))
  f:write(body); f:close()
  local ok, err = pcall(fn, path)
  os.remove(path)
  if not ok then error(err, 0) end
end

local function opts(extra)
  local o = { category = CAT, commands = { "LKTEST_TOGGLE", "LKTEST_SECOND" }, brand = "Ka0s Test",
              globals = globals() }
  for k, v in pairs(extra or {}) do o[k] = v end
  return o
end

test("kit bindings: Kit.assertBindingsXml is on the kit table and published by Kit.expose", function()
  assertEqual(type(Kit.assertBindingsXml), "function", "the kit installs the check")
  assertEqual(type(T.assertBindingsXml), "function", "and Kit.expose hands it to the suite")
end)

test("kit bindings: a conforming file passes with string commands and returns the list", function()
  withFile(GOOD, function(path)
    local list = Kit.assertBindingsXml(path, opts())
    assertEqual(#list, 2, "the commented-out Binding is not counted")
    assertEqual(list[1].name, "LKTEST_TOGGLE"); assertEqual(list[1].category, CAT)
    assertEqual(list[2].name, "LKTEST_SECOND")
  end)
end)

test("kit bindings: NS.BINDINGS-style records and matching labels are accepted", function()
  withFile(GOOD, function(path)
    local list = Kit.assertBindingsXml(path, opts{
      commands = { { command = "LKTEST_TOGGLE" }, { command = "LKTEST_SECOND" } },
      labels = { LKTEST_TOGGLE = "Toggle the window" } })
    assertEqual(#list, 2)
  end)
end)

local function failsWith(body, extra, needle)
  withFile(body, function(path)
    assertErrorMatches(function() Kit.assertBindingsXml(path, opts(extra)) end, path)
    assertErrorMatches(function() Kit.assertBindingsXml(path, opts(extra)) end, "launcher-§6")
    assertErrorMatches(function() Kit.assertBindingsXml(path, opts(extra)) end, needle)
  end)
end

test("kit bindings: a Binding in the ADDONS category fails", function()
  failsWith((GOOD:gsub('category="BINDING_HEADER_LKTEST"', 'category="ADDONS"', 1)), nil, "ADDONS")
end)

test("kit bindings: a header= attribute fails", function()
  failsWith((GOOD:gsub('<Binding name="LKTEST_TOGGLE"', '<Binding header="LKTEST" name="LKTEST_TOGGLE"')),
    nil, "header=")
end)

test("kit bindings: a default= attribute fails", function()
  failsWith((GOOD:gsub("<Binding name='LKTEST_SECOND'", "<Binding default='F' name='LKTEST_SECOND'")),
    nil, "default=")
end)

test("kit bindings: a missing BINDING_NAME_ global fails, and so does a wrong label", function()
  failsWith(GOOD, { globals = globals{ BINDING_NAME_LKTEST_SECOND = false } }, "BINDING_NAME_LKTEST_SECOND")
  failsWith(GOOD, { globals = globals{ BINDING_NAME_LKTEST_SECOND = "" } }, "BINDING_NAME_LKTEST_SECOND")
  failsWith(GOOD, { labels = { LKTEST_TOGGLE = "Something else" } }, "Something else")
end)

test("kit bindings: the commands out of order fail", function()
  failsWith(GOOD, { commands = { "LKTEST_SECOND", "LKTEST_TOGGLE" } }, "LKTEST_SECOND")
  failsWith(GOOD, { commands = { "LKTEST_TOGGLE" } }, "count")
end)

test("kit bindings: a category global that is not the brand fails", function()
  failsWith(GOOD, { brand = "Someone Else" }, "Someone Else")
end)

test("kit bindings: a file with no Binding fails", function()
  failsWith("<Bindings>\n  <!-- <Binding name=\"X\" category=\"Y\"/> -->\n</Bindings>\n", nil, "no <Binding>")
end)

test("kit bindings: a missing file fails, naming it", function()
  local path = os.tmpname(); os.remove(path)
  assertErrorMatches(function() Kit.assertBindingsXml(path, opts()) end, path)
  assertErrorMatches(function() Kit.assertBindingsXml(path, opts()) end, "cannot read")
end)

test("kit bindings: a failure is reported at the caller's line", function()
  withFile(GOOD, function(path)
    local ok, err = pcall(function() Kit.assertBindingsXml(path, opts{ brand = "Nope" }) end)
    assertTrue(not ok)
    assertTrue(tostring(err):find("test_kit_bindings.lua", 1, true) ~= nil, "at the caller: " .. tostring(err))
  end)
end)

-- ── Kit.keybindThroughTab ────────────────────────────────────────────────────────────────────

local Bench = dofile("tests/fixture_keybinds.lua")

test("kit bindings: Kit.keybindThroughTab is on the kit table and published by Kit.expose", function()
  assertEqual(type(Kit.keybindThroughTab), "function", "the kit installs the driver")
  assertEqual(type(T.keybindThroughTab), "function", "and Kit.expose hands it to the suite")
end)

Bench.case("kit bindings: keybindThroughTab binds a key through an Options instance's row", function()
  local _, _, _, rows = Bench.rowsPage()
  local status = T.keybindThroughTab(rows()[1], 1, "F8")
  assertEqual(Bench.keys(Bench.TOGGLE), "F8", "GetBindingKey returns the key bound through the tab")
  assertEqual(status, T.mocks.KEY_BOUND, "and the outcome line comes back")
  assertEqual(T.keybindThroughTab(rows()[2], 1, "J", { alt = true, shift = true }), T.mocks.KEY_BOUND)
  assertEqual(Bench.keys(Bench.SECOND), "ALT-SHIFT-J", "with the modifiers held for the press")
  assertTrue(not T.mocks.IsAltKeyDown() and not T.mocks.IsShiftKeyDown(), "and let go after it")
end)

Bench.case("kit bindings: keybindThroughTab slot 2 binds the game page's key through the model", function()
  -- OptionsKeybinds minor 4 draws one key button per row; a second key is the one a player sets on
  -- Options -> Keybindings, so slot 2 writes it with the library's own slot semantics.
  local _, _, _, rows = Bench.rowsPage()
  assertEqual(T.keybindThroughTab(rows()[1], 1, "F8"), T.mocks.KEY_BOUND)
  assertEqual(T.keybindThroughTab(rows()[1], 2, "F9", { ctrl = true }), T.mocks.KEY_BOUND)
  assertEqual(Bench.keys(Bench.TOGGLE), "F8,CTRL-F9", "slot 2 written beside slot 1")
  assertTrue(not T.mocks.IsControlKeyDown(), "the modifiers let go after it")
  assertEqual(rows()[1].slots[1].text, "F8 +1", "and the row shows it")
end)

Bench.case("kit bindings: keybindThroughTab fails naming options-ui-§20 without a row or a slot", function()
  assertErrorMatches(function() T.keybindThroughTab(nil, 1, "K") end, "options-ui-§20")
  assertErrorMatches(function() T.keybindThroughTab({ slots = {} }, 1, "K") end, "options-ui-§20")
  assertErrorMatches(function() T.keybindThroughTab({ slots = {} }, 2, "K") end, "options-ui-§20")
end)
