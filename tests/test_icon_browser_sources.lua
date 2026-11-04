-- tests/test_icon_browser_sources.lua — LibKa0s-IconBrowser-1.0's sources (IconBrowserSources.lua):
-- the tab descriptors, host tabs and hidden built-ins, what each tab lists and calls an icon, the
-- search, the macro icon readers and the glyph color helpers. Lifted from Ka0s Quick Comms'
-- settings/IconBrowser_Sources.lua and its cases in that repo's tests/test_icon_browser.lua.
--
-- Every case runs on a fresh environment with Core, Compat, Media and the sources loaded, so a
-- memo one case builds is never another case's starting state, and nothing a case builds outlives
-- it. Only the cases that need the sets' prefixes load MediaIcons, the generated catalog, and none
-- of those builds a whole list it does not need: the catalog is some 5,800 paths per owner, and a
-- run's peak string count is heap its leak gate later counts (Lua 5.1's string table keeps the size
-- the peak grew it to while a quarter of it stays in use).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local MAJOR = "LibKa0s-IconBrowser-1.0"
local OWNER = "TestHost"
local SKULL = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"

--- A fresh environment: the mocks, the browser's library table and the Media major. `catalog`
--- loads the generated icon sets too.
local function env(catalog)
  local m = buildMocks()
  local files = catalog and { "Core", "Compat", "Media", "MediaIcons", "IconBrowserSources" }
    or { "Core", "Compat", "Media", "IconBrowserSources" }
  for _, f in ipairs(files) do
    Loader.load("LibKa0s/" .. f .. ".lua", nil, m)
  end
  -- This suite's own loader keeps its compiled chunks for the rest of the run (some 1.4 MB, the
  -- generated catalog's constants most of it), and the leak gate counts them: let them go.
  Loader.uncache()
  return m, m.LibStub(MAJOR), m.LibStub("LibKa0s-Media-1.0")
end

--- The tabs a host with `spec` (owner defaulted) is offered.
local function tabsOf(IB, spec)
  spec = spec or {}
  spec.owner = spec.owner or OWNER
  return IB.Sources.Tabs(spec)
end

local function keysOf(tabs)
  local out = {}
  for i, t in ipairs(tabs) do out[i] = t.key end
  return table.concat(out, ",")
end

local function tabNamed(tabs, key)
  for _, t in ipairs(tabs) do
    if t.key == key then return t end
  end
  return nil
end

local function listed(list, value)
  for _, v in ipairs(list) do if v == value then return true end end
  return false
end

-- ── the major ──────────────────────────────────────────────────────────────────────────────

test("sources: the major registers with the three built-in tabs, in order", function()
  local _, IB = env()
  -- red under: no LibKa0s/IconBrowserSources.lua
  assertTrue(IB ~= nil, "LibKa0s-IconBrowser-1.0 is registered")
  assertEqual(table.concat(IB.BUILTIN_TABS, ","), "markers,game,glyphs")
  assertEqual(IB.MODULES.IconBrowserSources, IB.MINOR)
end)

test("sources: the module is absent without the Media major", function()
  local m = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, m)
  Loader.load("LibKa0s/IconBrowserSources.lua", nil, m)
  assertNil(m.LibStub(MAJOR, true), "no NewLibrary: a host holding a partial payload gets no browser")
end)

-- ── the tabs ───────────────────────────────────────────────────────────────────────────────

test("sources: a host tab owns its fileIDs before game does", function()
  local _, IB = env()
  local rec = { key = "rec", label = "Recommended", list = function() return { 135349 }, true end,
    owns = function(i) return i == 135349 end }
  local tabs = tabsOf(IB, { tabs = { rec } })
  -- red under: check the built-in tabs before the host's
  assertEqual(IB.Sources.TabFor(135349, tabs), "rec")
  assertEqual(IB.Sources.TabFor(135350, tabs), "game")
  assertEqual(keysOf(tabs), "rec,markers,game,glyphs", "host tabs first, in the host's order")
end)

