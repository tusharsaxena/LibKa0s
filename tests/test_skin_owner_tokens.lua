-- tests/test_skin_owner_tokens.lua — LibKa0s-Skin-1.0's owner tokens (Skin minor 7; LK-01 of
-- Ka0sAddonsCommonTasks docs/2026-10-29-SKINNING_ROLLOUT): `RegisterOwner(owner, { tokens = {...} })`,
-- an addon's own named colors (or any token value) laid over its skin's table in `__Tokens`, so
-- `Token`, `Color`, the facade and every primitive that takes a token NAME resolve them.
--
-- What it pins: Ka0s Default answers the token's `default` (today's pixels, exactly); a skin answers
-- its `skins` entry, else the `follow` library token's value in that skin; the eui source answers the
-- follow token's EllesmereUI value. A name with no dot, one that collides with a SkinDefs schema name,
-- or a malformed definition is refused and logged once, and the good names beside it still land. The
-- library's own tokens never move: an owner with no owner tokens reads the resolved table itself, and
-- one with them reads every library token unchanged. A skin switch repaints a primitive that named an
-- owner token; an owner's font and texture overrides still apply; one owner's tokens never reach
-- another owner.
--
-- Every case runs on a fresh environment (tests/fixture_skin_paint.lua, tests/fixture_skin_eui.lua).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")
local E = dofile("tests/fixture_skin_eui.lua")

local OWNER, OTHER = "DropWatcher", "DpsRace"

