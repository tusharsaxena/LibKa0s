-- tests/test_options_skin_picker_faces.lua -- a skin picker row's name never stays blank
-- (OptionsSkinPicker.lua minor 4, LK-A2 of Ka0sAddonsCommonTasks
-- docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES, the owner's report of a blank Azeroth row).
--
-- What it pins: a refused SetFont (false, nil, or a raise) leaves a named row in the template's
-- face; only a nil answer that reads back as the face asked for counts as taken, since the kit's
-- SetFont answers nothing; every skin's body face, and no other, goes through lib.__PreloadFonts
-- before the list can show; every open, and a skin switch under an open list, dresses every row at
-- once and again next frame, font and text, through ""; a name that measures nothing next frame goes
-- to the template's face, and the next open tries its skin's again; and the degraded paths.
--
-- These pin what the library asks of the client and nothing of what the client draws. A fake cannot
-- show that a face which reports success paints, so the blank row itself is the owner's to re-check.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertFalse, K.assertNil

local Bench = dofile("tests/fixture_skin_picker.lua")
local OWNER = Bench.OWNER

local function faceOf(key) return "Fonts\\" .. key .. ".ttf" end

--- A fresh client whose LSM has every face, each row built with `refuse(path)`'s answer for SetFont
--- (absent: the kit's). `refuse` answers false, "nil", "raise" or nothing. Answers the bench.
local function bench(refuse)
  local m, Skin, lib = Bench.env()
  m.LibStub("LibSharedMedia-3.0", true).Fetch = function(_, _, key) return faceOf(key) end
  local create = m.CreateFrame
  m.CreateFrame = function(...)
    local f = create(...)
    local createFs = f.CreateFontString
    rawset(f, "CreateFontString", function(self, ...)
      local fs = createFs(self, ...)
      local setFont = fs.SetFont
      rawset(fs, "SetFont", function(s, path, size, flags)
        local how = refuse and refuse(path)
        if how == "raise" then error("cannot open " .. tostring(path)) end
        if how == "nil" then return nil end
        if how == false then return false end
        setFont(s, path, size, flags)
        return how
      end)
      return fs
    end)
    return f
  end
  local store = Bench.register(Skin, OWNER)
  local O = Bench.instance(lib, OWNER)
  return m, Skin, lib, O, store
end

local function rowsOf(f)
  local rows = {}
  for _, row in ipairs({ f.list:GetChildren() }) do
    if row.key then rows[#rows + 1] = row end
  end
  return rows
end

local function rowFor(f, key)
  for _, row in ipairs(rowsOf(f)) do
    if row.key == key then return row end
  end
end

--- Log what reaches `row`'s string: "font:<path>", "object" and "text:<text>", in order.
local function spy(row)
  local fs, log = row.text, {}
  for name, tag in pairs({ SetFont = "font", SetText = "text" }) do
    local stock = fs[name]
    rawset(fs, name, function(self, a, ...)
      log[#log + 1] = tag .. ":" .. tostring(a)
      return stock(self, a, ...)
    end)
  end
  local stock = fs.SetFontObject
  rawset(fs, "SetFontObject", function(self, a)
    log[#log + 1] = "object"
    return stock(self, a)
  end)
  return log
end

--- Measured width `w` for every row's name (the kit answers 0, unarmed).
local function armWidths(f, w)
  for _, row in ipairs(rowsOf(f)) do
    rawset(row.text, "GetStringWidth", function() return w end)
  end
end

local function runTimers(m)
  local due = m.__timers
  m.__timers = {}
  for _, t in ipairs(due) do if t.fn then t.fn() end end
end

local function fontPath(fs) return (fs:GetFont()) end

-- ── a refused SetFont ────────────────────────────────────────────────────────────────────────

for _, how in ipairs({ { "false", false }, { "nil", "nil" }, { "a raise", "raise" } }) do
  test("skin picker faces: a SetFont answering " .. how[1] .. " keeps a named row in the template's face", function()
    local azeroth = faceOf("Ka0s Open Sans Semibold")
    local _, Skin, _, O, store = bench(function(path)
      if path == azeroth then return how[2] end
      return true
    end)
    local f = O.SkinPicker(Bench.specFor(store))
    local row = rowFor(f, "azeroth")
    assertEqual(row.text:GetText(), Skin:GetSkin("azeroth").label, "the row keeps its name")
    assertEqual(row.text:GetFontObject(), "GameFontHighlight", "the template's face draws it")
    assertNil(fontPath(row.text), "no face of its own")
    assertEqual(fontPath(rowFor(f, "obsidian").text), faceOf("Ka0s Expressway"), "the next row keeps its own")
  end)
end

test("skin picker faces: a SetFont answering true, or nothing with the face read back, keeps the face", function()
  local _, _, _, O, store = bench(function() return true end)
  local f = O.SkinPicker(Bench.specFor(store))
  assertEqual(fontPath(rowFor(f, "azeroth").text), faceOf("Ka0s Open Sans Semibold"))
  local _, _, _, O2, store2 = bench()   -- the kit's SetFont answers nothing
  local f2 = O2.SkinPicker(Bench.specFor(store2))
  assertEqual(fontPath(rowFor(f2, "azeroth").text), faceOf("Ka0s Open Sans Semibold"))
end)

-- ── the preload ──────────────────────────────────────────────────────────────────────────────

test("skin picker faces: every skin's body face is preloaded before the list can open, and no other", function()
  local _, Skin, lib, O, store = bench()
  O.SkinPicker(Bench.specFor(store))
  local paths = lib.__fontPreload.paths
  local want = 0
  for _, def in ipairs(Skin:Skins()) do
    local face = faceOf(Skin:ResolveSkin(def.key)["font.body"])
    assertTrue(paths[face], def.key .. ": its face went through the preload")
  end
  for _ in pairs(paths) do want = want + 1 end
  local distinct = {}
  for _, def in ipairs(Skin:Skins()) do distinct[Skin:ResolveSkin(def.key)["font.body"]] = true end
  local n = 0
  for _ in pairs(distinct) do n = n + 1 end
  assertEqual(want, n, "only the skins' faces: a player who never opens settings pays for no other")
end)

test("skin picker faces: a copy without the preload shows its rows", function()
  local _, _, lib, O, store = bench()
  lib.__PreloadFonts = nil
  local f = O.SkinPicker(Bench.specFor(store))
  assertEqual(#rowsOf(f) > 0, true)
end)

-- ── the redress ──────────────────────────────────────────────────────────────────────────────

test("skin picker faces: every open dresses each row, then again next frame, font and text through an empty string", function()
  local m, Skin, _, O, store = bench()
  local f = O.SkinPicker(Bench.specFor(store))
  armWidths(f, 40)
  local row = rowFor(f, "azeroth")
  local log = spy(row)
  local name, face = Skin:GetSkin("azeroth").label, faceOf("Ka0s Open Sans Semibold")
  local one = { "font:" .. face, "text:", "text:" .. name }
  for open = 1, 2 do
    m.__timers = {}
    for i = #log, 1, -1 do log[i] = nil end
    f.dd:__fire("OnClick")
    assertEqual(table.concat(log, "|"), table.concat(one, "|"), "open " .. open .. ": dressed at once")
    runTimers(m)
    assertEqual(#log, 6, "open " .. open .. ": and again next frame")
    assertEqual(log[6], "text:" .. name)
    f.dd:__fire("OnClick")   -- closes it
  end
  assertEqual(row.text:GetText(), name)
  assertEqual(fontPath(row.text), face)
end)

test("skin picker faces: a list closed before the next frame is left alone", function()
  local m, _, _, O, store = bench()
  local f = O.SkinPicker(Bench.specFor(store))
  armWidths(f, 40)
  m.__timers = {}
  f.dd:__fire("OnClick")
  f.dd:__fire("OnClick")
  local log = spy(rowFor(f, "azeroth"))
  runTimers(m)
  assertEqual(#log, 0)
end)

test("skin picker faces: a closed list is not dressed by a repaint", function()
  local m, Skin, _, O, store = bench()
  local f = O.SkinPicker(Bench.specFor(store))
  local log = spy(rowFor(f, "azeroth"))
  m.__timers = {}
  Skin:SetChoice(OWNER, "ka0s", "ember")
  runTimers(m)
  assertEqual(#log, 0)
end)

test("skin picker faces: a skin switch under an open list dresses each row, which keep their names and faces", function()
  local m, Skin, _, O, store = bench()
  local f = O.SkinPicker(Bench.specFor(store))
  armWidths(f, 40)
  f.dd:__fire("OnClick")
  runTimers(m)
  local row = rowFor(f, "azeroth")
  local log = spy(row)
  Skin:SetChoice(OWNER, "ka0s", "ember")
  assertTrue(#log >= 3, "dressed at once")
  local now = #log
  runTimers(m)
  assertTrue(#log > now, "and again next frame")
  assertEqual(row.text:GetText(), Skin:GetSkin("azeroth").label)
  assertEqual(fontPath(row.text), faceOf("Ka0s Open Sans Semibold"))
end)

test("skin picker faces: a pick's repaint leaves the next open dressing every row", function()
  local m, _, _, O, store = bench()
  local f = O.SkinPicker(Bench.specFor(store))
  armWidths(f, 40)
  f.dd:__fire("OnClick")
  rowFor(f, "ember"):__fire("OnClick")
  assertFalse(f.list:IsShown(), "the pick closed it")
  local log = spy(rowFor(f, "azeroth"))
  m.__timers = {}
  f.dd:__fire("OnClick")
  assertEqual(#log, 3)
  runTimers(m)
  assertEqual(#log, 6)
end)

test("skin picker faces: a later showing of the same window still dresses on open", function()
  local m, _, _, O, store = bench()
  local spec = Bench.specFor(store)
  local f = O.SkinPicker(spec)
  armWidths(f, 40)
  O.HideSkinPicker()
  O.SkinPicker(spec)
  local log = spy(rowFor(f, "azeroth"))
  m.__timers = {}
  f.dd:__fire("OnClick")
  runTimers(m)
  assertEqual(#log, 6)
end)

test("skin picker faces: a host's name for a skin survives the redress", function()
  local m, _, _, O, store = bench()
  local f = O.SkinPicker(Bench.specFor(store, { strings = { SKIN_azeroth = "Azeroth!" } }))
  armWidths(f, 40)
  f.dd:__fire("OnClick")
  runTimers(m)
  assertEqual(rowFor(f, "azeroth").text:GetText(), "Azeroth!")
end)

test("skin picker faces: a name that measures nothing next frame takes the template's face, and the next open tries its own", function()
  local m, Skin, _, O, store = bench()
  local f = O.SkinPicker(Bench.specFor(store))
  armWidths(f, 40)
  local row = rowFor(f, "azeroth")
  rawset(row.text, "GetStringWidth", function() return 0 end)
  local name = Skin:GetSkin("azeroth").label
  f.dd:__fire("OnClick")
  runTimers(m)
  assertEqual(row.text:GetFontObject(), "GameFontHighlight", "SetFont said yes and drew nothing")
  assertEqual(row.text:GetText(), name)
  assertEqual(fontPath(rowFor(f, "ember").text), faceOf(Skin:ResolveSkin("ember")["font.body"]), "the others keep theirs")
  f.dd:__fire("OnClick")
  rawset(row.text, "GetStringWidth", function() return 40 end)
  f.dd:__fire("OnClick")
  runTimers(m)
  assertEqual(fontPath(row.text), faceOf("Ka0s Open Sans Semibold"), "the face that loaded since is worn")
end)

test("skin picker faces: a client without C_Timer dresses at once and raises nothing", function()
  local m, _, _, O, store = bench()
  local f = O.SkinPicker(Bench.specFor(store))
  m.C_Timer = nil
  local log = spy(rowFor(f, "azeroth"))
  f.dd:__fire("OnClick")
  assertEqual(#log, 3)
  assertTrue(f.list:IsShown())
end)
