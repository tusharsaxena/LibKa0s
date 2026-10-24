-- LibKa0s-Skin-1.0 — the token schema and the skins themselves. Ka0s Default here; the other eight
-- skins join it in this file.
--
-- ── WHY IT IS A FILE OF ITS OWN AND NOT MORE OF Skin.lua ─────────────────────────────────────
--
-- Skin.lua is the engine (owners, choice, resolve, the frame registry, the repaint); this file is
-- data. It is part of `LibKa0s-Skin-1.0`, paired on the shell's minor with the Widgets / Sim idiom,
-- so a skin table from one vendored copy never attaches to an engine from another without saying
-- so. A payload without this file still runs the engine: no skin is registered, every token
-- resolves to nil, and every primitive leaves the frame's stock look alone.
--
-- ── THE SCHEMA ───────────────────────────────────────────────────────────────────────────────
--
-- `lib.SCHEMA` lists every token a skin may set, in groups, each as `{ name, kind, nilable }`.
-- Kinds: `color` ({ r, g, b, a }, 0-1), `colors` (an ordered list of colors), `number`, `string`
-- (an LSM key, a texture path, an anchor word) and `bool`. A NILABLE token may resolve to nil, and
-- nil always means "leave the stock value alone": Ka0s Default leaves every font token nil, so a
-- FontString keeps its font object, its size and whatever a font-replacement addon did to it.
-- A skin derives from Ka0s Default (Skin:ResolveSkin): it names only the tokens it changes, and
-- `false` is how it says "none" for a token Ka0s Default sets.
--
-- ── KA0S DEFAULT IS TODAY'S CONSTANTS ────────────────────────────────────────────────────────
--
-- Every value below is a constant the library or LootHistory draws today, cited by name. Where two
-- sites draw one role in two colors, both survive as two tokens (`text.heading` and
-- `text.headingAlt`, `menu.border` and `menu.borderAlt`, ...) rather than one pixel changing; the
-- list is docs/api/Skin's "Split roles", the candidates for leg 2. Meaning-carrying colors (item
-- quality) stay the client's: the `q.*` tokens are nil in Ka0s Default, which reads the client's
-- ITEM_QUALITY_COLORS.
--
-- Geometry (`title.height`, `scroll.width`, `scroll.gutter`, `win.inset`) is skin-invariant in leg
-- 1: every skin carries Ka0s Default's value, so a live switch and a reload lay out the same.

local lib = LibStub and LibStub("LibKa0s-Skin-1.0", true)
if not lib then return end   -- the shell refused (no Core, or below its floor): nothing to attach to

local DEFS_MINOR = 1
if lib.__defsMinor and lib.__defsMinor >= DEFS_MINOR
  and lib.__defsShellMinor == lib.MINOR then return end
lib.__defsMinor      = DEFS_MINOR
lib.__defsShellMinor = lib.MINOR

lib.MODULES = lib.MODULES or {}
lib.MODULES.SkinDefs = DEFS_MINOR

-- ── the schema ───────────────────────────────────────────────────────────────────────────────

