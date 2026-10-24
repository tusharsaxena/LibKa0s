-- tests/test_skin_defs.lua — LibKa0s-Skin-1.0's nine skins: completeness, invariance, legibility.
--
-- test_skin.lua pins the engine and Ka0s Default against today's constants. This suite holds the
-- other eight skins to the rules every skin keeps: it names only schema tokens, of the right kind;
-- it resolves every token Ka0s Default does; its geometry is Ka0s Default's, so a live switch lays
-- out exactly as a reload; its GameTooltip lines read on the client's dark tooltip; its text reads
-- on its own window; and the Blizzard-art choices recorded in docs/api/Skin stay what they say.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local MAJOR = "LibKa0s-Skin-1.0"

local KEYS = { "ka0s", "obsidian", "azeroth", "glass", "contrast", "ember", "wow", "midnight",
  "forever" }
local LABELS = {
  ka0s = "Ka0s Default", obsidian = "Obsidian", azeroth = "Azeroth", glass = "Glass",
  contrast = "High Contrast", ember = "Ember", wow = "WoW Default", midnight = "WoW Midnight",
  forever = "WoW Forever",
}

local function skinLib() return T.mocks.LibStub(MAJOR) end

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

-- ── per-skin choices (docs/api/Skin, "The eight skins") ──────────────────────────────────────

local CONTROLS = { "btn", "btnPrimary", "input", "check", "tab", "nav", "drawer", "popup", "menu" }

test("skin defs: High Contrast draws every control border at 2px or more", function()
  local t = skinLib():ResolveSkin("contrast")
  for _, ctl in ipairs(CONTROLS) do
    assertTrue((t[ctl .. ".borderSize"] or 0) >= 2, "contrast: " .. ctl .. ".borderSize >= 2")
  end
  assertTrue(t["win.borderSize"] >= 2, "contrast: the window edge is 2px")
end)

test("skin defs: Glass is the rounded skin, radius 8 on the Ka0s Glass nine-slice", function()
  local Skin = skinLib()
  local t = Skin:ResolveSkin("glass")
  assertEqual(t["win.radius"], 8, "glass window radius")
  assertEqual(t["win.borderStyle"], "nine:Ka0s Glass", "glass window edge")
  for _, ctl in ipairs({ "btn", "btnPrimary", "input", "popup" }) do
    assertEqual(t[ctl .. ".radius"], 8, "glass " .. ctl .. ".radius")
    assertEqual(t[ctl .. ".borderStyle"], "nine:Ka0s Glass", "glass " .. ctl .. ".borderStyle")
  end
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
  assertEqual(t["btn.borderStyle"], "bevelOut", "buttons: a bevelOut edge")
  assertEqual(t["btn.borderSize"], 2, "buttons: 2px")
  assertEqual(("%.4f %.4f %.4f"):format(t["btn.border"][1], t["btn.border"][2], t["btn.border"][3]),
    ("%.4f %.4f %.4f"):format(0xa0 / 255, 0x7c / 255, 0x2c / 255), "buttons: the gold #a07c2c edge")
  assertTrue(t["btn.bgTop"] ~= nil and t["btn.bgBottom"] ~= nil, "buttons: a red gradient")
  assertTrue(t["btn.bgTop"][1] > t["btn.bgTop"][2] * 3, "the gradient is red")
  assertEqual(t["tab.texture"], "Interface\\OptionsFrame\\UI-OptionsFrame-InActiveTab", "idle tab")
  assertEqual(t["tab.onTexture"], "Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab", "active tab")
  assertEqual(t["scroll.thumbTexture"], "Interface\\Buttons\\UI-ScrollBar-Knob", "scroll knob")
  assertEqual(t["check.texture"], "Interface\\Buttons\\UI-CheckBox-Up", "checkbox box")
  assertEqual(t["check.markTexture"], "Interface\\Buttons\\UI-CheckBox-Check", "checkbox tick")
end)

local ART_TOKENS = { "win.bgTexture", "tab.texture", "tab.onTexture", "scroll.thumbTexture",
  "check.texture", "check.markTexture" }

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
    assertEqual(t["font.body"], "Ka0s Barlow", "Barlow")
  end)

-- ── what a skin names exists ─────────────────────────────────────────────────────────────────

-- LibSharedMedia's own default border keys a skin may name besides the shipped ones.
local LSM_BORDERS = { ["Blizzard Dialog"] = true, ["Blizzard Tooltip"] = true }

test("skin defs: every font and border a skin names is shipped or an LSM default", function()
  local Skin = skinLib()
  local Media = T.mocks.LibStub("LibKa0s-Media-1.0")
  for _, def in ipairs(Skin:Skins()) do
    for name, v in pairs(def.tokens) do
      if name:match("^font%.") and type(v) == "string" and name ~= "font.outline" then
        assertTrue(Media.FONTS[v] ~= nil, def.key .. ": " .. name .. " = " .. v .. " is shipped")
      end
      local nine = type(v) == "string" and v:match("^nine:(.+)$")
      if nine then
        assertTrue(Media.BORDERS[nine] ~= nil or LSM_BORDERS[nine],
          def.key .. ": " .. name .. " names a known border, " .. nine)
      end
      if name:match("borderStyle$") and name ~= "bar.borderStyle" and type(v) == "string" then
        assertTrue(v == "flat" or v == "bevelOut" or v == "bevelIn" or nine,
          def.key .. ": " .. name .. " is flat | bevelOut | bevelIn | nine:<key>")
      end
    end
  end
end)

test("skin defs: the font assignments follow the spec", function()
  local Skin = skinLib()
  local want = {
    obsidian = { "Ka0s Barlow", "Ka0s Barlow SemiBold" }, glass = { "Ka0s Barlow", "Ka0s Barlow SemiBold" },
    forever = { "Ka0s Barlow", "Ka0s Barlow SemiBold" }, contrast = { "Ka0s Atkinson", "Ka0s Atkinson Bold" },
    azeroth = { nil, "Ka0s Cinzel" }, ember = { nil, "Ka0s Cinzel" }, midnight = { nil, "Ka0s Cinzel" },
    wow = { nil, nil }, ka0s = { nil, nil },
  }
  for key, pair in pairs(want) do
    local t = Skin:ResolveSkin(key)
    assertEqual(t["font.body"], pair[1], key .. " body font")
    assertEqual(t["font.title"], pair[2], key .. " title font")
  end
  local base, hc = Skin:ResolveSkin("obsidian"), Skin:ResolveSkin("contrast")
  assertEqual(hc["font.bodySize"], base["font.bodySize"] + 2, "High Contrast reads 2pt larger")
end)
