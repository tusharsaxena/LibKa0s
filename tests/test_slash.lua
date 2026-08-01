-- tests/test_slash.lua — the dispatcher, the help renderer, the formatters, and the parser.

local T = _G.LK_TEST
local slash = T.slash
local test, assertEqual = T.test, T.assertEqual

local F = dofile("tests/fixture_slash.lua")
local plain = F.plain

-- ── dispatch ───────────────────────────────────────────────────────────────────────────────

test("sl: an empty message prints the help index", function()
  local Sl, rec = F.new()
  Sl:OnSlash("")
  assertEqual(#rec.chat, #rec.commands + 1, "a header plus one row per command")
  T.assertTrue(plain(rec.chat[1]):find("slash commands", 1, true) ~= nil, "the header comes first")
end)

test("sl: whitespace-only input is treated as empty", function()
  local Sl, rec = F.new()
  Sl:OnSlash("   ")
  assertEqual(#rec.chat, #rec.commands + 1)
end)

test("sl: an unknown verb names it, then prints the help index", function()
  local Sl, rec = F.new()
  Sl:OnSlash("bogus")
  T.assertTrue(rec.chat[1]:find("unknown command 'bogus'", 1, true) ~= nil, rec.chat[1])
  assertEqual(#rec.chat, #rec.commands + 2, "the error line, the header, and one row per command")
end)

test("sl: the verb is lowercased but the argument keeps its case", function()
  -- Load-bearing: schema paths are case-sensitive, so lowercasing the whole message would break
  -- every dotted path a user types.
  local Sl, rec = F.new()
  Sl:OnSlash("GET units.player.barWidth")
  assertEqual(#rec.chat, 1)
  T.assertTrue(rec.chat[1]:find("units.player.barWidth", 1, true) ~= nil,
    "the path survived intact: " .. plain(rec.chat[1]))
end)

test("sl: an alias is rewritten to its target verb", function()
  local Sl, rec = F.new()
  Sl:OnSlash("options")
  assertEqual(rec.chat[1], "opened", "the alias reached config")
  T.assertTrue(plain(rec.chat[1]):find("unknown", 1, true) == nil)
end)

test("sl: a handler receives the rest of the line, not the verb", function()
  local seen
  local Sl, rec = F.new()
  rec.commands[#rec.commands + 1] = { "echo", "echo", function(rest) seen = rest end }
  Sl:OnSlash("echo  a  b ")
  assertEqual(seen, "a  b", "trimmed at the ends, internal spacing preserved")
end)

test("sl: New requires a slash prefix and a commands table", function()
  T.assertTrue(T.assertError(function() slash:New{ commands = {} } end):find("slash", 1, true) ~= nil)
  T.assertTrue(T.assertError(function() slash:New{ slash = "/x" } end):find("commands", 1, true) ~= nil)
end)

-- ── the row formatter (decision D3) ────────────────────────────────────────────────────────

test("sl: a help row is gold command, single-spaced em dash, white description", function()
  -- The one formatter both the chat help and a host's landing page render through. Uppercase hex,
  -- one space either side of the em dash, and the description coloured rather than left bare.
  assertEqual(slash.FormatRow("/th get", "Print a setting"),
    "|cFFFFFF00/th get|r \226\128\148 |cFFFFFFFFPrint a setting|r")
end)

test("sl: HelpRows indents for chat; LandingRows does not", function()
  -- A leading indent exists to sit a chat line under a header. In a settings panel, where each row
  -- is its own label, the same indent reads as a mistake.
  local Sl = F.new()
  local help, landing = Sl:HelpRows(), Sl:LandingRows()
  assertEqual(#help, #landing)
  assertEqual(help[1], "  " .. landing[1], "the indent is the only difference")
  T.assertTrue(landing[1]:sub(1, 1) ~= " ", "a landing row starts at the margin")
end)

test("sl: help rows name each verb with the host's own slash prefix", function()
  local Sl = F.new{ slash = "/kcd" }
  T.assertTrue(plain(Sl:HelpRows()[1]):find("/kcd help", 1, true) ~= nil, plain(Sl:HelpRows()[1]))
end)

test("sl: the help header carries the version and the chat alias", function()
  local Sl, rec = F.new()
  Sl:PrintHelp()
  local header = plain(rec.chat[1])
  T.assertTrue(header:find("v1.2.3", 1, true) ~= nil, header)
  T.assertTrue(header:find("/testhost", 1, true) ~= nil, "the alias is named: " .. header)
  T.assertTrue(header:find("/th", 1, true) ~= nil, header)
end)

test("sl: a host with no chat alias gets a header without the alias clause", function()
  local Sl, rec = F.new{ slashAliases = false }
  Sl:PrintHelp()
  local header = plain(rec.chat[1])
  T.assertTrue(header:find("alias", 1, true) == nil, "no dangling clause: " .. header)
  T.assertTrue(header:find("v1.2.3", 1, true) ~= nil, header)
end)

test("sl: no rendered line ends in a colon", function()
  -- House style, and the reason FormatKV uses " = " rather than ": ".
  local Sl, rec = F.new()
  Sl:OnSlash("")
  Sl:OnSlash("list")
  for _, line in ipairs(rec.chat) do
    T.assertTrue(plain(line):sub(-1) ~= ":", "line ends in a colon: " .. plain(line))
  end
end)

-- ── FormatKV and FormatValue ───────────────────────────────────────────────────────────────

test("sl: FormatKV is a gold key, ' = ', a white value, and no trailing colon", function()
  assertEqual(slash.FormatKV("units.player.barWidth", "200 px"),
    "|cFFFFFF00units.player.barWidth|r = |cFFFFFFFF200 px|r")
end)

test("sl: FormatValue renders every schema type the library knows", function()
  local Sl, rec = F.new()
  local row = function(path) return rec.byPath[path] end
  assertEqual(slash.FormatValue(row("showOnlyInCombat"), false), "false")
  assertEqual(slash.FormatValue(row("showOnlyInCombat"), true), "true")
  assertEqual(slash.FormatValue(row("units.player.barWidth"), 200), "200 px", "row.fmt is applied")
  assertEqual(slash.FormatValue(row("labelText"), "short"), "short")
  assertEqual(slash.FormatValue(row("emptyLabel"), ""), "(none)", "an empty string reads as (none)")
  assertEqual(slash.FormatValue(row("units.player.barColor"),
    { r = 0.1, g = 0.2, b = 0.3, a = 0.4 }), "{0.10, 0.20, 0.30, 0.40}")
  assertEqual(slash.FormatValue(row("showOnlyInCombat"), nil), "nil")
end)

test("sl: a number row with no fmt renders bare", function()
  assertEqual(slash.FormatValue({ type = "number" }, 42), "42")
end)

-- A stand-in for a WoW combat "secret" value, the same shape the Core suite uses: `..` succeeds on
-- it (a real secret propagates silently) while `table.concat` refuses it, which is what the seam
-- probes. A settings value is *supposed* to be an ordinary stored scalar; these cases exist because
-- nothing enforces that, and a host whose getter returns a live or derived value must not raise.
local secretMock = setmetatable({}, {
  __concat = function() return "secret-propagated" end,
})

test("sl: FormatValue renders a secret as the sentinel on every formatting branch", function()
  local _, rec = F.new()
  local row = function(path) return rec.byPath[path] end
  assertEqual(slash.FormatValue(row("units.player.barWidth"), secretMock), T.core.SECRET,
    "the row.fmt branch guards before string.format")
  assertEqual(slash.FormatValue({ type = "number" }, secretMock), T.core.SECRET,
    "the bare-number branch guards before tostring")
  assertEqual(slash.FormatValue(row("units.player.barColor"),
    { r = secretMock, g = 0.2, b = 0.3, a = 0.4 }), T.core.SECRET,
    "the colour branch guards each component before the %.2f tuple")
  assertEqual(slash.FormatValue(row("labelText"), secretMock), T.core.SECRET,
    "the string branch guards")
end)

test("sl: FormatValue reads a POSITIONAL colour as well as a named-key one", function()
  -- The Ka0s options colour widget writes { r, g, b, a } positionally. Rendered through the
  -- named-key reader alone, every such row read as {0.00, 0.00, 0.00, 1.00} — and shipped that
  -- way, because nothing asserts a rendered colour's VALUE outside this file.
  local _, rec = F.new()
  local row = rec.byPath["units.player.barColor"]
  assertEqual(slash.FormatValue(row, { 0.1, 0.2, 0.3, 0.4 }), "{0.10, 0.20, 0.30, 0.40}",
    "byte-identical to the named-key rendering of the same colour")
end)

test("sl: a positional colour with a secret component still renders the sentinel", function()
  -- The guard has to cover the new indexing path too, or a combat-protected component reaches
  -- string.format by the back door.
  local _, rec = F.new()
  local row = rec.byPath["units.player.barColor"]
  assertEqual(slash.FormatValue(row, { secretMock, 0.2, 0.3, 0.4 }), T.core.SECRET)
end)

test("sl: a host colour codec round-trips through set and its echo", function()
  -- The end-to-end case, parameterised by shape: parse writes what the host stores, and the echo
  -- reads it back through the same codec. A partial fix that changed only one of them renders a
  -- colour the host never stored.
  local POSITIONAL = {
    colorDecode = function(c) c = type(c) == "table" and c or {}
                              return c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1 end,
    colorEncode = function(r, g, b, a) return { r, g, b, a or 1 } end,
  }
  local Sl, rec = F.new(POSITIONAL)
  rec.chat = {}
  Sl:CliSet("units.player.barColor 0.1 0.2 0.3 0.4")
  local stored = rec.store["units.player.barColor"]
  T.assertNear(stored[1], 0.1, 1e-6, "written in the host's positional shape")
  T.assertNil(stored.r, "and not in the library's named-key one")
  local text = table.concat(rec.chat, "\n")
  T.assertTrue(text:find("{0.10, 0.20, 0.30, 0.40}", 1, true) ~= nil,
    "the echo reads it back through the same codec: " .. text)
end)

test("sl: CliReset's echo uses the host colour codec too", function()
  -- The second FormatValue site, and the one a partial fix misses.
  local store = {}
  local Sl, rec = F.new({
    colorDecode = function(c) c = type(c) == "table" and c or {}
                              return c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1 end,
    colorEncode = function(r, g, b, a) return { r, g, b, a or 1 } end,
    get = function(path) return store[path] end,
    set = function(path, value) store[path] = value end,
    applyDefault = function(row) store[row.path] = { 0.5, 0.6, 0.7, 0.8 } end,
  })
  rec.chat = {}
  Sl:CliReset("units.player.barColor")
  local text = table.concat(rec.chat, "\n")
  T.assertTrue(text:find("{0.50, 0.60, 0.70, 0.80}", 1, true) ~= nil, text)
end)

test("sl: a guarded FormatValue still survives the FormatKV string.format around it", function()
  local ok, out = pcall(function()
    return slash.FormatKV("units.player.barWidth",
      slash.FormatValue({ type = "number" }, secretMock))
  end)
  T.assertTrue(ok, "rendering a secret must not raise: " .. tostring(out))
  assertEqual(out, "|cFFFFFF00units.player.barWidth|r = |cFFFFFFFF" .. T.core.SECRET .. "|r")
end)

-- ── the parser ─────────────────────────────────────────────────────────────────────────────

test("sl: booleans accept the whole human vocabulary", function()
  local row = { type = "bool" }
  for _, word in ipairs({ "true", "1", "on", "yes", "TRUE", "On" }) do
    assertEqual(slash.ParseValue(row, word), true, word)
  end
  for _, word in ipairs({ "false", "0", "off", "no", "OFF" }) do
    assertEqual(slash.ParseValue(row, word), false, word)
  end
end)

test("sl: a junk boolean is rejected and the accepted words are listed", function()
  local v, err = slash.ParseValue({ type = "bool" }, "maybe")
  T.assertNil(v)
  T.assertTrue(err:find("true/false/on/off/1/0/yes/no", 1, true) ~= nil, err)
end)

test("sl: a number is clamped to the row's range rather than rejected", function()
  local row = { type = "number", min = 50, max = 500 }
  assertEqual(slash.ParseValue(row, "99999"), 500, "clamped to max, not refused")
  assertEqual(slash.ParseValue(row, "1"), 50, "and to min")
  assertEqual(slash.ParseValue(row, "250"), 250)
end)

test("sl: a non-numeric value for a number row is rejected", function()
  local v, err = slash.ParseValue({ type = "number" }, "wide")
  T.assertNil(v)
  T.assertTrue(err:find("expected a number", 1, true) ~= nil, err)
end)

test("sl: a string is validated against its enum, case-sensitively", function()
  local row = { type = "string", values = { none = true, short = true } }
  assertEqual(slash.ParseValue(row, "short"), "short")
  local v, err = slash.ParseValue(row, "Short")
  T.assertNil(v, "the enum match is case-sensitive")
  T.assertTrue(err:find("none, short", 1, true) ~= nil, "the allowed values are listed, sorted: " .. err)
end)

test("sl: an enum declared as an ordered array is offered in declaration order", function()
  -- The Ka0s options schema declares enums as an ordered array of { value =, text = }, because
  -- the declared order IS the dropdown's display order. Declared here so that alphabetical and
  -- declared order DISAGREE — with a list that happens to sort into its own order, the assertion
  -- passes whether or not the implementation honours the position.
  local row = { type = "string", values = {
    { value = "short", text = "Short" },
    { value = "none",  text = "None"  },
  } }
  assertEqual(slash.ParseValue(row, "short"), "short")
  local v, err = slash.ParseValue(row, "Short")
  T.assertNil(v, "the enum match is case-sensitive")
  T.assertTrue(err:find("short, none", 1, true) ~= nil,
    "the allowed values are listed in DECLARED order, not sorted: " .. err)
end)

test("sl: an ordered array supplied as a function is evaluated at parse time", function()
  local row = { type = "string", values = function()
    return { { value = "flat", text = "Flat" } }
  end }
  assertEqual(slash.ParseValue(row, "flat"), "flat")
end)

test("sl: a numeric dropdown rejects an out-of-list value rather than clamping it", function()
  -- Clamping lands BETWEEN two entries, and the renderer then has no label for what is stored:
  -- the row reads blank and the user cannot tell what they set. Constraining says so instead.
  local row = { type = "number", min = 1, max = 4,
    values = { { value = 1 }, { value = 2 }, { value = 4 } } }
  assertEqual(slash.ParseValue(row, "4"), 4)
  local v, err = slash.ParseValue(row, "3")
  T.assertNil(v, "a value inside the range but off the list is refused")
  T.assertTrue(err:find("1, 2, 4", 1, true) ~= nil, err)
  T.assertNil((slash.ParseValue(row, "99")), "and one outside it is refused, not clamped to 4")
end)

test("sl: a number row with no values list still clamps to min/max", function()
  local row = { type = "number", min = 50, max = 500 }
  assertEqual(slash.ParseValue(row, "10"), 50)
  assertEqual(slash.ParseValue(row, "9000"), 500)
end)

test("sl: a string row with no values list accepts free text", function()
  -- The EditBox row. The old reader walked an empty allowed-list and therefore refused every
  -- value, so that widget type shipped un-settable from the CLI.
  assertEqual(slash.ParseValue({ type = "string" }, "anything"), "anything")
end)

test("sl: a key SET labels its entries with its keys, not with 'true'", function()
  -- { SHORT = true } is a degenerate key map. Rendering the VALUE as the label is how such a row
  -- becomes a list of entries all reading "true"; the key is the only honest label it has.
  local row = { type = "string", values = { none = true, short = true } }
  local _, err = slash.ParseValue(row, "nope")
  T.assertTrue(err:find("none, short", 1, true) ~= nil, err)
end)

test("sl: an enum supplied as a function is evaluated at parse time", function()
  -- A host's media list is populated by another addon and is not knowable at load.
  local row = { type = "string", values = function() return { flat = true } end }
  assertEqual(slash.ParseValue(row, "flat"), "flat")
end)

test("sl: a colour parses r g b with an optional alpha", function()
  local c = slash.ParseValue({ type = "color" }, "0.1 0.2 0.3 0.4")
  T.assertNear(c.r, 0.1, 1e-6); T.assertNear(c.a, 0.4, 1e-6)
  local d = slash.ParseValue({ type = "color" }, "0.1 0.2 0.3")
  assertEqual(d.a, 1, "alpha defaults to opaque")
end)

test("sl: a colour given in 0-255 is rescaled, and all three channels together", function()
  -- Rescaling per channel would mangle a mixed input worse than rescaling jointly does; this is
  -- the existing behaviour and it is preserved deliberately rather than tidied.
  local c = slash.ParseValue({ type = "color" }, "255 128 0")
  T.assertNear(c.r, 1, 1e-6); T.assertNear(c.b, 0, 1e-6)
  T.assertTrue(c.g > 0.5 and c.g < 0.51, "128/255")
end)

test("sl: a colour missing a channel is rejected with the expected form", function()
  local v, err = slash.ParseValue({ type = "color" }, "1 0")
  T.assertNil(v)
  T.assertTrue(err:find("r g b", 1, true) ~= nil, err)
end)

test("sl: an unknown row type is rejected by name", function()
  local v, err = slash.ParseValue({ type = "wibble" }, "x")
  T.assertNil(v)
  T.assertTrue(err:find("wibble", 1, true) ~= nil, err)
end)

-- ── the CLI verbs ──────────────────────────────────────────────────────────────────────────

test("sl: list groups rows under the host's own group keys, indented", function()
  local Sl, rec = F.new()
  Sl:CliList()
  local out = {}
  for i, line in ipairs(rec.chat) do out[i] = plain(line) end
  assertEqual(out[1], "Available settings", "the header, with no colon")
  local joined = table.concat(out, "\n")
  T.assertTrue(joined:find("  [general]", 1, true) ~= nil, "a bare page header, indented two")
  T.assertTrue(joined:find("  [bar / player]", 1, true) ~= nil, "and a per-unit one")
  T.assertTrue(joined:find("    units.player.barWidth = 200 px", 1, true) ~= nil,
    "rows indent four, and render through FormatKV: " .. joined)
end)

test("sl: the list keeps its own colours \226\128\148 green header, azure group headings", function()
  -- Decision D3 converges the COMMAND-row formatter, and nothing else. Recasing these to match it
  -- would be a user-visible change outside what was asked for.
  local Sl, rec = F.new()
  Sl:CliList()
  assertEqual(rec.chat[1], "|cff33ff99Available settings|r")
  local sawGroup = false
  for _, line in ipairs(rec.chat) do
    if line:find("|cff3399ff[", 1, true) then sawGroup = true end
  end
  T.assertTrue(sawGroup, "group headings stay azure")
end)

test("sl: list says so when nothing is registered", function()
  local Sl, rec = F.new{ allRows = function() return {} end }
  Sl:CliList()
  assertEqual(#rec.chat, 1)
  assertEqual(plain(rec.chat[1]), "No settings registered yet")
end)

test("sl: get echoes the canonical path and the stored value", function()
  local Sl, rec = F.new()
  Sl:CliGet("units.player.barWidth")
  assertEqual(#rec.chat, 1)
  assertEqual(plain(rec.chat[1]), "units.player.barWidth = 200 px")
end)

test("sl: a stored false renders as false, not as nil", function()
  -- `x and false or nil` collapses a legitimate value. Every unticked checkbox in a host addon is a
  -- stored false, so this is most of what /at list prints.
  local Sl, rec = F.new()
  assertEqual(rec.store["showOnlyInCombat"], false, "the fixture really does store false")
  Sl:CliGet("showOnlyInCombat")
  assertEqual(plain(rec.chat[1]), "showOnlyInCombat = false")
  Sl:CliList()
  local listed = {}
  for i, line in ipairs(rec.chat) do listed[i] = plain(line) end
  T.assertTrue(table.concat(listed, "\n"):find("showOnlyInCombat = false", 1, true) ~= nil,
    "and the same in the listing")
end)

test("sl: get with no path prints usage; an unknown path says so", function()
  local Sl, rec = F.new()
  Sl:CliGet("")
  T.assertTrue(plain(rec.chat[1]):find("Usage: /th get", 1, true) ~= nil, plain(rec.chat[1]))
  Sl:CliGet("nosuchsetting")
  T.assertTrue(plain(rec.chat[2]):find("Setting not found: nosuchsetting", 1, true) ~= nil,
    plain(rec.chat[2]))
end)

test("sl: set writes through the host and echoes what was STORED, not what was typed", function()
  -- The echo re-reads, which is the only reason a clamp is visible to the user.
  local Sl, rec = F.new()
  Sl:CliSet("units.player.barWidth 99999")
  assertEqual(rec.store["units.player.barWidth"], 500)
  assertEqual(plain(rec.chat[1]), "units.player.barWidth = 500 px")
end)

test("sl: set with no path points at the list verb", function()
  local Sl, rec = F.new()
  Sl:CliSet("")
  local line = plain(rec.chat[1])
  T.assertTrue(line:find("Usage: /th set", 1, true) ~= nil, line)
  T.assertTrue(line:find("/th list", 1, true) ~= nil, "and names where to find the paths: " .. line)
end)

test("sl: a rejected value is not written, and the reason is a second, indented line", function()
  local Sl, rec = F.new()
  Sl:CliSet("units.player.barWidth wide")
  assertEqual(rec.store["units.player.barWidth"], 200, "a rejected parse must not write")
  T.assertTrue(plain(rec.chat[1]):find("Invalid value for units.player.barWidth", 1, true) ~= nil,
    plain(rec.chat[1]))
  assertEqual(plain(rec.chat[2]), "  expected a number", "the detail is indented under it")
end)

test("sl: set accepts a value made of several tokens", function()
  local Sl, rec = F.new()
  Sl:CliSet("units.player.barColor 0.1 0.2 0.3 0.4")
  T.assertNear(rec.store["units.player.barColor"].r, 0.1, 1e-6)
  T.assertTrue(plain(rec.chat[1]):find("{0.10, 0.20, 0.30, 0.40}", 1, true) ~= nil,
    plain(rec.chat[1]))
end)

test("sl: reset restores one setting to its default", function()
  -- Decision D1: the library owns `reset <path>`, resetting a single setting. There is no
  -- page-shaped form, here or in any host.
  local Sl, rec = F.new()
  Sl:CliSet("units.player.barWidth 250")
  assertEqual(rec.store["units.player.barWidth"], 250)
  Sl:CliReset("units.player.barWidth")
  assertEqual(rec.store["units.player.barWidth"], 200, "back to the row's default")
  T.assertTrue(plain(rec.chat[#rec.chat]):find("units.player.barWidth", 1, true) ~= nil,
    "and it echoes what it reset")
end)

test("sl: reset leaves every other setting alone", function()
  local Sl, rec = F.new()
  Sl:CliSet("units.player.barWidth 250")
  Sl:CliSet("units.target.barWidth 300")
  Sl:CliReset("units.player.barWidth")
  assertEqual(rec.store["units.target.barWidth"], 300, "one path, not a page")
end)

test("sl: reset with no path prints usage; an unknown path says so", function()
  local Sl, rec = F.new()
  Sl:CliReset("")
  T.assertTrue(plain(rec.chat[1]):find("Usage: /th reset <path>", 1, true) ~= nil, plain(rec.chat[1]))
  Sl:CliReset("bar")
  T.assertTrue(plain(rec.chat[2]):find("Setting not found: bar", 1, true) ~= nil,
    "a page name is just an unknown path now: " .. plain(rec.chat[2]))
end)

test("sl: reset does not lowercase its argument", function()
  -- The inverse of the rule the page-shaped verb had. Pages were a closed lowercase set; a path is
  -- case-sensitive, so folding case here would resolve settings the user did not name.
  local Sl, rec = F.new()
  Sl:CliSet("units.player.barWidth 250")
  Sl:CliReset("UNITS.PLAYER.BARWIDTH")
  assertEqual(rec.store["units.player.barWidth"], 250, "nothing was reset")
  -- Asserted on the ECHOED path, not just on the prefix: a lowercasing CliReset would still print
  -- "Setting not found" for this input, so a prefix match cannot tell the two apart.
  assertEqual(plain(rec.chat[#rec.chat]), "Setting not found: UNITS.PLAYER.BARWIDTH")
end)

test("sl: resetall applies every row's default", function()
  local Sl, rec = F.new()
  Sl:CliSet("units.player.barWidth 250")
  Sl:CliSet("showOnlyInCombat true")
  Sl:CliResetAll()
  assertEqual(rec.store["units.player.barWidth"], 200)
  assertEqual(rec.store["showOnlyInCombat"], false)
end)

test("sl: version prints one line and nothing else", function()
  local Sl, rec = F.new()
  Sl:CliVersion()
  assertEqual(#rec.chat, 1)
  assertEqual(plain(rec.chat[1]), "v1.2.3")
end)

-- ── the row annotator ──────────────────────────────────────────────────────────────────────

test("sl: the annotator fires on list, get and set — and on nothing else", function()
  -- Three sites, and never on reset or resetall: an annotation explaining what a value means is
  -- noise attached to an acknowledgement that a value went away.
  local Sl, rec = F.new()
  Sl:SetRowAnnotator(function(row)
    return row.unit == "target" and "  (annotated)" or ""
  end)
  local function saw(fn)
    local before = #rec.chat
    fn()
    for i = before + 1, #rec.chat do
      if rec.chat[i]:find("(annotated)", 1, true) then return true end
    end
    return false
  end
  T.assertTrue(saw(function() Sl:CliGet("units.target.barWidth") end), "get")
  T.assertTrue(saw(function() Sl:CliSet("units.target.barWidth 250") end), "set")
  T.assertTrue(saw(function() Sl:CliList() end), "list")
  T.assertFalse(saw(function() Sl:CliReset("units.target.barWidth") end), "never on reset")
  T.assertFalse(saw(function() Sl:CliResetAll() end), "nor on resetall")
end)

test("sl: the annotation follows the coloured pair rather than interrupting it", function()
  local Sl, rec = F.new()
  Sl:SetRowAnnotator(function() return "  (note)" end)
  Sl:CliGet("units.player.barWidth")
  local line = rec.chat[1]
  T.assertTrue(line:find("|cFFFFFFFF200 px|r  (note)", 1, true) ~= nil,
    "the gold/white pair stays intact: " .. line)
end)

test("sl: with no annotator set, nothing is appended", function()
  local Sl, rec = F.new()
  Sl:CliGet("units.player.barWidth")
  assertEqual(plain(rec.chat[1]), "units.player.barWidth = 200 px")
end)

-- ── the module ─────────────────────────────────────────────────────────────────────────────

test("sl: Slash refuses to register without Core", function()
  local Loader = dofile("tests/_kit/loader.lua")
  local buildMocks = dofile("tests/wow_mock.lua")
  local bare = buildMocks()
  Loader.load("LibKa0s/Slash.lua", nil, bare)
  T.assertNil(bare.LibStub("LibKa0s-Slash-1.0", true), "no Core, no dispatcher")
end)

-- ── the `L` trap ────────────────────────────────────────────────────────────
--
-- See tests/test_debuglog.lua for the full account. In short: a Ka0s host's
-- locale table answers EVERY key with the key itself (the standard mandates the
-- metatable fallback), so resolving an override with a plain index makes this
-- module's own STRINGS unreachable and the host prints raw keys.

local function fallbackLocale()
  return setmetatable({}, { __index = function(_, k) return k end })
end

test("sl: an L whose metatable synthesises every key does NOT mask the module's strings", function()
  -- red under: reverting Sl:Text to `strings[key]`
  local Sl = F.new({ L = fallbackLocale() })
  assertEqual(Sl:Text("LIST_HEADER"), slash.STRINGS.LIST_HEADER,
    "a synthesised override must fall through to the module's own string")
  assertEqual(Sl:Text("NOT_FOUND"), slash.STRINGS.NOT_FOUND)
end)

test("sl: a REAL entry in an L that also has a fallback still overrides", function()
  local L = fallbackLocale()
  rawset(L, "LIST_HEADER", "Reglages disponibles")
  local Sl = F.new({ L = L })
  assertEqual(Sl:Text("LIST_HEADER"), "Reglages disponibles", "a real entry must still win")
  assertEqual(Sl:Text("NOT_FOUND"), slash.STRINGS.NOT_FOUND,
    "and its neighbours must still fall through")
end)

test("sl: a plain L table overrides exactly as before", function()
  local Sl = F.new({ L = { LIST_HEADER = "Settings!" } })
  assertEqual(Sl:Text("LIST_HEADER"), "Settings!")
  assertEqual(Sl:Text("NOT_FOUND"), slash.STRINGS.NOT_FOUND)
end)

-- ── the format hook ────────────────────────────────────────────────────────────────────────
--
-- Added at Slash minor 5, and it closes an asymmetry rather than adding a feature: `parse` has been
-- a descriptor field since -1.0, so a host has always been able to teach the CLI to READ a value
-- type this library does not know — but there was no way to teach it to WRITE one back.
--
-- Two hosts hit it. BankLedger stores a settings row as a SET of muted stores (`type = "table"`),
-- which lib.FormatValue falls through to Core's SafeToString: a table is not concat-safe, so the
-- user is told a plain settings value is "<secret>" — actively misleading rather than merely ugly.
-- prettychat needs `|` doubled to `||` so a stored pattern renders literally.

test("slash: a host can supply its own value formatter for a type the library does not know",
  function()
    local rows = { { path = "s.stores", type = "table", default = {} } }
    local store = { ["s.stores"] = { BANK = true, GUILD = true } }
    local Sl = slash:New({
      slash = "/th", commands = {},
      print = function() end,
      allRows = function() return rows end,
      findRow = function(p) for _, r in ipairs(rows) do if r.path == p then return r end end end,
      get = function(p) return store[p] end,
      format = function(_, v)
        local keys = {}
        for k, on in pairs(v) do if on then keys[#keys + 1] = k end end
        table.sort(keys)
        return "{" .. table.concat(keys, ", ") .. "}"
      end,
    })
    local lines = Sl:BuildListLines()
    assertEqual(lines[#lines], "    " .. slash.FormatKV("s.stores", "{BANK, GUILD}"),
      "the host's formatter renders the list row")
  end)

test("slash: the format hook reaches the get, set and reset echoes too", function()
  local rows = { { path = "s.x", type = "table", default = {} } }
  local store = { ["s.x"] = { A = true } }
  local out = {}
  local Sl = slash:New({
    slash = "/th", commands = {},
    print = function(line) out[#out + 1] = line end,
    allRows = function() return rows end,
    findRow = function(p) for _, r in ipairs(rows) do if r.path == p then return r end end end,
    get = function(p) return store[p] end,
    set = function(p, v) store[p] = v end,
    applyDefault = function(r) store[r.path] = {} end,
    parse = function() return { B = true } end,
    format = function(_, v)
      local keys = {}
      for k in pairs(v) do keys[#keys + 1] = k end
      table.sort(keys)
      return #keys == 0 and "(none)" or ("{" .. table.concat(keys, ", ") .. "}")
    end,
  })
  Sl:CliGet("s.x")
  assertEqual(out[#out], slash.FormatKV("s.x", "{A}"), "get")
  Sl:CliSet("s.x whatever")
  assertEqual(out[#out], slash.FormatKV("s.x", "{B}"), "set, re-read after storing")
  Sl:CliReset("s.x")
  assertEqual(out[#out], slash.FormatKV("s.x", "(none)"), "reset")
end)

test("slash: a host with no format hook renders exactly as it always did", function()
  -- The existing-consumer path. Every branch of lib.FormatValue must still be the one that answers.
  local rows = { { path = "s.n", type = "number", fmt = "%.2fx", default = 1 } }
  local Sl = slash:New({
    slash = "/th", commands = {},
    print = function() end,
    allRows = function() return rows end,
    findRow = function() return rows[1] end,
    get = function() return 1.5 end,
  })
  local lines = Sl:BuildListLines()
  assertEqual(lines[#lines], "    " .. slash.FormatKV("s.n", "1.50x"))
end)

test("slash: the format hook takes precedence over the colour codec, and gets the raw stored value",
  function()
    -- A host that supplies both is telling us it owns rendering outright. Handing it the DECODED
    -- colour instead of what it stored would make the two hooks disagree about their own input.
    local rows = { { path = "s.c", type = "color", default = {} } }
    local seen
    local Sl = slash:New({
      slash = "/th", commands = {},
      print = function() end,
      allRows = function() return rows end,
      findRow = function() return rows[1] end,
      get = function() return { 1, 0, 0, 1 } end,
      colorDecode = function(t) return t[1], t[2], t[3], t[4] end,
      format = function(_, v) seen = v; return "red" end,
    })
    local lines = Sl:BuildListLines()
    assertEqual(lines[#lines], "    " .. slash.FormatKV("s.c", "red"))
    assertEqual(seen[1], 1, "the hook is handed the value as STORED")
  end)
