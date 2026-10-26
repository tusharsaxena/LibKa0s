-- tests/test_skin.lua — LibKa0s-Skin-1.0, the skin engine and Ka0s Default.
--
-- Two kinds of case. The engine cases run on a fresh environment with only Core, Skin and
-- SkinDefs loaded (`env()`), so owners, skins and recorded frames never leak between cases. The
-- Ka0s Default cases read the full load (T.mocks) and the library's own source text: a token is
-- pinned against the constant it replaces, read out of the file that draws it today, so a constant
-- edited without its token (or the reverse) goes red here.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil, assertError =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil, T.assertError
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local MAJOR = "LibKa0s-Skin-1.0"

--- A fresh environment with Core, Skin and (unless `noDefs`) SkinDefs loaded.
local function env(noDefs)
  local m = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, m)
  Loader.load("LibKa0s/Skin.lua", nil, m)
  if not noDefs then Loader.load("LibKa0s/SkinDefs.lua", nil, m) end
  return m, m.LibStub(MAJOR)
end

--- A test skin deriving from Ka0s Default, with a red window and no inner rule.
local function redSkin(Skin)
  return Skin:RegisterSkin({ key = "red", label = "Red", tokens = {
    ["win.bg"] = { 1, 0, 0, 1 }, ["win.inner"] = false, ["bar.gloss"] = true,
  } })
end

