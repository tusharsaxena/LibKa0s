-- tests/test_skin_defs.lua — LibKa0s-Skin-1.0's nine skins: completeness, invariance, legibility.
--
-- test_skin.lua pins the engine and Ka0s Default against today's constants. This suite holds the
-- other eight skins to the rules every skin keeps: it names only schema tokens, of the right kind;
-- it resolves every token Ka0s Default does; its geometry is Ka0s Default's, so a live switch lays
-- out exactly as a reload; its GameTooltip lines read on the client's dark tooltip; its text reads
-- on its own window; and the Blizzard-art choices recorded in docs/api/Skin stay what they say.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil

local MAJOR = "LibKa0s-Skin-1.0"

local KEYS = { "ka0s", "obsidian", "azeroth", "glass", "contrast", "ember", "wow", "midnight",
  "forever" }
local LABELS = {
  ka0s = "Ka0s Default", obsidian = "Obsidian", azeroth = "Azeroth", glass = "Glass",
  contrast = "High Contrast", ember = "Ember", wow = "WoW Default", midnight = "WoW Midnight",
  forever = "WoW Forever",
}

local function skinLib() return T.mocks.LibStub(MAJOR) end

local function colorKey(c)
  return type(c) == "table" and ("%.3f,%.3f,%.3f,%.3f"):format(c[1], c[2], c[3], c[4] or 1) or tostring(c)
end

local KIND_OK = {
  color = function(v) return type(v) == "table" and type(v[1]) == "number" and #v >= 3 end,
  colors = function(v) return type(v) == "table" and #v > 0 and type(v[1]) == "table" end,
  number = function(v) return type(v) == "number" end,
  string = function(v) return type(v) == "string" end,
  bool = function(v) return type(v) == "boolean" end,
}

