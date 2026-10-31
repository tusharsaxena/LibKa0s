-- tests/test_options_appearance_overrides.lua -- the Appearance tab's font and texture overrides:
-- the font outline, a skin change resetting the overrides and the Skin tab's layout around them
-- (OptionsAppearance minor 4, LK-03, LK-07 and LK-08 of Ka0sAddonsCommonTasks
-- docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK). Moved unchanged out of tests/test_options_appearance.lua
-- on the seam the watch list named (FX-LK-SIZE of docs/2026-10-31-FINDINGS_REMEDIATION); the bench is
-- shared through tests/fixture_appearance.lua.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertFalse, K.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local Bench = dofile("tests/fixture_appearance.lua")
local OWNER, OTHER, THIRD = Bench.OWNER, Bench.OTHER, Bench.THIRD
local env, register, page, specFor = Bench.env, Bench.register, Bench.page, Bench.specFor
local flatten, hasText, mediaEnv, indexOf = Bench.flatten, Bench.hasText, Bench.mediaEnv, Bench.indexOf

-- ── the font outline (minor 4, LK-03 of docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK) ─────────────

test("appearance: the Font outline dropdown sits in the Font and texture section, All text first", function()
  -- red under: minor 4 as LK-03 drew it, under the Scope's check boxes (LK-08 moves it, D-11).
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  local S = lib.APPEARANCE_STRINGS
  local dd = view.outline
  assertEqual(dd.labelText, "Font outline")
  assertEqual(table.concat(dd.order, "|"), "all|hud|off", "the three modes in the tab's order")
  assertEqual(dd.list.all, "All text"); assertEqual(dd.list.hud, "HUD text only"); assertEqual(dd.list.off, "Off")
  assertEqual(dd.value, "hud", "the default, HUD text only")
  assertFalse(dd.disabled == true, "live while Ignore fonts is off")
  assertTrue(S.OUTLINE_TIP:find("Ignore fonts", 1, true) ~= nil, "the tooltip says Ignore fonts wins")
  local all = flatten(ctx.scroll)
  assertTrue(indexOf(all, view.reset.texture) < indexOf(all, dd) and indexOf(all, dd) < indexOf(all, view.ignore.panel),
    "under the reset buttons, above the Scope")
  assertEqual(dd.relativeWidth, lib.BUTTON_PAIR_REL or 0.492, "on the dropdowns' half-width grid")
end)

test("appearance: an outline pick moves the Skin major first, then writes every media half", function()
  -- red under: setOutline writing { outline } alone (a minor-6 setter clears both overrides).
  local m, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  Skin:SetOutline(OWNER, "all")
  Skin:SetOverride(OWNER, "Ka0s Expressway", nil)
  local frame = F.window(m)
  frame.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
  Skin:For(OWNER).Shell(frame)
  local O, ctx = page(lib, OWNER)
  local spec = specFor(store)
  local seam, seen = spec.set, nil
  spec.set = function(...)
    seen = { mode = Skin:GetOutline(OWNER), ... }
    seam(...)
  end
  local view = O.AppearanceRows(ctx, spec)
  assertEqual(frame.title:GetFontObject().font[3], "OUTLINE", "all: the title is outlined")
  view.outline:__fire("OnValueChanged", "hud")
  assertEqual(seen.mode, "hud", "SetOutline ran before the owner's write seam")
  assertNil(seen[1]); assertNil(seen[2]); assertNil(seen[3], "no source, skin or scope")
  assertEqual(store.media.outline, "hud", "written through the fourth argument")
  assertEqual(store.media.font, "Ka0s Expressway", "with the font override as it is")
  assertEqual(store.media.texture, false, "and the texture")
  assertEqual(frame.title:GetFontObject().font[3], "", "the title repainted unoutlined, live")
  assertEqual(view.outline.value, "hud")
  view.media.texture:__fire("OnValueChanged", "Ka0s Flat")
  assertEqual(store.media.outline, "hud", "a texture pick carries the outline too")
end)

test("appearance: Ignore fonts grays the Font outline out, and it comes back live", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  view.ignore.fonts:__fire("OnValueChanged", true)
  assertTrue(view.outline.disabled, "grayed while Ignore fonts is on")
  view.ignore.fonts:__fire("OnValueChanged", false)
  assertFalse(view.outline.disabled, "live again")
  Skin:SetIgnore(OWNER, nil, true)
  view.sync()
  assertTrue(view.outline.disabled, "an Ignore fonts set elsewhere is read back")
end)