--- A spy primitive: records `{ owner, frame, n, ... }` per call.
local function spyPrim(Skin, name)
  local calls = {}
  Skin.prim[name] = function(owner, frame, ...)
    calls[#calls + 1] = { owner = owner, frame = frame, n = select("#", ...), ... }
    Skin:Track(owner, frame, name, ...)
  end
  return calls
end

local function frame(name) return { name = name } end

local function sameColor(c, want, label)
  assertTrue(type(c) == "table", label .. ": a color table")
  for i = 1, 3 do assertEqual(c[i], want[i], label .. " component " .. i) end
  assertEqual(c[4] or 1, want[4] or 1, label .. " alpha")
end

-- ── the major ────────────────────────────────────────────────────────────────────────────────

test("skin: the major registers both files and the sentinel", function()
  local Skin = T.mocks.LibStub(MAJOR)
  assertTrue(Skin ~= nil, "LibKa0s-Skin-1.0 is loaded by LibKa0s.xml")
  assertEqual(Skin.MODULES.Skin, Skin.MINOR, "the shell's entry is the major's minor")
  assertEqual(Skin.MODULES.SkinDefs, Skin.__defsMinor, "SkinDefs reports its own minor")
  assertEqual(Skin.__defsShellMinor, Skin.MINOR, "SkinDefs attached to the live shell")
  assertEqual(Skin.FROM_SKIN, "@skin", "the sentinel")
  assertEqual(Skin.DEFAULT, "ka0s", "the default skin")
end)

test("skin: the shell refuses without Core, and SkinDefs then attaches to nothing", function()
  local m = buildMocks()
  Loader.load("LibKa0s/Skin.lua", nil, m)
  Loader.load("LibKa0s/SkinDefs.lua", nil, m)
  assertNil(m.LibStub(MAJOR, true), "no Core, no major")
end)

test("skin: without SkinDefs the engine runs and every token is nil", function()
  local _, Skin = env(true)
  Skin:RegisterOwner("A")
  assertNil(Skin:Token("A", "win.bg"), "no skin registered, nothing resolves")
  assertNil(Skin:Color("A", "win.bg"), "Color answers nil too")
  assertEqual(#Skin:Skins(), 0, "no skins")
end)

-- ── the schema and Ka0s Default ──────────────────────────────────────────────────────────────

local KIND_OK = {
  color = function(v) return type(v) == "table" and type(v[1]) == "number" and #v >= 3 end,
  colors = function(v) return type(v) == "table" and #v > 0 and type(v[1]) == "table" end,
  number = function(v) return type(v) == "number" end,
  string = function(v) return type(v) == "string" end,
  bool = function(v) return type(v) == "boolean" end,
}

test("skin: the schema names each token once, with a known kind", function()
  local Skin = T.mocks.LibStub(MAJOR)
  local seen = {}
  assertTrue(#Skin.SCHEMA > 150, "the schema is the whole vocabulary, got " .. #Skin.SCHEMA)
  for _, e in ipairs(Skin.SCHEMA) do
    assertNil(seen[e.name], "token " .. e.name .. " is listed once")
    seen[e.name] = true
    assertTrue(KIND_OK[e.kind] ~= nil, e.name .. " has a known kind: " .. tostring(e.kind))
  end
  for _, name in ipairs({ "gtip.title", "gtip.body", "gtip.muted", "text.headingAlt",
    "win.bgTop", "win.bgBottom", "title.bgTop", "title.bgBottom", "input.radius", "tab.radius",
    "check.radius", "scroll.radius", "popup.radius", "chart.series" }) do
    assertTrue(seen[name], "the schema carries " .. name)
  end
  for _, ctl in ipairs({ "btn", "btnPrimary", "input", "check", "tab", "nav", "drawer", "popup",
    "menu" }) do
    assertTrue(seen[ctl .. ".borderSize"], ctl .. ".borderSize")
    assertTrue(seen[ctl .. ".borderStyle"], ctl .. ".borderStyle")
  end
end)

test("skin: every registered skin resolves every schema token to its kind", function()
  local Skin = T.mocks.LibStub(MAJOR)
  assertTrue(#Skin:Skins() >= 1, "at least Ka0s Default is registered")
  for _, def in ipairs(Skin:Skins()) do
    local tokens = Skin:ResolveSkin(def.key)
    for _, e in ipairs(Skin.SCHEMA) do
      local v = tokens[e.name]
      if v == nil then
        assertTrue(e.nilable, def.key .. ": " .. e.name .. " resolves (only nilable tokens may be nil)")
      else
        assertTrue(KIND_OK[e.kind](v), def.key .. ": " .. e.name .. " is a " .. e.kind)
      end
    end
  end
end)

test("skin: Ka0s Default sets every token, faces and sizes included", function()
  -- SkinDefs minor 8, the owner's ruling (2026-10-26): Ka0s Default leaves nothing to the client.
  -- Every schema token carries a value or `false` (the explicit "none"); its faces are Friz
  -- Quadrata, set rather than inherited from the client's font objects, and its sizes the reference
  -- every skin scales against. red under: a Ka0s Default token left nil.
  local Skin = T.mocks.LibStub(MAJOR)
  local own = Skin.skins.ka0s.tokens
  local missing = {}
  for _, e in ipairs(Skin.SCHEMA) do
    if own[e.name] == nil then missing[#missing + 1] = e.name end
  end
  assertEqual(#missing, 0, "Ka0s Default leaves these to the client: " .. table.concat(missing, ", "))
  local tokens = Skin:ResolveSkin("ka0s")
  assertEqual(tokens["font.body"], "Friz Quadrata TT", "the body face, set")
  assertEqual(tokens["font.title"], "Friz Quadrata TT", "the title face, set")
  assertEqual(tokens["font.bodySize"], 12, "the body reference")
  assertEqual(tokens["font.titleSize"], 14, "the title reference")
  sameColor(tokens["q.epic"], { 0.64, 0.21, 0.93, 1 }, "the client's epic purple, written out")
end)

test("skin: Ka0s Default equals the published constants", function()
  local Skin = T.mocks.LibStub(MAJOR)
  local core = T.mocks.LibStub("LibKa0s-Core-1.0")
  local W = T.mocks.LibStub("LibKa0s-Widgets-1.0")
  local k = Skin:ResolveSkin("ka0s")
  sameColor(k["win.bg"], core.SKIN.bg, "win.bg = Core.SKIN.bg")
  sameColor(k["win.border"], core.SKIN.border, "win.border = Core.SKIN.border")
  sameColor(k["win.inner"], core.SKIN.innerBorder, "win.inner = Core.SKIN.innerBorder")
  sameColor(k["divider"], core.SKIN.divider, "divider = Core.SKIN.divider")
  sameColor(k["title.text"], core.SKIN.title, "title.text = Core.SKIN.title")
  assertEqual(k["win.borderSize"], core.SKIN.edgeSize, "win.borderSize = Core.SKIN.edgeSize")
  assertEqual(k["win.inset"], core.SKIN.insets.left, "win.inset = Core.SKIN.insets")
  local LC = W.LINE_CHART
  sameColor(k["chart.axis"], LC.AXIS, "chart.axis")
  sameColor(k["chart.grid"], LC.GRID, "chart.grid")
  sameColor(k["chart.crosshair"], LC.CROSSHAIR, "chart.crosshair")
  sameColor(k["chart.marker"], LC.MARKER, "chart.marker")
  sameColor(k["chart.line"], LC.LINE, "chart.line")
  local AC = W.AUTOCOMPLETE
  sameColor(k["input.border"], AC.BORDER, "input.border = AUTOCOMPLETE.BORDER")
  sameColor(k["input.bg"], AC.BG, "input.bg = AUTOCOMPLETE.BG")
  sameColor(k["text.body"], AC.TEXT, "text.body = AUTOCOMPLETE.TEXT")
  sameColor(k["menu.hover"], AC.HIGHLIGHT, "menu.hover = AUTOCOMPLETE.HIGHLIGHT")
end)

--- The numbers in the first `NAME = { ... }` line of a payload file: `{ 0.3, 0.5, 1 }`,
--- `{ r = 0.1, g = 0.1, b = 0.1, a = 0.85 }`, or a bare number.
local function constant(file, name)
  local f = assert(io.open("LibKa0s/" .. file, "r"))
  local src = f:read("*a")
  f:close()
  for line in src:gmatch("[^\n]+") do
    local body = line:match("^%s*local%s+" .. name .. "%s*=%s*{([^{}]*)}")
      or line:match("^%s*" .. name .. "%s*=%s*{([^{}]*)}")
    if body then
      local out = {}
      for n in body:gmatch("%-?%d*%.?%d+") do out[#out + 1] = tonumber(n) end
      return out
    end
    local num = line:match("^%s*local%s+" .. name .. "%s*=%s*(%d+)")
    if num then return tonumber(num) end
  end
  error(file .. ": no constant " .. name)
end

-- { file, constant, token }: the file-local constant each Ka0s Default token replaces.
local PINS = {
  { "Core.lua", "CLOSE_REST", "close.rest" }, { "Core.lua", "CLOSE_HOT", "close.hot" },
  { "Widgets.lua", "fill", "input.bg" }, { "Widgets.lua", "line", "input.border" },
  { "Widgets.lua", "focus", "input.focus" },
  { "Widgets.lua", "test", "strip.test" }, { "Widgets.lua", "sim", "strip.sim" },
  { "OptionsNav.lua", "SELECT_RGB", "nav.selBg" }, { "OptionsNav.lua", "LABEL_GOLD", "nav.text" },
  { "OptionsNav.lua", "LABEL_WHITE", "nav.selText" }, { "OptionsNav.lua", "PANE_FILL", "nav.bg" },
  { "OptionsNav.lua", "PANE_BORDER", "nav.border" },
  { "OptionsDrawer.lua", "HEAD_FILL", "drawer.bg" },
  { "OptionsDrawer.lua", "HEAD_FILL_OPEN", "drawer.bgOpen" },
  { "OptionsDrawer.lua", "HEAD_EDGE", "drawer.border" },
  { "OptionsDrawer.lua", "HEAD_EDGE_OPEN", "drawer.borderOpen" },
  { "OptionsDrawer.lua", "BOX_FILL", "drawer.boxBg" },
  { "OptionsDrawer.lua", "BOX_EDGE", "drawer.boxBorder" },
  { "OptionsDrawer.lua", "GOLD", "drawer.textSet" }, { "OptionsDrawer.lua", "WHITE", "drawer.text" },
  { "OptionsDrawer.lua", "SUMMARY_SET", "drawer.summarySet" },
  { "OptionsDrawer.lua", "SUMMARY_ANY", "drawer.summary" },
  { "OptionsTabs.lua", "TAB_BG_BOTTOM_COLOR", "tab.bgBottom" },
  { "OptionsTabs.lua", "TAB_BG_BOTTOM_COLOR", "tab.bg" },
  { "OptionsTabs.lua", "TAB_BG_TOP_COLOR", "tab.bgTop" },
  { "OptionsTabs.lua", "TAB_GLOW_BOTTOM", "tab.glow" },
  { "OptionsTabs.lua", "CHROME_RULE_COLOR", "tab.rule" },
  { "OptionsScroll.lua", "THUMB_ON", "scroll.thumbOn" },
  { "OptionsScroll.lua", "THUMB_OFF", "scroll.thumbOff" },
  { "OptionsScroll.lua", "GUTTER", "scroll.gutter" },
  { "DebugLogWindow.lua", "DIAG_REST", "text.link" }, { "DebugLogWindow.lua", "DIAG_HOT", "text.linkHot" },
  { "DebugLogWindow.lua", "REST", "text.muted" }, { "DebugLogWindow.lua", "HOT", "text.accent" },
  { "DebugLogWindow.lua", "BAR_W", "scroll.width" },
  { "PerfPanel.lua", "CMD_COLOR", "text.faint" }, { "SimPanel.lua", "CMD_COLOR", "text.faint" },
  { "SimPanel.lua", "HOVER_CANCEL", "sem.stepCancelHot" }, { "SimPanel.lua", "HOVER_GOLD", "text.accent" },
}

test("skin: Ka0s Default equals the file-local constants it replaces", function()
  local k = T.mocks.LibStub(MAJOR):ResolveSkin("ka0s")
  for _, pin in ipairs(PINS) do
    local file, name, token = pin[1], pin[2], pin[3]
    local want, label = constant(file, name), token .. " = " .. file .. " " .. name
    if type(want) == "number" then
      assertEqual(k[token], want, label)
    else
      sameColor(k[token], want, label)
    end
  end
end)

-- LootHistory's constants (inputs/LOOTHISTORY_SURFACES.md section 3), written out: a library
-- suite cannot read a consumer's source, so the values are restated here with their sites.
local LOOTHISTORY = {
  { "text.headingAlt", { 0.91, 0.77, 0.42 } },          -- Panel.lua GOLD_RGB (AH header)
  { "list.stripe", { 1, 1, 1, 0.03 } },                 -- BrowserTable / HoldingsTab stripe
  { "list.hover", { 1, 0.82, 0, 0.10 } },               -- BrowserTable / HoldingsTab hover
  { "menu.borderAlt", { 0.62, 0.5, 0.18, 1 } },         -- BrowserTable row menu edge
  { "btn.bg", { 0.1, 0.1, 0.12, 0.9 } },                -- the three flat button copies
  { "btn.border", { 0.24, 0.24, 0.27, 0.9 } },
  { "btn.icon", { 0.85, 0.85, 0.85 } },
  { "btn.text", { 1, 1, 1 } }, { "btn.hover", { 1, 0.82, 0 } },
  -- SkinDefs minor 7 (the owner's note): Ka0s Default's checkbox is a square box in the control
  -- colors, Widgets SKIN.fill under SKIN.line, rather than Timeline's .24 gray.
  { "check.bg", { 0.1, 0.1, 0.12, 0.9 } }, { "check.border", { 0.24, 0.24, 0.27, 0.9 } },
  { "check.mark", { 1, 0.82, 0, 1 } },
  { "card.bg", { 0.1, 0.1, 0.12, 0.85 } }, { "card.border", { 0.24, 0.24, 0.27, 0.9 } },
  { "panel.bg", { 0.08, 0.08, 0.10, 0.6 } }, { "panel.border", { 0.24, 0.24, 0.27, 0.7 } },
  { "section.rule", { 1, 0.82, 0, 0.35 } }, { "chart.track", { 1, 1, 1, 0.06 } },
  { "chart.axisAlt", { 0.55, 0.55, 0.60, 0.9 } }, { "chart.bar", { 0.40, 0.60, 0.95, 0.9 } },
  { "chart.other", { 0.55, 0.62, 0.72 } }, { "chart.total", { 1, 0.82, 0, 1 } },
  { "tab.text", { 0.7, 0.7, 0.72 } }, { "tab.onText", { 1, 0.82, 0 } },
  { "gtip.title", { 1, 0.82, 0 } }, { "gtip.body", { 0.9, 0.9, 0.9 } },
  { "gtip.muted", { 0.5, 0.5, 0.5 } },
  { "sem.good", { 0.35, 0.80, 0.45 } }, { "sem.bad", { 1.00, 0.33, 0.33 } },
  { "sem.neutral", { 0.62, 0.62, 0.66 } }, { "sem.gold", { 1.00, 0.86, 0.55 } },
  { "sem.warband", { 0.25, 0.75, 0.95, 1 } }, { "sem.modeTest", { 1, 0.15, 0.15 } },
  { "sem.info", { 0.3, 0.8, 1 } },
  -- The bind states (SkinDefs minor 5): BrowserTable BOUND_STYLE, the table's padlocks ...
  { "sem.boundNone", { 0.60, 0.60, 0.60, 0.40 } }, { "sem.boundBoE", { 0.92, 0.92, 0.92, 0.95 } },
  { "sem.boundBoP", { 0.30, 0.82, 0.42, 1 } }, { "sem.boundWarband", { 0.30, 0.58, 0.98, 1 } },
  { "sem.boundWarbandUE", { 0.95, 0.52, 0.12, 1 } },
  -- ... and AnalyticsFormat BOUND_COLOR, Insights' split of three of them (warband and warband
  -- until equipped are the table's own two there).
  { "sem.boundBoPAlt", { 0.85, 0.45, 0.45, 1 } }, { "sem.boundBoEAlt", { 0.55, 0.80, 0.60, 1 } },
  { "sem.boundNoneAlt", { 0.60, 0.60, 0.65, 1 } },
  { "sem.danger", { 1, 1 / 3, 1 / 3, 1 } },             -- the row menu's Delete / Forget |cffff5555
  -- The rest of LootHistory's constants (SkinDefs minor 6), each where no older token matched:
  { "text.value", { 0.8, 0.8, 0.82, 1 } },              -- AnalyticsCharts value / legend text
  { "text.bodyAlt", { 0.86, 0.86, 0.86, 1 } },          -- Panel.lua live AH addon name
  { "text.subtle", { 0.85, 0.85, 0.85, 1 } },           -- HoldingsTab holder total and fresh age
  { "text.highlight", { 1, 1, 1, 1 } },                 -- HoldingsTab setCell's default
  { "gtip.value", { 1, 1, 1, 1 } },                     -- Compat / Timeline / Insights values
  { "gtip.subtle", { 0.7, 0.7, 0.7, 1 } },              -- LauncherSetup's record-count line
  { "icon.dim", { 0.55, 0.55, 0.55, 1 } },              -- Panel.lua inactive info-icon tint
  { "sem.goodAlt", { 0.25, 1, 0.25, 1 } },              -- LedgerFormat |cff40ff40
  { "sem.badAlt", { 1, 0.25, 0.25, 1 } },               -- LedgerFormat |cffff4040
  { "sem.warbandAlt", { 0.4, 0.78, 1, 1 } },            -- HoldingsTab Warband label
  { "sem.unknown", { 0.6, 0.6, 0.6, 1 } },              -- AnalyticsFormat qualityColor fallback
}

test("skin: Ka0s Default equals LootHistory's constants", function()
  local k = T.mocks.LibStub(MAJOR):ResolveSkin("ka0s")
  for _, pin in ipairs(LOOTHISTORY) do sameColor(k[pin[1]], pin[2], pin[1]) end
  assertEqual(k["title.height"], 30, "title.height = Browser SKIN.titleBarH")
  assertEqual(#k["chart.series"], 21, "chart.series = AnalyticsFormat PALETTE (21)")
  sameColor(k["chart.series"][1], { 0.90, 0.25, 0.25 }, "PALETTE[1]")
  sameColor(k["chart.series"][21], { 0.50, 0.28, 0.62 }, "PALETTE[21]")
  local d = k["sem.danger"]
  local function byte(v) return math.floor(v * 255 + 0.5) end
  assertEqual(("%02x%02x%02x"):format(byte(d[1]), byte(d[2]), byte(d[3])), "ff5555",
    "sem.danger hex-encodes to the row menu's exact |cffff5555 byte")
  -- The escapes LootHistory writes as literals, each from the token that keeps its bytes.
  for name, want in pairs({ ["sem.goodAlt"] = "40ff40", ["sem.badAlt"] = "ff4040",
      ["text.disabled"] = "808080", ["text.accent"] = "ffd100" }) do
    local c = k[name]
    assertEqual(("%02x%02x%02x"):format(byte(c[1]), byte(c[2]), byte(c[3])), want,
      name .. " hex-encodes to LootHistory's |cff" .. want)
  end
end)

-- ── skins ────────────────────────────────────────────────────────────────────────────────────

test("skin: a skin derives from Ka0s Default, and false means none", function()
  local _, Skin = env()
  redSkin(Skin)
  local t = Skin:ResolveSkin("red")
  sameColor(t["win.bg"], { 1, 0, 0, 1 }, "the skin's own token")
  sameColor(t["win.border"], { 0, 0, 0, 1 }, "inherited from Ka0s Default")
  assertNil(t["win.inner"], "false resolves to none")
  assertEqual(t["bar.gloss"], true, "a bool keeps its value")
  assertEqual(Skin:ResolveSkin("nope"), Skin:ResolveSkin("ka0s"), "an unknown key is Ka0s Default")
end)

test("skin: RegisterSkin validates, orders and replaces", function()
  local _, Skin = env()
  assertError(function() Skin:RegisterSkin({ tokens = {} }) end)
  assertError(function() Skin:RegisterSkin({ key = "x" }) end)
  local shipped = #Skin:Skins()
  redSkin(Skin)
  local list = Skin:Skins()
  assertEqual(list[1].key, "ka0s", "Ka0s Default first")
  assertEqual(list[1].label, "Ka0s Default", "its label")
  assertEqual(#list[1].swatches, 4, "four swatches")
  assertEqual(list[shipped + 1].key, "red", "then registration order, after the shipped skins")
  local before = Skin:ResolveSkin("red")
  Skin:RegisterSkin({ key = "red", tokens = { ["win.bg"] = { 0, 1, 0, 1 } } })
  assertEqual(#Skin:Skins(), shipped + 1, "a second registration replaces, it does not append")
  assertTrue(Skin:ResolveSkin("red") ~= before, "the cache is rebuilt")
  sameColor(Skin:Token("x", "win.bg"), { 0.06, 0.06, 0.08, 0.92 }, "unregistered owner: Ka0s")
end)

-- ── owners and choice ────────────────────────────────────────────────────────────────────────

test("skin: an unregistered owner is not an owner and reads Ka0s Default", function()
  local _, Skin = env()
  assertFalse(Skin:IsOwner("Nobody"), "not registered")
  local source, skin = Skin:GetChoice("Nobody")
  assertEqual(source, "ka0s", "source")
  assertEqual(skin, "ka0s", "skin")
  local changed = Skin:SetChoice("Nobody", "ka0s", "red")
  assertFalse(changed, "SetChoice refuses an unregistered owner")
  assertError(function() Skin:RegisterOwner("") end)
  assertError(function() Skin:For(nil) end)
end)

test("skin: RegisterOwner reads the host's choice once, in either shape", function()
  local _, Skin = env()
  redSkin(Skin)
  local S = Skin:RegisterOwner("A", { get = function() return { source = "ka0s", skin = "red" } end })
  assertTrue(Skin:IsOwner("A"), "registered")
  assertEqual(S, Skin:For("A"), "answers the facade")
  assertEqual(select(2, Skin:GetChoice("A")), "red", "table form")
  Skin:RegisterOwner("B", { get = function() return "eui", "red" end, label = "Bee" })
  assertEqual(Skin:GetChoice("B"), "eui", "two-value form")
  assertEqual(Skin.owners.B.label, "Bee", "label")
  Skin:RegisterOwner("C", { get = function() return "bogus", 7 end })
  local src, sk = Skin:GetChoice("C")
  assertEqual(src, "ka0s", "an unknown source is cleaned")
  assertEqual(sk, "ka0s", "a non-string skin is cleaned")
  Skin:RegisterOwner("A", { get = function() return "ka0s", "ka0s" end })
  assertEqual(select(2, Skin:GetChoice("A")), "red", "a second registration keeps the choice")
  local owners = Skin:Owners()
  assertEqual(table.concat(owners, ","), "A,B,C", "sorted owners")
end)

test("skin: SetChoice is idempotent", function()
  local _, Skin = env()
  redSkin(Skin)
  Skin:RegisterOwner("A")
  local calls = spyPrim(Skin, "Shell")
  Skin.prim.Shell("A", frame("f"))
  local fired = 0
  Skin:OnLooksChanged("A", function() fired = fired + 1 end)
  local changed = Skin:SetChoice("A", "ka0s", "ka0s")
  assertFalse(changed, "the same choice changes nothing")
  assertEqual(#calls, 1, "nothing repainted")
  assertEqual(fired, 0, "no listener fired")
  assertTrue(Skin:SetChoice("A", nil, "red"), "a new skin is a change")
  assertEqual(#calls, 2, "repainted once")
  assertEqual(fired, 1, "the listener fired once")
  assertFalse(Skin:SetChoice("A", "ka0s", "red"), "and repeating it is not")
end)

test("skin: SetChoice resolves before the listeners run", function()
  local _, Skin = env()
  redSkin(Skin)
  local S = Skin:RegisterOwner("A")
  local seen
  S.OnLooksChanged(function(source, skin) seen = { source, skin, S.Token("win.bg") } end)
  Skin:SetChoice("A", "ka0s", "red")
  assertEqual(seen[1], "ka0s", "source")
  assertEqual(seen[2], "red", "skin")
  sameColor(seen[3], { 1, 0, 0, 1 }, "the listener reads the new skin's tokens")
end)

test("skin: leaving eui after EllesmereUI painted asks for one reload and repaints nothing", function()
  local _, Skin = env()
  redSkin(Skin)
  Skin:RegisterOwner("A", { get = function() return "eui", "ka0s" end })
  Skin.euiPainted.A = true   -- SkinEUI.lua's latch: EllesmereUI painted A this session
  local calls = spyPrim(Skin, "Shell")
  Skin.prim.Shell("A", frame("f"))
  local changed, reload = Skin:SetChoice("A", "ka0s", "red")
  assertTrue(changed, "the choice is stored")
  assertTrue(reload, "the first switch away from eui needs a reload")
  assertTrue(Skin:PendingReload("A"), "the flag is set")
  assertEqual(#calls, 1, "nothing repainted")
  local _, again = Skin:SetChoice("A", "ka0s", "ka0s")
  assertFalse(again, "the popup is raised at most once")
  assertEqual(select(2, Skin:GetChoice("A")), "ka0s", "the choice still moves")
  assertFalse(Skin:PendingReload("B"), "another owner has no flag")
end)

test("skin: leaving an eui EllesmereUI never painted is an ordinary change", function()
  local _, Skin = env()
  redSkin(Skin)
  Skin:RegisterOwner("A", { get = function() return "eui", "ka0s" end })
  local calls = spyPrim(Skin, "Shell")
  Skin.prim.Shell("A", frame("f"))
  local asked = 0
  Skin:OnReloadRequest("A", function() asked = asked + 1 end)
  local changed, reload = Skin:SetChoice("A", "ka0s", "red")
  assertTrue(changed, "the choice moves")
  assertFalse(reload, "no reload: the owner wore its Ka0s skin all along")
  assertFalse(Skin:PendingReload("A"), "no flag")
  assertEqual(#calls, 2, "repainted live")
  assertEqual(asked, 0, "no reload request")
end)

-- ── per-owner isolation and the repaint ──────────────────────────────────────────────────────

test("skin: one owner switching never repaints another's frames", function()
  local _, Skin = env()
  redSkin(Skin)
  Skin:RegisterOwner("A")
  Skin:RegisterOwner("B")
  local calls = spyPrim(Skin, "Shell")
  local fa, fb = frame("a"), frame("b")
  Skin.prim.Shell("A", fa)
  Skin.prim.Shell("B", fb)
  local firedB = 0
  Skin:OnLooksChanged("B", function() firedB = firedB + 1 end)
  Skin:SetChoice("A", "ka0s", "red")
  assertEqual(#calls, 3, "one repaint call")
  assertEqual(calls[3].frame, fa, "of A's frame")
  assertEqual(calls[3].owner, "A", "for A")
  assertEqual(firedB, 0, "B's listener did not fire")
  sameColor(Skin:Token("A", "win.bg"), { 1, 0, 0, 1 }, "A wears red")
  sameColor(Skin:Token("B", "win.bg"), { 0.06, 0.06, 0.08, 0.92 }, "B still wears Ka0s Default")
  assertTrue(Skin:For("A") ~= Skin:For("B"), "each owner has its own facade")
end)

test("skin: a repaint replays each recorded frame once, primitives in first-paint order", function()
  local _, Skin = env()
  Skin:RegisterOwner("A")
  local order = {}
  for _, name in ipairs({ "Shell", "Divider" }) do
    Skin.prim[name] = function(owner, f, ...)
      order[#order + 1] = name .. ":" .. f.name .. ":" .. tostring((...))
      Skin:Track(owner, f, name, ...)
    end
  end
  local f1, f2, f3 = frame("1"), frame("2"), frame("3")
  Skin.prim.Shell("A", f1, "x")
  Skin.prim.Shell("A", f1, "y")     -- repeated: replaces the arguments
  Skin.prim.Shell("A", f2)
  Skin.prim.Divider("A", f2, "d")
  Skin.prim.Shell("A", f3)
  order = {}
  assertEqual(Skin:Repaint("A"), 4, "four primitive calls over three frames")
  local seen = {}
  for _, line in ipairs(order) do seen[line] = (seen[line] or 0) + 1 end
  assertEqual(seen["Shell:1:y"], 1, "f1 once, with its latest arguments")
  assertEqual(seen["Shell:1:x"], nil, "never with its replaced ones")
  assertEqual(seen["Shell:2:nil"], 1, "f2's Shell once")
  assertEqual(seen["Divider:2:d"], 1, "f2's Divider once")
  assertEqual(seen["Shell:3:nil"], 1, "f3 once")
  local i, j
  for n, line in ipairs(order) do
    if line == "Shell:2:nil" then i = n elseif line == "Divider:2:d" then j = n end
  end
  assertTrue(i < j, "a frame's primitives replay in first-paint order")
  assertEqual(Skin:Repaint("Nobody"), 0, "an owner with no frames repaints nothing")
end)

test("skin: a repaint replays frames in the order they were first painted", function()
  local _, Skin = env()
  Skin:RegisterOwner("A")
  Skin:RegisterOwner("B")
  local order = {}
  Skin.prim.Shell = function(owner, f)
    order[#order + 1] = f
    Skin:Track(owner, f, "Shell")
  end
  -- Enough frames that a hash walk would almost never come out in paint order.
  local frames = {}
  for n = 1, 40 do frames[n] = frame(tostring(n)) end
  for n = 40, 1, -1 do Skin.prim.Shell("A", frames[n]) end
  Skin.prim.Shell("A", frames[40])  -- painted again: keeps its first-paint place
  Skin.prim.Shell("B", frames[20])  -- moved to B: no longer A's
  Skin.prim.Shell("A", frames[20])  -- back to A: a fresh first paint, so last
  order = {}
  assertEqual(Skin:Repaint("A"), 40, "every frame once")
  local want = {}
  for n = 40, 1, -1 do if n ~= 20 then want[#want + 1] = frames[n] end end
  want[#want + 1] = frames[20]
  for n = 1, 40 do assertEqual(order[n], want[n], "frame " .. n .. " in first-paint order") end
end)

test("skin: the repaint flag is up only while replaying, and a raising primitive stops nothing", function()
  local _, Skin = env()
  Skin:RegisterOwner("A")
  local flags, ran = {}, 0
  Skin.prim.Shell = function(owner, f)
    flags[#flags + 1] = Skin.__repainting == true
    Skin:Track(owner, f, "Shell")
    if f.name == "bad" and Skin.__repainting then error("boom") end
    ran = ran + 1
  end
  Skin.prim.Shell("A", frame("bad"))
  Skin.prim.Shell("A", frame("good"))
  assertFalse(flags[1], "a first paint is not a repaint")
  ran = 0
  Skin:Repaint("A")
  assertEqual(ran, 1, "the good frame still repainted")
  assertTrue(flags[3] and flags[4], "the flag is up during the replay")
  assertFalse(Skin.__repainting == true, "and down after it")
end)

test("skin: a frame painted for a second owner moves to it; Untrack forgets it", function()
  local _, Skin = env()
  Skin:RegisterOwner("A")
  Skin:RegisterOwner("B")
  local calls = spyPrim(Skin, "Shell")
  local f = frame("pooled")
  Skin.prim.Shell("A", f)
  Skin.prim.Shell("B", f)
  assertEqual(Skin.painted[f].owner, "B", "the record follows the latest owner")
  assertNil(Skin.byOwner.A[f], "A no longer holds it")
  assertEqual(Skin:Repaint("A"), 0, "A repaints nothing")
  assertEqual(Skin:Repaint("B"), 1, "B repaints it")
  Skin:Untrack(f)
  assertNil(Skin.painted[f], "forgotten")
  assertEqual(Skin:Repaint("B"), 0, "and no longer repainted")
  assertEqual(#calls, 3, "two paints and one repaint")
  assertNil(Skin:Track("A", nil, "Shell"), "Track ignores a missing frame")
end)

test("skin: the frame registry holds its frames weakly", function()
  local _, Skin = env()
  Skin:RegisterOwner("A")
  Skin.prim.Shell = function(owner, f) Skin:Track(owner, f, "Shell") end
  Skin.prim.Shell("A", frame("gone"))
  collectgarbage("collect")
  collectgarbage("collect")
  assertEqual(next(Skin.byOwner.A), nil, "a dropped frame leaves the owner's set")
  assertEqual(next(Skin.painted), nil, "and the record table")
end)

-- ── the facade ───────────────────────────────────────────────────────────────────────────────

test("skin: the facade is late-bound: swapping lib.prim reaches a cached S", function()
  local _, Skin = env()
  local S = Skin:RegisterOwner("A")
  assertNil(S.Button(frame("b")), "no primitive loaded: a quiet nil")
  local hit
  Skin.prim.Button = function(owner, btn, opts) hit = { owner, btn, opts } ; return "ok" end
  local btn, opts = frame("b"), { primary = true }
  assertEqual(S.Button(btn, opts), "ok", "the spy answers")
  assertEqual(hit[1], "A", "called with the owner first")
  assertEqual(hit[2], btn, "then the caller's arguments")
  assertEqual(hit[3], opts, "all of them")
  for _, name in ipairs(Skin.VOCAB) do
    assertEqual(type(S[name]), "function", "S." .. name)
  end
  assertEqual(S.apiVersion, 3, "EllesmereUI's facade API version")
  assertEqual(S.owner, "A", "the owner")
  assertEqual(S.FROM_SKIN, "@skin", "the sentinel")
  assertTrue(S.IsEnabled(), "a registered owner is skinned")
  assertFalse(Skin:For("Other").IsEnabled(), "an unregistered one is not")
  assertEqual(S.GetStyle(), "ka0s:ka0s", "GetStyle names the skin")
  local r, g, b, a = S.Color("title.text")
  assertEqual(r + g + b + a, 1 + 0.82 + 0 + 1, "Color answers r, g, b and alpha 1")
end)

test("skin: a newer minor keeps every facade table and re-fills it", function()
  local m, Skin = env()
  local S = Skin:RegisterOwner("A")
  Skin:SetChoice("A", "ka0s", "ka0s")
  local oldToken = S.Token
  local src = Loader.readFile("LibKa0s/Skin.lua")
  local newer, n = src:gsub('local MAJOR, MINOR = "LibKa0s%-Skin%-1%.0", %d+',
    'local MAJOR, MINOR = "LibKa0s-Skin-1.0", 999', 1)
  assertEqual(n, 1, "the minor line was found")
  Loader.loadSource(newer, "newer/Skin.lua", nil, m)
  local live = m.LibStub(MAJOR)
  assertEqual(live, Skin, "the same library table")
  assertEqual(live.MINOR, 999, "the newer minor won")
  assertEqual(live:For("A"), S, "the facade table survived")
  assertTrue(S.Token ~= oldToken, "its entries were re-filled by the newer copy")
  assertTrue(live:IsOwner("A"), "the owner survived")
  assertEqual(live:ResolveSkin("ka0s")["title.height"], 30, "the skins survived")
end)

-- ── FROM_SKIN ────────────────────────────────────────────────────────────────────────────────

test("skin: Resolve answers the skin's value for the sentinel or a fromSkin companion", function()
  local _, Skin = env()
  redSkin(Skin)
  local S = Skin:RegisterOwner("A")
  assertEqual(S.Resolve("bar.texture", "@skin"), "Blizzard", "the sentinel resolves")
  assertEqual(S.Resolve("bar.texture", "Smooth"), "Smooth", "a real value passes through")
  assertEqual(S.Resolve("bar.texture", "Smooth", true), "Blizzard", "the companion wins")
  assertEqual(S.Resolve("bar.texture", nil, false), nil, "nil stays nil")
  Skin:SetChoice("A", nil, "red")
  assertEqual(S.Resolve("bar.gloss", Skin.FROM_SKIN), true, "follows the owner's skin")
  assertTrue(Skin.IsFromSkin("@skin"), "IsFromSkin")
  assertFalse(Skin.IsFromSkin("Blizzard"), "IsFromSkin on a value")
end)

test("skin: ResetToSkin puts listed keys back on the skin", function()
  local _, Skin = env()
  local p = {
    barTexture = "Smooth", fontColor = { 1, 1, 1 }, untouched = "x",
    font = { face = "Arial", color = { 0, 1, 0 } },
  }
  local n = Skin.ResetToSkin(p, { "barTexture", "fontColor", "font.face", "font.color",
    "missing.leaf", "newKey" })
  assertEqual(n, 5, "five keys set; a path through a missing table is skipped")
  assertEqual(p.barTexture, "@skin", "a plain key takes the sentinel")
  assertEqual(p.fontColor[1], 1, "a color keeps its value")
  assertEqual(p.fontColorFromSkin, true, "and its companion turns on")
  assertEqual(p.font.face, "@skin", "a dotted path")
  assertEqual(p.font.colorFromSkin, true, "a dotted color's companion")
  assertEqual(p.newKey, "@skin", "an absent key is set too")
  assertEqual(p.untouched, "x", "an unlisted key is left alone")
  assertNil(p.missing, "no table is created")
  assertEqual(Skin:ResetToSkin({ a = 1 }, { "a" }), 1, "the colon form works too")
  assertEqual(Skin.ResetToSkin(nil, { "a" }), 0, "no profile, nothing set")
end)