test("sources: hidden built-in tabs are not offered", function()
  local _, IB = env()
  local tabs = tabsOf(IB, { hide = { markers = true } })
  assertEqual(keysOf(tabs), "game,glyphs")
  -- red under: TabFor reading the built-ins rather than the tabs it is handed
  assertNil(IB.Sources.TabFor("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1", tabs))
  assertEqual(keysOf(tabsOf(IB, { hide = { markers = true, game = true, glyphs = true } })), "")
end)

test("sources: a host tab with a built-in's key replaces it; a malformed host tab is skipped", function()
  local _, IB = env()
  local mine = { key = "game", label = "Mine", list = function() return { 1 }, true end }
  local tabs = tabsOf(IB, { tabs = { mine, { label = "no key" }, { key = "nolist" }, "junk" } })
  assertEqual(keysOf(tabs), "game,markers,glyphs")
  assertTrue(tabs[1] == mine, "the host's descriptor, not the built-in")
end)

test("sources: the built-in descriptors carry label, tooltip and the swatch on glyphs only", function()
  local _, IB = env()
  local tabs = tabsOf(IB)
  assertEqual(tabNamed(tabs, "markers").label, "Markers")
  assertEqual(tabNamed(tabs, "game").label, "Game icons")
  assertEqual(tabNamed(tabs, "glyphs").label, "Glyphs")
  assertEqual(tabNamed(tabs, "markers").tooltip, "The eight raid target markers.")
  assertTrue(tabNamed(tabs, "glyphs").swatch == true)
  assertFalse(tabNamed(tabs, "game").swatch == true)
  assertFalse(tabNamed(tabs, "markers").swatch == true)
  assertTrue(tabsOf(IB)[1] == tabs[1], "one descriptor per owner for the session, so the search memo holds")
end)

test("sources: a host's L overrides the built-ins' words, and an L answering its key does not", function()
  local _, IB = env()
  local L = setmetatable({ TAB_MARKERS = "Marqueurs" }, { __index = function(_, k) return k end })
  local tabs = tabsOf(IB, { L = L })
  assertEqual(tabNamed(tabs, "markers").label, "Marqueurs")
  -- red under: index L plainly, which answers "TAB_GAME" for a key it does not carry
  assertEqual(tabNamed(tabs, "game").label, "Game icons")
end)

test("sources: TabFor answers each built-in's icons, and nil for a path no tab lists", function()
  local _, IB, Media = env(true)
  local tabs = tabsOf(IB)
  assertEqual(IB.Sources.TabFor(SKULL, tabs), "markers")
  assertEqual(IB.Sources.TabFor(132092, tabs), "game")
  assertEqual(IB.Sources.TabFor(Media.Icon(OWNER, "ph:arrow-up"), tabs), "glyphs")
  assertNil(IB.Sources.TabFor("Interface\\Icons\\Spell_Nature_Bloodlust", tabs), "a typed path is on no tab")
  assertNil(IB.Sources.TabFor(nil, tabs))
end)