test("appearance: in combat an outline pick writes nothing and snaps back", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  lib.__combatLocked = true
  view.outline:__fire("OnValueChanged", "off")
  assertEqual(Skin:GetOutline(OWNER), "hud", "the Skin major did not move")
  assertNil(store.seamCalls, "the seam was not called")
  assertEqual(view.outline.value, "hud", "the refused pick snaps back")
  lib.__combatLocked = false
end)

test("appearance: a page drawn disabled keeps the Font outline disabled after a sync", function()
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  ctx.__renderDisabled = true
  local view = O.AppearanceRows(ctx, specFor(store))
  ctx.__renderDisabled = nil
  view.sync()
  assertTrue(view.outline.disabled)
end)

test("appearance: copy gives every other owner this owner's font outline", function()
  local m, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  local other = register(Skin, OTHER)
  Skin:SetOutline(OWNER, "off")
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  view.copy:__fire("OnClick")
  m.popups[1].dialog.OnAccept(nil, m.popups[1].data)
  assertEqual(Skin:GetOutline(OTHER), "off", "the other owner's applied mode moved")
  assertEqual(other.media.outline, "off", "and its profile, through WriteChoice's media")
end)

test("appearance: the copy helper keeps a target's own half for a media half left out", function()
  -- red under: lib.__copySkinTo handing a partial media to WriteChoice (the target's overrides cleared).
  local _, Skin, lib = env()
  register(Skin, OWNER)
  local other = register(Skin, OTHER)
  Skin:SetOverride(OTHER, "Ka0s Expressway", "Ka0s Flat")
  lib.__copySkinTo(Skin, OTHER, "ka0s", "ka0s", nil, { outline = "hud" })
  assertEqual(Skin:GetOutline(OTHER), "hud", "the outline moved")
  local font, texture = Skin:GetOverride(OTHER)
  assertEqual(font, "Ka0s Expressway", "the font kept"); assertEqual(texture, "Ka0s Flat", "and the texture")
  assertEqual(other.media.font, "Ka0s Expressway", "and written back as it is")
  assertEqual(other.media.texture, "Ka0s Flat")
  assertNil(other.media.outline, "already the default: nothing stored")
  -- LK-07: a half left out is the target's own after the move, and a move to another look reset it.
  lib.__copySkinTo(Skin, OTHER, "ka0s", "ember", nil, { outline = "off" })
  font, texture = Skin:GetOverride(OTHER)
  assertNil(font); assertNil(texture, "another skin: the new skin's own font and texture")
  assertEqual(other.media.font, false, "written back as the skin's own")
  assertEqual(other.media.texture, false)
  assertEqual(other.media.outline, "off")
end)

test("appearance: the other owners and one owner's skin copy are library-level, for the skin picker", function()
  -- red under: others(view) and copyTo's per-owner body private to the attach (the picker's
  -- "Apply to all Ka0s addons" had to restate them).
  local _, Skin, lib = env()
  register(Skin, OWNER)
  local other = register(Skin, OTHER)
  register(Skin, THIRD)
  assertEqual(table.concat(lib.__skinOthers(Skin, OWNER), "|"), OTHER .. "|" .. THIRD, "sorted, the owner left out")
  assertEqual(#lib.__skinOthers(Skin, "NotAnOwner"), 3, "every owner for a name that is none")
  Skin:SetIgnore(OTHER, true, false)
  local before = other.writes
  local reload = lib.__copySkinTo(Skin, OTHER, "ka0s", "ember")
  assertFalse(reload, "no reload for a Ka0s skin switch")
  assertEqual(select(2, Skin:GetChoice(OTHER)), "ember", "the applied choice moved")
  assertEqual(other.skin, "ember", "and its profile, through its own setter")
  assertEqual(other.writes, before + 1, "one write")
  assertNil(other.ignore, "no scope half written")
  assertNil(other.media, "no overrides to reset: no font or texture half written")
  assertEqual(select(1, Skin:GetIgnore(OTHER)), true, "its scope left alone")
  -- red under: minor 3's copy, which left a target's font alone across a skin change (LK-07, D-10).
  Skin:SetOverride(OTHER, "Ka0s Expressway", nil)
  Skin:SetOutline(OTHER, "off")
  lib.__copySkinTo(Skin, OTHER, "ka0s", "glass")
  assertNil((Skin:GetOverride(OTHER)), "another skin: its font back to the skin's own")
  assertEqual(other.media.font, false, "and its profile written to match")
  assertEqual(other.media.texture, false)
  assertEqual(other.media.outline, "off", "its own outline written back as it is")
  assertEqual(select(1, Skin:GetIgnore(OTHER)), true, "its scope still left alone")
end)

test("appearance: a font pick stores no outline the owner never chose, and keeps one it did", function()
  -- red under: the write sending GetOutline, which stored v1.82.0's "all" for every owner that
  -- picked a font, so the owner's item 5 never reached them.
  local _, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  view.media.font:__fire("OnValueChanged", "Ka0s Expressway")
  assertEqual(store.media.font, "Ka0s Expressway", "the pick went through")
  assertNil(store.media.outline, "never set: nothing stored")
  assertEqual(Skin:GetOutline(OWNER), "hud", "and the default applies")
  Skin:SetOutline(OWNER, "all")
  view.media.font:__fire("OnValueChanged", "Ka0s Fira Sans")
  assertEqual(store.media.outline, "all", "a stored mode stays")
  Skin:SetOutline(OWNER, "hud")
  view.media.font:__fire("OnValueChanged", "Ka0s Expressway")
  assertEqual(store.media.outline, "hud", "and a move off it back to the default is written")
end)

test("appearance: the copy gives a target the source's applied outline, the default included", function()
  -- red under: the copy sending the stored half, nil here, so a target on All text kept it.
  local m, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  local other = register(Skin, OTHER)
  Skin:SetOutline(OTHER, "all")
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  view.copy:__fire("OnClick")
  local p = m.popups[1]
  p.dialog.OnAccept(nil, p.data)
  assertEqual(Skin:GetOutline(OTHER), "hud", "the target wears it")
  assertEqual(other.media.outline, "hud", "and stores it")
end)

-- ── a skin change resets the overrides (still minor 4: LK-07, the owner's item 1, D-10) ───────

--- A view on mediaEnv with both overrides set, its seam recording every call's four arguments.
local function resetEnv(extra)
  local m, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  Skin:SetOverride(OWNER, "Ka0s Expressway", "Ka0s Flat")
  local O, ctx = page(lib, OWNER)
  local spec = specFor(store, extra)
  local seam = spec.set
  store.calls = {}
  spec.set = function(...)
    store.calls[#store.calls + 1] = { n = select("#", ...), ... }
    seam(...)
  end
  return m, Skin, lib, store, O.AppearanceRows(ctx, spec)
end

test("appearance: a skin pick with both overrides set resets both, live and through the seam", function()
  local _, Skin, _, store, view = resetEnv()
  assertEqual(view.media.font.value, "Ka0s Expressway", "the override shows first")
  view.skins.obsidian:__fire("OnValueChanged", true)
  local font, texture = Skin:GetOverride(OWNER)
  assertNil(font); assertNil(texture, "the Skin major wears the new skin's own font and texture")
  assertEqual(#store.calls, 2, "the skin write, then the media write")
  assertEqual(store.calls[1][1], "ka0s"); assertEqual(store.calls[1][2], "obsidian")
  assertNil(store.calls[1][4], "the skin write carries no media")
  local media = store.calls[2][4]
  assertNil(store.calls[2][1]); assertNil(store.calls[2][2]); assertNil(store.calls[2][3])
  assertEqual(media.font, false, "the font: the skin's own")
  assertEqual(media.texture, false, "the texture: the skin's own")
  assertNil(media.outline, "an outline never set stays unset")
  assertEqual(view.media.font.value, "@skin", "both dropdowns read the skin's own")
  assertEqual(view.media.texture.value, "@skin")
end)

test("appearance: re-clicking the checked skin, or a pick with no overrides, writes no media", function()
  local _, Skin, _, store, view = resetEnv()
  view.skins.ka0s:__fire("OnValueChanged", true)
  assertEqual((Skin:GetOverride(OWNER)), "Ka0s Expressway", "the same skin keeps its overrides")
  assertNil(store.calls[2], "and writes no media half")
  Skin:SetOverride(OWNER, false, false)
  store.calls = {}
  view.skins.ember:__fire("OnValueChanged", true)
  assertEqual(#store.calls, 1, "no override to reset: the skin write alone")
end)

test("appearance: an override picked after a switch sticks until the next switch", function()
  local _, Skin, _, store, view = resetEnv()
  view.skins.obsidian:__fire("OnValueChanged", true)
  view.media.texture:__fire("OnValueChanged", "Blizzard")
  view.sync()
  assertEqual(select(2, Skin:GetOverride(OWNER)), "Blizzard", "the new pick lands")
  assertEqual(view.media.texture.value, "Blizzard", "and stays after a sync")
  assertEqual(store.media.texture, "Blizzard")
  view.skins.glass:__fire("OnValueChanged", true)
  assertNil(select(2, Skin:GetOverride(OWNER)), "the next switch resets it")
  assertEqual(store.media.texture, false)
end)

test("appearance: in combat a skin pick resets nothing", function()
  local _, Skin, lib, store, view = resetEnv()
  lib.__combatLocked = true
  view.skins.obsidian:__fire("OnValueChanged", true)
  lib.__combatLocked = false
  local font, texture = Skin:GetOverride(OWNER)
  assertEqual(font, "Ka0s Expressway"); assertEqual(texture, "Ka0s Flat", "both overrides kept")
  assertEqual(#store.calls, 0, "nothing written")
end)

test("appearance: a pick keeps the overrides while the look drawn does not change (Skin:DrawsKey)", function()
  local _, Skin, lib = mediaEnv()
  register(Skin, OWNER)
  local draws = "eui"
  Skin.DrawsKey = function() return draws end
  Skin:SetOverride(OWNER, "Ka0s Expressway", nil)
  local changed, _, cleared = lib.__chooseSkin(Skin, OWNER, "eui", "ember")
  assertTrue(changed, "the choice moved")
  assertFalse(cleared, "EllesmereUI still paints: the fallback pick is not seen, the overrides stay")
  assertEqual((Skin:GetOverride(OWNER)), "Ka0s Expressway")
  Skin.DrawsKey = function() local d = draws; draws = "glass"; return d end
  changed, _, cleared = lib.__chooseSkin(Skin, OWNER, "ka0s", "glass")
  assertTrue(changed); assertTrue(cleared, "the look drawn changed: reset")
  assertNil((Skin:GetOverride(OWNER)))
  changed, _, cleared = lib.__chooseSkin(Skin, OWNER, "ka0s", "glass")
  assertFalse(changed); assertFalse(cleared, "an unchanged choice answers false, false")
end)

test("appearance: onto an EllesmereUI that paints resets the overrides; a fallback pick under it does not",
function()
  local _, Skin, lib, eui = env({ eui = {} })
  local store = register(Skin, OWNER)
  eui.login()
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  Skin:SetOverride(OWNER, "Ka0s Expressway", nil)
  view.source.eui:__fire("OnValueChanged", true)
  assertEqual(Skin:DrawsKey(OWNER), "eui", "EllesmereUI paints the owner")
  assertNil((Skin:GetOverride(OWNER)), "its face replaced the skin's: the override reset")
  Skin:SetOverride(OWNER, "Ka0s Expressway", nil)
  view.skins.ember:__fire("OnValueChanged", true)
  assertEqual(select(2, Skin:GetChoice(OWNER)), "ember", "the fallback skin moved")
  assertEqual((Skin:GetOverride(OWNER)), "Ka0s Expressway", "the look did not: the override stays")
end)

test("appearance: copy gives an other owner whose skin changes this owner's overrides, none for none", function()
  local m, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER, "ka0s", "ember")
  local other = register(Skin, OTHER)
  Skin:SetChoice(OWNER, "ka0s", "ember")
  Skin:SetOverride(OTHER, "Ka0s Expressway", "Ka0s Flat")
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  view.copy:__fire("OnClick")
  m.popups[1].dialog.OnAccept(nil, m.popups[1].data)
  local font, texture = Skin:GetOverride(OTHER)
  assertNil(font); assertNil(texture, "this owner has none, so the other owner has none")
  assertEqual(other.media.font, false); assertEqual(other.media.texture, false)
  assertEqual(other.skin, "ember")
end)

-- ── the Skin tab's layout (still minor 4: LK-08, the owner's item 6, D-11) ────────────────────

--- The index in `all` of the first widget whose text is `text`.
local function indexOfText(all, text)
  for i, w in ipairs(all) do
    if w.text == text or w.labelText == text then return i end
  end
  return nil
end

--- The container under `root` (`root` itself included) whose children hold `w`, or nil.
local function holderOf(root, w)
  for _, c in ipairs(root.children or {}) do
    if c == w then return root end
    local h = holderOf(c, w)
    if h then return h end
  end
  return nil
end

--- The half width the dropdowns use: the instance's BUTTON_PAIR_REL.
local function half(O) return O.BUTTON_PAIR_REL or 0.492 end

test("appearance: Reset font and Reset texture sit under their dropdowns, at the dropdowns' width", function()
  local _, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  local S = lib.APPEARANCE_STRINGS
  local font, texture = view.reset.font, view.reset.texture
  assertEqual(font.text, "Reset font"); assertEqual(texture.text, "Reset texture")
  assertEqual(S.RESET_FONT, "Reset font"); assertEqual(S.RESET_TEXTURE, "Reset texture")
  assertEqual(font.relativeWidth, half(O), "half width"); assertEqual(texture.relativeWidth, half(O))
  assertEqual(view.media.font.relativeWidth, half(O), "as the dropdowns are")
  local all = flatten(ctx.scroll)
  assertTrue(indexOf(all, view.media.texture) < indexOf(all, font) and indexOf(all, font) < indexOf(all, texture),
    "a row of their own under the two dropdowns, font first")
  local row = holderOf(ctx.scroll, font)
  assertTrue(row ~= nil and row ~= holderOf(ctx.scroll, view.media.font),
    "not on the dropdowns' line (their labels top-align)")
  assertTrue(row == holderOf(ctx.scroll, texture), "the two share one row")
  assertTrue(font.disabled, "no override: Reset font is disabled")
  assertTrue(texture.disabled, "and Reset texture")
end)

test("appearance: a reset clears only its half, live and then through the seam", function()
  local m, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  Skin:SetOverride(OWNER, "Ka0s Expressway", "Ka0s Flat")
  local frame = F.window(m)
  frame.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
  Skin:For(OWNER).Shell(frame)
  local O, ctx = page(lib, OWNER)
  local spec = specFor(store)
  local seam, seen = spec.set, nil
  spec.set = function(...)
    seen = { font = (Skin:GetOverride(OWNER)), ... }
    seam(...)
  end
  local view = O.AppearanceRows(ctx, spec)
  assertFalse(view.reset.font.disabled, "an override: Reset font is live")
  assertFalse(view.reset.texture.disabled)
  assertEqual((frame.title:GetFont()), "Fonts\\Expressway.ttf")
  view.reset.font:__fire("OnClick")
  assertNil(seen.font, "SetOverride ran before the owner's write seam")
  assertNil(seen[1]); assertNil(seen[2]); assertNil(seen[3])
  assertEqual(store.media.font, false, "the font: the skin's own")
  assertEqual(store.media.texture, "Ka0s Flat", "the texture kept")
  assertNil(store.media.outline, "and no default stored as a choice")
  assertEqual(select(2, Skin:GetOverride(OWNER)), "Ka0s Flat", "the texture override stays live")
  assertTrue((frame.title:GetFont()) ~= "Fonts\\Expressway.ttf", "the title repainted in the skin's face")
  assertEqual(view.media.font.value, "@skin", "the dropdown reads the skin's own")
  assertTrue(view.reset.font.disabled, "and Reset font disables itself")
  assertFalse(view.reset.texture.disabled, "Reset texture stays live")
  view.reset.font:__fire("OnClick")
  assertEqual(store.seamCalls, 1, "a disabled reset writes nothing")
  view.reset.texture:__fire("OnClick")
  assertNil(select(2, Skin:GetOverride(OWNER)), "the texture reset")
  assertEqual(store.media.texture, false)
  assertTrue(view.reset.texture.disabled)
end)

test("appearance: a reset is refused in combat, and a dropdown pick re-enables it", function()
  local _, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  view.media.texture:__fire("OnValueChanged", "Ka0s Flat")
  assertFalse(view.reset.texture.disabled, "an override picked: live")
  lib.__combatLocked = true
  view.reset.texture:__fire("OnClick")
  lib.__combatLocked = false
  assertEqual(select(2, Skin:GetOverride(OWNER)), "Ka0s Flat", "the Skin major did not move")
  assertEqual(store.media.texture, "Ka0s Flat", "nothing written")
end)

test("appearance: a page drawn disabled keeps both resets disabled after a sync", function()
  local _, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  Skin:SetOverride(OWNER, "Ka0s Expressway", "Ka0s Flat")
  local O, ctx = page(lib, OWNER)
  ctx.__renderDisabled = true
  local view = O.AppearanceRows(ctx, specFor(store))
  ctx.__renderDisabled = nil
  view.sync()
  assertTrue(view.reset.font.disabled); assertTrue(view.reset.texture.disabled)
end)

test("appearance: the resets' tooltips name the skin's own, and spec.strings translates them", function()
  local _, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local tips = {}
  local attach = O.AttachTooltip
  O.AttachTooltip = function(w, label, tip)
    tips[w] = { label = label, tip = tip }
    return attach(w, label, tip)
  end
  local view = O.AppearanceRows(ctx, specFor(store, { strings = {
    RESET_FONT = "Police d'origine", RESET_FONT_TIP = "Police %s", RESET_TEXTURE = "Texture d'origine",
    RESET_TEXTURE_TIP = "Texture %s", COPY_HEADING = "Autres" } }))
  assertEqual(view.reset.font.text, "Police d'origine"); assertEqual(view.reset.texture.text, "Texture d'origine")
  assertEqual(tips[view.reset.font].tip, "Police Ka0s Prototype", "the skin's own face")
  assertEqual(tips[view.reset.texture].tip, "Texture Ka0s Default", "and its bar texture")
  assertTrue(hasText(ctx, "Autres"), "the copy's heading translated")
  view.skins.obsidian:__fire("OnValueChanged", true)
  assertEqual(tips[view.reset.font].tip, "Police " .. Skin:ResolveSkin("obsidian")["font.body"],
    "re-worded for the skin worn now")
  assertEqual(lib.APPEARANCE_STRINGS.RESET_FONT_TIP, "Use the skin's default font again (%s).")
  assertEqual(lib.APPEARANCE_STRINGS.RESET_TEXTURE_TIP, "Use the skin's default bar texture again (%s).")
end)

test("appearance: the Scope's check boxes sit on the dropdowns' half-width grid", function()
  -- red under: minor 3's W_CHOICE (0.32), the skins' three-column grid (image-30).
  local _, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  assertEqual(view.ignore.panel.relativeWidth, half(O))
  assertEqual(view.ignore.fonts.relativeWidth, half(O))
  assertEqual(view.ignore.fonts.relativeWidth, view.media.texture.relativeWidth, "Ignore fonts lines up with Texture")
  assertEqual(view.skins.ka0s.relativeWidth, 0.32, "the skins keep three to a line")
end)

test("appearance: the copy has its own heading, Other Ka0s addons, after the Scope, the tab ending on it", function()
  local _, Skin, lib = mediaEnv()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  local S = lib.APPEARANCE_STRINGS
  assertEqual(S.COPY_HEADING, "Other Ka0s addons")
  local all = flatten(ctx.scroll)
  local scopeH, copyH = indexOfText(all, S.SCOPE_HEADING), indexOfText(all, S.COPY_HEADING)
  assertTrue(copyH ~= nil, "the heading drawn")
  assertTrue(scopeH < indexOf(all, view.ignore.fonts) and indexOf(all, view.ignore.fonts) < copyH
    and copyH < indexOf(all, view.copy), "Scope, its check boxes, then the heading, then the button")
  local row = holderOf(ctx.scroll, view.copy)
  assertTrue(row ~= nil and row ~= ctx.scroll and #row.children == 1, "the button sits in a row of its own")
  assertEqual(view.copy.relativeWidth, half(O))
  assertTrue(indexOfText(all, S.COPY_NONE) > indexOf(all, view.copy), "the hint under it")
  assertTrue(indexOfText(all, S.COPY_NONE) == #all or indexOfText(all, S.COPY_NONE) > copyH,
    "nothing after the copy row but its hint")
end)

test("appearance: the note leads the Look section, ahead of the first skin", function()
  -- red under: minor 3, which drew it last, under the copy button (image-30).
  local _, Skin, lib = env()
  local store = register(Skin, OWNER)
  local O, ctx = page(lib, OWNER)
  local view = O.AppearanceRows(ctx, specFor(store))
  local S = lib.APPEARANCE_STRINGS
  local all = flatten(ctx.scroll)
  local look, note = indexOfText(all, S.SKIN_HEADING), indexOf(all, view.note)
  assertTrue(note ~= nil, "view.note is kept")
  assertEqual(view.note.text, S.NOTE)
  assertTrue(look < note and note < indexOf(all, view.skins[view.order[1]]), "under Look, before the skins")
  assertTrue(note < indexOfText(all, S.MEDIA_HEADING), "and before Font and texture")
end)