-- WCAG 2 relative luminance and contrast ratio, alpha ignored (a fill's own color).
local function channel(c)
  if c <= 0.03928 then return c / 12.92 end
  return ((c + 0.055) / 1.055) ^ 2.4
end
local function luminance(c)
  return 0.2126 * channel(c[1]) + 0.7152 * channel(c[2]) + 0.0722 * channel(c[3])
end
local function contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  if la < lb then la, lb = lb, la end
  return (la + 0.05) / (lb + 0.05)
end

-- ── the registry ─────────────────────────────────────────────────────────────────────────────

test("skin defs: the nine skins register in order with their labels", function()
  local Skin = skinLib()
  local list = Skin:Skins()
  assertEqual(#list, #KEYS, "nine skins")
  for i, key in ipairs(KEYS) do
    assertEqual(list[i].key, key, "skin " .. i)
    assertEqual(list[i].label, LABELS[key], key .. " label")
    assertTrue(list[i].desc ~= "", key .. " has a description")
    assertEqual(#list[i].swatches, 4, key .. " has four swatches")
    for n, hex in ipairs(list[i].swatches) do
      assertTrue(type(hex) == "string" and hex:match("^#%x%x%x%x%x%x$") ~= nil,
        key .. " swatch " .. n .. " is #rrggbb")
    end
  end
  assertTrue(Skin:GetSkin("eui") == nil, "the mockup's EllesmereUI preview is never a skin")
  assertTrue(Skin:GetSkin("classic") == nil and Skin:GetSkin("wowdefault") == nil,
    "the mockup's keys are mapped: classic -> ka0s, wowdefault -> wow")
end)

test("skin defs: every skin names only schema tokens, each of its kind", function()
  local Skin = skinLib()
  for _, def in ipairs(Skin:Skins()) do
    for name, v in pairs(def.tokens) do
      local entry = Skin.__schemaIndex[name]
      assertTrue(entry ~= nil, def.key .. ": " .. name .. " is a schema token")
      if v ~= false then
        assertTrue(KIND_OK[entry.kind](v), def.key .. ": " .. name .. " is a " .. entry.kind)
      end
    end
  end
end)

test("skin defs: every skin defines every schema token or inherits it from Ka0s Default", function()
  local Skin = skinLib()
  local base = Skin:ResolveSkin("ka0s")
  for _, key in ipairs(KEYS) do
    local def, tokens = Skin:GetSkin(key), Skin:ResolveSkin(key)
    for _, e in ipairs(Skin.SCHEMA) do
      local own = def.tokens[e.name]
      if own == nil then
        assertEqual(tokens[e.name], base[e.name], key .. ": " .. e.name .. " inherits Ka0s Default")
      end
      if tokens[e.name] == nil then
        assertTrue(e.nilable, key .. ": " .. e.name .. " resolves (only nilable tokens may be nil)")
      end
    end
  end
end)

-- ── geometry is skin-invariant ───────────────────────────────────────────────────────────────

test("skin defs: geometry tokens equal Ka0s Default in all nine skins", function()
  local Skin = skinLib()
  local base = Skin:ResolveSkin("ka0s")
  for _, key in ipairs(KEYS) do
    local tokens = Skin:ResolveSkin(key)
    for _, name in ipairs({ "title.height", "scroll.width", "scroll.gutter", "win.inset" }) do
      assertEqual(tokens[name], base[name], key .. ": " .. name .. " is Ka0s Default's")
    end
  end
end)

-- ── legibility ───────────────────────────────────────────────────────────────────────────────

local TOOLTIP_DARK = { 0.05, 0.05, 0.08 }

test("skin defs: every skin's GameTooltip lines read on the client's dark tooltip", function()
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local tokens = Skin:ResolveSkin(key)
    for _, name in ipairs({ "gtip.title", "gtip.body", "gtip.muted" }) do
      local ratio = contrast(tokens[name], TOOLTIP_DARK)
      assertTrue(ratio >= 4.5, ("%s: %s contrast %.2f on (.05,.05,.08), want >= 4.5")
        :format(key, name, ratio))
    end
  end
end)

local TEXT_MIN = {
  ["text.body"] = 4.5, ["text.muted"] = 3, ["text.heading"] = 3, ["text.headingAlt"] = 3,
  ["text.accent"] = 3, ["text.disabled"] = 3, ["text.link"] = 3, ["text.linkHot"] = 3,
}

test("skin defs: every skin's text reads on its own window", function()
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local tokens = Skin:ResolveSkin(key)
    for name, want in pairs(TEXT_MIN) do
      local ratio = contrast(tokens[name], tokens["win.bg"])
      assertTrue(ratio >= want, ("%s: %s contrast %.2f on win.bg, want >= %.1f")
        :format(key, name, ratio, want))
    end
  end
end)

-- OptionsDrawer draws a drawer's label in drawer.textSet when its value is set and in drawer.text
-- when it is not: the label color is the set/unset cue, so the two must be told apart at a glance.
-- "Apart" is one channel at least 0.2 away (Azeroth's #2A1C0C / #3A2412 differed by 0.06).
-- A color over another, by its alpha (the client's blend), opaque.
local function over(top, under)
  local a = top[4] or 1
  return { top[1] * a + under[1] * (1 - a), top[2] * a + under[2] * (1 - a), top[3] * a + under[3] * (1 - a), 1 }
end

test("skin defs: every skin's arrows and check mark wear its own accent", function()
  -- SkinDefs minor 12 (the owner's round-5 showroom audit): the paging, dropdown and sort arrows were
  -- the art's yellow in every skin, and WoW Forever's check mark Ka0s gold under a tan accent.
  for _, key in ipairs(KEYS) do
    local t = skinLib():ResolveSkin(key)
    assertEqual(colorKey(t["icon.arrow"]), colorKey(t["text.accent"]), key .. ": the arrows in its accent")
  end
  local fv = skinLib():ResolveSkin("forever")
  assertEqual(colorKey(fv["check.mark"]), colorKey(fv["text.accent"]), "WoW Forever's check mark is its tan")
end)

test("skin defs: every skin's scroll bar draws a corridor on its window and a knob on the corridor", function()
  -- The owner's round-5 notes: "a knob and a scroll corridor" in every skin; Azeroth's was the
  -- example (corridor 1.12). red under: a clear or window-colored `scroll.track` (Obsidian, Glass,
  -- WoW Forever and High Contrast drew none), or a knob that sinks into it.
  for _, key in ipairs(KEYS) do
    local t = skinLib():ResolveSkin(key)
    local win = over(t["win.bg"], { 0, 0, 0, 1 })
    local corridor = over(t["scroll.track"], win)
    local c = contrast(corridor, win)
    assertTrue(c >= 1.12, ("%s: corridor %.2f on its window, want >= 1.12"):format(key, c))
    for _, name in ipairs({ "scroll.thumb", "scroll.thumbOn" }) do
      local k = contrast(over(t[name], corridor), corridor)
      assertTrue(k >= 3, ("%s: %s %.2f on its corridor, want >= 3"):format(key, name, k))
    end
  end
end)

test("skin defs: no flat window frame is thicker than the others", function()
  -- The owner's 2026-10-28 note: Azeroth's border read much thicker than Ember's or WoW Midnight's.
  -- A flat frame is its edge plus the 1px inner rule where `win.inner` is set. red under: Azeroth's
  -- 3px edge and its rule, 4px against Ember's 2 and Midnight's 3.
  for _, key in ipairs(KEYS) do
    local t = skinLib():ResolveSkin(key)
    if t["win.borderStyle"] == "flat" then
      local frame = t["win.borderSize"] + (t["win.inner"] and 1 or 0)
      assertTrue(frame <= 3, ("%s: a %dpx window frame, want <= 3"):format(key, frame))
    end
  end
end)

test("skin defs: every skin's set drawer label differs from its unset one", function()
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local tokens = Skin:ResolveSkin(key)
    local a, b = tokens["drawer.text"], tokens["drawer.textSet"]
    local apart = 0
    for i = 1, 3 do apart = math.max(apart, math.abs(a[i] - b[i])) end
    assertTrue(apart >= 0.2, ("%s: drawer.textSet is %.2f from drawer.text, want >= 0.2")
      :format(key, apart))
  end
end)

-- The bind-state and danger tokens (SkinDefs minor 5): LootHistory's padlocks, its Insights split
-- and the row menu's destructive items draw text and glyphs on the window, so each reads there.
-- Contrast ignores alpha, as above: `sem.boundNone`'s faint 0.40 is Ka0s Default's own choice.
local BIND = { "sem.boundNone", "sem.boundBoE", "sem.boundBoP", "sem.boundWarband",
  "sem.boundWarbandUE", "sem.boundBoPAlt", "sem.boundBoEAlt", "sem.boundNoneAlt", "sem.danger" }

test("skin defs: every skin's bind-state and danger colors read on its own window", function()
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local tokens = Skin:ResolveSkin(key)
    for _, name in ipairs(BIND) do
      local ratio = contrast(tokens[name], tokens["win.bg"])
      assertTrue(ratio >= 3, ("%s: %s contrast %.2f on win.bg, want >= 3"):format(key, name, ratio))
    end
  end
end)

-- The dark skins inherit Ka0s Default's bind colors (the hue is the meaning); Azeroth, the light
-- skin, sets every one, and High Contrast sets the gray and off-white ones, fully opaque.
-- Azeroth overrode all of them for its light parchment until SkinDefs minor 8 made it dark.
local BIND_OWN = {
  contrast = { "sem.boundNone", "sem.boundBoE", "sem.boundNoneAlt" },
}

test("skin defs: the bind-state tokens inherit Ka0s Default unless a skin overrides for legibility",
  function()
  local Skin = skinLib()
  local k = Skin:ResolveSkin("ka0s")
  for _, key in ipairs(KEYS) do
    local tokens, own = Skin:ResolveSkin(key), {}
    for _, name in ipairs(BIND_OWN[key] or {}) do own[name] = true end
    for _, name in ipairs(BIND) do
      local same = true
      for i = 1, 4 do same = same and (tokens[name][i] or 1) == (k[name][i] or 1) end
      assertEqual(same, not own[name], ("%s: %s %s Ka0s Default's"):format(key, name,
        own[name] and "overrides" or "inherits"))
    end
  end
  for _, name in ipairs(BIND_OWN.contrast) do
    assertEqual(Skin:ResolveSkin("contrast")[name][4] or 1, 1, "High Contrast: " .. name .. " opaque")
  end
end)

-- The rest of LootHistory's constants (SkinDefs minor 6): the window ones draw text, icons and
-- signed figures on the window, the two gtip ones lines on Blizzard's always-dark GameTooltip.
local SPLIT_WIN = { "text.value", "text.bodyAlt", "text.subtle", "text.highlight", "icon.dim",
  "sem.goodAlt", "sem.badAlt", "sem.warbandAlt", "sem.unknown" }
local SPLIT_TIP = { "gtip.value", "gtip.subtle" }

test("skin defs: every skin's split text, icon and signed colors read where they draw", function()
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local tokens = Skin:ResolveSkin(key)
    for _, name in ipairs(SPLIT_WIN) do
      local ratio = contrast(tokens[name], tokens["win.bg"])
      assertTrue(ratio >= 3, ("%s: %s contrast %.2f on win.bg, want >= 3"):format(key, name, ratio))
    end
    for _, name in ipairs(SPLIT_TIP) do
      local ratio = contrast(tokens[name], TOOLTIP_DARK)
      assertTrue(ratio >= 4.5, ("%s: %s contrast %.2f on (.05,.05,.08), want >= 4.5")
        :format(key, name, ratio))
    end
  end
end)

-- The dark skins inherit them; Azeroth, the light skin, sets every window one in ink and neither
-- gtip one (the tooltip stays dark); High Contrast sets the grays in its own palette.
local SPLIT_OWN = {
  contrast = { "text.value", "text.bodyAlt", "text.subtle", "icon.dim", "sem.unknown", "gtip.subtle" },
}

test("skin defs: the split tokens inherit Ka0s Default unless a skin overrides for legibility",
  function()
  local Skin = skinLib()
  local k = Skin:ResolveSkin("ka0s")
  local all = {}
  for _, name in ipairs(SPLIT_WIN) do all[#all + 1] = name end
  for _, name in ipairs(SPLIT_TIP) do all[#all + 1] = name end
  for _, key in ipairs(KEYS) do
    local tokens, own = Skin:ResolveSkin(key), {}
    for _, name in ipairs(SPLIT_OWN[key] or {}) do own[name] = true end
    for _, name in ipairs(all) do
      local same = true
      for i = 1, 4 do same = same and (tokens[name][i] or 1) == (k[name][i] or 1) end
      assertEqual(same, not own[name], ("%s: %s %s Ka0s Default's"):format(key, name,
        own[name] and "overrides" or "inherits"))
    end
  end
end)

-- ── per-skin choices (docs/api/Skin, "The eight skins") ──────────────────────────────────────

local CONTROLS = { "btn", "btnPrimary", "input", "check", "tab", "nav", "drawer", "popup", "menu" }

test("skin defs: High Contrast draws 1px control edges inside a 2px window and popup edge", function()
  -- SkinDefs minor 7, the owner's note of 2026-10-26: "borders are too thick on most elements".
  -- red under: a control edge back at 2px, or the window or popup losing its heavier frame.
  local t = skinLib():ResolveSkin("contrast")
  for _, ctl in ipairs(CONTROLS) do
    local want = (ctl == "popup" or ctl == "menu") and 2 or 1
    assertEqual(t[ctl .. ".borderSize"], want, "contrast: " .. ctl .. ".borderSize")
  end
  assertEqual(t["win.borderSize"], 2, "contrast: the window edge is 2px")
end)

test("skin defs: Glass rounds its window and popups only, on the Ka0s Glass nine-slice", function()
  -- SkinDefs minor 7, the owner's note of 2026-10-26: Glass's buttons and tabs looked awkward on the
  -- rounded art. The window and its popups keep it; the controls take a flat 1px edge.
  local Skin = skinLib()
  local t = Skin:ResolveSkin("glass")
  assertEqual(t["win.radius"], 8, "glass window radius")
  assertEqual(t["win.borderStyle"], "nine:Ka0s Glass", "glass window edge")
  assertEqual(t["popup.radius"], 8, "glass popup radius")
  assertEqual(t["popup.borderStyle"], "nine:Ka0s Glass", "glass popup edge")
  for _, ctl in ipairs({ "btn", "btnPrimary", "input", "tab", "drawer" }) do
    assertEqual(t[ctl .. ".borderStyle"], "flat", "glass " .. ctl .. ".borderStyle")
    assertEqual(t[ctl .. ".borderSize"], 1, "glass " .. ctl .. ".borderSize")
  end
  assertTrue((t["win.bg"][4] or 1) >= 0.85, "glass is dense enough to read over the world")
  for _, key in ipairs(KEYS) do
    if key ~= "glass" then
      local other = Skin:ResolveSkin(key)
      for _, name in ipairs({ "win.radius", "btn.radius", "btnPrimary.radius", "input.radius",
        "check.radius", "tab.radius", "scroll.radius", "popup.radius" }) do
        assertEqual(other[name], 0, key .. ": " .. name .. " is square (no rounded art but Glass's)")
      end
    end
  end
end)

test("skin defs: WoW Default wears the Blizzard art docs/api/Skin names", function()
  local t = skinLib():ResolveSkin("wow")
  assertEqual(t["win.borderStyle"], "nine:Blizzard Dialog", "UI-DialogBox-Border edge")
  assertEqual(t["win.borderSize"], 32, "BACKDROP_DIALOG_32_32's edge size")
  assertEqual(t["win.bgTexture"], "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    "the dark dialog background")
  -- SkinDefs minor 7, the owner's note: the 2px bevelOut gold edge read as a frame. The client's own
  -- button is the red gradient under a thin dark rim.
  assertEqual(t["btn.borderStyle"], "flat", "buttons: a flat rim")
  assertEqual(t["btn.borderSize"], 1, "buttons: 1px")
  assertEqual(("%.4f %.4f %.4f"):format(t["btn.border"][1], t["btn.border"][2], t["btn.border"][3]),
    ("%.4f %.4f %.4f"):format(0x1a / 255, 0x08 / 255, 0x05 / 255), "buttons: the dark #1a0805 rim")
  assertTrue(t["btn.bgTop"] ~= nil and t["btn.bgBottom"] ~= nil, "buttons: a red gradient")
  assertTrue(t["btn.bgTop"][1] > t["btn.bgTop"][2] * 3, "the gradient is red")
  -- The owner's note (round 3): the InActiveTab art is drawn shorter, so idle tabs wear the active art
  -- too and stand as tall as the selected one; the white label tells the selected tab.
  assertEqual(t["tab.texture"], "Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab", "idle tab")
  -- ...and the inputs (the dropdown with them) and the nav rail take a 1px edge, the primary's size.
  assertEqual(t["input.borderSize"], 1, "inputs: 1px")
  assertEqual(t["nav.borderSize"], 1, "the nav rail: 1px")
  assertEqual(t["tab.onTexture"], "Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab", "active tab")
  assertEqual(t["check.texture"], "Interface\\Buttons\\UI-CheckBox-Up", "checkbox box")
  assertEqual(t["check.markTexture"], "Interface\\Buttons\\UI-CheckBox-Check", "checkbox tick")
end)

local ART_TOKENS = { "win.bgTexture", "tab.texture", "tab.onTexture", "check.texture",
  "check.markTexture" }

test("skin defs: WoW Midnight is flat with a 2px gold edge and gradients, no Blizzard art", function()
  local t = skinLib():ResolveSkin("midnight")
  assertEqual(t["win.borderStyle"], "flat", "flat WHITE8x8 edge")
  assertEqual(t["win.borderSize"], 2, "2px")
  assertEqual(("%.4f %.4f %.4f"):format(t["win.border"][1], t["win.border"][2], t["win.border"][3]),
    ("%.4f %.4f %.4f"):format(0xb0 / 255, 0x8a / 255, 0x3e / 255), "the #b08a3e edge")
  assertTrue(t["win.bgTop"] ~= nil and t["title.bgTop"] ~= nil, "window and title gradients")
  for _, name in ipairs(ART_TOKENS) do assertTrue(t[name] == nil, "midnight: no " .. name) end
  for _, ctl in ipairs(CONTROLS) do
    assertEqual(t[ctl .. ".borderStyle"], "flat", "midnight: " .. ctl .. " is flat")
  end
end)

test("skin defs: only WoW Default names Blizzard art", function()
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    if key ~= "wow" then
      local t = Skin:ResolveSkin(key)
      for _, name in ipairs(ART_TOKENS) do assertTrue(t[name] == nil, key .. ": no " .. name) end
    end
  end
end)

test("skin defs: WoW Forever is warm charcoal, black centered titles, tan accent, gold headings",
  function()
    local t = skinLib():ResolveSkin("forever")
    local function hex(c) return ("#%02X%02X%02X"):format(
      math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5)) end
    assertEqual(t["title.align"], "CENTER", "centered titles")
    assertEqual(hex(t["title.bg"]), "#050505", "black title bar")
    assertEqual(hex(t["title.text"]), "#FFFFFF", "white titles")
    assertEqual(hex(t["text.accent"]), "#C9A07A", "tan accent")
    assertEqual(hex(t["text.heading"]), "#F2B33D", "gold headings")
    assertEqual(t["win.borderSize"], 1, "thin window edge")
    for _, ctl in ipairs(CONTROLS) do
      assertEqual(t[ctl .. ".borderSize"], 1, "forever: thin " .. ctl .. " edge")
    end
    local bg = t["win.bg"]
    assertTrue(bg[1] > bg[3] and luminance(bg) < 0.03, "warm charcoal window")
    assertEqual(t["font.body"], "Ka0s Fira Sans", "Fira Sans (minor 11: a face of its own; Barlow read blurry)")
  end)

-- ── what a skin names exists ─────────────────────────────────────────────────────────────────

-- LibSharedMedia's own default border keys a skin may name besides the shipped ones.
local LSM_BORDERS = { ["Blizzard Dialog"] = true, ["Blizzard Tooltip"] = true }
-- ...and its default font keys: Friz Quadrata, the client's own face, set by name (WoW Default's: its
-- HUD face explicitly since SkinDefs minor 16, its body and titles through KEEP).
local LSM_FONTS = { ["Friz Quadrata TT"] = true }
-- ...and its default statusbar key: the client's Blizzard bar, WoW Default's through KEEP.
local LSM_BARS = { ["Blizzard"] = true }

-- A face names a shipped or LSM font, a bar texture a shipped or LSM bar.
local function assertNamedFile(Media, key, name, v)
  if name == "bar.texture" then
    assertTrue(Media.TEXTURES[v] ~= nil or LSM_BARS[v], key .. ": bar.texture = " .. tostring(v) .. " is shipped")
  end
  if (name:match("^font%.") or name == "hud.font") and type(v) == "string" and name ~= "font.outline" then
    assertTrue(Media.FONTS[v] ~= nil or LSM_FONTS[v], key .. ": " .. name .. " = " .. v .. " is shipped")
  end
end

-- One token of skin `key`: its file (assertNamedFile), a nine-slice a known border, a border style
-- one of the four shapes.
local function assertNamedMedia(Media, key, name, v)
  assertNamedFile(Media, key, name, v)
  local nine = type(v) == "string" and v:match("^nine:(.+)$")
  if nine then
    assertTrue(Media.BORDERS[nine] ~= nil or LSM_BORDERS[nine],
      key .. ": " .. name .. " names a known border, " .. nine)
  end
  -- `bar.borderStyle` and `icon.borderStyle` (SkinDefs minor 15) name a LibSharedMedia border key, the
  -- HUD pickers' own values, not a primitive's edge shape.
  if name == "icon.borderStyle" then
    assertTrue(v == "Solid" or v == "None" or Media.BORDERS[v] ~= nil or LSM_BORDERS[v],
      key .. ": icon.borderStyle names a border the library draws, " .. tostring(v))
  end
  if name:match("borderStyle$") and name ~= "bar.borderStyle" and name ~= "icon.borderStyle"
    and type(v) == "string" then
    assertTrue(v == "flat" or v == "bevelOut" or v == "bevelIn" or nine,
      key .. ": " .. name .. " is flat | bevelOut | bevelIn | nine:<key>")
  end
end

test("skin defs: every font, bar texture and border a skin names is shipped or an LSM default", function()
  local Skin = skinLib()
  local Media = T.mocks.LibStub("LibKa0s-Media-1.0")
  for _, def in ipairs(Skin:Skins()) do
    for name, v in pairs(def.tokens) do assertNamedMedia(Media, def.key, name, v) end
  end
end)

local FRIZ = "Friz Quadrata TT"

--- A face's family: its LSM key without the weight.
local function family(face)
  return (face:gsub(" SemiBold$", ""):gsub(" Bold$", ""))
end

test("skin defs: every skin draws one family of its own, for body and titles alike", function()
  -- SkinDefs minor 11 (the owner's round-5 notes: titles that do not match the body, faces reused
  -- across skins). red under: a skin whose titles are another family than its body (Cinzel over a
  -- body face), or a face two skins share, but the client's Friz Quadrata, which WoW Default draws.
  -- SkinDefs minor 14: Ka0s Default draws Oxanium, SemiBold body and Bold titles, the owner's choice.
  local Skin = skinLib()
  local want = {
    obsidian = { "Ka0s Inter", "Ka0s Inter SemiBold" }, glass = { "Ka0s Nunito", "Ka0s Nunito SemiBold" },
    azeroth = { "Ka0s Vollkorn", "Ka0s Vollkorn Bold" }, contrast = { "Ka0s Atkinson", "Ka0s Atkinson Bold" },
    ember = { "Ka0s Bitter", "Ka0s Bitter Bold" }, midnight = { "Ka0s Philosopher", "Ka0s Philosopher Bold" },
    forever = { "Ka0s Fira Sans", "Ka0s Fira Sans SemiBold" }, wow = { FRIZ, FRIZ },
    ka0s = { "Ka0s Oxanium SemiBold", "Ka0s Oxanium Bold" },
  }
  local owner = {}
  for key, pair in pairs(want) do
    local t = Skin:ResolveSkin(key)
    assertEqual(t["font.body"], pair[1], key .. " body font")
    assertEqual(t["font.title"], pair[2], key .. " title font")
    assertEqual(family(pair[2]), family(pair[1]), key .. ": its titles are its body's family")
    local fam = family(pair[1])
    if fam ~= FRIZ then
      assertNil(owner[fam], fam .. " is " .. tostring(owner[fam]) .. "'s and " .. key .. "'s")
      owner[fam] = key
    end
  end
  -- Every skin draws the client's shadow now: Azeroth's shadowless body was for its light parchment,
  -- and SkinDefs minor 8 made it dark. A dark label goes shadowless on its own (SkinPaint minor 5).
  for key in pairs(want) do
    assertEqual(Skin:ResolveSkin(key)["font.shadow"], true, key .. " draws the shadow")
  end
  local base, hc = Skin:ResolveSkin("obsidian"), Skin:ResolveSkin("contrast")
  assertTrue(hc["font.bodySize"] > base["font.bodySize"], "High Contrast reads larger")
end)

-- Each skin's HUD face (SkinDefs minor 16, the owner's ruling R-4, DECISIONS D-11): the skin's own
-- family at its heavier shipped weight; WoW Default the client's Friz Quadrata, set explicitly.
local HUD_FACE = {
  ka0s = "Ka0s Oxanium SemiBold", obsidian = "Ka0s Inter SemiBold", azeroth = "Ka0s Vollkorn Bold",
  glass = "Ka0s Nunito SemiBold", contrast = "Ka0s Atkinson Bold", ember = "Ka0s Bitter Bold",
  wow = FRIZ, midnight = "Ka0s Philosopher Bold", forever = "Ka0s Fira Sans SemiBold",
}

test("skin defs: every skin names a HUD face of its own, its text's family; only WoW Default draws Friz", function()
  -- SkinDefs minor 16 (R-4, D-11). red under: `hud.font` back in KEEP or a skin's entry dropped (that
  -- skin's HUD text falls back to Friz Quadrata), a HUD face of another family than the skin's text,
  -- or WoW Default's Friz left to a fallback instead of named in its own tokens.
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local t = Skin:ResolveSkin(key)
    assertEqual(t["hud.font"], HUD_FACE[key], key .. "'s HUD face")
    assertEqual(Skin.skins[key].tokens["hud.font"], HUD_FACE[key], key .. " names its HUD face itself")
    assertEqual(family(t["hud.font"]), family(t["font.body"]), key .. ": its HUD face is its text's family")
    assertEqual(t["hud.outline"], "OUTLINE", key .. " outlines HUD text")
    assertEqual(t["hud.fontSize"], 12, key .. "'s HUD size stays 12")
    if key ~= "wow" then assertTrue(t["hud.font"] ~= FRIZ, key .. " does not draw Friz on the HUD") end
  end
end)

test("skin defs: Ka0s Default's Oxanium and its own bar stay its own; a skin naming neither keeps Friz and Blizzard", function()
  -- SkinDefs minor 14. Every skin inherits Ka0s Default's tokens, so without KEEP minor 14's choice
  -- would have moved every skin's faces and bar texture with it. red under: a skin naming no body
  -- face or bar texture of its own that reads Oxanium or the Ka0s Default bar. (The HUD face left
  -- KEEP in minor 16: every skin names its own, pinned above.)
  local Skin = skinLib()
  local k = Skin:ResolveSkin("ka0s")
  assertEqual(k["hud.font"], "Ka0s Oxanium SemiBold", "Ka0s Default's HUD face")
  assertEqual(k["bar.texture"], "Ka0s Default", "Ka0s Default's bar texture")
  for _, key in ipairs(KEYS) do
    if key ~= "ka0s" then
      local own, t = Skin.skins[key].tokens, Skin:ResolveSkin(key)
      assertTrue(family(t["hud.font"]) ~= "Ka0s Oxanium", key .. " does not inherit Ka0s Default's HUD face")
      assertEqual(t["bar.texture"], own["bar.texture"] or "Blizzard", key .. " draws its own bar or Blizzard")
      assertTrue(family(t["font.body"]) ~= "Ka0s Oxanium" and family(t["font.title"]) ~= "Ka0s Oxanium",
        key .. " does not inherit Ka0s Default's face")
    end
  end
  local wow = Skin:ResolveSkin("wow")
  assertEqual(wow["font.body"], FRIZ, "WoW Default's body, through KEEP")
  assertEqual(wow["font.title"], FRIZ, "WoW Default's titles, through KEEP")
end)

test("skin defs: every skin draws its own bar texture, and WoW Default the client's", function()
  -- SO-04, the owner's approved mockup (still SkinDefs minor 14 and Media minor 9, unreleased).
  -- red under: a skin drawing another skin's bar, or WoW Default losing the client's Blizzard bar.
  local Skin = skinLib()
  local want = {
    ka0s = "Ka0s Default", obsidian = "Ka0s Matte", azeroth = "Ka0s Parchment", glass = "Ka0s Glass Bar",
    contrast = "Ka0s Solid", ember = "Ka0s Forge", wow = "Blizzard", midnight = "Ka0s Satin",
    forever = "Ka0s Classic",
  }
  local seen = {}
  for _, key in ipairs(KEYS) do
    local bar = Skin:ResolveSkin(key)["bar.texture"]
    assertEqual(bar, want[key], key .. "'s bar texture")
    assertNil(seen[bar], tostring(bar) .. " is " .. tostring(seen[bar]) .. "'s and " .. key .. "'s")
    seen[bar] = key
  end
end)

local function sameColor(c, want, label)
  assertTrue(type(c) == "table", label .. ": no color")
  for i = 1, #want do
    assertTrue(math.abs(c[i] - want[i]) < 0.005, ("%s component %d: %s, want %s"):format(label, i, tostring(c[i]), tostring(want[i])))
  end
end

-- ── the owner's notes of 2026-10-26 (SkinDefs minor 7) ───────────────────────────────────────

test("skin defs: every skin sets both sizes, within a point and a half of Ka0s Default's", function()
  -- red under: a skin with no size (it would not scale with the others), or one far enough from the
  -- reference to break a layout measured against the stock fonts.
  local Skin = skinLib()
  local ref = Skin:ResolveSkin("ka0s")
  for _, key in ipairs(KEYS) do
    local own = Skin.skins[key].tokens
    for _, name in ipairs({ "font.bodySize", "font.titleSize" }) do
      assertTrue(type(own[name]) == "number", key .. " sets " .. name)
      assertTrue(math.abs(own[name] - ref[name]) <= 1.5, ("%s: %s %s is near the reference %s")
        :format(key, name, tostring(own[name]), tostring(ref[name])))
    end
  end
end)

test("skin defs: a hovered row is told apart from a selected one", function()
  -- red under: hover and selection in one hue at nearly one alpha (the owner: "hard to distinguish").
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    if key ~= "ka0s" and key ~= "contrast" then
      local t = Skin:ResolveSkin(key)
      local h, s = t["list.hover"], t["list.sel"]
      local same = math.abs(h[1] - s[1]) + math.abs(h[2] - s[2]) + math.abs(h[3] - s[3])
      assertTrue(same > 0.3, key .. ": list.hover is not list.sel's hue")
      sameColor(h, { t["text.body"][1], t["text.body"][2], t["text.body"][3], 0.10 }, key .. " hover is the body text at .10")
    end
  end
end)

test("skin defs: WoW Default's checkbox art is its only box", function()
  local wow = skinLib():ResolveSkin("wow")
  assertTrue(wow["check.border"] == nil, "no edge around UI-CheckBox-Up, which is itself a box")
end)

test("skin defs: in every skin a primary button differs from a normal one", function()
  -- The owner's note (round 2): Ka0s Default's, Azeroth's and WoW Default's primary were their normal
  -- button. red under: a skin whose primary fill and edge are both the normal button's.
  local Skin = skinLib()
  local function differs(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a ~= b end
    for i = 1, 4 do if math.abs((a[i] or 1) - (b[i] or 1)) > 0.02 then return true end end
    return false
  end
  for _, key in ipairs(KEYS) do
    local t = Skin:ResolveSkin(key)
    assertTrue(differs(t["btnPrimary.bg"], t["btn.bg"]) or differs(t["btnPrimary.border"], t["btn.border"]),
      key .. ": the primary button is not the normal one")
  end
end)

test("skin defs: no skin draws a box round a slider's bar", function()
  -- The owner's note (round 2): sliders look alike in every skin, Ka0s Default's thin bar the reference.
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local b = Skin:ResolveSkin(key)["slider.trackBorder"]
    assertTrue(b == nil or (b[4] or 1) == 0, key .. ": no slider track border")
  end
end)