-- A near-miss gray (Ka0s Default's exact pixels, no library token holds them), following
-- text.accent so every skin draws it in a color of its own; obsidian sets its own value.
local GAIN = { 0.36, 0.86, 0.46, 1 }
local OBSIDIAN_GAIN = { 0.2, 0.9, 0.5, 1 }
local RULE = { 0.533, 0.533, 0.533, 1 }

local function tokens()
  return {
    ["dw.gain"] = { default = GAIN, follow = "text.accent", skins = { obsidian = OBSIDIAN_GAIN } },
    ["dw.rule"] = { default = RULE, follow = "divider" },
    ["dw.alone"] = { default = { 0.1, 0.2, 0.3, 1 } },
  }
end

--- Register `owner` with `toks`, logging into a fresh array. Answers its facade and the log.
local function register(Skin, owner, toks, skin)
  local log = {}
  local S = Skin:RegisterOwner(owner, {
    get = function() return "ka0s", skin or "ka0s" end,
    log = function(line) log[#log + 1] = line end,
    tokens = toks,
  })
  return S, log
end

test("skin owner tokens: Ka0s Default answers each token's default, exactly", function()
  local _, Skin = F.env()
  local S = register(Skin, OWNER, tokens())
  assertEqual(F.rgba(S.Token("dw.gain")), F.rgba(GAIN), "the facade's Token")
  assertEqual(F.rgba({ S.Color("dw.rule") }), F.rgba(RULE), "the facade's Color")
  assertEqual(F.rgba({ Skin:Color(OWNER, "dw.alone") }), "0.100,0.200,0.300,1", "Skin:Color")
  assertTrue(Skin:Token(OWNER, "dw.gain") == GAIN, "the registered value itself, never a copy")
end)

test("skin owner tokens: a skin answers its own entry, else the follow token's value in that skin", function()
  local _, Skin = F.env()
  local S = register(Skin, OWNER, tokens())
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(F.rgba(S.Token("dw.gain")), F.rgba(OBSIDIAN_GAIN), "obsidian's own entry")
  assertEqual(F.rgba(S.Token("dw.rule")), F.tok(Skin, "obsidian", "divider"), "no entry: the follow token")
  Skin:SetChoice(OWNER, "ka0s", "azeroth")
  assertEqual(F.rgba(S.Token("dw.gain")), F.tok(Skin, "azeroth", "text.accent"), "azeroth follows text.accent")
  assertEqual(F.rgba(S.Token("dw.alone")), "0.100,0.200,0.300,1", "no follow and no entry: the default")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(F.rgba(S.Token("dw.gain")), F.rgba(GAIN), "back on Ka0s Default, the default again")
end)

test("skin owner tokens: false in a skin's entry is that skin's none", function()
  local _, Skin = F.env()
  local S = register(Skin, OWNER, { ["dw.wash"] = { default = { 1, 1, 1, 0.1 }, follow = "text.accent",
                                                     skins = { glass = false } } })
  Skin:SetChoice(OWNER, "ka0s", "glass")
  assertNil(S.Token("dw.wash"), "glass draws no wash")
  assertNil(S.Color("dw.wash"), "and Color answers nil")
end)

test("skin owner tokens: the library's tokens never move, and an owner with none reads the resolved table", function()
  local _, Skin = F.env()
  register(Skin, OTHER, nil)
  assertTrue(Skin:__Tokens(OTHER) == Skin:ResolveSkin("ka0s"), "no owner tokens: the resolved table itself")
  register(Skin, OWNER, tokens())
  local base, own = Skin:ResolveSkin("ka0s"), Skin:__Tokens(OWNER)
  for name, v in pairs(base) do
    assertTrue(own[name] == v, name .. " is the library's value, unchanged")
  end
  assertNil(base["dw.gain"], "ResolveSkin never carries an owner token")
  assertTrue(Skin:__Tokens(OWNER) == own, "the owner's table is cached")
end)

test("skin owner tokens: a name with no dot, a schema name and a malformed definition are refused, logged once", function()
  local _, Skin = F.env()
  local bad = tokens()
  bad["nodot"] = { default = RULE }
  bad["text.body"] = { default = RULE }
  bad["dw.nodefault"] = { follow = "divider" }
  bad["dw.badfollow"] = { default = RULE, follow = "dw.gain" }
  bad["dw.notatable"] = RULE[1]
  bad[".dw"] = { default = RULE }
  local S, log = register(Skin, OWNER, bad)
  for _, name in ipairs({ "nodot", "dw.nodefault", "dw.badfollow", "dw.notatable", ".dw" }) do
    assertNil(S.Token(name), name .. " was refused")
  end
  assertEqual(F.rgba(S.Token("text.body")), F.tok(Skin, "ka0s", "text.body"), "the schema name keeps the library's value")
  assertEqual(F.rgba(S.Token("dw.gain")), F.rgba(GAIN), "the good names beside them still land")
  assertEqual(#log, 6, "one line per refused name")
  local all = table.concat(log, "\n")
  assertTrue(all:find("text.body", 1, true) ~= nil, "the line names the token")
  assertTrue(all:find(OWNER, 1, true) ~= nil, "and the owner")
  Skin:RegisterOwner(OWNER, { tokens = bad })
  assertEqual(#log, 6, "a second registration logs nothing again")
end)

test("skin owner tokens: with no log hook a refusal reaches the error handler, once", function()
  local m, Skin = F.env()
  local seen = {}
  m.geterrorhandler = function() return function(err) seen[#seen + 1] = err end end
  Skin:RegisterOwner(OWNER, { tokens = { nodot = { default = RULE } } })
  Skin:RegisterOwner(OWNER, { tokens = { nodot = { default = RULE } } })
  assertEqual(#seen, 1, "reported once")
end)

test("skin owner tokens: a second registration adds tokens and replaces a name it repeats", function()
  local _, Skin = F.env()
  local S = register(Skin, OWNER, tokens())
  local first = Skin:__Tokens(OWNER)
  Skin:RegisterOwner(OWNER, { tokens = { ["dw.extra"] = { default = RULE }, ["dw.alone"] = { default = GAIN } } })
  assertTrue(Skin:__Tokens(OWNER) ~= first, "the cache is rebuilt")
  assertEqual(F.rgba(S.Token("dw.extra")), F.rgba(RULE), "added")
  assertEqual(F.rgba(S.Token("dw.alone")), F.rgba(GAIN), "replaced")
  assertEqual(F.rgba(S.Token("dw.gain")), F.rgba(GAIN), "kept")
end)

test("skin owner tokens: one owner's tokens never reach another owner", function()
  local _, Skin = F.env()
  register(Skin, OWNER, tokens())
  local B = register(Skin, OTHER, nil)
  assertNil(B.Token("dw.gain"), "the other owner has no dw.gain")
  assertNil(Skin:Token("Nobody", "dw.gain"), "nor an unregistered one")
end)

test("skin owner tokens: Divider's token name resolves an owner token and repaints on a skin switch", function()
  local m, Skin = F.env()
  local S = register(Skin, OWNER, tokens())
  local tex = m.CreateFrame("Frame", nil, m.UIParent):CreateTexture(nil, "ARTWORK")
  S.Divider(tex, { token = "dw.gain" })
  local function color() return F.rgba(m.__paint(tex).color) end
  local before = color()
  assertEqual(before, F.rgba(GAIN), "Ka0s Default's exact pixels")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(color(), F.rgba(OBSIDIAN_GAIN), "the switch repainted it in obsidian's value")
  Skin:SetChoice(OWNER, "ka0s", "ember")
  assertEqual(color(), F.tok(Skin, "ember", "text.accent"), "and in ember's followed accent")
end)

test("skin owner tokens: the owner's font and texture overrides still apply beside them", function()
  local LSM = { ["font:Ka0s Inter"] = "Fonts\\Inter.ttf", ["statusbar:Ka0s Flat"] = "Interface\\Ka0s\\Flat" }
  local _, Skin = F.env({ lsm = LSM })
  local S = register(Skin, OWNER, { ["dw.face"] = { default = "Ka0s Oxanium SemiBold", follow = "font.body" } })
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  Skin:SetOverride(OWNER, "Ka0s Inter", "Ka0s Flat")
  assertEqual(S.Token("font.body"), "Ka0s Inter", "the font override")
  assertEqual(S.Token("bar.texture"), "Ka0s Flat", "the texture override")
  assertEqual(S.Token("dw.face"), "Ka0s Inter", "an owner token following font.body follows the override")
  Skin:SetOverride(OWNER, false, false)
  assertEqual(S.Token("dw.face"), Skin:ResolveSkin("obsidian")["font.body"], "cleared: the skin's own again")
end)

test("skin owner tokens: under eui a token answers its follow token's EllesmereUI value", function()
  local _, Skin, eui = E.env()
  local S = Skin:RegisterOwner(E.OWNER, { get = function() return "eui", "ka0s" end, tokens = tokens() })
  assertEqual(F.rgba(S.Token("dw.gain")), F.rgba(GAIN), "before EllesmereUI paints: the Ka0s skin's default")
  eui.login()
  assertTrue(Skin.euiPainted[E.OWNER], "EllesmereUI paints the owner")
  assertEqual(F.rgba(S.Token("dw.gain")), F.rgba(eui.accent), "follows EllesmereUI's accent")
  assertEqual(F.rgba(S.Token("dw.rule")), F.tok(Skin, "ka0s", "divider"), "a token EllesmereUI does not drive")
  assertEqual(F.rgba(S.Token("dw.alone")), "0.100,0.200,0.300,1", "no follow: the default")
  eui.accent = { 0.9, 0.1, 0.2 }
  for _, fn in ipairs(eui.looks) do fn() end
  assertEqual(F.rgba(S.Token("dw.gain")), F.rgba(eui.accent), "a live looks change reaches it")
end)

test("skin owner tokens: an owner token is no vocabulary entry and needs no SkinDefs change", function()
  local _, Skin = F.env()
  register(Skin, OWNER, tokens())
  assertFalse(Skin.__schemaIndex["dw.gain"] ~= nil, "the schema never learns an owner token")
  for _, name in ipairs(Skin.VOCAB) do assertTrue(name ~= "dw.gain", "nor the vocabulary") end
end)
