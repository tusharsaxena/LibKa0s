-- tests/test_widgets_bar.lua — LibKa0s-Widgets-1.0's data bar, `W.Bar` (WidgetsBar minor 1),
-- LibKa0s#80 (LK-80 of Ka0sAddonsCommonTasks docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS, design section
-- 3.8, research note R4 section 3): Ka0s Skill Master's `modules/Bar.lua` promoted, its profile reads
-- and class colors left in the host, its owner tokens swapped for token NAMES resolved at paint time.
--
-- The first eleven cases are Skill Master's `tests/test_bar.lua`, ported with the renamed fields
-- (`tiers` -> `segments`, `tiered` -> `segmented`, `{rank}` -> `{value}`). The rest are new: the
-- presets, an owner-less bar on Ka0s Default, a skin switch repainting names and not literals, the
-- remap onto an owner token, the reverse fill, the `{rank}` alias, Park, and the pool without the
-- Pool major.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local function near(a, b, msg) assertTrue(math.abs((a or 0) - b) < 1e-6, (msg or "") .. ": " .. tostring(a) .. " vs " .. tostring(b)) end

-- A fresh client with the paint recorder, the Skin major (unless `noSkin`) and the Widgets shell and
-- bar (and the Pool major unless `noPool`). Answers m, Skin, W.
local function env(opts)
  opts = opts or {}
  local files = {}
  for _, f in ipairs(opts.noSkin and { "Core", "CorePixel" } or F.FILES) do files[#files + 1] = f end
  if not opts.noPool then files[#files + 1] = "Pool" end
  files[#files + 1] = "Widgets"; files[#files + 1] = "WidgetsBar"
  local m, Skin = F.env({ files = files, lsm = opts.lsm })
  return m, Skin, m.LibStub("LibKa0s-Widgets-1.0")
end

-- Two clients for the whole suite: one with the Skin major, Pool and a LibSharedMedia fake, one with
-- neither Skin nor Pool. A bench per case would load the Skin major two dozen times over, and the
-- run's leak gate counts those. Each case that registers a skin owner names its own.
local mocks, SKIN, W = env({ lsm = { ["border:Thin"] = "path\\thin" } })
local BARE, _, BW = env({ noSkin = true, noPool = true })

local function fresh(preset, owner)
  return W.Bar(mocks.UIParent, { preset = preset or "row", owner = owner })
end

local function colorOf(m, tex)
  local p = m.__paint(tex)
  return F.rgba(p.color or p.vertex)
end

-- ── Skill Master's cases, ported ─────────────────────────────────────────────────────────────

test("bar: a bonus past the cap clamps the base, draws to the end and keeps the full text", function()
  -- red under: a bonus segment that is not clamped (it would draw past the bar's end), or a text
  -- built from the clamped numbers.
  local bar = fresh()
  bar:SetValues{ value = 105, max = 110, bonus = 5, bonusKind = "perm" }
  near(bar.geom.fill, 105 / 110, "105 / 110 base")
  near(bar.geom.fill + bar.geom.bonus, 1, "+5 reaches exactly the end")
  assertEqual(bar.text:GetText(), "105 +5 / 110")

  bar:SetValues{ value = 150, max = 150, bonus = 100, bonusKind = "temp" }
  assertEqual(bar.geom.fill, 1, "a full base")
  assertEqual(bar.geom.bonus, 0, "no room past the end: the segment draws nothing beyond it")
  assertEqual(bar.text:GetText(), "150 +100 / 150", "the text still shows the full numbers")

  bar:SetValues{ value = 107, max = 150, bonus = 100, bonusKind = "temp" }
  near(bar.geom.fill + bar.geom.bonus, 1, "a +100 at 107 / 150 stops at the end")

  bar:SetValues{ value = 160, max = 150 }
  assertEqual(bar.geom.fill, 1, "a value above its cap clamps")
  assertEqual(bar.text:GetText(), "160 / 150")
end)

test("bar: the bonus segment wears the temp or the permanent color", function()
  local bar = fresh()
  bar:ApplyStyle{ bonusTemp = { 0.1, 0.2, 0.3, 1 }, bonusPerm = { 0.4, 0.5, 0.6, 1 } }
  bar:SetValues{ value = 10, max = 100, bonus = 5, bonusKind = "temp" }
  assertEqual(bar.bonusColor[1], 0.1, "temp")
  bar:SetValues{ value = 10, max = 100, bonus = 5, bonusKind = "perm" }
  assertEqual(bar.bonusColor[1], 0.4, "perm")
end)

test("bar: an empty cap draws nothing and raises nothing", function()
  local bar = fresh()
  bar:SetValues{ value = 0, max = 0 }
  assertEqual(bar.geom.fill, 0)
  assertEqual(bar.geom.bonus, 0)
  assertEqual(bar.text:GetText(), "0 / 0")
end)

test("bar: a segmented bar draws to its last cap, its fill one segment per cap entered", function()
  local caps = { 75, 150, 225, 300 }
  local g = W.BarCompute({ value = 121, max = 150, bonus = 10, segments = caps }, nil, true)
  near(g.fill, 121 / 300, "on a scale to 300, not to the cap")
  near(g.bonus, 10 / 300, "the bonus on the same scale")
  assertEqual(#g.segments, 2, "two segments entered")
  near(g.segments[1].from, 0, "first from")
  near(g.segments[1].to, 75 / 300, "first to")
  assertEqual(g.segments[2].tier, 2)
  near(g.segments[2].to, 121 / 300, "the second stops at the value")
  assertEqual(g.text, "121 +10 / 150", "the text keeps the real cap")
  assertEqual(#W.BarCompute({ value = 300, max = 300, segments = caps }, nil, true).segments, 4, "all four at 300")
  assertEqual(#W.BarCompute({ value = 0, max = 75, segments = caps }, nil, true).segments, 0, "none at 0")
  local plain = W.BarCompute({ value = 121, max = 150, segments = caps }, nil, false)
  assertNil(plain.segments, "not segmented: no segments")
  near(plain.fill, 121 / 150, "not segmented: on the cap")
  local none = W.BarCompute({ value = 50, max = 110 }, nil, true)
  assertTrue(none.segments == nil and math.abs(none.fill - 50 / 110) < 1e-9, "no caps: as before")
end)

test("bar: markers keep the end and drop what is past it; labels are carried in geom, not drawn", function()
  local bar = fresh("tooltip")
  bar:SetValues{ value = 22, max = 100, markers = { { at = 55.6, label = "5%" }, { at = 100, label = "9%" },
                                                   { at = 120, label = "past" } } }
  assertEqual(#bar.geom.markers, 2)
  near(bar.geom.markers[1].at, 0.556, "first marker")
  assertEqual(bar.geom.markers[2].at, 1, "a marker at the cap is drawn on the end")
  assertEqual(bar.geom.markers[2].label, "9%")
  local shown = 0
  for _, t in ipairs(bar.markerTextures) do if t:IsShown() then shown = shown + 1 end end
  assertEqual(shown, 2, "one line per marker; no font string carries a label")
  local row = fresh("row")
  row:SetValues{ value = 22, max = 100, markers = { { at = 50, label = "x" } } }
  assertEqual(#row.geom.markers, 0, "the row preset draws no markers")
end)

test("bar: the timer formats m:ss and h:mm:ss", function()
  assertEqual(W.BarFormatTimer(252), "4:12")
  assertEqual(W.BarFormatTimer(5), "0:05")
  assertEqual(W.BarFormatTimer(3725), "1:02:05")
  assertEqual(W.BarFormatTimer(-3), "0:00")
  assertEqual(W.BarFormatTimer(nil), "0:00")
end)

test("bar: SetTimer shows the time left, ticks it, and SetTimer(nil) disarms the OnUpdate", function()
  -- red under: an OnUpdate left armed after the timer is cleared (a per-frame cost nobody sees).
  local bar = fresh()
  local saved = mocks.__now
  mocks.__now = 1000
  bar:SetTimer(1252)
  assertTrue(bar.timer:IsShown(), "the timer shows")
  assertEqual(bar.timer:GetText(), "4:12")
  assertTrue(bar:GetScript("OnUpdate") ~= nil, "armed while a timer runs")
  mocks.__now = 1010
  bar:__fire("OnUpdate", 0.1)
  assertEqual(bar.timer:GetText(), "4:12", "under TIMER_TICK nothing redraws")
  bar:__fire("OnUpdate", 0.1)
  assertEqual(bar.timer:GetText(), "4:02", "the tick re-reads the clock")
  bar:SetTimer(nil)
  assertFalse(bar.timer:IsShown(), "hidden")
  assertNil(bar:GetScript("OnUpdate"), "disarmed")
  mocks.__now = saved
end)

test("bar: a timer that runs out clears itself, and a style with showTimer false draws none", function()
  local bar = fresh()
  local saved = mocks.__now
  mocks.__now = 1000
  bar:SetTimer(1001)
  mocks.__now = 1002
  bar:__fire("OnUpdate", 1)
  assertFalse(bar.timer:IsShown(), "hidden once expired")
  assertNil(bar:GetScript("OnUpdate"), "and disarmed")
  local off = W.Bar(mocks.UIParent, { style = W.BarStyle("row", { showTimer = false }) })
  off:SetTimer(5000)
  assertFalse(off.timer:IsShown())
  assertNil(off:GetScript("OnUpdate"))
  mocks.__now = saved
end)

test("bar: the presets carry Skill Master's sizes and switches; overrides win; an unknown key is row", function()
  local P = W.BAR.PRESETS
  assertEqual(P.row.height, 14); assertTrue(P.row.showText); assertFalse(P.row.showMarkers)
  assertEqual(P.compact.height, 14); assertTrue(P.compact.showText)
  assertEqual(P.tooltip.height, 8); assertFalse(P.tooltip.showText); assertTrue(P.tooltip.showMarkers)
  assertEqual(P.mini.height, 10); assertFalse(P.mini.showText); assertFalse(P.mini.showMarkers)
  local s = W.BarStyle("mini", { height = 12, fill = { 1, 0, 0, 1 } })
  assertEqual(s.key, "mini"); assertEqual(s.height, 12); assertEqual(s.fill[1], 1)
  assertEqual(s.bonusTemp, "sem.info", "the temp bonus defaults to sem.info (R4 Q10)")
  assertEqual(s.bonusPerm, "sem.good", "the permanent bonus defaults to sem.good (R4 Q10)")
  assertEqual(s.bg, "bar.bg"); assertEqual(s.border, "bar.border"); assertEqual(s.marker, "hud.label")
  assertEqual(W.BarStyle("nope").key, "row")
  local other = W.BarStyle("mini")
  assertEqual(other.height, 10, "an override never reaches the preset table")
  local bar = fresh("mini")
  local heights = {}
  rawset(bar, "SetHeight", function(_, h) heights[#heights + 1] = h end)
  bar:ApplyStyle(W.BarStyle("mini"))
  assertEqual(heights[1], 10, "the preset's height")
  bar:SetValues{ value = 1, max = 2 }
  assertFalse(bar.text:IsShown(), "a mini bar draws no text")
end)

test("bar: the pool hands bars back in order and clears their timers on release", function()
  local pool = mocks.LibStub("LibKa0s-Pool-1.0").New()
  local a = W.AcquireBar(pool, mocks.UIParent, { preset = "row" })
  local b = W.AcquireBar(pool, mocks.UIParent, { preset = "row" })
  local saved = mocks.__now
  mocks.__now = 0
  a:SetTimer(5000)
  W.ReleaseBars(pool)
  assertNil(a:GetScript("OnUpdate"), "a released bar runs no timer")
  assertFalse(a:IsShown())
  assertTrue(W.AcquireBar(pool, mocks.UIParent, { preset = "row" }) == a, "position 1 gets its bar back")
  assertTrue(W.AcquireBar(pool, mocks.UIParent, { preset = "mini" }) == b)
  assertEqual(b.style.key, "mini", "an acquire restyles")
  W.ReleaseBars(pool)
  mocks.__now = saved
end)

test("bar: a secret width lays out on the last plain width", function()
  -- red under: arithmetic on the secret GetWidth (WoW Forever, Skill Master 2026-11-12: "attempt to
  -- perform arithmetic on a secret number value").
  local saved = rawget(mocks, "issecretvalue")
  mocks.issecretvalue = function(v) return v == 777 end
  local bar = fresh("tooltip")
  bar.knownWidth = 200
  bar.GetWidth = function() return 777 end
  local ok, err = pcall(bar.SetValues, bar, { value = 74, max = 125 })
  mocks.issecretvalue = saved
  assertTrue(ok, tostring(err))
  near(bar.fill:GetWidth(), (200 - 2) * 74 / 125, "the fill sized from the plain width")
end)

-- ── new: text, reverse, Park ─────────────────────────────────────────────────────────────────

test("bar: the template's tokens, and {rank} as an alias of {value}", function()
  assertEqual(W.BarText(107, 25, 150), "107 +25 / 150", "the default template")
  assertEqual(W.BarText(107, -3, 150, "{rank} {bonus}"), "107 -3", "{rank} reads the value")
  assertEqual(W.BarText(30, 0, 120, "{value} ({pct}%) {left} left {bonus}"), "30 (25%) 90 left")
  assertEqual(W.BarText(5, 0, 0, "{pct}"), "0", "an empty cap is 0 percent")
  assertEqual(W.BarText(1, 0, 2, "{nope}"), "{nope}", "an unknown token stays as written")
  local bar = fresh()
  bar:SetValues{ value = 1, max = 2, text = "custom" }
  assertEqual(bar.text:GetText(), "custom", "values.text wins over the template")
end)

test("bar: a reverse fill mirrors the geometry from the right edge", function()
  local bar = W.Bar(mocks.UIParent, { style = W.BarStyle("row", { reverse = true }) })
  bar:__setGeom(102, 14)
  bar:SetValues{ value = 50, max = 100, bonus = 10 }
  local p, rel, rp, x = bar.fill:GetPoint(1)
  assertEqual(p, "TOPRIGHT"); assertTrue(rel == bar); assertEqual(rp, "TOPRIGHT"); assertEqual(x, -1)
  near(bar.fill:GetWidth(), 50, "half of the inner 100")
  local _, _, _, bx = bar.bonus:GetPoint(1)
  assertEqual(bx, -51, "the bonus starts where the fill ends, leftward")
  local fwd = fresh()
  fwd:__setGeom(102, 14)
  fwd:SetValues{ value = 50, max = 100, bonus = 10 }
  local fp, _, _, fx = fwd.fill:GetPoint(1)
  assertEqual(fp, "TOPLEFT"); assertEqual(fx, 1)
  local _, _, _, fbx = fwd.bonus:GetPoint(1)
  assertEqual(fbx, 51)
end)

test("bar: Park disarms the timer and clears the points", function()
  local bar = fresh()
  local cleared = 0
  rawset(bar, "ClearAllPoints", function() cleared = cleared + 1 end)
  local saved = mocks.__now
  mocks.__now = 0
  bar:SetTimer(100)
  bar:Park()
  assertNil(bar:GetScript("OnUpdate"))
  assertFalse(bar.timer:IsShown())
  assertEqual(cleared, 1, "its points cleared")
  mocks.__now = saved
end)

test("bar: an invalid parent raises at the caller", function()
  local ok, err = pcall(W.Bar, nil, {})
  assertFalse(ok)
  assertTrue(tostring(err):find("Bar", 1, true) ~= nil, tostring(err))
end)

-- ── new: paint, owners, skin switches ────────────────────────────────────────────────────────

test("bar: an owner-less bar paints Ka0s Default, with the Skin major and without it", function()
  for _, pair in ipairs({ { mocks, W }, { BARE, BW } }) do
    local m, Wm = pair[1], pair[2]
    local bar = Wm.Bar(m.UIParent, { preset = "row" })
    bar:SetValues{ value = 5, max = 10, bonus = 1, bonusKind = "temp" }
    assertEqual(colorOf(m, bar.fill), "0.200,0.550,0.950,1", "bar.fill")
    assertEqual(colorOf(m, bar.bonus), "0.300,0.800,1,1", "sem.info")
    assertEqual(colorOf(m, bar.bg), "0,0,0,0.500", "bar.bg")
    assertEqual(F.rgba(m.__paint(bar.text).textColor), "1,1,1,1", "hud.text")
  end
end)

test("bar: the owner-less fallback is Ka0s Default's values, token for token", function()
  -- red under: a Ka0s Default token moved and the bar's fallback copy left behind
  local ka0s = SKIN:ResolveSkin("ka0s")
  for name, c in pairs(W.__barFallback) do
    assertEqual(F.rgba(c), F.rgba(ka0s[name]), name)
  end
end)

test("bar: a registered owner's token names repaint on a skin switch; a literal does not move", function()
  local m, Skin, Wm = mocks, SKIN, W
  F.owner(Skin, "BarHost", "obsidian")
  local bar = Wm.Bar(m.UIParent, { owner = "BarHost", style = Wm.BarStyle("row", { bg = { 0.1, 0.2, 0.3, 1 } }) })
  bar:SetValues{ value = 5, max = 10, bonus = 1, bonusKind = "perm" }
  assertEqual(colorOf(m, bar.fill), F.tok(Skin, "obsidian", "bar.fill"))
  assertEqual(colorOf(m, bar.bonus), F.tok(Skin, "obsidian", "sem.good"))
  Skin:SetChoice("BarHost", "ka0s", "azeroth")
  assertEqual(colorOf(m, bar.fill), F.tok(Skin, "azeroth", "bar.fill"), "a switch repaints the fill")
  assertEqual(colorOf(m, bar.bonus), F.tok(Skin, "azeroth", "sem.good"), "and the bonus")
  assertEqual(F.rgba(m.__paint(bar.text).textColor), F.tok(Skin, "azeroth", "hud.text"), "and the text")
  assertEqual(colorOf(m, bar.bg), "0.100,0.200,0.300,1", "a literal stays")
end)

test("bar: a style slot remapped onto an owner token reads it", function()
  local m, Skin, Wm = mocks, SKIN, W
  Skin:RegisterOwner("BarRemap", { tokens = { ["br.bonus"] = { default = { 0.9, 0.1, 0.9, 1 } } } })
  local bar = Wm.Bar(m.UIParent, { owner = "BarRemap", style = Wm.BarStyle("row", { bonusTemp = "br.bonus" }) })
  bar:SetValues{ value = 5, max = 10, bonus = 1, bonusKind = "temp" }
  assertEqual(colorOf(m, bar.bonus), "0.900,0.100,0.900,1")
end)

test("bar: a values color is a literal or a token name, and the segments shade it", function()
  local m, Wm = mocks, W
  local bar = Wm.Bar(m.UIParent, { style = Wm.BarStyle("row", { segmented = true }) })
  bar:__setGeom(302, 14)
  bar:SetValues{ value = 200, max = 300, segments = { 100, 200, 300 }, color = { 1, 1, 1, 1 } }
  assertEqual(colorOf(m, bar.segmentTextures[1]), "1,1,1,1", "the first segment is the color")
  assertEqual(colorOf(m, bar.segmentTextures[2]), "0.800,0.800,0.800,1", "the next a shade darker")
  assertFalse(bar.fill:IsShown(), "segments take the fill's place")
  bar:SetValues{ value = 5, max = 10, color = "sem.bad" }
  assertEqual(colorOf(m, bar.fill), "1,0.330,0.330,1", "a name resolves")
  local s = Wm.BarShade({ 1, 0.5, 0.2, 0.4 }, 9)
  assertEqual(F.rgba(s), "0.500,0.250,0.100,0.400", "past the table, the last shade; alpha kept")
end)

test("bar: a Solid border draws four edges; None and size 0 draw none; another style a backdrop", function()
  local m, Wm = mocks, W
  local bar = Wm.Bar(m.UIParent, { style = Wm.BarStyle("row", { borderShow = true }) })
  for _, t in ipairs(bar.edges) do assertTrue(t:IsShown()) end
  assertEqual(colorOf(m, bar.edges[1]), "0,0,0,1", "bar.border")
  bar:ApplyStyle{ borderStyle = "None" }
  for _, t in ipairs(bar.edges) do assertFalse(t:IsShown()) end
  bar:ApplyStyle{ borderStyle = "Solid", borderSize = 0 }
  for _, t in ipairs(bar.edges) do assertFalse(t:IsShown()) end
  local plain = Wm.Bar(m.UIParent, { preset = "row" })
  for _, t in ipairs(plain.edges) do assertFalse(t:IsShown(), "no border by default (Ka0s Default's None)") end
end)

test("bar: a non-Solid border style draws through LibSharedMedia's border on a backdrop child", function()
  local m, Wm = mocks, W
  local bar = Wm.Bar(m.UIParent, { style = Wm.BarStyle("row", { borderShow = true, borderStyle = "Thin", borderSize = 2 }) })
  assertTrue(bar.edgeFrame ~= nil and bar.edgeFrame:IsShown())
  assertEqual(m.__paint(bar.edgeFrame).backdrop.edgeFile, "path\\thin")
  for _, t in ipairs(bar.edges) do assertFalse(t:IsShown(), "the edges give way") end
  bar:ApplyStyle{ borderStyle = "Solid" }
  assertFalse(bar.edgeFrame:IsShown())
end)

test("bar: an acquire with no Pool major degrades to the same order", function()
  local m, Wm = BARE, BW
  assertNil(m.LibStub("LibKa0s-Pool-1.0", true))
  local pool = { free = {}, active = {} }
  local a = Wm.AcquireBar(pool, m.UIParent, { preset = "row" })
  local b = Wm.AcquireBar(pool, m.UIParent, { preset = "row" })
  Wm.ReleaseBars(pool)
  assertEqual(#pool.active, 0); assertEqual(#pool.free, 2)
  assertTrue(Wm.AcquireBar(pool, m.UIParent) == a)
  assertTrue(Wm.AcquireBar(pool, m.UIParent) == b)
end)

-- Last: let the two benches go. Every case above shares them through these upvalues, and a suite's
-- closures live for the whole run, so without this the two clients would count against the run's
-- leak gate until it ends.
test("bar: the suite releases its two benches", function()
  mocks, SKIN, W, BARE, BW = nil, nil, nil, nil, nil
  collectgarbage("collect")
  assertNil(W)
end)
