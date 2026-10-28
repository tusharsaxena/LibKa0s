-- tests/test_options_compose_skin.lua — the group composers follow the skin on request
-- (OptionsCompose minor 12, OptionsWidgets minor 35, Skin minor 3; LK-07 of Ka0sAddonsCommonTasks
-- docs/2026-10-25-SKINNING, the plan review's resolution of the owner's ruling R3).
--
-- A suite of its own: tests/test_options_compose.lua is in the band and peels on the next
-- OptionsCompose minor that adds cases there (CLAUDE.md).
--
-- What is pinned:
--
--   * WITHOUT `fromSkin`, FontGroup / BorderGroup / BarGroup emit exactly the rows minor 11 emitted.
--   * WITH IT, one companion bool `<key>FromSkin` follows the canonical rows (default false, on a
--     line of its own); the picker is disabled while it is set and shows the skin's value, and the
--     companion writes and clears through the host's seam like any row.
--   * NO SENTINEL REACHES A LIST: the picker's values (the CLI's allowed values) are unchanged.
--   * Skin.ResetToSkin sets a companion to true rather than writing the sentinel into a pick.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")
local Skin = T.skin

local OWNER = "ComposeSkinHost"

local function paths(rows)
  local out = {}
  for i, r in ipairs(rows) do out[i] = r.path or r.field end
  return table.concat(out, ",")
end

local function rowAt(rows, path)
  for _, r in ipairs(rows) do if (r.path or r.field) == path then return r end end
  return nil
end

--- An instance whose descriptor names `owner`, over a plain store.
local function host(owner)
  local O, rec = Fixture.new({ addonName = owner })
  return O, rec
end

