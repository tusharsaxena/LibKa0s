-- tests/test_widgets_footer.lua — LibKa0s-Widgets-1.0: `lib.Footer` and `lib.FOOTER` (minor 27), a
-- window's footer in the look the owner ruled on 2026-11-15 (WowAddonStandards v2.110.0,
-- standalone-windows' *The footer*): no fill, a hairline in `divider` along its top, a left and an
-- optional right line in `text.muted`, an optional slot of catalog marks, and the resize grip's
-- corner, 24 px tall under every skin.
--
-- The geometry cases run under tests/fixture_geom.lua's factory, wrapped by `recording` for the
-- justification and the word wrap (tests/test_widgets_teststrip.lua's header gives the reason). The
-- skin cases run on the kit's paint recorder (tests/fixture_skin_paint.lua), as
-- tests/test_widgets_skin.lua does.

local T = _G.LK_TEST
local assertEqual = T.assertEqual
local assertTrue  = T.assertTrue
local assertNil   = T.assertNil
local mocks       = T.mocks
local W = T.widgets

local Geom = dofile("tests/fixture_geom.lua")
local test = Geom.test
local rawTest = T.test
local F = dofile("tests/fixture_skin_paint.lua")

local MARK = "Interface\\AddOns\\Host\\libs\\LibKa0s\\media\\icons\\settings"

local function record(f)
  rawset(f, "SetJustifyH", function(self, v) self.__justifyH = v end)
  rawset(f, "SetWordWrap", function(self, v) self.__wordWrap = v end)
  local makeTexture, makeFontString = f.CreateTexture, f.CreateFontString
  rawset(f, "CreateTexture", function(self, ...)
    local r = record(makeTexture(self, ...))
    r.__layer = select(2, ...)
    return r
  end)
  rawset(f, "CreateFontString", function(self, ...)
    local r = record(makeFontString(self, ...))
    r.__layer = select(2, ...)
    return r
  end)
  return f
end

local function recording(fn)
  local saved = mocks.CreateFrame
  mocks.CreateFrame = function(...) return record(saved(...)) end
  local ok, err = pcall(fn)
  mocks.CreateFrame = saved
  if not ok then error(err, 0) end
end

local function point(region, i)
  local p, rel, relPoint, x, y = region:GetPoint(i)
  return { point = p, rel = rel, relPoint = relPoint, x = x, y = y }
end

local function assertPoint(region, i, p, rel, relPoint, x, y, label)
  local got = point(region, i)
  assertEqual(got.point, p, label)
  assertTrue(got.rel == rel, (label or "") .. ": the relative frame")
  assertEqual(got.relPoint, relPoint, label)
  assertEqual(got.x, x, label)
  assertEqual(got.y, y, label)
end

-- ── the figures ──────────────────────────────────────────────────────────────────────────────

test("Footer: FOOTER publishes HEIGHT 24 and the slot's figures", function()
  assertEqual(W.FOOTER.HEIGHT, 24)
  assertEqual(W.FOOTER.PAD, 8)
  assertEqual(W.FOOTER.GRIP, 22)
  assertEqual(W.FOOTER.MARK, 16)
  assertEqual(W.FOOTER.MARK_ART, 12)
  assertEqual(W.FOOTER.MARK_GAP, 4)
end)

test("Footer: a write to FOOTER.HEIGHT does not move the next footer", function()
  recording(function()
    local saved = W.FOOTER.HEIGHT
    W.FOOTER.HEIGHT = 40
    local ok, err = pcall(function() assertEqual(W.Footer(mocks.UIParent):GetHeight(), 24) end)
    W.FOOTER.HEIGHT = saved
    if not ok then error(err, 0) end
  end)
end)

-- ── birth ────────────────────────────────────────────────────────────────────────────────────

test("Footer: born shown, 24 tall, across the window's bottom edge, with no fill", function()
  recording(function()
    local win = mocks.CreateFrame("Frame", nil, mocks.UIParent)
    local foot = W.Footer(win, { left = "12 records" })
    assertEqual(foot.__frameType, "Frame")
    assertTrue(foot.__parent == win, "parented to the window")
    assertTrue(foot:IsShown())
    assertEqual(foot:GetHeight(), 24)
    assertPoint(foot, 1, "BOTTOMLEFT", win, "BOTTOMLEFT", 0, 0)
    assertPoint(foot, 2, "BOTTOMRIGHT", win, "BOTTOMRIGHT", 0, 0)
    assertNil(rawget(foot, "SetBackdrop"), "a bare frame")
    assertNil(rawget(foot, "__fill"), "no fill: the window shows through")
  end)
end)

test("Footer: the hairline is one pixel along the top, 1 in from each side, in Ka0s Default's divider", function()
  recording(function()
    local foot = W.Footer(mocks.UIParent)
    local line = foot.line
    assertEqual(line.__layer, "ARTWORK")
    assertPoint(line, 1, "TOPLEFT", foot, "TOPLEFT", 1, 0)
    assertPoint(line, 2, "TOPRIGHT", foot, "TOPRIGHT", -1, 0)
    assertEqual(line:GetHeight(), 1)
    local c = line.__colorTexture
    assertEqual(c[1], 0.24); assertEqual(c[2], 0.24); assertEqual(c[3], 0.27); assertEqual(c[4], 0.85)
    assertTrue(W.__pxLines[line] ~= nil, "a recorded pixel line, re-sized on a scale change")
  end)
end)

test("Footer: opts.inset moves the hairline's ends", function()
  recording(function()
    local foot = W.Footer(mocks.UIParent, { inset = 0 })
    assertPoint(foot.line, 1, "TOPLEFT", foot, "TOPLEFT", 0, 0)
    assertPoint(foot.line, 2, "TOPRIGHT", foot, "TOPRIGHT", 0, 0)
  end)
end)

test("Footer: the left and right lines are one line each, in Ka0s Default's muted gray", function()
  recording(function()
    local foot = W.Footer(mocks.UIParent, { left = "live · 10 Hz", right = "3 fights" })
    assertEqual(foot.left:GetText(), "live · 10 Hz")
    assertEqual(foot.right:GetText(), "3 fights")
    for _, fs in ipairs({ foot.left, foot.right }) do
      assertEqual(fs.__layer, "OVERLAY")
      assertEqual(fs.__wordWrap, false)
      local c = fs.__textColor
      assertEqual(c[1], 0.7); assertEqual(c[2], 0.7); assertEqual(c[3], 0.72)
    end
    assertEqual(foot.left.__justifyH, "LEFT")
    assertEqual(foot.right.__justifyH, "RIGHT")
  end)
end)

test("Footer: the left line sits on the padding and runs up to the right line", function()
  recording(function()
    local foot = W.Footer(mocks.UIParent, { left = "a" })
    assertPoint(foot.left, 1, "LEFT", foot, "LEFT", 8, 0)
    assertPoint(foot.left, 2, "RIGHT", foot.right, "LEFT", -8, 0)
    assertPoint(foot.right, 1, "RIGHT", foot, "RIGHT", -8, 0, "no grip, no marks: the padding")
  end)
end)

test("Footer: SetLeft and SetRight set the lines; nil and non-strings give ''", function()
  recording(function()
    local foot = W.Footer(mocks.UIParent, { left = 5 })
    assertEqual(foot.left:GetText(), "", "a number at birth is none")
    foot:SetLeft("12 records"); foot:SetRight("v1.0")
    assertEqual(foot.left:GetText(), "12 records")
    assertEqual(foot.right:GetText(), "v1.0")
    foot:SetRight(nil)
    assertEqual(foot.right:GetText(), "")
  end)
end)

-- ── the control slot and the grip ────────────────────────────────────────────────────────────

test("Footer: marks lay right to left from the corner, outermost first, the right line beside them", function()
  recording(function()
    local foot = W.Footer(mocks.UIParent, { right = "r", marks = { { icon = MARK }, { icon = 134400 } } })
    local a, b = foot.marks[1], foot.marks[2]
    assertEqual(#foot.marks, 2)
    assertEqual(a.__frameType, "Button")
    assertEqual(a:GetWidth(), 16); assertEqual(a:GetHeight(), 16)
    assertEqual(a.icon:GetWidth(), 12)
    assertEqual(a.icon.__texture, MARK)
    assertEqual(b.icon.__texture, 134400)
    assertPoint(a, 1, "RIGHT", foot, "RIGHT", -8, 0, "outermost at the padding")
    assertPoint(b, 1, "RIGHT", a, "LEFT", -4, 0, "the next at the pitch")
    assertPoint(foot.right, 1, "RIGHT", b, "LEFT", -8, 0, "the right line clear of the marks")
  end)
end)

test("Footer: a mark rests gray, lights white under the pointer, and runs the host's scripts", function()
  recording(function()
    local clicked, entered, left
    local foot = W.Footer(mocks.UIParent, { marks = { {
      icon = MARK,
      onClick = function(btn, button) clicked = { btn, button } end,
      onEnter = function(btn) entered = btn end,
      onLeave = function(btn) left = btn end,
    } } })
    local b = foot.marks[1]
    assertEqual(b.icon.__vertexColor[1], 0.7)
    b:__fire("OnEnter")
    assertEqual(b.icon.__vertexColor[1], 1)
    assertTrue(entered == b)
    b:__fire("OnLeave")
    assertEqual(b.icon.__vertexColor[1], 0.7)
    assertTrue(left == b)
    b:__fire("OnClick", "LeftButton")
    assertTrue(clicked[1] == b); assertEqual(clicked[2], "LeftButton")
  end)
end)

test("Footer: a mark spec that is not a table is skipped", function()
  recording(function()
    local foot = W.Footer(mocks.UIParent, { marks = { "x", { icon = MARK } } })
    assertEqual(#foot.marks, 1)
  end)
end)

test("Footer: opts.grip clears the grip's corner; SetGrip moves it either way", function()
  recording(function()
    local foot = W.Footer(mocks.UIParent, { grip = true, marks = { { icon = MARK } } })
    assertPoint(foot.marks[1], 1, "RIGHT", foot, "RIGHT", -22, 0, "clear of the grip")
    foot:SetGrip(false)
    assertPoint(foot.marks[1], 1, "RIGHT", foot, "RIGHT", -8, 0, "the padding again")
    foot:SetGrip(true)
    local bare = W.Footer(mocks.UIParent, { grip = true })
    assertPoint(bare.right, 1, "RIGHT", bare, "RIGHT", -22, 0, "the right line clears it with no marks")
  end)
end)

test("Footer: opts.resize builds Core.MakeResizable's grip on the footer, in its corner", function()
  recording(function()
    local win = mocks.CreateFrame("Frame", nil, mocks.UIParent)
    local resized
    local res = { minWidth = 200, onResizeStop = function(w) resized = w end }
    local foot = W.Footer(win, { resize = res })
    assertTrue(foot.grip ~= nil, "the grip MakeResizable answered")
    assertTrue(foot.grip.__parent == foot, "built on the footer (gripParent)")
    assertPoint(foot.grip, 1, "BOTTOMRIGHT", foot, "BOTTOMRIGHT", -1, 1, "the footer's corner, the window's")
    assertTrue(win.resizeGrip == foot.grip, "sizing stays on the window")
    assertPoint(foot.right, 1, "RIGHT", foot, "RIGHT", -22, 0, "the corner is cleared")
    assertNil(res.gripParent, "the host's table is not written")
    assertNil(resized)
  end)
end)

test("Footer: a host's own gripParent in opts.resize wins", function()
  recording(function()
    local win = mocks.CreateFrame("Frame", nil, mocks.UIParent)
    local art = mocks.CreateFrame("Frame", nil, win)
    local foot = W.Footer(win, { resize = { gripParent = art } })
    assertTrue(foot.grip.__parent == art)
  end)
end)

test("Footer: two footers share no regions", function()
  recording(function()
    local a = W.Footer(mocks.UIParent, { left = "a" })
    local b = W.Footer(mocks.UIParent, { left = "b" })
    assertTrue(a.line ~= b.line and a.left ~= b.left and a.right ~= b.right)
    assertEqual(a.left:GetText(), "a"); assertEqual(b.left:GetText(), "b")
  end)
end)

-- ── the skin ─────────────────────────────────────────────────────────────────────────────────

local OWNER = "LootHistory"
local WFILES = { "Widgets", "WidgetsDropdown", "WidgetsReorder", "WidgetsDragHandle", "WidgetsDragHandleTip", "WidgetsLineChart",
                 "WidgetsAutocomplete", "WidgetsCopyWindow" }

local function env()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  for _, f in ipairs(WFILES) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  return m, Skin, m.LibStub("LibKa0s-Widgets-1.0")
end

local function rgb(c) return F.rgba({ c[1], c[2], c[3] }) end

rawTest("Footer skin: a registered owner's hairline is its divider and its lines its text.muted", function()
  local m, Skin, Wl = env()
  F.owner(Skin, OWNER, "obsidian")
  local foot = Wl.Footer(m.UIParent, { left = "l", right = "r", owner = OWNER })
  assertEqual(F.rgba(m.__paint(foot.line).color), F.tok(Skin, "obsidian", "divider"))
  assertEqual(F.rgba(m.__paint(foot.left).textColor), F.tok(Skin, "obsidian", "text.muted"))
  assertEqual(F.rgba(m.__paint(foot.right).textColor), F.tok(Skin, "obsidian", "text.muted"))
  Skin:SetChoice(OWNER, "ka0s", "azeroth")
  assertEqual(F.rgba(m.__paint(foot.line).color), F.tok(Skin, "azeroth", "divider"), "a switch repaints it")
  assertEqual(F.rgba(m.__paint(foot.left).textColor), F.tok(Skin, "azeroth", "text.muted"))
end)

rawTest("Footer skin: an owned mark rests in icon.tint and lights in icon.hot", function()
  local m, Skin, Wl = env()
  F.owner(Skin, OWNER, "obsidian")
  local foot = Wl.Footer(m.UIParent, { marks = { { icon = MARK } }, owner = OWNER })
  local b = foot.marks[1]
  assertEqual(rgb(m.__paint(b.icon).vertex), rgb({ Skin:Color(OWNER, "icon.tint") }))
  b:__fire("OnEnter")
  assertEqual(rgb(m.__paint(b.icon).vertex), rgb({ Skin:Color(OWNER, "icon.hot") }))
  b:__fire("OnLeave")
  assertEqual(rgb(m.__paint(b.icon).vertex), rgb({ Skin:Color(OWNER, "icon.tint") }))
end)

rawTest("Footer skin: an unregistered owner draws the owner-less footer", function()
  local m, Skin, Wl = env()
  assertTrue(Skin ~= nil)
  local foot = Wl.Footer(m.UIParent, { left = "l", owner = "NotRegistered" })
  assertNil(Skin.painted[foot.line], "not handed to a facade")
  assertNil(Skin.painted[foot.left])
end)