-- One string per group: `name:kind`, a trailing `?` marks a nilable token.
local GROUPS = {
  { "Fonts", "font.body:string? font.title:string? font.mono:string? font.bodySize:number? "
    .. "font.titleSize:number? font.outline:string? font.shadow:bool?" },
  { "Window", "win.bg:color win.bgTop:color? win.bgBottom:color? win.bgTexture:string? "
    .. "win.bgDense:color win.border:color win.borderSize:number win.borderStyle:string "
    .. "win.inner:color? win.inset:number win.radius:number title.bg:color? title.bgTop:color? "
    .. "title.bgBottom:color? title.text:color title.align:string? title.height:number "
    .. "divider:color foot.bg:color? close.rest:color close.hot:color" },
  { "Text", "text.body:color text.muted:color text.heading:color text.headingAlt:color "
    .. "text.accent:color text.disabled:color text.link:color text.linkHot:color "
    .. "gtip.title:color gtip.body:color gtip.muted:color" },
  { "Buttons", "btn.bg:color btn.bgTop:color? btn.bgBottom:color? btn.border:color "
    .. "btn.borderSize:number? btn.borderStyle:string? btn.text:color btn.hover:color "
    .. "btn.icon:color btn.radius:number btnPrimary.bg:color btnPrimary.bgTop:color? "
    .. "btnPrimary.bgBottom:color? btnPrimary.border:color btnPrimary.borderSize:number? "
    .. "btnPrimary.borderStyle:string? btnPrimary.text:color btnPrimary.hover:color "
    .. "btnPrimary.icon:color btnPrimary.radius:number" },
  { "Inputs", "input.bg:color input.border:color input.borderSize:number? "
    .. "input.borderStyle:string? input.text:color? input.placeholder:color? input.focus:color "
    .. "input.radius:number check.bg:color check.border:color? check.borderSize:number? "
    .. "check.borderStyle:string? check.mark:color check.radius:number slider.track:color? "
    .. "slider.trackBorder:color? slider.fill:color? slider.thumb:color? scroll.track:color "
    .. "scroll.thumb:color scroll.thumbOn:color scroll.thumbOff:color scroll.width:number "
    .. "scroll.gutter:number scroll.radius:number" },
  { "Tabs and navigation", "tab.bg:color tab.bgTop:color? tab.bgBottom:color? tab.glow:color "
    .. "tab.text:color tab.border:color? tab.borderSize:number? tab.borderStyle:string? "
    .. "tab.onBg:color? tab.onText:color tab.onLine:color tab.rule:color tab.radius:number "
    .. "nav.bg:color nav.border:color nav.borderSize:number? nav.borderStyle:string? "
    .. "nav.text:color nav.selBg:color nav.selText:color nav.selBar:color?" },
  { "Drawers and menus", "drawer.bg:color drawer.bgOpen:color drawer.border:color "
    .. "drawer.borderOpen:color drawer.borderSize:number? drawer.borderStyle:string? "
    .. "drawer.boxBg:color drawer.boxBorder:color drawer.text:color drawer.textSet:color "
    .. "drawer.summary:color drawer.summarySet:color menu.bg:color menu.border:color "
    .. "menu.borderAlt:color menu.borderSize:number? menu.borderStyle:string? menu.hover:color "
    .. "menu.text:color menu.textSel:color" },
  { "Lists and cards", "list.header.bg:color? list.header.text:color list.stripe:color "
    .. "list.hover:color list.sel:color? list.selOutline:color? card.bg:color card.border:color "
    .. "panel.bg:color panel.border:color section.rule:color icon.tint:color icon.hot:color "
    .. "handle.bg:color" },
  { "Overlays", "popup.bg:color popup.border:color? popup.borderSize:number? "
    .. "popup.borderStyle:string? popup.radius:number tooltip.bg:color? tooltip.border:color? "
    .. "strip.test:color strip.sim:color cover.dim:color cover.text:color" },
  { "HUD", "bar.texture:string bar.gloss:bool bar.bg:color? bar.border:color? "
    .. "bar.borderStyle:string bar.borderSize:number icon.border:color? glow.color:color? "
    .. "hud.font:string hud.fontSize:number hud.outline:string" },
  { "Charts", "chart.axis:color chart.axisAlt:color chart.grid:color chart.crosshair:color "
    .. "chart.marker:color chart.line:color chart.bar:color chart.track:color chart.total:color "
    .. "chart.other:color chart.otherLine:color chart.series:colors" },
  { "Semantic", "q.poor:color? q.common:color? q.uncommon:color? q.rare:color? q.epic:color? "
    .. "q.legendary:color? sem.good:color sem.bad:color sem.neutral:color sem.warn:color "
    .. "sem.info:color sem.gold:color sem.warband:color sem.statusOk:color "
    .. "sem.statusWarn:color sem.statusBad:color sem.modeTest:color sem.on:color sem.off:color" },
}