--- Every field of a row but its closures, as one comparable string.
local function shape(rows)
  local out = {}
  for _, r in ipairs(rows) do
    local keys = {}
    for k, v in pairs(r) do
      if type(v) ~= "function" and type(v) ~= "table" then keys[#keys + 1] = k .. "=" .. tostring(v) end
    end
    table.sort(keys)
    out[#out + 1] = table.concat(keys, ";")
  end
  return table.concat(out, "\n")
end

test("compose skin: OptionsCompose is at minor 12 or later, and OptionsWidgets at 35 or later", function()
  assertTrue(T.options.MODULES.OptionsCompose >= 12)
  assertTrue(T.options.MODULES.OptionsWidgets >= 35)
end)

test("compose skin: without fromSkin the three groups emit exactly the rows they did", function()
  local O = host(OWNER)
  assertEqual(paths(O.FontGroup({ prefix = "t." })),
    "t.font,t.fontSize,t.fontColor,t.useClassColorFont,t.fontFlags,t.fontShadow")
  assertEqual(paths(O.BorderGroup({ prefix = "b." })), "b.borderStyle,b.borderSize,b.borderColor,b.useClassColorBorder")
  assertEqual(paths(O.BarGroup({ prefix = "r." })), "r.barTexture,r.barAlpha,r.barColor,r.useClassColorBar")
  for _, r in ipairs(O.FontGroup({ prefix = "t." })) do
    assertNil(r.disabledIf, (r.path or "?") .. " carries no disabledIf")
    assertNil(r.skinValue, (r.path or "?") .. " carries no skinValue")
  end
  assertEqual(shape(O.FontGroup({ prefix = "t.", fromSkin = false })), shape(O.FontGroup({ prefix = "t." })),
    "fromSkin = false is no fromSkin")
end)

test("compose skin: fromSkin appends one companion per picker, after the canonical rows", function()
  local O = host(OWNER)
  local font = O.FontGroup({ prefix = "t.", fromSkin = true })
  assertEqual(paths(font),
    "t.font,t.fontSize,t.fontColor,t.useClassColorFont,t.fontFlags,t.fontShadow,t.fontFromSkin")
  local c = rowAt(font, "t.fontFromSkin")
  assertEqual(c.type, "bool")
  assertEqual(c.label, "Use the skin's font")
  assertEqual(c.default, false)
  assertTrue(c.startsLine, "on a line of its own")
  assertEqual(rowAt(font, "t.font").disabledIf, "t.fontFromSkin", "the picker follows its companion")
  assertEqual(paths(O.BorderGroup({ prefix = "b.", fromSkin = true })),
    "b.borderStyle,b.borderSize,b.borderColor,b.useClassColorBorder,b.borderStyleFromSkin")
  assertEqual(rowAt(O.BorderGroup({ prefix = "b.", fromSkin = true }), "b.borderStyleFromSkin").label,
    "Use the skin's border")
  assertEqual(paths(O.BarGroup({ prefix = "r.", fromSkin = true })),
    "r.barTexture,r.barAlpha,r.barColor,r.useClassColorBar,r.barTextureFromSkin")
  assertEqual(rowAt(O.BarGroup({ prefix = "r.", fromSkin = true }), "r.barTextureFromSkin").label,
    "Use the skin's texture")
end)

test("compose skin: the canonical rows are unchanged beside the companion, and so is every list", function()
  local O = host(OWNER)
  local plain = O.FontGroup({ prefix = "t." })
  local skinned = O.FontGroup({ prefix = "t.", fromSkin = true })
  for i, r in ipairs(plain) do
    local s = skinned[i]
    assertEqual(s.path, r.path)
    assertEqual(s.label, r.label)
    assertEqual(s.default, r.default)
    assertEqual(type(s.values), type(r.values))
  end
  local picker = rowAt(skinned, "t.font")
  local list = type(picker.values) == "function" and picker.values() or picker.values
  for k, v in pairs(list or {}) do
    assertTrue(k ~= Skin.FROM_SKIN and v ~= Skin.FROM_SKIN, "no sentinel in the media list")
  end
end)

test("compose skin: omit and keys reach the companion like any canonical leaf", function()
  local O = host(OWNER)
  local rows = O.FontGroup({ prefix = "t.", fromSkin = true, omit = { fontFromSkin = true } })
  assertNil(rowAt(rows, "t.fontFromSkin"), "omitted")
  assertNil(rowAt(rows, "t.font").disabledIf, "and then the picker is not governed by it")
  local renamed = O.FontGroup({ prefix = "t.", fromSkin = true, keys = { font = "face" } })
  assertTrue(rowAt(renamed, "t.faceFromSkin") ~= nil, "the companion takes the picker's renamed key")
  assertEqual(rowAt(renamed, "t.face").disabledIf, "t.faceFromSkin")
end)

--- The widget labeled `label` anywhere under `w`.
local function widget(w, label)
  if type(w) ~= "table" then return nil end
  if w.labelText == label then return w end
  for _, c in ipairs(w.children or {}) do
    local found = widget(c, label)
    if found then return found end
  end
  return nil
end

local seq = 0

test("compose skin: the picker shows the skin's value while its companion is set, its own otherwise",
  function()
  if not Skin:IsOwner(OWNER) then Skin:RegisterOwner(OWNER) end
  local O, rec = host(OWNER)
  local picker = rowAt(O.FontGroup({ prefix = "t.", fromSkin = true }), "t.font")
  rec.store["t.font"] = "Ka0s Inter"
  assertNil(picker.skinValue(picker), "companion unset: the stored pick shows")
  rec.store["t.fontFromSkin"] = true
  assertEqual(picker.skinValue(picker), Skin:Token(OWNER, "hud.font"), "companion set: the skin's font")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(picker.skinValue(picker), Skin:ResolveSkin("obsidian")["hud.font"], "read at call time")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
end)

test("compose skin: a rendered picker is disabled while the companion is set and the companion writes",
  function()
  local O, rec = host(OWNER)
  local store = rec.store
  local rows = O.BarGroup({ prefix = "r.", fromSkin = true, page = "general", group = "Bar" })
  seq = seq + 1
  local ctx = O.CreatePanel("ComposeSkin" .. seq, "Compose skin", {})
  store["r.barTexture"] = "Smooth"
  O.RenderRows(ctx, rows)
  local picker = widget(ctx.scroll, "Bar texture")
  local companion = widget(ctx.scroll, "Use the skin's texture")
  assertTrue(picker ~= nil and companion ~= nil, "both rendered")
  assertFalse(picker.disabled == true, "companion unset: the picker is live")
  assertEqual(picker.value, "Smooth", "showing the stored pick")
  companion:__fire("OnValueChanged", true)
  assertEqual(store["r.barTextureFromSkin"], true, "the companion writes through the host's seam")
  assertTrue(picker.disabled, "and the picker is disabled")
  assertEqual(picker.value, Skin:Token(OWNER, "bar.texture"), "showing the skin's texture")
  assertEqual(store["r.barTexture"], "Smooth", "the stored pick is untouched")
  companion:__fire("OnValueChanged", false)
  assertEqual(store["r.barTextureFromSkin"], false, "and clears")
  assertFalse(picker.disabled)
  assertEqual(picker.value, "Smooth")
end)

test("compose skin: a record-backed group reads its companion from the record", function()
  local rec = { barTexture = "Smooth" }
  local O = host(OWNER)
  local rows = O.BarGroup({ fromSkin = true, bind = {
    record = function() return rec end, set = function(field, value) rec[field] = value end } })
  local picker, companion = rowAt(rows, "barTexture"), rowAt(rows, "barTextureFromSkin")
  assertTrue(companion ~= nil and companion.path == nil, "the companion is a record field")
  assertNil(picker.skinValue(picker))
  companion.set(true)
  assertEqual(rec.barTextureFromSkin, true)
  assertEqual(picker.skinValue(picker), Skin:Token(OWNER, "bar.texture"))
end)

test("compose skin: ResetToSkin sets companions to true and never writes the sentinel into a pick",
  function()
  local profile = { t = { font = "Ka0s Inter", fontFromSkin = false, color = { 1, 0, 0, 1 } },
                    b = { borderStyleFromSkin = false }, size = 12 }
  local n = Skin.ResetToSkin(profile, { "t.font", "b.borderStyleFromSkin", "t.color", "size" })
  assertEqual(n, 4)
  assertEqual(profile.t.font, "Ka0s Inter", "the pick is kept")
  assertEqual(profile.t.fontFromSkin, true, "its companion is set")
  assertEqual(profile.b.borderStyleFromSkin, true, "a companion named directly is set to true")
  assertEqual(profile.t.colorFromSkin, true, "a color still takes its companion")
  assertEqual(profile.size, Skin.FROM_SKIN, "a key with no companion still takes the sentinel")
end)

test("compose skin: Skin is at minor 3 or later", function()
  assertTrue(Skin.MINOR >= 3)
end)