test("sources: List hands the tab's list and filter on, loaded true when the descriptor says nothing", function()
  local _, IB = env()
  local got
  local host = { key = "h", label = "H", list = function(filter) got = filter; return { 5, 6 } end }
  local list, loaded = IB.Sources.List(host, "x")
  assertEqual(table.concat(list, ","), "5,6")
  assertEqual(got, "x")
  assertTrue(loaded == true)
  local markers = tabNamed(tabsOf(IB), "markers")
  assertEqual(#IB.Sources.List(markers), 8)
end)

-- ── markers and labels ─────────────────────────────────────────────────────────────────────

test("sources: Markers is the eight raid markers, in order, each named", function()
  local _, IB = env()
  local Src = IB.Sources
  local list = Src.Markers()
  assertEqual(list[1], "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
  assertEqual(list[8], SKULL)
  assertEqual(#list, 8)
  local markers = tabNamed(tabsOf(IB), "markers")
  assertEqual(Src.Label(markers, SKULL), "Skull")
  assertEqual(Src.Label(markers, Src.MarkerPath(1)), "Star")
end)

test("sources: Label names a game icon by its texture id, and a host tab by its own name", function()
  local _, IB = env()
  local Src = IB.Sources
  local tabs = tabsOf(IB)
  assertEqual(Src.Label(tabNamed(tabs, "game"), 136116), "Texture id 136116")
  assertEqual(Src.Label(nil, 136116), "Texture id 136116", "no tab: the default")
  local host = { key = "h", label = "H", list = function() return {} end,
    name = function(i) return i == 7 and "Seven" or nil end }
  assertEqual(Src.Label(host, 7), "Seven")
  assertEqual(Src.Label(host, 8), "Texture id 8", "a name that answers nil falls back")
  assertEqual(Src.Label(nil, "Interface\\Icons\\X"), "Interface\\Icons\\X")
  assertEqual(Src.Label(nil, nil), "")
end)

-- ── glyphs ─────────────────────────────────────────────────────────────────────────────────

test("sources: Glyphs is every catalog icon at the owner's path, labeled from its key", function()
  local _, IB, Media = env()
  local Src = IB.Sources
  local glyphs = tabNamed(tabsOf(IB), "glyphs")
  assertTrue(#Media.ICONS > 100, "the hand-written catalog")
  assertEqual(#Src.Glyphs(OWNER), #Media.ICONS)
  assertEqual(Src.Glyphs(OWNER)[1], Media.Icon(OWNER, Media.ICONS[1]))
  assertEqual(Src.Label(glyphs, Media.Icon(OWNER, "arrow-circle-down")), "Arrow circle down")
  assertEqual(Src.Label(glyphs, Media.Icon(OWNER, "close")), "Close")
  assertEqual(Src.Label(glyphs, Media.Icon(OWNER, "thumb-up")), "Thumbs up", "the curated label")
  assertEqual(Src.Label(glyphs, Media.Icon(OWNER, "speech-bubble")), "Speech bubble")
  -- red under: one session list shared across owners (the paths carry the owner's folder)
  assertEqual(Src.Glyphs("Other")[1], Media.Icon("Other", Media.ICONS[1]))
  assertEqual(#Src.Glyphs(nil), 0, "no owner, no paths")
end)

test("sources: a set's prefix is not in its label; the set and its credit are named", function()
  local _, IB, Media = env(true)
  local Src = IB.Sources
  local glyphs = tabNamed(tabsOf(IB), "glyphs")
  assertEqual(Src.GlyphLabel("ph:arrow-up"), "Arrow up")
  assertEqual(Src.Label(glyphs, Media.Icon(OWNER, "gi:sword-wound")), "Sword wound")
  assertEqual(Src.SetOf(Media.Icon(OWNER, "ph:arrow-up")), "phosphor")
  assertEqual(Src.SetOf(Media.Icon(OWNER, "gi:sword-wound")), "game-icons")
  assertEqual(Src.SetOf(Media.Icon(OWNER, "star")), "open-iconic")
  assertNil(Src.SetOf(SKULL), "a raid marker is in no set")
  assertEqual(Src.Credit(Media.Icon(OWNER, "ph:arrow-up")), "Phosphor")
  local credit = Src.Credit(Media.Icon(OWNER, "gi:sword-wound"))
  assertTrue(credit:find("^Game%-icons, by ") ~= nil, "a Game-icons mark names its author, got " .. credit)
  assertNil(Src.Credit(132092))
end)

test("sources: the Glyphs filter lists the library's sets and narrows to one", function()
  local _, IB = env(true)
  local Src = IB.Sources
  local sets = Src.GlyphSets()
  assertEqual(#sets, 3)
  assertEqual(sets[1].id .. "," .. sets[2].id .. "," .. sets[3].id, "open-iconic,phosphor,game-icons")
  assertEqual(sets[3].label, "Game-icons")
  local all, ph = #Src.Glyphs(OWNER), #Src.Glyphs(OWNER, "phosphor")
  assertTrue(ph > 1000 and ph < all, "Phosphor alone")
  assertEqual(#Src.Glyphs(OWNER, "open-iconic") + ph + #Src.Glyphs(OWNER, "game-icons"), all)
  local glyphs = tabNamed(tabsOf(IB), "glyphs")
  assertTrue(Src.List(glyphs, "phosphor") == Src.Glyphs(OWNER, "phosphor"), "the tab lists the set")
end)

test("sources: Glyphs is built once per owner and set: the same table across reads", function()
  local _, IB = env()
  local Src = IB.Sources
  -- red under: build a new table in Glyphs on every call (Search's memos would miss)
  assertTrue(Src.Glyphs(OWNER) == Src.Glyphs(OWNER), "one table for the session")
  assertTrue(Src.Glyphs(OWNER, "phosphor") == Src.Glyphs(OWNER, "phosphor"), "one table per set")
end)

-- ── game icons ─────────────────────────────────────────────────────────────────────────────

test("sources: Game icons is both macro lists, filtered All / Spells / Items, each icon once", function()
  local m, IB = env()
  m.GetMacroIcons = function(t) for _, v in ipairs({ 1, 2, 3 }) do t[#t + 1] = v end end
  m.GetMacroItemIcons = function(t) for _, v in ipairs({ 3, 4, "Interface\\Icons\\X" }) do t[#t + 1] = v end end
  local Src = IB.Sources
  assertEqual(table.concat(Src.GameIcons("all"), ","), "1,2,3,4", "spells, then items, ids only")
  assertEqual(table.concat(Src.GameIcons("spells"), ","), "1,2,3")
  assertEqual(table.concat(Src.GameIcons("items"), ","), "3,4")
  local game = tabNamed(tabsOf(IB), "game")
  assertEqual(table.concat(Src.List(game, "items"), ","), "3,4")
end)

test("sources: a filtered game list holds each icon once (the loose lists overlap the full ones)", function()
  local m, IB = env()
  m.GetMacroIcons = function(t) t[#t + 1] = 1; t[#t + 1] = 2 end
  m.GetMacroItemIcons = function(t) t[#t + 1] = 4 end
  m.GetLooseMacroIcons = function(t) t[#t + 1] = 9; t[#t + 1] = 1 end
  assertEqual(table.concat(IB.Sources.GameIcons("spells"), ","), "9,1,2")
  assertEqual(table.concat(IB.Sources.GameIcons("all"), ","), "9,1,2,4")
end)

test("sources: the game list not loaded yet says so, and an empty answer is asked again", function()
  local m, IB = env()
  local game = tabNamed(tabsOf(IB), "game")
  local list, loaded = IB.Sources.List(game, "all")
  assertEqual(#list, 0)
  assertFalse(loaded)
  m.GetMacroIcons = function(t) t[#t + 1] = 10; t[#t + 1] = 11 end
  m.GetMacroItemIcons = function(t) t[#t + 1] = 12 end
  list, loaded = IB.Sources.List(game, "all")
  assertTrue(loaded)
  assertEqual(table.concat(list, ","), "10,11,12")
end)

test("sources: MacroIcons reads both lists, plain texture ids only, never raising", function()
  local m, IB = env()
  m.GetMacroIcons = function(t) for _, v in ipairs({ 1, "path", 2 }) do t[#t + 1] = v end end
  m.GetMacroItemIcons = function(t) t[#t + 1] = 5 end
  assertEqual(table.concat(IB.MacroIcons("spells"), ","), "1,2")
  assertEqual(table.concat(IB.MacroIcons("items"), ","), "5")
  m.GetMacroIcons = function() return { 7, 8 } end
  assertEqual(table.concat(IB.MacroIcons("spells"), ","), "7,8", "a reader that returns its list")
  m.GetMacroIcons = function() error("changed API") end
  -- red under: call the reader without pcall
  assertEqual(#IB.MacroIcons("spells"), 0)
  m.GetMacroItemIcons = nil
  assertEqual(#IB.MacroIcons("items"), 0)
  assertEqual(#IB.MacroIcons("other"), 0)
  m.GetMacroIcons = function(t) t[#t + 1] = 3 end
  m.issecretvalue = function(v) return v == 3 end
  assertEqual(#IB.MacroIcons("spells"), 0, "a secret id is no plain number")
end)

test("sources: MacroIcons reads the loose lists first, as the macro icon selector does", function()
  local m, IB = env()
  m.GetMacroIcons = function(t) t[#t + 1] = 1; t[#t + 1] = 2 end
  m.GetLooseMacroIcons = function(t) t[#t + 1] = 9; t[#t + 1] = 1 end
  assertEqual(table.concat(IB.MacroIcons("spells"), ","), "9,1,1,2")
  m.GetLooseMacroItemIcons = function() return { 5 } end
  m.GetMacroItemIcons = function(t) t[#t + 1] = 6 end
  assertEqual(table.concat(IB.MacroIcons("items"), ","), "5,6")
  m.GetLooseMacroIcons = function() error("changed API") end
  assertEqual(table.concat(IB.MacroIcons("spells"), ","), "1,2", "a raising loose reader adds nothing")
end)

-- ── search ─────────────────────────────────────────────────────────────────────────────────

test("sources: Search matches a marker by name, a glyph by key or label, a game icon by id", function()
  local _, IB, Media = env(true)
  local Src = IB.Sources
  local tabs = tabsOf(IB)
  local markers, glyphsTab, gameTab = tabNamed(tabs, "markers"), tabNamed(tabs, "glyphs"), tabNamed(tabs, "game")
  local list = Src.Markers()
  assertEqual(table.concat(Src.Search(list, markers, "sk"), ","), SKULL)
  assertEqual(table.concat(Src.Search(list, markers, "SKULL"), ","), SKULL, "case-insensitive")
  assertEqual(#Src.Search(list, markers, "  "), 8, "a blank search keeps every icon")
  assertEqual(#Src.Search(list, markers, nil), 8)
  local thumb = Media.Icon(OWNER, "thumb-up")
  local glyphs = { Media.Icon(OWNER, "close"), thumb, Media.Icon(OWNER, "ph:arrow-up") }
  assertTrue(listed(Src.Search(glyphs, glyphsTab, "thumb-up"), thumb), "by its catalog key")
  assertTrue(listed(Src.Search(glyphs, glyphsTab, "Thumbs up"), thumb), "by its shown label")
  assertTrue(listed(Src.Search(glyphs, glyphsTab, "ph:arrow-up"), Media.Icon(OWNER, "ph:arrow-up")), "prefix and all")
  assertTrue(#Src.Search(glyphs, glyphsTab, "thumb") < #glyphs)
  local game = { 132092, 99, 51320, "Interface\\Icons\\Ability_CheapShot" }
  assertEqual(table.concat(Src.Search(game, gameTab, "132"), ","), "132092,51320", "by the id's digits")
  assertEqual(table.concat(Src.Search(game, gameTab, " 99 "), ","), "99", "trimmed")
  assertEqual(Src.Search(game, gameTab, "cheapshot")[1], game[4], "a texture path by its name")
  assertEqual(#Src.Search(game, gameTab, "icons"), 0, "the name only, not the folder")
  assertEqual(#Src.Search(game, gameTab, "%["), 0, "plain text, never a pattern")
end)

test("sources: Search narrows its last results, and stays correct when the query widens or the list grows", function()
  local _, IB = env()
  local Src = IB.Sources
  local gameTab = tabNamed(tabsOf(IB), "game")
  local swapped = { 132092, 99, 51320 }
  assertEqual(table.concat(Src.Search(swapped, gameTab, "13"), ","), "132092,51320")
  swapped[2] = 1399
  -- red under: drop the last-results narrowing
  assertEqual(#Src.Search(swapped, gameTab, "139"), 0, "narrowed from the last results")
  local list = { 132092, 99, 51320, 136116, 13209 }
  assertEqual(table.concat(Src.Search(list, gameTab, "13"), ","), "132092,51320,136116,13209")
  assertEqual(table.concat(Src.Search(list, gameTab, "1320"), ","), "132092,51320,13209", "narrowed")
  assertEqual(table.concat(Src.Search(list, gameTab, "2"), ","), "132092,51320,13209", "widened again")
  list[#list + 1] = 1320
  assertEqual(table.concat(Src.Search(list, gameTab, "1320"), ","), "132092,51320,13209,1320", "a grown list")
end)

test("sources: a host tab is searched by its search text, else its names, else the ids", function()
  local _, IB = env()
  local Src = IB.Sources
  local named = { key = "n", label = "N", list = function() return {} end,
    name = function(i) return ({ [1] = "Helm of Valor", [2] = "Boots" })[i] end }
  assertEqual(table.concat(Src.Search({ 1, 2, 3 }, named, "helm"), ","), "1")
  assertEqual(table.concat(Src.Search({ 1, 2, 3 }, named, "3"), ","), "3", "an unnamed id by its digits")
  local custom = { key = "c", label = "C", list = function() return {} end,
    search = function(i) return i == 2 and "secret word" or "" end }
  assertEqual(table.concat(Src.Search({ 1, 2 }, custom, "WORD"), ","), "2")
end)

-- ── the glyph helpers ──────────────────────────────────────────────────────────────────────

test("sources: IsGlyph names a catalog glyph by its path, for any owner, and nothing else", function()
  local _, IB, Media = env(true)
  assertEqual(IB.IsGlyph(Media.Icon(OWNER, "ph:arrow-up")), "ph:arrow-up")
  assertEqual(IB.IsGlyph(Media.Icon("Other", "close")), "close")
  assertEqual(IB.IsGlyph(Media.Icon(OWNER, "gi:sword-wound")), "gi:sword-wound")
  assertNil(IB.IsGlyph(SKULL))
  assertNil(IB.IsGlyph(132092))
  assertNil(IB.IsGlyph(nil))
  assertNil(IB.IsGlyph("Interface\\AddOns\\X\\libs\\LibKa0s\\media\\icons\\not-a-mark"))
  assertNil(IB.IsGlyph("Interface\\AddOns\\X\\libs\\LibKa0s\\media\\icons\\nowhere\\close"))
end)

test("sources: ColorFrom gives false for white and lowercase hex otherwise", function()
  local _, IB = env()
  -- red under: store white as "ffffff"
  assertEqual(IB.ColorFrom(1, 1, 1), false)
  assertEqual(IB.ColorFrom(1, 0.5, 0), "ff8000")
  assertEqual(IB.ColorFrom(0, 0.5, 1), "0080ff")
  assertEqual(IB.ColorFrom(2, -1, 0), "ff0000", "clamped")
end)

test("sources: ValidColor takes none or six lowercase hex digits; Tint reads one as r, g, b", function()
  local _, IB = env()
  assertTrue(IB.ValidColor(nil))
  assertTrue(IB.ValidColor(false))
  assertTrue(IB.ValidColor("ff8000"))
  local ok, why = IB.ValidColor("FF8000")
  assertFalse(ok)
  assertEqual(why, "badColor")
  assertFalse(IB.ValidColor("ff80"))
  assertFalse(IB.ValidColor(12))
  local r, g, b = IB.Tint("ff0080")
  assertEqual(r, 1)
  assertEqual(g, 0)
  assertEqual(b, 128 / 255)
  r, g, b = IB.Tint(nil)
  assertEqual(r + g + b, 3, "none is white")
  r, g, b = IB.Tint("nope")
  assertEqual(r + g + b, 3, "a malformed color is white")
end)