local function buildSchema()
  local schema, index = {}, {}
  for _, g in ipairs(GROUPS) do
    for name, kind, opt in g[2]:gmatch("([%w%.]+):(%a+)(%??)") do
      local entry = { name = name, kind = kind, nilable = opt == "?", group = g[1] }
      schema[#schema + 1] = entry
      index[name] = entry
    end
  end
  return schema, index
end

--- Every token a skin may set, in groups, as `{ name, kind, nilable, group }`. Read-only.
lib.SCHEMA, lib.__schemaIndex = buildSchema()

-- ── Ka0s Default ─────────────────────────────────────────────────────────────────────────────

local GOLD     = { 1, 0.82, 0, 1 }          -- NORMAL_FONT_COLOR: Core.SKIN.title, every heading
local WHITE    = { 1, 1, 1, 1 }
local GRAY     = { 0.7, 0.7, 0.72, 1 }      -- Core CLOSE_REST, Browser SKIN.tabIdle, axis labels
local BODY     = { 0.9, 0.9, 0.9, 1 }       -- Widgets menu text, BrowserTable enabled text
local DIM      = { 0.5, 0.5, 0.5, 1 }       -- BrowserTable disabled, Compat tooltip hint
local EDGE     = { 0.24, 0.24, 0.27, 0.85 } -- Core.SKIN.innerBorder / divider
local CTL_FILL = { 0.1, 0.1, 0.12, 0.9 }    -- Widgets SKIN.fill; LootHistory's three button copies
local CTL_LINE = { 0.24, 0.24, 0.27, 0.9 }  -- Widgets SKIN.line; the same three copies

-- LootHistory AnalyticsFormat PALETTE: three seven-hue ramps, inverse VIBGYOR.
local SERIES = {
  { 0.90, 0.25, 0.25, 1 }, { 0.95, 0.55, 0.15, 1 }, { 0.88, 0.82, 0.22, 1 }, { 0.35, 0.75, 0.38, 1 },
  { 0.28, 0.55, 0.90, 1 }, { 0.42, 0.38, 0.82, 1 }, { 0.72, 0.42, 0.86, 1 },
  { 0.97, 0.58, 0.58, 1 }, { 0.98, 0.76, 0.50, 1 }, { 0.94, 0.90, 0.55, 1 }, { 0.60, 0.87, 0.63, 1 },
  { 0.58, 0.76, 0.97, 1 }, { 0.68, 0.64, 0.92, 1 }, { 0.86, 0.68, 0.94, 1 },
  { 0.62, 0.18, 0.18, 1 }, { 0.70, 0.40, 0.10, 1 }, { 0.60, 0.56, 0.12, 1 }, { 0.18, 0.52, 0.28, 1 },
  { 0.15, 0.38, 0.66, 1 }, { 0.28, 0.24, 0.58, 1 }, { 0.50, 0.28, 0.62, 1 },
}

local KA0S = {
  -- Fonts: all nil. The font object each FontString was created with stays.
  -- Window: Core.SKIN, the CopyWindow backdrop, LootHistory's title bar.
  ["win.bg"] = { 0.06, 0.06, 0.08, 0.92 }, ["win.bgDense"] = { 0.06, 0.06, 0.08, 0.95 },
  ["win.border"] = { 0, 0, 0, 1 }, ["win.borderSize"] = 1, ["win.borderStyle"] = "flat",
  ["win.inner"] = EDGE, ["win.inset"] = 1, ["win.radius"] = 0,
  ["title.text"] = GOLD, ["title.height"] = 30, ["divider"] = EDGE,
  ["close.rest"] = GRAY, ["close.hot"] = { 1, 0.3, 0.3, 1 },
  -- Text: Widgets menu rows, BrowserTable cells, LootHistory Panel's AH header, DebugLog's link.
  ["text.body"] = BODY, ["text.muted"] = GRAY, ["text.heading"] = GOLD,
  ["text.headingAlt"] = { 0.91, 0.77, 0.42, 1 }, ["text.accent"] = GOLD, ["text.disabled"] = DIM,
  ["text.link"] = { 1, 0.5, 0, 1 }, ["text.linkHot"] = { 1, 0.72, 0.28, 1 },
  -- Lines added to Blizzard's GameTooltip (LootHistory Compat Show*): title, body, hint.
  ["gtip.title"] = GOLD, ["gtip.body"] = BODY, ["gtip.muted"] = DIM,
  -- Buttons: LootHistory's flat buttons (BrowserFilterBar, Export, Timeline). No primary today.
  ["btn.bg"] = CTL_FILL, ["btn.border"] = CTL_LINE, ["btn.borderSize"] = 1,
  ["btn.borderStyle"] = "flat", ["btn.text"] = WHITE, ["btn.hover"] = GOLD,
  ["btn.icon"] = { 0.85, 0.85, 0.85, 1 }, ["btn.radius"] = 0,
  ["btnPrimary.bg"] = CTL_FILL, ["btnPrimary.border"] = CTL_LINE, ["btnPrimary.borderSize"] = 1,
  ["btnPrimary.borderStyle"] = "flat", ["btnPrimary.text"] = WHITE, ["btnPrimary.hover"] = GOLD,
  ["btnPrimary.icon"] = { 0.85, 0.85, 0.85, 1 }, ["btnPrimary.radius"] = 0,
  -- Inputs: Widgets SKIN (dropdown, SearchBox), LootHistory Timeline's toggle box and tick.
  ["input.bg"] = CTL_FILL, ["input.border"] = CTL_LINE, ["input.borderSize"] = 1,
  ["input.borderStyle"] = "flat", ["input.focus"] = { 1, 0.82, 0, 0.9 }, ["input.radius"] = 0,
  ["check.bg"] = { 0.24, 0.24, 0.27, 1 },
  ["check.mark"] = GOLD, ["check.radius"] = 0,
  -- Scroll: DebugLog's console bar (BAR_W 8) and OptionsScroll's thumb tints and GUTTER.
  ["scroll.track"] = { 0.24, 0.24, 0.27, 0.3 }, ["scroll.thumb"] = { 0.5, 0.5, 0.55, 0.85 },
  ["scroll.thumbOn"] = WHITE, ["scroll.thumbOff"] = { 0.5, 0.5, 0.5, 0.6 },
  ["scroll.width"] = 8, ["scroll.gutter"] = 20, ["scroll.radius"] = 0,
  -- Tabs: OptionsTabs' backing gradient, glow and hairline; LootHistory Browser's labels.
  ["tab.bg"] = { 0.10, 0.10, 0.10, 0.85 }, ["tab.bgBottom"] = { 0.10, 0.10, 0.10, 0.85 },
  ["tab.bgTop"] = { 0.15, 0.15, 0.15, 0.85 }, ["tab.glow"] = { 1, 1, 1, 0.15 },
  ["tab.text"] = GRAY, ["tab.onText"] = GOLD, ["tab.onLine"] = GOLD,
  ["tab.rule"] = { 1, 0.82, 0, 0.16 }, ["tab.radius"] = 0,
  -- Nav rail: OptionsNav PANE_FILL / PANE_BORDER, SELECT_RGB, LABEL_GOLD / LABEL_WHITE.
  ["nav.bg"] = { 0.1, 0.1, 0.1, 0.5 }, ["nav.border"] = { 0.4, 0.4, 0.4, 1 },
  ["nav.text"] = GOLD, ["nav.selBg"] = { 0.3, 0.5, 1, 1 }, ["nav.selText"] = WHITE,
  -- Drawer: OptionsDrawer's palette.
  ["drawer.bg"] = { 0.08, 0.07, 0.06, 0.9 }, ["drawer.bgOpen"] = { 0.13, 0.11, 0.08, 0.95 },
  ["drawer.border"] = { 0.18, 0.16, 0.14, 1 }, ["drawer.borderOpen"] = { 0.42, 0.33, 0.13, 1 },
  ["drawer.borderSize"] = 1, ["drawer.borderStyle"] = "flat",
  ["drawer.boxBg"] = { 0.08, 0.07, 0.05, 0.9 }, ["drawer.boxBorder"] = { 0.24, 0.2, 0.13, 1 },
  ["drawer.text"] = WHITE, ["drawer.textSet"] = GOLD,
  ["drawer.summary"] = DIM, ["drawer.summarySet"] = { 0.91, 0.85, 0.66, 1 },
  -- Menus: Widgets' shared popup menu; LootHistory BrowserTable's row menu edge.
  ["menu.bg"] = { 0.06, 0.06, 0.08, 0.98 }, ["menu.border"] = { 0, 0, 0, 1 },
  ["menu.borderAlt"] = { 0.62, 0.5, 0.18, 1 }, ["menu.borderSize"] = 1,
  ["menu.borderStyle"] = "flat", ["menu.hover"] = { 1, 0.82, 0, 0.15 },
  ["menu.text"] = BODY, ["menu.textSel"] = GOLD,
  -- Lists and cards: BrowserTable / HoldingsTab rows, Analytics KPI cards and list panels.
  ["list.header.text"] = GOLD, ["list.stripe"] = { 1, 1, 1, 0.03 },
  ["list.hover"] = { 1, 0.82, 0, 0.10 },
  ["card.bg"] = { 0.1, 0.1, 0.12, 0.85 }, ["card.border"] = CTL_LINE,
  ["panel.bg"] = { 0.08, 0.08, 0.10, 0.6 }, ["panel.border"] = { 0.24, 0.24, 0.27, 0.7 },
  ["section.rule"] = { 1, 0.82, 0, 0.35 },
  ["icon.tint"] = GRAY, ["icon.hot"] = WHITE, ["handle.bg"] = { 0, 0, 0, 0.75 },
  -- Overlays: OptionsIds' suggestion popup, Widgets STRIP_FILL, OptionsCombat's cover.
  ["popup.bg"] = { 0, 0, 0, 0.92 }, ["popup.radius"] = 0,
  ["strip.test"] = { 1, 0.65, 0.15, 0.12 }, ["strip.sim"] = { 0.35, 0.8, 1, 0.12 },
  ["cover.dim"] = { 0, 0, 0, 0.6 }, ["cover.text"] = { 0.667, 0.667, 0.667, 1 },
  -- HUD: OptionsCompose's FontGroup / BorderGroup / BarGroup defaults.
  ["bar.texture"] = "Blizzard", ["bar.gloss"] = false, ["bar.borderStyle"] = "None",
  ["bar.borderSize"] = 1, ["hud.font"] = "Friz Quadrata TT", ["hud.fontSize"] = 12,
  ["hud.outline"] = "OUTLINE",
  -- Charts: Widgets LINE_CHART, LootHistory AnalyticsCharts / AnalyticsLedger / C.TIMELINE.
  ["chart.axis"] = { 0.45, 0.45, 0.5, 0.8 }, ["chart.axisAlt"] = { 0.55, 0.55, 0.60, 0.9 },
  ["chart.grid"] = { 1, 1, 1, 0.07 }, ["chart.crosshair"] = { 1, 1, 1, 0.35 },
  ["chart.marker"] = { 0.8, 0.8, 0.8, 0.6 }, ["chart.line"] = { 0.4, 0.6, 0.95, 1 },
  ["chart.bar"] = { 0.40, 0.60, 0.95, 0.9 }, ["chart.track"] = { 1, 1, 1, 0.06 },
  ["chart.total"] = GOLD, ["chart.other"] = { 0.55, 0.62, 0.72, 1 }, ["chart.otherLine"] = GRAY,
  ["chart.series"] = SERIES,
  -- Semantic: LootHistory C.DirRGB, C.GOLD_RGB, C.TIMELINE.WARBAND, Panel STATUS_RGB, Browser
  -- TEST_MARK / SIM_MARK; OptionsIds' warn; DebugLog's on / off. Quality: the client's (nil).
  ["sem.good"] = { 0.35, 0.80, 0.45, 1 }, ["sem.bad"] = { 1, 0.33, 0.33, 1 },
  ["sem.neutral"] = { 0.62, 0.62, 0.66, 1 }, ["sem.warn"] = { 1, 0.5, 0, 1 },
  ["sem.info"] = { 0.3, 0.8, 1, 1 }, ["sem.gold"] = { 1, 0.86, 0.55, 1 },
  ["sem.warband"] = { 0.25, 0.75, 0.95, 1 }, ["sem.statusOk"] = { 0.30, 0.95, 0.35, 1 },
  ["sem.statusWarn"] = { 1, 0.82, 0.10, 1 }, ["sem.statusBad"] = { 1, 0.32, 0.32, 1 },
  ["sem.modeTest"] = { 1, 0.15, 0.15, 1 }, ["sem.on"] = { 0.3, 0.85, 0.3, 1 },
  ["sem.off"] = { 0.9, 0.3, 0.3, 1 },
}

lib:RegisterSkin({
  key = "ka0s",
  label = "Ka0s Default",
  desc = "Today's look: dark panels, hard 1px black edges, gold titles.",
  swatches = { "#0f0f14", "#000000", "#3d3d45", "#ffd100" },
  tokens = KA0S,
})
