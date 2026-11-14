-- tests/test_callout_schema.lua — LibKa0s-Callout-1.0 on a Ka0s host's write route (plan row L11):
-- Callout minor 2's `d.path` / `d.set` and leaf keys, and CalloutSettings minor 3's `SchemaRows` and
-- the Options build whose rows carry their paths (architecture-§5).
--
-- The host is real: a LibKa0s-Schema-1.0 instance over a profile table, the call-out's rows
-- registered in it under "callout.", the drag's point in its `writeThrough`, and a recording seam in
-- front of its Set. The call-out's `d.db` hands out a fresh deep copy of the profile's table on every
-- read, so a write the instance made into its own db would land in a copy nobody keeps: whatever
-- reaches the profile went through the host's seam, which is the property under test.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local F = dofile("tests/fixture_callout.lua")
local Fixture = dofile("tests/fixture_options.lua")
local newCallout, parts, tts = F.newCallout, F.parts, F.tts
local Schema = T.schema

local PREFIX = "callout."

local function deepCopy(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, x in pairs(v) do out[k] = deepCopy(x) end
  return out
end

local function rowsByPath(rows)
  local out = {}
  for _, r in ipairs(rows) do out[r.path] = r end
  return out
end

--- A Ka0s host around a call-out: `host.profile.callout` seeded from the rows' defaults, the rows in
--- a Schema instance, and `host.writes` listing every path that reached the seam, in order.
--- `d` overrides the call-out's descriptor; `before(m)` runs before the files load.
local function hostCallout(d, before)
  local host = { profile = { callout = {} }, writes = {}, announced = {} }
  local desc = {
    path = PREFIX,
    db = function() return deepCopy(host.profile.callout) end,
    set = function(path, value) return host.Set(path, value) end,
  }
  for k, v in pairs(d or {}) do desc[k] = v end
  local c, m, _, logs, Callout = newCallout(desc, before)
  local rows, named = c:SchemaRows(PREFIX)
  host.rows, host.named = rows, named
  host.S = Schema:New({
    rows = rows,
    resolveRoot = function() return host.profile, 1 end,
    writeThrough = named,
    announce = function(_, path) host.announced[#host.announced + 1] = path end,
  })
  function host.Set(path, value)
    host.writes[#host.writes + 1] = path
    return host.S.Set(path, value)
  end
  for _, r in ipairs(rows) do
    if not r.sessionOnly then Schema.Write(host.profile, r.path, deepCopy(r.default)) end
  end
  return c, host, m, logs, Callout
end

--- The host's Options instance, reading and writing through the host's Schema (as a Ka0s host's
--- descriptor does: `get = NS.GetByPath`, `set = NS.SetByPath`).
local pageSeq = 0
local function hostPage(host)
  pageSeq = pageSeq + 1
  local O = Fixture.new({
    get = function(path) return host.S.Get(path) end,
    set = function(path, value) return host.Set(path, value) end,
    findRow = function(path) return host.S.FindRow(path) end,
  })
  local ctx = O.CreatePanel("CalloutSchemaBench" .. pageSeq, "Call-out " .. pageSeq, {})
  return O, ctx, O.EnsureScroll(ctx)
end

local function widgetLabeled(scroll, label)
  for _, w in ipairs(Fixture.flatten(scroll)) do
    if w.labelText == label then return w end
  end
end

local function widgetTexted(scroll, wtype, text)
  for _, w in ipairs(Fixture.flatten(scroll)) do
    if w.type == wtype and w.text == text then return w end
  end
end

-- ── the rows ─────────────────────────────────────────────────────────────────────────────────

--- A stored row's own fields: no `set` (the host stores it), a `get` on a color row alone (the
--- stored color in either shape, answered in the host's), a validate and an onChange.
local function assertStoredRow(r)
  if r.type == "color" then
    assertEqual(type(r.get), "function", r.path .. " reads the stored color in either shape")
  else
    assertNil(r.get, r.path .. " has no get of its own: the host stores it")
  end
  assertNil(r.set, r.path .. " has no set of its own: the host stores it")
  assertEqual(type(r.validate), "function", r.path .. " validates")
  assertEqual(type(r.onChange), "function", r.path .. " reacts")
end

test("callout schema: SchemaRows answers a row with a path under the prefix for every setting a control chooses", function()
  local c, _, _, _, Callout = newCallout()
  local rows, named = c:SchemaRows("co")
  local paths = {}
  for _, r in ipairs(rows) do
    assertTrue(type(r.path) == "string" and r.path:sub(1, 3) == "co.", tostring(r.key) .. " carries a path under the prefix")
    assertEqual(r.path, "co." .. r.key, r.key .. "'s path is the prefix and its key")
    assertNil(paths[r.path], r.path .. " is answered once")
    paths[r.path] = true
    assertTrue(type(r.group) == "string" and r.group ~= "", r.path .. " has a group (options-ui-§13)")
    assertTrue(r.type == "bool" or r.type == "number" or r.type == "string" or r.type == "color", r.path .. "'s type")
    if not r.sessionOnly then assertStoredRow(r) end
  end
  assertEqual(#named, 1)
  assertEqual(named[1], "co.point", "the drag's point is the named state beside the rows")
  local want = 0
  for _, key in ipairs(Callout.SETTINGS) do
    if key ~= "point" and key ~= "texts" and key ~= "muted" then
      want = want + 1
      assertTrue(paths["co." .. key], key .. " has a row")
    end
  end
  for _, kind in ipairs(Callout.KINDS) do assertTrue(paths["co.colors." .. kind], kind .. "'s color has a row") end
  for _, key in ipairs(Callout.STOCK_ORDER) do
    assertTrue(paths["co.texts." .. key], key .. "'s own text has a row")
    assertTrue(paths["co.muted." .. key], key .. "'s mute has a row")
  end
  assertTrue(paths["co.play"] and paths["co.unlocked"], "the two session rows")
  assertEqual(#rows, want + #Callout.KINDS + 2 * #Callout.STOCK_ORDER + 2)
end)

--- A color's channels in either stored shape, as one string.
local function channels(c) return table.concat({ c.r or c[1], c.g or c[2], c.b or c[3] }, ",") end

local SKIP_SAME = { texts = true, muted = true, glowColor = true }   -- glowColor: by its channels

test("callout schema: every stored row's default is what the instance reads with nothing stored", function()
  local c, _, _, _, Callout = newCallout()
  local rows = c:SchemaRows(PREFIX)
  local by = rowsByPath(rows)
  for _, key in ipairs(Callout.SETTINGS) do
    local r = by[PREFIX .. key]
    if r and key ~= "glowColor" then   -- a color's default is in the host's shape, below
      assertTrue(Schema.SameValue(r.default, Callout.DEFAULTS[key]), key .. "'s default is DEFAULTS'")
      assertTrue(r.validate(r.default), key .. "'s default passes its own validate")
    end
  end
  local gd = by[PREFIX .. "glowColor"].default
  assertEqual(gd.r .. "," .. gd.g .. "," .. gd.b, table.concat(Callout.DEFAULTS.glowColor, ","), "the glow's DEFAULTS color")
  for _, kind in ipairs(Callout.KINDS) do
    local d, want = by[PREFIX .. "colors." .. kind].default, Callout.DEFAULTS.colors[kind]
    assertEqual(d.r .. "," .. d.g .. "," .. d.b, table.concat(want, ","), kind .. ": DEFAULTS' color")
  end
  for _, key in ipairs(Callout.STOCK_ORDER) do
    assertEqual(by[PREFIX .. "texts." .. key].default, "", key .. ": no own text")
    assertFalse(by[PREFIX .. "muted." .. key].default, key .. ": not muted")
  end
  -- A profile seeded from the rows reads exactly as an empty one: the defaults are DEFAULTS'.
  local seeded = {}
  for _, r in ipairs(rows) do
    if not r.sessionOnly then Schema.Write(seeded, r.path, deepCopy(r.default)) end
  end
  local a = newCallout({ db = seeded.callout })
  local b = newCallout({ db = {} })
  for _, key in ipairs(Callout.SETTINGS) do
    if not SKIP_SAME[key] then
      assertTrue(Schema.SameValue(a:Get(key), b:Get(key)), key .. " reads the same")
    end
  end
  for _, key in ipairs(Callout.STOCK_ORDER) do
    assertEqual(a:Get("texts." .. key), b:Get("texts." .. key))
    assertEqual(a:Get("muted." .. key), b:Get("muted." .. key))
  end
  assertEqual(channels(a:Get("glowColor")), channels(b:Get("glowColor")), "glowColor reads the same channels")
  for _, kind in ipairs(Callout.KINDS) do
    assertEqual(table.concat({ a:GetColor(kind) }, ","), table.concat({ b:GetColor(kind) }, ","), kind)
  end
end)

test("callout schema: the host's Validate resolves every row against defaults built from them", function()
  local c = newCallout()
  local rows = c:SchemaRows(PREFIX)
  local defaults = {}
  for _, r in ipairs(rows) do
    if not r.sessionOnly then Schema.Write(defaults, r.path, deepCopy(r.default)) end
  end
  local printed = {}
  local S = Schema:New({ rows = rows, print = function(l) printed[#printed + 1] = l end })
  local errors, resolved, missing = S.Validate({ defaultsRoot = function() return defaults, 1 end })
  assertEqual(errors, 0, table.concat(printed, " | "))
  assertEqual(missing, 0)
  assertTrue(resolved > 60, "every stored row resolved")
end)

test("callout schema: the voice row offers and defaults to the packs the host ships", function()
  local c = newCallout({ packs = { "callout/male-joe" } })
  local by = rowsByPath(c:SchemaRows(PREFIX))
  local voice = by[PREFIX .. "voice"]
  local keys = {}
  for i, v in ipairs(voice.values()) do keys[i] = v.value end
  assertEqual(table.concat(keys, ","), "male,tts,off", "only the shipped pack, then text to speech and off")
  assertEqual(voice.default, "male", "the default pack is not shipped: the first pack that is")
  assertFalse(voice.validate("female"), "a pack the host does not ship is refused")
  assertTrue(voice.validate("tts"))
  local none = rowsByPath(newCallout({ packs = {} }):SchemaRows(PREFIX))[PREFIX .. "voice"]
  assertEqual(none.default, "off", "no pack shipped: off")
end)

test("callout schema: the choice rows refuse what the instance refuses, and texts are trimmed", function()
  local c = newCallout()
  local by = rowsByPath(c:SchemaRows(PREFIX))
  assertFalse(by[PREFIX .. "size"].validate(500))
  assertTrue(by[PREFIX .. "size"].validate(120))
  assertFalse(by[PREFIX .. "outline"].validate("THIN"))
  assertFalse(by[PREFIX .. "speakFrom"].validate(2.5))
  assertTrue(by[PREFIX .. "ttsVoice"].validate(false), "false is the client's first voice")
  assertFalse(by[PREFIX .. "colors.go"].validate({}), "a color with no channels")
  assertTrue(by[PREFIX .. "colors.go"].validate({ r = 1, g = 0, b = 0, a = 1 }), "named keys")
  assertTrue(by[PREFIX .. "colors.go"].validate({ 1, 0, 0 }), "an array")
  assertFalse(by[PREFIX .. "muted.GO"].validate("yes"))
  assertEqual(by[PREFIX .. "texts.GO"].normalize("  Charge  "), "Charge")
  assertEqual(by[PREFIX .. "font"].dialogControl, "Ka0sMedia_Font")
  assertEqual(type(by[PREFIX .. "font"].values), "function")
  local size = by[PREFIX .. "size"]
  assertEqual(size.min .. "," .. size.max .. "," .. size.step, "32,200,1")
end)

test("callout schema: the text to speech rows are schema rows whatever the client lists", function()
  local c = newCallout()
  local by = rowsByPath(c:SchemaRows(PREFIX))
  assertTrue(by[PREFIX .. "ttsVoice"] ~= nil and by[PREFIX .. "ttsRate"] ~= nil and by[PREFIX .. "ttsVolume"] ~= nil,
    "the settings exist with no voice on this client")
  assertEqual(#by[PREFIX .. "ttsVoice"].values(), 0)
  local c2 = newCallout(nil, function(m) tts(m, { { voiceID = 3, name = "Zira" } }) end)
  local v = rowsByPath(c2:SchemaRows(PREFIX))[PREFIX .. "ttsVoice"].values()
  assertFalse(v[1].value, "the default, the client's first voice, leads")
  assertEqual(v[1].text, "Default (Zira)")
  assertEqual(v[2].value .. "," .. v[2].text, "3,Zira", "the choices are read when they are drawn")
end)

test("callout schema: SchemaRows takes the descriptor's path when given none, and refuses with neither", function()
  local c = newCallout({ path = "race.callout" })
  local rows, named = c:SchemaRows()
  assertEqual(rows[1].path:sub(1, 13), "race.callout.")
  assertEqual(named[1], "race.callout.point")
  local bare = newCallout()
  local ok, err = pcall(bare.SchemaRows, bare)
  assertFalse(ok)
  assertTrue(tostring(err):find("prefix", 1, true) ~= nil, "the refusal names the prefix")
  local paged = newCallout():SchemaRows(PREFIX, { page = "race" })
  for _, r in ipairs(paged) do assertEqual(r.page, "race") end
end)

test("callout schema: New refuses a d.set with no d.path", function()
  local ok, err = pcall(newCallout, { set = function() end })
  assertFalse(ok)
  assertTrue(tostring(err):find("d.path", 1, true) ~= nil)
end)

-- ── the host's route ─────────────────────────────────────────────────────────────────────────

test("callout schema: on the host's route every write the instance makes goes through the host's seam", function()
  local c, host = hostCallout()
  assertTrue(c:Set("size", 120))
  assertEqual(host.profile.callout.size, 120, "the seam stored it")
  assertEqual(c:Get("size"), 120, "and the instance reads it back off its db")
  assertTrue(c:Set("texts.GO", "Charge"))
  assertEqual(host.profile.callout.texts.GO, "Charge")
  assertTrue(c:Set("muted.STOP", true))
  assertTrue(host.profile.callout.muted.STOP)
  assertTrue(c:SetColor("go", 0, 0, 1))
  local go = host.profile.callout.colors.go
  assertEqual(go.r .. "," .. go.g .. "," .. go.b .. "," .. go.a, "0,0,1,1", "the color in the host's (named) shape")
  assertEqual(table.concat({ c:GetColor("go") }, ","), "0,0,1")
  assertTrue(c:Set("size", nil))
  assertEqual(host.profile.callout.size, 96, "nil writes the default through the seam")
  assertTrue(c:SetColor("go"))
  assertEqual(host.profile.callout.colors.go.g, 1, "a cleared color is its default, through the seam")
  assertTrue(c:Set("texts.GO", nil))
  assertEqual(host.profile.callout.texts.GO, "")
  assertEqual(table.concat(host.writes, ","),
    "callout.size,callout.texts.GO,callout.muted.STOP,callout.colors.go,callout.size,callout.colors.go,callout.texts.GO")
  assertEqual(#host.announced, #host.writes, "and the host announced each")
end)

test("callout schema: a whole texts or muted table on the host's route is one write per stock key", function()
  local c, host, _, _, Callout = hostCallout()
  assertTrue(c:Set("texts", { GO = "Charge", STOP = "Halt" }), "the whole-table form still writes")
  assertEqual(host.profile.callout.texts.GO, "Charge")
  assertEqual(host.profile.callout.texts.STOP, "Halt")
  assertEqual(host.profile.callout.texts.READY, "", "a key the table leaves out is its default")
  assertEqual(c:Get("texts").GO, "Charge", "and the instance reads it back")
  assertEqual(#host.writes, #Callout.STOCK_ORDER, "one leaf write per stock key")
  for i, key in ipairs(Callout.STOCK_ORDER) do assertEqual(host.writes[i], PREFIX .. "texts." .. key) end
  assertTrue(c:Set("muted", { GO = true }))
  assertTrue(host.profile.callout.muted.GO)
  assertFalse(host.profile.callout.muted.STOP)
  assertTrue(c:Set("texts", nil), "nil puts every key's default back")
  assertEqual(host.profile.callout.texts.GO, "")
  assertEqual(host.profile.callout.texts.STOP, "")
  assertTrue(c:Set("muted", nil))
  assertFalse(host.profile.callout.muted.GO)
  assertFalse(c:Set("texts", { GO = 5 }), "an invalid table is refused before any write")
  assertEqual(host.profile.callout.texts.GO, "")
  local h2
  local refusing
  refusing, h2 = hostCallout({ set = function(path, v)
    if path == PREFIX .. "texts.STOP" then return false end
    return h2.Set(path, v)
  end })
  assertFalse(refusing:Set("texts", { GO = "A", STOP = "B" }), "one refused leaf is a refused write")
  assertEqual(h2.profile.callout.texts.GO, "A", "the leaves the seam took are written")
end)

test("callout schema: a stored array color shows its own color in the host's swatch", function()
  local c, host = hostCallout()
  host.profile.callout.colors.go = { 0.3, 0.2, 0.1 }   -- what a minor-1 instance wrote into d.db
  assertEqual(table.concat({ c:GetColor("go") }, ","), "0.3,0.2,0.1")
  local got = host.S.Get(PREFIX .. "colors.go")
  assertEqual(got.r .. "," .. got.g .. "," .. got.b .. "," .. got.a, "0.3,0.2,0.1,1", "read in the host's shape")
  local O, ctx, scroll = hostPage(host)
  c:BuildSettings(ctx, { options = O, tab = "texts" })
  local sw = widgetLabeled(scroll, "Go").color
  assertEqual(sw.r .. "," .. sw.g .. "," .. sw.b, "0.3,0.2,0.1", "the swatch and the call-out agree")
  widgetLabeled(scroll, "Go"):__fire("OnValueConfirmed", 0.5, 0.25, 0.5, 1)
  assertEqual(host.profile.callout.colors.go.g, 0.25, "a write still stores through the seam")
end)

test("callout schema: a color row's reader counts a profile at its defaults as unchanged", function()
  local _, host = hostCallout()
  assertEqual(host.S.CountOffDefault(), 0, "the seeded defaults")
  for _, kind in ipairs({ "go", "stop" }) do
    local d = host.S.FindRow(PREFIX .. "colors." .. kind).default
    host.profile.callout.colors[kind] = { d.r, d.g, d.b }   -- the default, in the array shape
  end
  assertEqual(host.S.CountOffDefault(), 0, "a default color stored as an array is still the default")
  host.S.Set(PREFIX .. "colors.go", { r = 0, g = 0, b = 1, a = 1 })
  assertEqual(host.S.CountOffDefault(), 1)
  local _, host2 = hostCallout({ colorEncode = function(r, g, b) return { r, g, b, 1 } end })
  assertEqual(host2.S.CountOffDefault(), 0, "the host's own shape, at its defaults")
end)

test("callout schema: the text to speech voice dropdown names the voice spoken at its default", function()
  local c, host = hostCallout(nil, function(m) tts(m, { { voiceID = 7, name = "Zira" }, { voiceID = 9, name = "David" } }) end)
  assertFalse(host.profile.callout.ttsVoice, "the stored default: the client's first voice")
  local O, ctx, scroll = hostPage(host)
  c:BuildSettings(ctx, { options = O, tab = "sound" })
  local dd = widgetLabeled(scroll, "Text to speech voice")
  assertFalse(dd.value, "the dropdown reads the stored value")
  assertEqual(dd.list[false], "Default (Zira)", "and the default has a label naming the voice spoken")
  assertEqual(dd.order[1], false)
  assertEqual(dd.list[9], "David")
  assertEqual(host.S.CountOffDefault(), 0, "the default is not counted as changed")
  dd:__fire("OnValueChanged", 9)
  assertEqual(host.profile.callout.ttsVoice, 9)
  dd:__fire("OnValueChanged", false)
  assertFalse(host.profile.callout.ttsVoice, "the default can be picked again")
end)

test("callout schema: a value the host's seam refuses is no write, and the instance says so", function()
  local c, host = hostCallout({ set = function() return false, "no" end })
  assertFalse(c:Set("size", 120))
  assertEqual(host.profile.callout.size, 96)
  assertFalse(c:Set("size", 999), "the instance's own refusal comes first")
end)

test("callout schema: a drag's point and Reset position go through the host's seam", function()
  local c, host, m = hostCallout()
  local f = parts(c)
  c:SetLocked(false)
  f:__fire("OnDragStart")
  f:SetPoint("TOPLEFT", m.UIParent, "TOPLEFT", 40, -60)
  f:__fire("OnDragStop")
  assertEqual(host.writes[#host.writes], "callout.point", "the drag wrote through the seam")
  assertEqual(host.profile.callout.point[1], "TOPLEFT")
  assertEqual(host.profile.callout.point[4], -60)
  c:SetLocked(true)
  c:ResetPosition()
  assertEqual(host.writes[#host.writes], "callout.point")
  assertEqual(table.concat(host.profile.callout.point, ","), "CENTER,CENTER,0,180", "the default point")
  assertEqual(rawget(f, "__point")[1], "CENTER", "and the frame is back on it")
end)

test("callout schema: a raising host seam under a drag reaches the error handler, not the drag", function()
  local c, _, m = hostCallout({ set = function() error("seam down") end })
  local f = parts(c)
  c:SetLocked(false)
  f:__fire("OnDragStart")
  f:__fire("OnDragStop")
  assertEqual(#m.__errors, 1)
  assertTrue(tostring(m.__errors[1]):find("seam down", 1, true) ~= nil)
end)

test("callout schema: a host write by path reacts on the call-out (slash set reaches it)", function()
  local c, host = hostCallout()
  local _, text = parts(c)
  assertEqual(select(2, text:GetFont()), 96)
  assertTrue(host.S.Set(PREFIX .. "size", 140))
  assertEqual(select(2, text:GetFont()), 140, "the row's onChange applied it")
  assertTrue(host.S.Set(PREFIX .. "outline", "NONE"))
  assertEqual(select(3, text:GetFont()), "")
  assertFalse(host.S.Set(PREFIX .. "size", 900), "the seam refuses what the instance refuses")
  local row = host.S.FindRow(PREFIX .. "size")
  assertTrue(host.S.ApplyDefault(row))
  assertEqual(select(2, text:GetFont()), 96, "a reset reaches it too")
end)

-- ── the Options build on the host's route ────────────────────────────────────────────────────

test("callout schema: the Options build on the host's route draws rows that carry their paths", function()
  local c, host = hostCallout()
  local O, ctx = hostPage(host)
  local view = c:BuildSettings(ctx, { options = O })
  assertEqual(view.prefix, PREFIX)
  assertTrue(#view.rows > 50)
  for _, r in ipairs(view.rows) do
    assertTrue(type(r.path) == "string", r.label .. " carries its path")
    assertTrue(host.S.FindRow(r.path) ~= nil, r.path .. " is a row the host registered")
  end
end)

test("callout schema: a widget's change writes only through the host's seam, and the call-out follows", function()
  local c, host = hostCallout()
  local O, ctx, scroll = hostPage(host)
  local view = c:BuildSettings(ctx, { options = O, tab = "look" })
  local _, text = parts(c)
  widgetLabeled(scroll, "Outline"):__fire("OnValueChanged", "MONOCHROME")
  assertEqual(host.writes[#host.writes], "callout.outline")
  assertEqual(host.profile.callout.outline, "MONOCHROME")
  assertEqual(select(3, text:GetFont()), "MONOCHROME", "the row's onChange applied it to the frame")
  widgetLabeled(scroll, "Shadow"):__fire("OnValueChanged", false)
  assertFalse(host.profile.callout.shadow)
  local before = view.preview.text
  host.S.Set(PREFIX .. "colors.go", { r = 0, g = 0, b = 1, a = 1 })
  O.RefreshScalars()
  assertFalse(view.preview.text == before, "the preview repaints off the host's write")
  assertTrue(view.preview.text:find("0000ff", 1, true) ~= nil)
end)

test("callout schema: the Texts tab's boxes, mutes and swatches write through the host's seam", function()
  local c, host = hostCallout()
  local O, ctx, scroll = hostPage(host)
  c:BuildSettings(ctx, { options = O, tab = "texts" })
  widgetLabeled(scroll, "READY"):__fire("OnEnterPressed", "  Set  ")
  assertEqual(host.profile.callout.texts.READY, "Set", "normalized by the row, through the seam")
  widgetLabeled(scroll, "Mute STOP"):__fire("OnValueChanged", true)
  assertTrue(host.profile.callout.muted.STOP)
  widgetLabeled(scroll, "Numbers"):__fire("OnValueConfirmed", 0.5, 0.25, 0.5, 1)
  assertEqual(host.profile.callout.colors.number.g, 0.25)
  assertEqual(select(2, c:GetColor("number")), 0.25, "the instance reads the host's shape")
  for _, p in ipairs(host.writes) do assertEqual(p:sub(1, #PREFIX), PREFIX) end
end)

test("callout schema: the preview block's session rows and buttons work on the host's route", function()
  local c, host, m = hostCallout()
  local O, ctx, scroll = hostPage(host)
  c:BuildSettings(ctx, { options = O, tab = "sound" })
  widgetLabeled(scroll, "Unlock to move"):__fire("OnValueChanged", true)
  assertFalse(c:Locked(), "the session row unlocks, through the seam")
  assertEqual(host.writes[#host.writes], "callout.unlocked")
  assertNil(host.profile.callout.unlocked, "and nothing is stored")
  widgetLabeled(scroll, "Unlock to move"):__fire("OnValueChanged", false)
  assertTrue(c:Locked())
  widgetLabeled(scroll, "Text to play"):__fire("OnValueChanged", "MOVE")
  widgetTexted(scroll, "Button", "Play"):__fire("OnClick")
  local f, text = parts(c)
  assertTrue(f:IsShown())
  assertEqual(text:GetText(), "MOVE")
  m.__now = 100
  widgetTexted(scroll, "Button", "Test countdown"):__fire("OnClick")
  assertTrue((c:Running()))
  c:Cancel()
  widgetTexted(scroll, "Button", "Reset position"):__fire("OnClick")
  assertEqual(host.writes[#host.writes], "callout.point")
end)

test("callout schema: SettingsTabs on the host's route hands its prefix to each tab", function()
  local c, host = hostCallout({ path = "other." })
  local O, ctx, scroll = hostPage(host)
  -- The descriptor names "other.", the tabs "callout.": the tabs' prefix is the one drawn.
  local tabs = c:SettingsTabs({ options = O, prefix = PREFIX })
  tabs[1].render(ctx)
  widgetLabeled(scroll, "Glow behind the text"):__fire("OnValueChanged", false)
  assertEqual(host.profile.callout.glow, false)
end)

-- ── the leaf keys, off the host's route ──────────────────────────────────────────────────────

test("callout schema: the leaf keys read and write one entry of d.db, as minor 1's tables", function()
  local c, _, db = newCallout()
  assertEqual(c:Get("texts.GO"), "", "no own text")
  assertFalse(c:Get("muted.GO"))
  assertEqual(c:Get("colors.go")[2], 1, "a kind's color, array half")
  assertEqual(c:Get("colors.go").g, 1, "and named half")
  assertTrue(c:Set("texts.GO", "Charge"))
  assertEqual(db.texts.GO, "Charge")
  assertTrue(c:Set("texts.GO", nil))
  assertNil(db.texts.GO, "nil removes it")
  assertTrue(c:Set("muted.STOP", true))
  assertTrue(db.muted.STOP)
  assertFalse(c:Set("texts.NOPE", "x"), "no such stock key")
  assertFalse(c:Set("colors.purple", { 1, 0, 0 }), "no such kind")
  assertFalse(c:Set("muted.GO", "yes"))
  assertTrue(c:SetColor("go", 0.1, 0.2, 0.3))
  assertEqual(table.concat(db.colors.go, ","), "0.1,0.2,0.3", "an array into d.db, as before")
  assertNil(c:Get("texts.nope"))
end)

test("callout schema: a stored color is read in either shape", function()
  local c, _, db = newCallout()
  db.colors = { go = { r = 0.1, g = 0.2, b = 0.3, a = 1 }, stop = { 0.4, 0.5, 0.6 } }
  assertEqual(table.concat({ c:GetColor("go") }, ","), "0.1,0.2,0.3")
  assertEqual(table.concat({ c:GetColor("stop") }, ","), "0.4,0.5,0.6")
  db.colors.warn = { r = "x" }
  assertEqual(table.concat({ c:GetColor("warn") }, ","), "1,0.78,0.2", "neither shape: the default")
end)

test("callout schema: a host's colorEncode decides the shape the instance writes", function()
  local c, host = hostCallout({ colorEncode = function(r, g, b) return { r, g, b, 1 } end })
  c:SetColor("stop", 0.2, 0.3, 0.4)
  assertEqual(table.concat(host.profile.callout.colors.stop, ","), "0.2,0.3,0.4,1")
  assertEqual(table.concat({ c:GetColor("stop") }, ","), "0.2,0.3,0.4")
end)
