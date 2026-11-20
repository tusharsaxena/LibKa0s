-- tests/test_skin_follow_shells.lua -- LibKa0s#97's batch D (SD-LK-97D of Ka0sAddonsCommonTasks
-- docs/2026-11-20-LIBKA0S_94_97_99_100; the audit is docs/2026-11-20-SKIN_DEFAULTS_AUDIT): owner
-- inference and window shells (ruling R-2: under any skin an element takes the skin's value).
--
--   97.1   THE OWNER CHECK (Widgets minor 30 extended; WidgetsDropdown 3 and WidgetsBar 2 extended,
--          WidgetsDragHandle 16, WidgetsLineChart 8, Charts 3 extended): a library widget built
--          with no registered owner under a frame an owner's skin paints is reported to the sink
--          that owner registered (W.OwnerWarnings), once per widget; nothing is walked without one
--   97.5   a DragHandle's host `spec.edge` is called again with the new `handle.edge` on a repaint
--          (WidgetsDragHandle minor 16)
--   97.16  Core.ApplySkin with a host skin table, `skinBands` and a registered owner draws the
--          owner's gradient and art bands under the host's edge, following switches (Core minor 19,
--          SkinPaint minor 20's Shell `keepEdge` / `noBands`): Quick Comms' pad window
--
-- Each case names the minor it is red under. One bench for the suite (the run's leak gate counts
-- each load of the Skin major), released by the last case.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local function bench()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  for _, f in ipairs({ "Pool", "Widgets", "WidgetsDropdown", "WidgetsDragHandle", "WidgetsDragHandleTip",
                       "WidgetsLineChart", "WidgetsBar", "Charts", "ChartsRender" }) do
    files[#files + 1] = f
  end
  local m, Skin = F.env({ files = files })
  dofile("tests/_kit/mock_layers.lua")(m)   -- a real GetParent, for the ancestor walk
  return m, Skin, m.LibStub("LibKa0s-Widgets-1.0"), m.LibStub("LibKa0s-Core-1.0")
end

local M, SKIN, W, CORE = bench()

local function survey(obj) return M.__paint(obj) end

--- A window `owner`'s skin paints (S.Shell), and a plain child of it.
local function ownedWindow(owner)
  local win = F.window(M)
  SKIN:For(owner).Shell(win)
  local child = M.CreateFrame("Frame", nil, win)
  return win, child
end

--- A sink that collects its messages.
local function collector()
  local got = {}
  return got, function(msg, widget, frame) got[#got + 1] = { msg = msg, widget = widget, frame = frame } end
end

-- ── 97.1: the owner check ────────────────────────────────────────────────────────────────────

test("owner check: an owner-less dropdown inside an owned window is reported to its owner (97.1)", function()
  -- red under Widgets minor 30 as v1.107.0+SD-LK-94 shipped it: no W.OwnerWarnings, nothing said.
  assertEqual(type(W.OwnerWarnings), "function", "the sink registry")
  F.owner(SKIN, "OC_Drop")
  local got, sink = collector()
  W.OwnerWarnings("OC_Drop", sink)
  local win, child = ownedWindow("OC_Drop")
  local dd = W.Dropdown(child, 120, {})
  assertEqual(#got, 1, "one report")
  assertTrue(got[1].widget == dd, "naming the widget")
  assertTrue(got[1].frame == win, "and the painted ancestor it sits under")
  assertTrue(got[1].msg:find("Dropdown", 1, true) ~= nil, "the message names the kind")
  assertTrue(got[1].msg:find('owner = "OC_Drop"', 1, true) ~= nil, "and the owner to pass")
  W.OwnerWarnings("OC_Drop", nil)
end)

test("owner check: every Widgets constructor and a chart context run it (97.1)", function()
  -- red under WidgetsBar 2, WidgetsDragHandle 15, WidgetsLineChart 7 and Charts 3 as Batch B left
  -- them: no constructor called the check.
  F.owner(SKIN, "OC_All")
  local got, sink = collector()
  W.OwnerWarnings("OC_All", sink)
  local _, child = ownedWindow("OC_All")
  W.SearchBox(child, 100, {})
  W.TestStrip(child, {})
  W.Footer(child, {})
  W.Bar(child, { preset = "row" })
  W.DragHandle(child, { label = "Move", moveFrame = M.CreateFrame("Frame") })
  W.LineChart(child, {})
  M.LibStub("LibKa0s-Charts-1.0"):New(child, {})
  local kinds = {}
  for _, g in ipairs(got) do kinds[#kinds + 1] = g.msg:match("a (.-) was built") end
  assertEqual(table.concat(kinds, ","), "SearchBox,TestStrip,Footer,Bar,DragHandle,LineChart,chart context")
  W.OwnerWarnings("OC_All", nil)
end)

test("owner check: an owned widget, a widget outside the window, and a second build say nothing (97.1)", function()
  F.owner(SKIN, "OC_Quiet")
  local got, sink = collector()
  W.OwnerWarnings("OC_Quiet", sink)
  local _, child = ownedWindow("OC_Quiet")
  W.Dropdown(child, 120, { owner = "OC_Quiet" })
  W.Dropdown(M.CreateFrame("Frame", nil, M.UIParent), 120, {})
  assertEqual(#got, 0, "owned, or under no painted frame")
  local dd = W.Dropdown(child, 120, {})
  W.__checkOwner(dd, child, nil, "Dropdown")
  assertEqual(#got, 1, "once per widget")
  W.Dropdown(child, 120, { owner = "NotRegistered" })
  assertEqual(#got, 2, "an unregistered owner is reported too")
  assertTrue(got[2].msg:find('unregistered owner "NotRegistered"', 1, true) ~= nil, got[2].msg)
  W.OwnerWarnings("OC_Quiet", nil)
end)

test("owner check: with no sink nothing is walked, and another owner's sink is not told (97.1)", function()
  F.owner(SKIN, "OC_Mine")
  F.owner(SKIN, "OC_Theirs")
  local got, sink = collector()
  W.OwnerWarnings("OC_Theirs", sink)
  local _, child = ownedWindow("OC_Mine")
  W.Dropdown(child, 120, {})
  assertEqual(#got, 0, "OC_Mine registered no sink, and OC_Theirs paints nothing here")
  W.OwnerWarnings("OC_Theirs", nil)
  assertNil(next(W.__ownerSinks), "every sink released")
  local walked = false
  local probe = setmetatable({}, { __index = function(_, k)
    if k == "GetParent" then walked = true end
  end })
  W.__checkOwner({}, probe, nil, "probe")
  assertFalse(walked, "debug-gated: no sink, no walk")
end)

test("owner check: a raising sink costs one error, never the constructor (97.1)", function()
  F.owner(SKIN, "OC_Raise")
  W.OwnerWarnings("OC_Raise", function() error("boom") end)
  local errs = {}
  local prev = M.geterrorhandler
  M.geterrorhandler = function() return function(e) errs[#errs + 1] = e end end
  local _, child = ownedWindow("OC_Raise")
  local ok, dd = pcall(W.Dropdown, child, 120, {})
  M.geterrorhandler = prev
  W.OwnerWarnings("OC_Raise", nil)
  assertTrue(ok and dd ~= nil, "the dropdown is built")
  assertEqual(#errs, 1, "the sink's raise reported once")
end)

-- ── 97.5: a host edge painter follows the skin ───────────────────────────────────────────────

test("drag handle: a host's spec.edge is called again with the new handle.edge (97.5)", function()
  -- red under WidgetsDragHandle minor 15: dhRepaint recolored only the library's own strips.
  F.owner(SKIN, "DH_Edge")
  local calls = {}
  local function edge(frame, size, r, g, b, a) calls[#calls + 1] = { frame = frame, size = size, c = { r, g, b, a } } end
  local h = W.DragHandle(M.UIParent, { label = "Move", moveFrame = M.CreateFrame("Frame"), owner = "DH_Edge", edge = edge })
  assertEqual(#calls, 1, "drawn once at birth")
  assertEqual(F.rgba(calls[1].c), F.tok(SKIN, "ka0s", "handle.edge"))
  SKIN:SetChoice("DH_Edge", "ka0s", "contrast")
  assertEqual(#calls, 2, "called again on the switch")
  assertTrue(calls[2].frame == h and calls[2].size == 1, "on the same strip, at 1")
  assertEqual(F.rgba(calls[2].c), F.tok(SKIN, "contrast", "handle.edge"), "in the new skin's edge")
  assertNil(h.__edges, "and the library drew no strips of its own")
  SKIN:SetChoice("DH_Edge", "ka0s", "ka0s")
end)

test("drag handle: a raising edge painter costs one error and the repaint finishes (97.5)", function()
  F.owner(SKIN, "DH_EdgeRaise")
  local n = 0
  local h = W.DragHandle(M.UIParent, { label = "Move", moveFrame = M.CreateFrame("Frame"), owner = "DH_EdgeRaise",
    edge = function() n = n + 1; if n > 1 then error("edge") end end })
  local errs = {}
  local prev = M.geterrorhandler
  M.geterrorhandler = function() return function(e) errs[#errs + 1] = e end end
  SKIN:SetChoice("DH_EdgeRaise", "ka0s", "obsidian")
  M.geterrorhandler = prev
  assertEqual(#errs, 1, "reported once")
  assertEqual(F.rgba(survey(h.bg).color), F.tok(SKIN, "obsidian", "handle.bg"), "the fill still repainted")
  SKIN:SetChoice("DH_EdgeRaise", "ka0s", "ka0s")
end)

-- ── 97.16: a host skin's window wears the skin's bands ──────────────────────────────────────

--- A host skin table in R.SkinFor's shape (Quick Comms' pad): its own edge art and fill.
local function hostSkin(bands)
  return {
    bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "host\\edge", edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
    bg = { 0.1, 0.2, 0.3, 0.9 }, border = { 0.5, 0.4, 0.3, 1 },
    skinBands = bands,
  }
end

test("host bands: skinBands draws the owner's gradient under the host's own edge (97.16)", function()
  -- red under Core minor 18: a host table took the owner's facade never, so no band drew.
  F.owner(SKIN, "HB_Grad", "midnight")
  local f = F.window(M)
  CORE.ApplySkin(f, hostSkin(true), "HB_Grad")
  local s = survey(f)
  assertEqual(s.backdrop.edgeFile, "host\\edge", "the host's edge art stays")
  assertEqual(F.rgba(s.backdropColor), "0.100,0.200,0.300,0.900", "and its fill")
  assertEqual(F.rgba(s.backdropBorderColor), "0.500,0.400,0.300,1", "and its edge color")
  local grad = F.region(SKIN, f, "grad")
  assertTrue(grad ~= nil and grad:IsShown(), "the skin's gradient")
  local g = survey(grad).gradient
  local tokens = SKIN:ResolveSkin("midnight")
  assertEqual(F.rgba({ g.max.r, g.max.g, g.max.b, g.max.a }), F.rgba(tokens["win.bgTop"]), "top stop")
  assertEqual(F.rgba({ g.min.r, g.min.g, g.min.b, g.min.a }), F.rgba(tokens["win.bgBottom"]), "bottom stop")
  local top = F.region(SKIN, f, "top")
  assertTrue(top == nil or not top:IsShown(), "no top bar: the host draws its own header")
  local edge = F.region(SKIN, f, "edgeTop")
  assertTrue(edge == nil or not edge:IsShown(), "no edge of the skin's over the host's")
end)

test("host bands: the art band, a switch, and a host table without skinBands (97.16)", function()
  F.owner(SKIN, "HB_Art", "wow")
  local f = F.window(M)
  CORE.ApplySkin(f, hostSkin(true), "HB_Art")
  local art = F.region(SKIN, f, "art")
  assertEqual(survey(art).texture, SKIN:ResolveSkin("wow")["win.bgTexture"], "WoW Default's tiled art")
  assertTrue(art:IsShown())
  SKIN:SetChoice("HB_Art", "ka0s", "obsidian")
  assertFalse(art:IsShown(), "a skin with no art draws none")
  assertEqual(survey(f).backdrop.edgeFile, "host\\edge", "and the replay left the host's edge alone")
  SKIN:SetChoice("HB_Art", "ka0s", "wow")
  assertTrue(art:IsShown(), "back")
  CORE.ApplySkin(f, hostSkin(nil), "HB_Art")
  assertFalse(art:IsShown(), "the host stopped following: its bands are gone")
  SKIN:SetChoice("HB_Art", "ka0s", "midnight")
  local grad = F.region(SKIN, f, "grad")
  assertTrue(grad == nil or not grad:IsShown(), "and a switch does not bring them back")
  SKIN:SetChoice("HB_Art", "ka0s", "ka0s")
end)

test("host bands: a later ApplySkin with no host table is the owner's whole Shell again (97.16)", function()
  -- a bare Shell call repeats its frame's last opts (SkinPaint minor 18); keepEdge must not stick.
  F.owner(SKIN, "HB_Back", "contrast")
  local f = F.window(M)
  CORE.ApplySkin(f, hostSkin(true), "HB_Back")
  CORE.ApplySkin(f, nil, "HB_Back")
  assertEqual(F.rgba(survey(f).backdropColor), F.tok(SKIN, "contrast", "win.bg"), "the skin's own fill")
  local edge = F.region(SKIN, f, "edgeTop")
  assertTrue(edge ~= nil and edge:IsShown(), "and the skin's own edge")
  assertEqual(F.rgba(survey(edge).color), F.tok(SKIN, "contrast", "win.border"))
  SKIN:SetChoice("HB_Back", "ka0s", "ka0s")
end)

test("host bands: no skinBands, an unregistered owner or no owner is minor 18's paint (97.16)", function()
  F.owner(SKIN, "HB_Plain", "midnight")
  local function trace(skin, owner)
    local tr = F.tracer(M)
    local f = F.window(M)
    tr.watch(f)
    tr.start(); CORE.ApplySkin(f, skin, owner); tr.stop(); tr.restore()
    return tr.text(), f
  end
  local bare = trace(hostSkin(nil), nil)
  local plain, f = trace(hostSkin(nil), "HB_Plain")
  assertEqual(plain, bare, "a registered owner without skinBands: the host's paint, call for call")
  assertNil(SKIN.painted[f], "and nothing tracked")
  local stranger, g = trace(hostSkin(true), "NotAnOwner")
  assertEqual(stranger, trace(hostSkin(true), nil), "skinBands with no registered owner draws nothing more")
  assertNil(SKIN.painted[g])
end)

-- Last: let the bench go (the run's leak gate counts it until the end otherwise).
test("skin follow shells: the suite releases its bench", function()
  M, SKIN, W, CORE = nil, nil, nil, nil
  collectgarbage("collect")
  assertNil(W)
end)
