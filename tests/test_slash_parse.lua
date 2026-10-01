-- tests/test_slash_parse.lua — LibKa0s-Slash-1.0's parser: ParseBool and the value parser behind
-- `set`, row type by row type.
--
-- A file of its own because tests/test_slash.lua was 1339 lines, in `layout-§1`'s 1000-1500 band,
-- and the parser block (ParseBool through ParseValue) is the seam its watch-list entry named. The
-- cases moved unchanged, in their original order, in the 2026-09-26 automated-tests sweep.

local T = _G.LK_TEST
local slash = T.slash
local test, assertEqual = T.test, T.assertEqual

local F = dofile("tests/fixture_slash.lua")
local plain = F.plain

test("sl: ParseBool accepts the same eight words the error string advertises", function()
  for _, word in ipairs({ "true", "1", "on", "yes", "TRUE", "On" }) do
    assertEqual(slash.ParseBool(word), true, word)
  end
  for _, word in ipairs({ "false", "0", "off", "no", "OFF" }) do
    assertEqual(slash.ParseBool(word), false, word)
  end
end)

test("sl: ParseBool answers nil, never false, for a non-boolean word", function()
  -- nil means "not a boolean word", which is what lets a caller implement toggle-on-absent. A
  -- false here would make `/xx bar` and `/xx bar off` indistinguishable.
  T.assertNil(slash.ParseBool("maybe"))
  T.assertNil(slash.ParseBool(""))
  T.assertNil(slash.ParseBool(nil))
  T.assertNil(slash.ParseBool(1))
  T.assertNil(slash.ParseBool({}))
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
  -- passes whether or not the implementation honors the position.
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

-- A STRING ROW TAKES THE WHOLE REMAINDER (minor 10). Through minor 9 it took the first token, so
-- `/am set container.name My Raid Buffs` stored "My", and an enum whose values carry a space -- an
-- LSM font, the "OUTLINE, MONOCHROME" flag -- could not be named. Found by an AuraMaster test agent;
-- PrettyChat had worked around it with a descriptor `parse`.
-- red under: parseString reading args[1], or trimming internal spacing as well as the edges.
test("sl: a free-text string row keeps every word of a multi-word value", function()
  assertEqual(slash.ParseValue({ type = "string" }, "My Raid Buffs"), "My Raid Buffs")
  assertEqual(slash.ParseValue({ type = "string" }, "a  b"), "a  b", "internal spacing is the user's")
end)

test("sl: a string enum accepts an entry that contains spaces, in both enum shapes", function()
  local map = { type = "string", values = { ["Friz Quadrata TT"] = true, Arial = true } }
  assertEqual(slash.ParseValue(map, "Friz Quadrata TT"), "Friz Quadrata TT")
  local arr = { type = "string", values = {
    { value = "OUTLINE, MONOCHROME", text = "Monochrome outline" }, { value = "OUTLINE" } } }
  assertEqual(slash.ParseValue(arr, "OUTLINE, MONOCHROME"), "OUTLINE, MONOCHROME")
  -- Matched on the FULL string: a valid entry followed by more words is refused, not truncated.
  local v, err = slash.ParseValue(map, "Arial Narrow")
  T.assertNil(v, "trailing words after a valid entry are not dropped")
  T.assertTrue(err:find("allowed values", 1, true) ~= nil, err)
end)

test("sl: a string value is trimmed at both ends before it is stored or validated", function()
  assertEqual(slash.ParseValue({ type = "string" }, "   My Raid Buffs  "), "My Raid Buffs")
  local map = { type = "string", values = { ["Friz Quadrata TT"] = true } }
  assertEqual(slash.ParseValue(map, "\tFriz Quadrata TT "), "Friz Quadrata TT")
end)

test("sl: an empty or blank string value is still refused with 'expected a value'", function()
  for _, text in ipairs({ "", "   ", false }) do
    local v, err = slash.ParseValue({ type = "string" }, text or nil)
    T.assertNil(v, "refused: '" .. tostring(text) .. "'")
    assertEqual(err, slash.STRINGS.ERR_STRING)
  end
end)

test("sl: bool, number and color rows still read tokens exactly as before", function()
  -- red under: routing every type through the whole-remainder read.
  assertEqual(slash.ParseValue({ type = "bool" }, "on and more"), true, "a bool reads its first token")
  assertEqual(slash.ParseValue({ type = "number", min = 50, max = 500 }, "250 px"), 250,
    "a number reads its first token")
  local c = slash.ParseValue({ type = "color" }, "  0.1 0.2   0.3 0.4 extra ")
  T.assertNear(c.b, 0.3, 1e-6, "a color reads its four tokens")
  T.assertNear(c.a, 0.4, 1e-6)
  local _, err = slash.ParseValue({ type = "number" }, "")
  assertEqual(err, slash.STRINGS.ERR_NUMBER)
end)

test("sl: set stores a multi-word free-text value whole, through the dispatcher", function()
  local Sl, rec = F.new()
  local row = { path = "container.name", page = "general", type = "string", default = "" }
  rec.rows[#rec.rows + 1] = row
  rec.byPath[row.path] = row
  Sl:OnSlash("set container.name   My Raid Buffs  ")
  assertEqual(rec.store["container.name"], "My Raid Buffs")
  assertEqual(plain(rec.chat[1]), "container.name = My Raid Buffs", "and the echo shows all of it")

  -- A path with no value keeps today's refusal: the row is found, the parse refuses, nothing is
  -- written.
  Sl:CliSet("container.name")
  assertEqual(rec.store["container.name"], "My Raid Buffs", "a blank value does not write")
  T.assertTrue(plain(rec.chat[2]):find("Invalid value for container.name", 1, true) ~= nil,
    plain(rec.chat[2]))
  assertEqual(plain(rec.chat[3]), "  expected a value")
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

test("sl: a color parses r g b with an optional alpha", function()
  local c = slash.ParseValue({ type = "color" }, "0.1 0.2 0.3 0.4")
  T.assertNear(c.r, 0.1, 1e-6); T.assertNear(c.a, 0.4, 1e-6)
  local d = slash.ParseValue({ type = "color" }, "0.1 0.2 0.3")
  assertEqual(d.a, 1, "alpha defaults to opaque")
end)

test("sl: a color given in 0-255 is rescaled, and all three channels together", function()
  -- Rescaling per channel would mangle a mixed input worse than rescaling jointly does; this is
  -- the existing behavior and it is preserved deliberately rather than tidied.
  local c = slash.ParseValue({ type = "color" }, "255 128 0")
  T.assertNear(c.r, 1, 1e-6); T.assertNear(c.b, 0, 1e-6)
  T.assertTrue(c.g > 0.5 and c.g < 0.51, "128/255")
end)

test("sl: a color missing a channel is rejected with the expected form", function()
  local v, err = slash.ParseValue({ type = "color" }, "1 0")
  T.assertNil(v)
  T.assertTrue(err:find("r g b", 1, true) ~= nil, err)
end)

test("sl: an unknown row type is rejected by name", function()
  local v, err = slash.ParseValue({ type = "wibble" }, "x")
  T.assertNil(v)
  T.assertTrue(err:find("wibble", 1, true) ~= nil, err)
end)

-- ── the host's L reaches the parser (minor 19, issue #40) ──────────────────────────────────
--
-- Through minor 18 the file-level parsers and the empty-string formatter read lib.STRINGS
-- directly, so a host's `L` overrode the dispatcher's own lines but never the parse refusals or
-- the "(none)" a `get` prints. ConsumableMaster carried ERR_BOOL, ERR_ALLOWED and ERR_COLOR in its
-- table, marked dead for exactly that reason. The instance now hands Sl:Text to the parsers.

local OVERRIDES = {
  ERR_BOOL = "B!", ERR_ALLOWED = "A:%s", ERR_COLOR = "C!", ERR_NUMBER = "N!",
  ERR_STRING = "S!", ERR_TYPE = "T:%s", NONE = "--",
}

local function withRows(Sl, rec, extra)
  for _, row in ipairs(extra) do
    rec.rows[#rec.rows + 1] = row
    rec.byPath[row.path] = row
  end
  return Sl, rec
end

local function overriddenHost(L)
  local Sl, rec = F.new({ L = L })
  return withRows(Sl, rec, {
    { path = "weird", page = "general", type = "weird" },
    { path = "freeText", page = "general", type = "string" },
    { path = "steps", page = "general", type = "number", values = { 1, 2, 3 } },
  })
end

-- The reason line `set` prints under INVALID, for one bad input.
local function reasonFor(Sl, rec, input)
  local before = #rec.chat
  Sl:CliSet(input)
  assertEqual(#rec.chat, before + 2, "INVALID and one reason line for: " .. input)
  return plain(rec.chat[before + 2])
end

test("sl: the host's L reaches every parse refusal through set", function()
  -- red under: Slash minor 18, whose parsers read lib.STRINGS and never the host's L
  local Sl, rec = overriddenHost(OVERRIDES)
  assertEqual(reasonFor(Sl, rec, "showOnlyInCombat maybe"), "  B!", "ERR_BOOL")
  assertEqual(reasonFor(Sl, rec, "units.player.barWidth wide"), "  N!", "ERR_NUMBER")
  assertEqual(reasonFor(Sl, rec, "steps 9"), "  A:1, 2, 3", "ERR_ALLOWED, number row")
  assertEqual(reasonFor(Sl, rec, "freeText    "), "  S!", "ERR_STRING")
  assertEqual(reasonFor(Sl, rec, "labelText nope"), "  A:none, short", "ERR_ALLOWED, string row")
  assertEqual(reasonFor(Sl, rec, "units.player.barColor 1 2"), "  C!", "ERR_COLOR")
  assertEqual(reasonFor(Sl, rec, "weird x"), "  T:weird", "ERR_TYPE")
end)

test("sl: the host's L reaches the empty-string formatter through get", function()
  -- red under: Slash minor 18, whose FORMATTERS.string read lib.STRINGS.NONE
  local Sl, rec = overriddenHost(OVERRIDES)
  Sl:CliGet("emptyLabel")
  assertEqual(plain(rec.chat[#rec.chat]), "emptyLabel = --")
end)

test("sl: a key-echoing L still falls through to the library's parse strings", function()
  -- The rawget rule Sl:Text keeps: a locale table that answers every key with the key must not
  -- turn a parse refusal into the bare key name.
  local Sl, rec = overriddenHost(setmetatable({}, { __index = function(_, k) return k end }))
  assertEqual(reasonFor(Sl, rec, "showOnlyInCombat maybe"), "  " .. slash.STRINGS.ERR_BOOL)
  assertEqual(reasonFor(Sl, rec, "units.player.barColor 1"), "  " .. slash.STRINGS.ERR_COLOR)
  Sl:CliGet("emptyLabel")
  assertEqual(plain(rec.chat[#rec.chat]), "emptyLabel = " .. slash.STRINGS.NONE)
end)

test("sl: ParseValue and FormatValue take an optional resolver, and default to the library's strings", function()
  local textOf = function(k) return OVERRIDES[k] end
  local _, err = slash.ParseValue({ type = "bool" }, "maybe")
  assertEqual(err, slash.STRINGS.ERR_BOOL, "two arguments: unchanged")
  _, err = slash.ParseValue({ type = "bool" }, "maybe", textOf)
  assertEqual(err, "B!", "a resolver is read")
  _, err = slash.ParseValue({ type = "nope" }, "x", textOf)
  assertEqual(err, "T:nope")
  assertEqual(slash.FormatValue({ type = "string" }, ""), slash.STRINGS.NONE, "two arguments: unchanged")
  assertEqual(slash.FormatValue({ type = "string" }, "", textOf), "--")
end)

test("sl: a host's own parse is handed the instance's resolver as a third argument", function()
  local seen
  local Sl = F.new({
    L = { ERR_BOOL = "nope!" },
    parse = function(row, text, textOf)
      seen = textOf
      return slash.ParseValue(row, text, textOf)
    end,
  })
  Sl:CliSet("showOnlyInCombat maybe")
  assertEqual(type(seen), "function", "the resolver reached the host's parse")
  assertEqual(seen("ERR_BOOL"), "nope!", "and it resolves through the host's L")
  assertEqual(seen("ERR_COLOR"), slash.STRINGS.ERR_COLOR, "falling through where L is silent")
end)
-- ── the file it lives in (addendum A2) ────────────────────────────────────────────────────────
--
-- The parser block (lib.ParseBool through lib.ParseValue, with enumList and allowedText) left
-- Slash.lua for LibKa0s/SlashParse.lua, a secondary file of the same major paired on the shell's
-- minor, so Slash.lua leaves `layout-§1`'s 1000-1500 band. Every case above runs unchanged against
-- the moved code; these two pin the pairing and the partial payload.

test("sl: the parser lives in SlashParse.lua at minor 1, paired on the live shell", function()
  -- red under: the parser written into Slash.lua, which publishes no SlashParse minor
  assertEqual(slash.MODULES.SlashParse, 1)
  assertEqual(slash.__parseMinor, 1)
  assertEqual(slash.__parseShellMinor, slash.MINOR, "attached to the shell that is live")
  assertEqual(type(slash.ParseValue), "function")
  assertEqual(type(slash.ParseBool), "function")
end)

test("sl: a payload without SlashParse.lua loads whole, and set refuses naming the file", function()
  -- red under: the parser written into Slash.lua, which a shell-only payload still carries
  local Loader     = dofile("tests/_kit/loader.lua")
  local buildMocks = dofile("tests/wow_mock.lua")
  local env = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, env)
  Loader.load("LibKa0s/Slash.lua", nil, env)
  local lib = env.LibStub("LibKa0s-Slash-1.0")
  T.assertNil(lib.ParseValue, "no parser without its file")
  T.assertNil(lib.ParseBool)
  T.assertNil(lib.MODULES.SlashParse)
  assertEqual(type(lib.FormatValue), "function", "the rest of the major is unaffected")

  local chat, wrote = {}, 0
  local row = { path = "width", type = "number", default = 1 }
  local store = { width = 1 }
  local sl
  sl = lib:New({
    slash = "/np",
    print = function(line) chat[#chat + 1] = line end,
    get = function(path) return store[path] end,
    set = function() wrote = wrote + 1 end,
    findRow = function(path) return path == "width" and row or nil end,
    allRows = function() return { row } end,
    commands = { { "set", "Change a setting", function(rest) sl:CliSet(rest) end } },
  })
  sl:CliSet("width 5")
  assertEqual(wrote, 0, "nothing is written")
  assertEqual(#chat, 2, "the refusal and its reason")
  assertEqual(plain(chat[1]), "Invalid value for width")
  T.assertTrue(chat[2]:find("SlashParse.lua", 1, true) ~= nil, "the reason names the missing file")

  Loader.load("LibKa0s/SlashParse.lua", nil, env)
  assertEqual(type(lib.ParseValue), "function", "and the file adds the parser when it arrives")
  assertEqual(lib.__parseShellMinor, lib.MINOR)
end)
