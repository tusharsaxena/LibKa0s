-- tests/test_skin_host_gaps.lua -- the gaps the addons' full-skinning flips found in the Skin major
-- (FS-FIX of Ka0sAddonsCommonTasks docs/2026-11-01-FULL_SKINNING, the owner's rulings of 2026-11-01).
--
-- What it pins: every skin's own bar, icon, glow and cover values; a skin's None bar border deferring
-- to the player and a real style winning; S.HudFont's shadow token and its one font object per look;
-- a box's noBg on a frame with no backdrop; S.IconBorder on a Texture; a numeric path segment;
-- S.HoverArt; and a mark on a pooled AceGUI widget giving itself back at release.
--
-- Every case runs on a fresh environment (tests/fixture_skin_paint.lua).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")
local E = dofile("tests/fixture_skin_eui.lua")

local OWNER = "AuraMaster"
local FACE = "Fonts\\Host.ttf"
local OTHERS = { "obsidian", "azeroth", "glass", "contrast", "ember", "wow", "midnight", "forever" }
local OWN = { "bar.bg", "bar.border", "icon.border", "glow.color", "cover.dim" }
local REAL_EDGE = { azeroth = { "Solid", 1 }, contrast = { "Solid", 1 }, wow = { "Blizzard Tooltip", 2 },
                    midnight = { "Solid", 1 } }

local function fontString(m) return m.CreateFrame("Frame"):CreateFontString() end
local function survey(m, r) return m.__paint(r) end

-- ── every skin answers its own ───────────────────────────────────────────────────────────────

test("skin host gaps: Ka0s Default's bar, icon, glow and cover values stand", function()
  -- red under: Ka0s Default's look moving with the others.
  local _, Skin = F.env()
  assertEqual(F.tok(Skin, "ka0s", "bar.bg"), F.rgba({ 0, 0, 0, 0.5 }))
  assertEqual(F.tok(Skin, "ka0s", "bar.border"), F.rgba({ 0, 0, 0, 1 }))
  assertEqual(F.tok(Skin, "ka0s", "icon.border"), F.rgba({ 0, 0, 0, 1 }))
  assertEqual(F.tok(Skin, "ka0s", "glow.color"), F.rgba({ 1, 0.82, 0, 1 }))
  assertEqual(F.tok(Skin, "ka0s", "cover.dim"), F.rgba({ 0, 0, 0, 0.6 }))
  assertEqual(Skin:ResolveSkin("ka0s")["bar.borderStyle"], "None")
end)

test("skin host gaps: every other skin answers its own five values", function()
  -- red under: a skin left on Ka0s Default's constant, or two skins sharing one value.
  local _, Skin = F.env()
  for _, name in ipairs(OWN) do
    local seen = { [F.tok(Skin, "ka0s", name)] = "ka0s" }
    for _, key in ipairs(OTHERS) do
      local v = F.tok(Skin, key, name)
      assertNil(seen[v], key .. " shares " .. name .. " with " .. tostring(seen[v]))
      seen[v] = key
    end
  end
end)

test("skin host gaps: a skin's glow is its accent, and its dim sees the screen through it", function()
  -- red under: a glow outside the palette, or a cover that blacks the page out.
  local _, Skin = F.env()
  for _, key in ipairs(OTHERS) do
    -- WoW Default's accent is Ka0s Default's gold to the digit, so its glow is its primary's gold edge.
    if key ~= "wow" then assertEqual(F.tok(Skin, key, "glow.color"), F.tok(Skin, key, "text.accent"), key) end
    local dim = Skin:ResolveSkin(key)["cover.dim"]
    assertTrue(dim[4] > 0.4 and dim[4] < 0.95, key .. " cover alpha")
    assertTrue(Skin:ResolveSkin(key)["bar.bg"][4] < 1, key .. " bar.bg is a translucent track")
  end
end)

test("skin host gaps: the skins whose palette calls for an edge state a real bar border", function()
  -- red under: a real style lost, or one leaking into a skin that leaves the bar to the player.
  local _, Skin = F.env()
  for _, key in ipairs(OTHERS) do
    local t, want = Skin:ResolveSkin(key), REAL_EDGE[key]
    assertEqual(t["bar.borderStyle"], want and want[1] or "None", key)
    assertEqual(t["bar.borderSize"], want and want[2] or 1, key)
  end
end)

test("skin host gaps: the eui source answers its own values from EllesmereUI's looks", function()
  -- red under: the eui source left on Ka0s Default's constants.
  local _, Skin, eui = E.env()
  local S = E.owner(Skin, E.OWNER, "eui")
  eui.accent, eui.panel = { 0.2, 0.9, 0.4 }, { 0.3, 0.1, 0.5, 0.8 }
  eui.login()
  assertEqual(F.rgba(S.Token("glow.color")), F.rgba({ 0.2, 0.9, 0.4, 1 }))
  assertEqual(F.rgba(S.Token("bar.bg")), F.rgba({ 0.3, 0.1, 0.5, 0.5 }))
  assertEqual(F.rgba(S.Token("cover.dim")), F.rgba({ 0.3, 0.1, 0.5, 0.6 }))
  assertEqual(F.rgba(S.Token("bar.border")), F.rgba({ 0.15, 0.05, 0.25, 1 }))
  assertEqual(F.rgba(S.Token("icon.border")), F.rgba({ 0.15, 0.05, 0.25, 1 }))
end)

-- ── a skin's None bar border defers ──────────────────────────────────────────────────────────

test("skin host gaps: S.Resolve hands back the stored bar border under a skin's None", function()
  -- red under: a companion on Ka0s Default drawing None over the player's stored style.
  local _, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  assertEqual(S.Resolve("bar.borderStyle", "Blizzard Tooltip", true), "Blizzard Tooltip")
  assertEqual(S.Resolve("bar.borderSize", 4, true), 4, "the thickness defers with it")
  assertEqual(S.Resolve("bar.borderStyle", "@skin"), "None", "the sentinel names no style of its own")
  assertEqual(S.Resolve("bar.borderStyle", nil, true), "None", "nothing stored: the skin's own")
  assertEqual(S.Resolve("bar.borderSize", nil, true), 1)
end)

test("skin host gaps: a real bar border style in a skin wins", function()
  -- red under: the deferral reaching a skin that states a style.
  local _, Skin = F.env()
  local S = F.owner(Skin, OWNER, "wow")
  assertEqual(S.Resolve("bar.borderStyle", "Solid", true), "Blizzard Tooltip")
  assertEqual(S.Resolve("bar.borderSize", 4, true), 2)
  assertEqual(S.Resolve("bar.borderStyle", "Solid", false), "Solid", "a companion off is the player's")
end)

test("skin host gaps: the deferral is the bar's alone", function()
  -- red under: an icon border or another string token reading the stored value while following.
  local _, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  Skin:RegisterSkin({ key = "noicon", tokens = { ["icon.borderStyle"] = "None" } })
  Skin:SetChoice(OWNER, "ka0s", "noicon")
  assertEqual(S.Resolve("icon.borderStyle", "Solid", true), "None")
  assertEqual(S.Resolve("bar.texture", "Mine", true), Skin:Token(OWNER, "bar.texture"))
end)

test("skin host gaps: S.BarBorder answers style, show and size in one read", function()
  -- red under: Show border read under a real style, or not read under None.
  local _, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  assertEqual(type(S.BarBorder), "function")
  local style, show, size = S.BarBorder("Solid", false, 3, true)
  assertEqual(style, "Solid")
  assertEqual(show, false, "None hands back Show border")
  assertEqual(size, 3)
  style, show, size = S.BarBorder("Solid", true, 3, false)
  assertEqual(style .. tostring(show) .. size, "Solidtrue3", "a companion off is stored")
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  style, show, size = S.BarBorder("Blizzard Tooltip", false, 7, true)
  assertEqual(style, "Solid", "a real style wins")
  assertEqual(show, true, "and draws whatever Show border says")
  assertEqual(size, 1)
  style, show, size = S.BarBorder("Blizzard Tooltip", false, 7, false)
  assertEqual(style .. tostring(show) .. size, "Blizzard Tooltipfalse7", "a companion off stays stored")
end)

test("skin host gaps: S.BarBorder with the sentinel stored", function()
  -- red under: "@skin" reaching a caller as a style name.
  local _, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local style, show = S.BarBorder("@skin", true, 2)
  assertEqual(style, "None")
  assertEqual(show, true)
  Skin:SetChoice(OWNER, "ka0s", "wow")
  style, show = S.BarBorder("@skin", false, 2)
  assertEqual(style, "Blizzard Tooltip")
  assertEqual(show, true)
end)

-- ── S.HudFont's shadow token ─────────────────────────────────────────────────────────────────

local function shadowOwner(Skin, skin)
  Skin:RegisterOwner(OWNER, { tokens = { ["am.shadow"] = { default = { 0, 0, 0, 1 }, follow = "hud.shadow",
    skins = { ember = { 1, 0, 0, 1 }, glass = false } } } })
  if skin then Skin:SetChoice(OWNER, "ka0s", skin) end
  return Skin:For(OWNER)
end

test("skin host gaps: HudFont's shadowToken gives a host its shipped shadow under Ka0s Default", function()
  -- red under: hud.shadow's false drawing no shadow for a host that ships one.
  local m, Skin = F.env()
  local S = shadowOwner(Skin)
  local obj = S.HudFont(fontString(m), { face = FACE, size = 12, shadowToken = "am.shadow" })
  assertEqual(obj.shadow[1], 1)
  assertEqual(obj.shadow[2], -1)
  assertEqual(F.rgba(obj.shadowColor), F.rgba({ 0, 0, 0, 1 }))
end)

test("skin host gaps: HudFont's shadowToken follows a skin, a skin's own entry and its false", function()
  -- red under: the token read once, or hud.shadow read past the name.
  local m, Skin = F.env()
  local S = shadowOwner(Skin, "ember")
  local opts = { face = FACE, size = 12, shadowToken = "am.shadow" }
  local obj = S.HudFont(fontString(m), opts)
  assertEqual(F.rgba(obj.shadowColor), F.rgba({ 1, 0, 0, 1 }))
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  obj = S.HudFont(fontString(m), opts)
  assertEqual(F.rgba(obj.shadowColor), F.tok(Skin, "obsidian", "hud.shadow"))
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  obj = S.HudFont(fontString(m), opts)
  assertEqual(obj.shadow[1], 2, "the skin's offset")
  Skin:SetChoice(OWNER, "ka0s", "glass")
  obj = S.HudFont(fontString(m), opts)
  assertEqual(obj.shadow[1], 0, "false draws none")
  assertEqual(obj.shadowColor[4], 0)
end)

test("skin host gaps: HudFont's shadowToken stands down for the companion and Ignore fonts", function()
  -- red under: the token drawn over a stored shadow the player chose.
  local m, Skin = F.env()
  local S = shadowOwner(Skin)
  local stored = { 3, -3, 0, 1, 0, 1 }
  local obj = S.HudFont(fontString(m), { face = FACE, size = 12, shadow = stored, shadowToken = "am.shadow",
                                         shadowFromSkin = false })
  assertEqual(obj.shadow[1], 3)
  Skin:SetIgnore(OWNER, nil, true)
  obj = S.HudFont(fontString(m), { face = FACE, size = 12, shadow = stored, shadowToken = "am.shadow" })
  assertEqual(obj.shadow[1], 3, "the owner ignores fonts")
end)

test("skin host gaps: a name no token carries draws hud.shadow and is logged once", function()
  -- red under: a misspelled name silently drawing nothing.
  local m, Skin = F.env()
  local lines = {}
  Skin:RegisterOwner(OWNER, { log = function(l) lines[#lines + 1] = l end })
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  local S = Skin:For(OWNER)
  local obj = S.HudFont(fontString(m), { face = FACE, size = 12, shadowToken = "am.nope" })
  assertEqual(F.rgba(obj.shadowColor), F.tok(Skin, "obsidian", "hud.shadow"))
  S.HudFont(fontString(m), { face = FACE, size = 12, shadowToken = "am.nope" })
  assertEqual(#lines, 1)
end)

test("skin host gaps: S.HudShadow takes the name too, and a non-color token is no shadow", function()
  -- red under: the getter and HudFont disagreeing.
  local _, Skin = F.env()
  local S = shadowOwner(Skin)
  local x, y, r = S.HudShadow("am.shadow")
  assertEqual(x, 1)
  assertEqual(y, -1)
  assertEqual(r, 0)
  assertEqual(S.HudShadow(), false, "no name is hud.shadow")
  assertEqual(S.HudShadow("bar.texture"), false)
end)

-- ── one font object per look ─────────────────────────────────────────────────────────────────

test("skin hud count: forty strings of one look spend one font object", function()
  -- red under: one object per string, which the client never frees.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  for _ = 1, 40 do S.HudFont(fontString(m), { face = FACE, size = 12 }) end
  assertEqual(#m.__fontsMade, 1)
end)

test("skin hud count: two owners with one look share it, and a new look makes one", function()
  -- red under: the look keyed on the owner, or on less than all of it.
  local m, Skin = F.env()
  local A, B = F.owner(Skin, OWNER), F.owner(Skin, "KickCD")
  local one = A.HudFont(fontString(m), { face = FACE, size = 12 })
  assertTrue(B.HudFont(fontString(m), { face = FACE, size = 12 }) == one)
  assertEqual(#m.__fontsMade, 1)
  local looks = { { face = "Fonts\\B.ttf", size = 12 }, { face = FACE, size = 13 },
                  { face = FACE, size = 12, flags = "THICKOUTLINE" },
                  { face = FACE, size = 12, shadow = true, shadowFromSkin = false },
                  { face = FACE, size = 12, shadow = { 2, -2, 1, 0, 0, 1 }, shadowFromSkin = false } }
  for i, look in ipairs(looks) do
    assertTrue(A.HudFont(fontString(m), look) ~= one, "look " .. i)
    assertEqual(#m.__fontsMade, 1 + i)
  end
end)

test("skin hud count: a string moved to another look leaves the first object's look alone", function()
  -- red under: one object written over, which repaints every string that wears it.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local a, b = fontString(m), fontString(m)
  local shared = S.HudFont(a, { face = FACE, size = 12 })
  S.HudFont(b, { face = FACE, size = 12 })
  local moved = S.HudFont(b, { face = FACE, size = 20 })
  assertTrue(moved ~= shared)
  assertEqual(shared.font[2], 12, "the shared object keeps its size")
  assertEqual(moved.font[2], 20)
  assertTrue(a:GetFontObject() == shared, "the other string still wears it")
end)

test("skin hud count: going back to a look reuses its object", function()
  -- red under: a skin switch back and forth spending an object each way.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "obsidian")
  local fs = fontString(m)
  local first = S.HudFont(fs, { face = FACE, size = 12 })
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  S.HudFont(fs, { face = FACE, size = 12 })
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertTrue(S.HudFont(fs, { face = FACE, size = 12 }) == first)
  assertEqual(#m.__fontsMade, 2)
end)

test("skin hud count: a repeat call writes an object once", function()
  -- red under: a pass rewriting a shared object every frame.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local obj = S.HudFont(fontString(m), { face = FACE, size = 12 })
  local writes, real = 0, obj.SetFont
  function obj:SetFont(...) writes = writes + 1; return real(self, ...) end
  S.HudFont(fontString(m), { face = FACE, size = 12 })
  assertEqual(writes, 0)
end)

test("skin hud count: a face the client refused is tried again on the next call", function()
  -- red under: a shared object stuck on the fallback face for the session.
  local m, Skin = F.env()
  m.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
  local S = F.owner(Skin, OWNER)
  local ready = false
  local real = m.CreateFont
  m.CreateFont = function(name)
    local o = real(name)
    local set = o.SetFont
    function o:SetFont(path, ...)
      if path == FACE and not ready then return false end
      return set(self, path, ...)
    end
    return o
  end
  Skin.__hudLooks = {}
  local obj = S.HudFont(fontString(m), { face = FACE, size = 12 })
  assertEqual(obj.font[1], "Fonts\\FRIZQT__.TTF")
  ready = true
  assertTrue(S.HudFont(fontString(m), { face = FACE, size = 12 }) == obj)
  assertEqual(obj.font[1], FACE)
end)

test("skin hud count: a replaced CreateFont starts a fresh table", function()
  -- red under: a host suite's fake never reached, because an earlier look answers from the table.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local first = S.HudFont(fontString(m), { face = FACE, size = 12 })
  local real, made = m.CreateFont, 0
  m.CreateFont = function(name) made = made + 1; return real(name) end
  local second = S.HudFont(fontString(m), { face = FACE, size = 12 })
  assertEqual(made, 1)
  assertTrue(second ~= first)
end)

-- ── noBg on a frame with no backdrop ─────────────────────────────────────────────────────────

local function bare(m)
  local f = m.CreateFrame("Frame")
  rawset(f, "SetBackdrop", nil)   -- no BackdropTemplate: the fill a region, every edge on the holder
  return f
end

test("skin host gaps: TitleBar's noBg on a frame with no backdrop draws no fill", function()
  -- red under: regionBox re-reading spec.fill, title.bg's alpha drawn over the Shell's band.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local bar = bare(m)
  S.TitleBar(bar, { noBg = true })
  assertNil(F.region(Skin, bar, "fill"), "no fill region")
end)

test("skin host gaps: noBg hides a fill an earlier paint made", function()
  -- red under: the region left showing from the call before.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local bar = bare(m)
  S.TitleBar(bar)
  local fill = F.region(Skin, bar, "fill")
  assertTrue(fill ~= nil and fill:IsShown(), "painted")
  S.TitleBar(bar, { noBg = true })
  assertFalse(fill:IsShown())
  S.TitleBar(bar)
  assertTrue(fill:IsShown(), "and back")
end)

test("skin host gaps: noBg keeps the box's edge on a frame with no backdrop", function()
  -- red under: the whole box dropped with its fill.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local p = bare(m)
  S.Panel(p, { noBg = true })
  assertNil(F.region(Skin, p, "fill"))
  assertTrue(F.region(Skin, p, "edgeTop") ~= nil, "the edge stays")
end)

-- ── S.IconBorder on a Texture ────────────────────────────────────────────────────────────────

test("skin host gaps: IconBorder on a Texture hangs its edge on a child of the parent", function()
  -- red under: a Texture refused, or an edge drawn on the parent.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local parent = m.CreateFrame("Button")
  rawset(parent, "GetFrameLevel", function() return 5 end)
  local tex = parent:CreateTexture()
  local level, bounds
  local make = m.CreateFrame
  m.CreateFrame = function(...)
    local f = make(...)
    rawset(f, "SetFrameLevel", function(_, n) level = n end)
    rawset(f, "SetAllPoints", function(_, to) bounds = to end)
    return f
  end
  S.IconBorder(tex, { fromSkin = true })
  m.CreateFrame = make
  local h = Skin.painted[tex].regions.holder
  assertTrue(h ~= nil, "a holder")
  assertTrue(m.__paint(h).parent == parent or h.__parent == parent, "a child of the Texture's parent")
  assertEqual(level, 6, "over it")
  assertTrue(bounds == tex, "on the Texture's bounds")
  local e = F.region(Skin, tex, "edgeTop")
  assertTrue(e ~= nil and e:IsShown(), "the edge is drawn")
  assertEqual(F.rgba(survey(m, e).color), F.tok(Skin, "ka0s", "icon.border"))
end)

test("skin host gaps: IconBorder's child never writes to a secure parent", function()
  -- red under: a call on the parent, which is a taint in combat on a secure button.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local parent = m.CreateFrame("Button")
  local tex = parent:CreateTexture()
  local touched = {}
  for _, name in ipairs({ "SetFrameLevel", "EnableMouse", "SetScript", "HookScript", "SetAttribute",
                          "SetAlpha", "SetBackdrop", "RegisterForClicks" }) do
    rawset(parent, name, function() touched[#touched + 1] = name end)
  end
  S.IconBorder(tex, { fromSkin = true })
  assertEqual(table.concat(touched, ","), "")
end)

test("skin host gaps: IconBorder on a Texture follows a skin and one holder serves", function()
  -- red under: a repaint making a second holder, or a Texture's call unrecorded.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local tex = m.CreateFrame("Frame"):CreateTexture()
  S.IconBorder(tex, { size = 3 })
  local h = Skin.painted[tex].regions.holder
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  assertTrue(Skin.painted[tex].regions.holder == h)
  assertEqual(F.rgba(survey(m, F.region(Skin, tex, "edgeTop")).color), F.tok(Skin, "contrast", "icon.border"))
end)

test("skin host gaps: IconBorder follows its Texture's shown state", function()
  -- red under: a border left standing around a hidden icon.
  local m, Skin = F.env()
  m.hooksecurefunc = function(t, name, fn)
    local real = t[name]
    rawset(t, name, function(...) real(...); fn(...) end)
  end
  local S = F.owner(Skin, OWNER)
  local tex = m.CreateFrame("Frame"):CreateTexture()
  tex:Hide()
  S.IconBorder(tex, { fromSkin = true })
  local h = Skin.painted[tex].regions.holder
  assertFalse(h:IsShown(), "a hidden Texture starts hidden")
  tex:Show()
  assertTrue(h:IsShown())
  tex:Hide()
  assertFalse(h:IsShown())
  tex:SetShown(true)
  assertTrue(h:IsShown())
end)

test("skin host gaps: IconBorder leaves a Texture with no parent alone", function()
  -- red under: CreateFrame handed a nil parent, a holder on UIParent.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local tex = m.CreateFrame("Frame"):CreateTexture()
  rawset(tex, "GetParent", function() return nil end)
  S.IconBorder(tex, { fromSkin = true })
  assertNil(Skin.painted[tex].regions.holder)
end)

-- ── a numeric path segment ───────────────────────────────────────────────────────────────────

test("skin host gaps: ResetToSkin walks a numeric segment into a list", function()
  -- red under: a window of a list skipped while the count and the record say it moved.
  local _, Skin = F.env()
  local p = { windows = { { textFromSkin = false }, { textFromSkin = false } } }
  assertEqual(Skin.ResetToSkin(p, { "windows.1.textFromSkin", "windows.2.textFromSkin" }), 2)
  assertTrue(p.windows[1].textFromSkin)
  assertTrue(p.windows[2].textFromSkin)
  assertNil(p.windows["1"], "no string key grows")
end)

test("skin host gaps: FollowOnce reaches a numeric container, and a string key wins", function()
  -- red under: the silent miss, or a numeric key read over a string key that exists.
  local _, Skin = F.env()
  local p = { containers = { [7] = { bars = { fontFromSkin = false } }, ["8"] = { fontFromSkin = false },
                             [8] = { fontFromSkin = false } } }
  assertTrue(Skin.FollowOnce(p, { "containers.7.bars.fontFromSkin", "containers.8.fontFromSkin" }))
  assertTrue(p.containers[7].bars.fontFromSkin)
  assertTrue(p.containers["8"].fontFromSkin)
  assertFalse(p.containers[8].fontFromSkin)
end)

test("skin host gaps: a numeric leaf lands on the list's own entry", function()
  -- red under: a string "1" key written beside the entry.
  local _, Skin = F.env()
  local p = { flags = { false, false } }
  Skin.ResetToSkin(p, { "flags.2" })
  assertEqual(p.flags[2], true)
  assertNil(p.flags["2"])
end)

test("skin host gaps: a missing numeric entry is still skipped", function()
  -- red under: a list grown by a path through nothing.
  local _, Skin = F.env()
  local p = { windows = { {} } }
  assertEqual(Skin.ResetToSkin(p, { "windows.3.textFromSkin" }), 0)
  assertNil(p.windows[3])
end)

-- ── S.HoverArt ───────────────────────────────────────────────────────────────────────────────

test("skin host gaps: S.HoverArt tints hover art in list.hoverArt and follows a skin", function()
  -- red under: a host left on the Options instance's private O.__hoverArt.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "obsidian")
  assertEqual(type(S.HoverArt), "function")
  local tex = m.CreateFrame("Frame"):CreateTexture()
  S.HoverArt(tex)
  assertEqual(F.rgba(survey(m, tex).vertex), F.tok(Skin, "obsidian", "list.hoverArt"))
  assertTrue(survey(m, tex).desaturated, "desaturated, so the token's hue shows")
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  assertEqual(F.rgba(survey(m, tex).vertex), F.tok(Skin, "contrast", "list.hoverArt"))
end)

test("skin host gaps: S.HoverArt leaves the client's art where the skin says false", function()
  -- red under: Ka0s Default's ADD art tinted or desaturated.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  local tex = m.CreateFrame("Frame"):CreateTexture()
  S.HoverArt(tex)
  assertTrue(not survey(m, tex).desaturated)
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertTrue(survey(m, tex).desaturated)
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertTrue(not survey(m, tex).desaturated, "given back")
end)

test("skin host gaps: S.HoverArt's panel scope and its back", function()
  -- red under: art tinted on an ignored panel, or a pooled texture kept on the record.
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER, "obsidian")
  local tex = m.CreateFrame("Frame"):CreateTexture()
  S.HoverArt(tex, { panel = true })
  assertTrue(survey(m, tex).desaturated)
  Skin:SetIgnore(OWNER, true)
  assertTrue(not survey(m, tex).desaturated, "ignored, live")
  Skin:SetIgnore(OWNER, false)
  assertTrue(survey(m, tex).desaturated, "and back, live")
  S.HoverArt(tex, { back = true })
  assertTrue(not survey(m, tex).desaturated, "back is the client's art")
  assertNil(Skin.painted[tex], "and the record is gone")
end)

-- ── a mark on a pooled AceGUI widget ─────────────────────────────────────────────────────────

-- SkinAce.lua holds Skin:OnRelease, and the fixture's default load leaves it out.
local function aceEnv()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  files[#files + 1] = "SkinAce"
  return F.env({ files = files })
end

local function iconWidget(m)
  local frame = m.CreateFrame("Button")
  local image = frame:CreateTexture()
  local widget = { type = "Icon", frame = frame, image = image, userdata = {} }
  rawset(frame, "obj", widget)
  return widget, image
end

test("skin host gaps: S.Mark on an AceGUI widget's texture gives itself back at release", function()
  -- red under: QuickComms' bug: the record outlives the release and repaints the next user.
  local m, Skin = aceEnv()
  local S = F.owner(Skin, OWNER, "obsidian")
  local widget, image = iconWidget(m)
  S.Mark(image)
  assertTrue(Skin.painted[image] ~= nil)
  widget:OnRelease()
  assertNil(Skin.painted[image], "forgotten")
  assertEqual(F.rgba(survey(m, image).vertex), F.rgba({ 1, 1, 1, 1 }), "and its tint is back")
  image:SetVertexColor(0.1, 0.2, 0.3, 1)
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  assertEqual(F.rgba(survey(m, image).vertex), F.rgba({ 0.1, 0.2, 0.3, 1 }), "no repaint reaches the next user")
end)

test("skin host gaps: a repaint does not stack a second release", function()
  -- red under: one more wrapper per skin change on the widget.
  local m, Skin = aceEnv()
  local S = F.owner(Skin, OWNER, "obsidian")
  local widget, image = iconWidget(m)
  local runs = 0
  function widget.OnRelease() runs = runs + 1 end
  S.Mark(image)
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  S.Mark(image)
  widget:OnRelease()
  assertEqual(runs, 1, "the widget's own release ran once")
  assertTrue(rawget(widget, "OnRelease") ~= nil)
  widget:OnRelease()
  assertEqual(runs, 2, "the wrapper took itself off")
end)

test("skin host gaps: a second acquire arms again", function()
  -- red under: the armed flag surviving the release.
  local m, Skin = aceEnv()
  local S = F.owner(Skin, OWNER, "obsidian")
  local widget, image = iconWidget(m)
  S.Mark(image)
  widget:OnRelease()
  S.Mark(image)
  widget:OnRelease()
  assertNil(Skin.painted[image])
end)

test("skin host gaps: S.Mark's opts.widget covers a texture a level down", function()
  -- red under: a pooled texture that is not a direct child of the widget's frame missed.
  local m, Skin = aceEnv()
  local S = F.owner(Skin, OWNER, "obsidian")
  local widget = iconWidget(m)
  local tex = m.CreateFrame("Frame"):CreateTexture()
  S.Mark(tex, { widget = widget })
  widget:OnRelease()
  assertNil(Skin.painted[tex])
end)

test("skin host gaps: S.Mark's stock puts the client's art back at release", function()
  -- red under: a Ka0s icon left on the texture the next user wears.
  local m, Skin = aceEnv()
  local S = F.owner(Skin, OWNER, "obsidian")
  local widget, image = iconWidget(m)
  local stocked = 0
  S.Mark(image, { art = "x", stock = function() stocked = stocked + 1 end })
  widget:OnRelease()
  assertEqual(stocked, 1)
end)

test("skin host gaps: a mark on a plain frame arms no release", function()
  -- red under: a release wrapper written onto a frame no pool owns.
  local m, Skin = aceEnv()
  local S = F.owner(Skin, OWNER, "obsidian")
  local f = m.CreateFrame("Frame")
  local tex = f:CreateTexture()
  S.Mark(tex)
  assertNil(rawget(f, "OnRelease"))
  assertTrue(Skin.painted[tex] ~= nil)
end)

test("skin host gaps: S.HoverArt on an AceGUI widget's texture gives itself back too", function()
  -- red under: a second way to leave a pooled record behind.
  local m, Skin = aceEnv()
  local S = F.owner(Skin, OWNER, "obsidian")
  local widget, image = iconWidget(m)
  S.HoverArt(image)
  widget:OnRelease()
  assertNil(Skin.painted[image])
end)
