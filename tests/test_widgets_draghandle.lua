-- tests/test_widgets_draghandle.lua — LibKa0s-Widgets-1.0: `lib.DragHandle`, the unlocked strip.
--
-- ── WHY A SUITE OF ITS OWN ────────────────────────────────────────────────────────────────────
--
-- `layout-§1`, and the same reason the widget is a file of its own. tests/test_widgets.lua was 1493
-- lines when these cases were written — seven from the 1500-line cap, and CLAUDE.md's band prose
-- says so — so a dozen cases appended there would have opened a breach needing a disposition.
-- v1.32.0's bulk-bracket cases and v1.33.0's font-preload cases took the same exit for the same
-- reason.
--
-- ── WHY IT BUILDS ITS OWN FRAMES ──────────────────────────────────────────────────────────────
--
-- For the reason tests/test_widgets.lua gives at length: the kit's base stub no-ops SetSize,
-- answers 0 from GetWidth and hands back the frame itself from CreateTexture. This widget sizes a
-- strip, sizes a mark inside it and then computes a width from both — against the base stub every
-- one of those numbers is unobservable. The factory below is a narrower cousin of that file's,
-- carrying only what these cases read, and it is installed per case for the same reason: the kit
-- collects every suite before it runs any case, so a factory installed at file scope would be gone
-- by the time the first body ran.
--
-- WHAT IS NOT MOCKED: the measuring FontString. `lib.__DragHandleMeasurer` is the seam the widget
-- publishes for exactly this, and the cases that assert a width replace it with a stub that
-- measures 6px per character — the same arithmetic tests/test_widgets.lua's menu stub uses. What is
-- being pinned is the `+ RESERVE * 2` rule around it, not the client's font metrics.

local T = _G.LK_TEST
local rawTest     = T.test
local assertEqual = T.assertEqual
local assertTrue  = T.assertTrue
local assertFalse = T.assertFalse
local mocks       = T.mocks

local W = T.widgets

--- A frame stub modeling the geometry, the scripts and the REGISTRATIONS this widget does work on.
--- The registrations are real rather than swallowed by the catch-all because "a host that passes no
--- right-click gets none" is a claim about RegisterForClicks having never been called, and against
--- the catch-all that claim is unfalsifiable.
local function geomFrame()
  local f = { __shown = true, __w = 0, __h = 0, __scripts = {}, __points = {}, __clicks = {}, __drags = {} }
  function f:SetSize(w, h) self.__w, self.__h = w, h; return self end
  function f:SetWidth(w) self.__w = w; return self end
  function f:SetHeight(h) self.__h = h; return self end
  function f:GetWidth() return self.__w end
  function f:GetHeight() return self.__h end
  function f:Show() self.__shown = true; return self end
  function f:Hide() self.__shown = false; return self end
  function f:SetShown(v) self.__shown = not not v; return self end
  function f:IsShown() return self.__shown end
  function f:SetScript(k, fn) self.__scripts[k] = fn; return self end
  function f:GetScript(k) return self.__scripts[k] end
  function f:__fire(k, ...) local fn = self.__scripts[k]; if fn then return fn(self, ...) end end
  function f:RegisterForClicks(...) self.__clicks = { ... }; return self end
  function f:RegisterForDrag(...) self.__drags = { ... }; return self end
  function f:SetPoint(point, rel, relPoint, x, y)
    self.__points[#self.__points + 1] =
      { point = point, relativeTo = rel, relativePoint = relPoint, x = x, y = y }
    return self
  end
  function f:ClearAllPoints() self.__points = {}; return self end
  function f:GetPoint(i)
    local pt = self.__points[i or 1]
    if not pt then return nil end
    return pt.point, pt.relativeTo, pt.relativePoint, pt.x, pt.y
  end
  function f:SetTexture(p) self.__texture = p; return self end
  function f:SetColorTexture(r, g, b, a) self.__colorTexture = { r, g, b, a }; return self end
  function f:SetText(t) self.__text = t; return self end
  function f:GetText() return self.__text end
  function f:SetTextColor(r, g, b) self.__textColor = { r, g, b }; return self end
  -- The mark's TINT and the label's BOUNDS, recorded rather than swallowed by the catch-all: both
  -- claims here are claims about the arguments a setter was handed, and against the catch-all
  -- (which answers every capitalized key with a function returning the frame) they are
  -- unfalsifiable.
  function f:SetVertexColor(r, g, b, a) self.__vertex = { r, g, b, a }; return self end
  function f:SetJustifyH(j) self.__justifyH = j; return self end
  function f:SetWordWrap(on) self.__wordWrap = on; return self end
  function f:SetMaxLines(n) self.__maxLines = n; return self end
  -- THE FACE a FontString was created with, recorded rather than answered from a font table: the
  -- claim under test is that the label is DRAWN in the same face it is MEASURED in, and that is a
  -- claim about the argument CreateFontString was handed.
  function f:GetStringWidth() return #(self.__text or "") * 6 end
  function f:CreateTexture() return geomFrame() end
  function f:CreateFontString(_, _, face) local fs = geomFrame(); fs.__face = face; return fs end
  -- StartMoving / StopMovingOrSizing, recorded: the whole point of `moveFrame` is that the drag
  -- reaches THAT frame and not the strip, and the catch-all would answer both with the frame.
  function f:StartMoving() self.__moving = true; return self end
  function f:StopMovingOrSizing() self.__moving = false; return self end
  setmetatable(f, { __index = function(_, k)
    if type(k) == "string" and k:match("^%u") then return function() return f end end
    return nil
  end })
  return f
end

local geomCreateFrame = function(frameType, name, parent)
  local f = geomFrame()
  f.__frameType, f.__name, f.__parent = frameType, name, parent
  return f
end
local geomUIParent = geomFrame()

--- Register a case whose body runs with the geometry factory installed, and with the measuring
--- seam restored afterwards -- a stub left on `lib.__DragHandleMeasurer` is a stub the next suite
--- inherits, and it is a lib-level member rather than a mock.
local realMeasurer = W.__DragHandleMeasurer
local function test(name, fn)
  return rawTest(name, function()
    local savedCF, savedUI = mocks.CreateFrame, mocks.UIParent
    mocks.CreateFrame, mocks.UIParent = geomCreateFrame, geomUIParent
    local ok, err = pcall(fn)
    mocks.CreateFrame, mocks.UIParent = savedCF, savedUI
    W.__DragHandleMeasurer = realMeasurer
    if not ok then error(err, 0) end
  end)
end

local HELP_FALLBACK = "Interface\\FriendsFrame\\InformationIcon"
local HOST_HELP     = "Interface\\AddOns\\Host\\media\\icons\\help"

--- Measure at 6px per character, whatever face is asked for.
local function stubMeasurer()
  local fs = geomFrame()
  W.__DragHandleMeasurer = function() return fs end
  return fs
end

--- A minimal well-formed spec: the two required fields and nothing else.
local function baseSpec(over)
  local spec = { label = "Buffs", moveFrame = geomFrame() }
  for k, v in pairs(over or {}) do spec[k] = v end
  return spec
end

--- Hover `frame` with GameTooltip recorded. Answers the owner call and every line, in order.
local function hover(frame)
  local tip = mocks.GameTooltip
  local seen = { lines = {} }
  local savedOwner = rawget(tip, "SetOwner")
  local savedText  = rawget(tip, "SetText")
  local savedLine  = rawget(tip, "AddLine")
  rawset(tip, "SetOwner", function(_, owner, anchor) seen.owner, seen.anchor = owner, anchor end)
  rawset(tip, "SetText", function(_, text, r, g, b)
    seen.lines[#seen.lines + 1] = { text = text, color = { r, g, b } }
  end)
  rawset(tip, "AddLine", function(_, text, r, g, b)
    seen.lines[#seen.lines + 1] = { text = text, color = { r, g, b } }
  end)
  local ok, err = pcall(function() frame:__fire("OnEnter") end)
  rawset(tip, "SetOwner", savedOwner)
  rawset(tip, "SetText", savedText)
  rawset(tip, "AddLine", savedLine)
  assertTrue(ok, tostring(err))
  return seen
end

-- ── It builds ────────────────────────────────────────────────────────────────

test("draghandle: it builds a named strip of the published height, hidden, with a label and a mark", function()
  local h = W.DragHandle(mocks.UIParent, baseSpec({ name = "KCMMacroBarHandle" }))
  assertTrue(h ~= nil, "a well-formed spec builds a handle")
  assertEqual(h.__name, "KCMMacroBarHandle", "a named handle keeps its name; a macro can reach it")
  assertEqual(h.__h, W.DRAG_HANDLE.HEIGHT)
  assertFalse(h:IsShown(), "the strip shows only while the host is unlocked, and the host says when")
  assertEqual(h.label:GetText(), "Buffs")
  assertTrue(h.help ~= nil, "the mark is built with the strip")
end)

test("draghandle: with no parent, and in a process with no CreateFrame, it answers nil", function()
  -- Headless, CreateFrame is a mock, so the second half asserts the guard exists rather than the
  -- absence. The real degraded path is a host loaded with no UI at all.
  assertEqual(W.DragHandle(nil, baseSpec()), nil)
  local saved = mocks.CreateFrame
  mocks.CreateFrame = nil
  local out = W.DragHandle(geomUIParent, baseSpec())
  mocks.CreateFrame = saved
  assertEqual(out, nil)
end)

test("draghandle: a frame that cannot make textures is drawn without them rather than raising", function()
  -- The degraded path is real: a headless mock's CreateTexture can answer nil, and every texture
  -- path here guards on the ANSWER rather than on the method.
  -- red under: calling SetAllPoints on the answer before checking it.
  local saved = mocks.CreateFrame
  mocks.CreateFrame = function(...)
    local f = saved(...)
    function f:CreateTexture() return nil end
    return f
  end
  local ok, err = pcall(function()
    local h = W.DragHandle(geomUIParent, baseSpec())
    assertTrue(h ~= nil, "the strip is still built")
    T.assertNil(h.bg, "and it holds no half-built texture to keep positioning")
  end)
  mocks.CreateFrame = saved
  assertTrue(ok, "a textureless frame raised: " .. tostring(err))
end)

-- ── The mark's size, which is the thing that was wrong ───────────────────────

test("draghandle: the mark's ART is 8px -- the chevron's INK rather than the chevron's BOX", function()
  -- The owner's complaint was that the "?" is too heavy beside the text, and the first answer to it
  -- was a box: 14 -> 12, on the dropdown chevron's SetSize(12, 12). A box is not a weight. The
  -- chevron's art inks 44 of its 64 rows, so a 12px box of it draws 8.25px of mark; this mark's
  -- art inks all 64 and the Blizzard fallback is a filled disc, so a 12px box of it draws 12 --
  -- about 1.7x the small label's cap height against the chevron's 1.1x. 8px of edge-to-edge ink is
  -- the chevron's ink.
  -- red under: 14, and equally 12, which matched the precedent in the one dimension that does not
  -- reach the player's eye.
  local h = W.DragHandle(mocks.UIParent, baseSpec())
  assertEqual(W.DRAG_HANDLE.HELP, 8, "and the published constant says so")
  assertEqual(h.help.icon.__w, 8)
  assertEqual(h.help.icon.__h, 8)
end)

test("draghandle: the mark is dimmed to the chevron's own tint, and brightens where a click is wired",
function()
  -- The other half of the same complaint. Both copies drew the mark at full white, the brightest
  -- element on a strip whose label is gold on a dark fill. The dropdown's chevron carries
  -- SetVertexColor(0.7, 0.7, 0.72), set by the widget so shared white art wears the widget's gray;
  -- the mark takes the same tint from the same place, and its alpha is left alone.
  -- red under: full white at rest, or a dim with no hover response on a frame that is a Button and
  -- opens a settings page.
  local h = W.DragHandle(mocks.UIParent, baseSpec({ onRightClick = function() end }))
  local rest = h.help.icon.__vertex
  assertEqual(rest[1], 0.7)
  assertEqual(rest[2], 0.7)
  assertEqual(rest[3], 0.72)
  T.assertNil(rest[4], "the tint is a color, not an alpha -- the mark composites at full opacity")
  h.help:__fire("OnEnter")
  assertEqual(h.help.icon.__vertex[1], 1, "full white under the cursor, so it reads as clickable")
  assertEqual(h.help.icon.__vertex[3], 1)
  h.help:__fire("OnLeave")
  assertEqual(h.help.icon.__vertex[3], 0.72, "and back to the resting tint when it leaves")
end)

test("draghandle: a mark with no click behind it does not light up under the cursor", function()
  -- The brighten is the sentence "this is a control". ConsumableMaster's strip registers no
  -- right-click at all -- dhSetClick declines to register one -- so a mark that went full white
  -- under the cursor there advertised an action nothing was behind. Hover feedback and the click
  -- register or decline together.
  -- red under: a constant HELP_TINT_OVER on OnEnter, which is what the first draft shipped.
  local h = W.DragHandle(mocks.UIParent, baseSpec())
  h.help:__fire("OnEnter")
  assertEqual(h.help.icon.__vertex[1], 0.7, "still the resting tint, because nothing is clickable")
  assertEqual(h.help.icon.__vertex[3], 0.72)
  h.help:__fire("OnLeave")
  assertEqual(h.help.icon.__vertex[3], 0.72, "and leaving changes nothing either")
end)

test("draghandle: the mark's FRAME is the full strip height, so the art shrank and the target did not", function()
  -- The ruling this widget was sent back for: a destructive-adjacent control that is also the only
  -- right-click affordance on AuraMaster's strip has to stay easy to hit. Same shape as O.IdList's
  -- remove icon one layer down -- ID_REMOVE_SIZE 16 of art inside an ID_REMOVE_HIT 26 frame -- so
  -- the art is centered in a gutter rather than filling its button.
  -- red under: a 12x12 Button, which is what shrinking the art alone produced.
  local h = W.DragHandle(mocks.UIParent, baseSpec())
  local D = W.DRAG_HANDLE
  assertEqual(D.HELP_HIT, D.HEIGHT, "the frame is the strip's own height")
  assertEqual(h.help.__w, D.HELP_HIT)
  assertEqual(h.help.__h, D.HELP_HIT)
  assertEqual(D.HELP_GUTTER, 5, "(18 - 8) / 2 on every side")
  local point, rel, relPoint = h.help.icon:GetPoint(1)
  assertEqual(point, "CENTER", "and the art is centered in it, not anchored to a corner")
  assertEqual(rel, h.help)
  assertEqual(relPoint, "CENTER")
end)

test("draghandle: the mark is anchored inside the strip's right end at the published inset", function()
  local h = W.DragHandle(mocks.UIParent, baseSpec())
  local point, rel, relPoint, x = h.help:GetPoint(1)
  assertEqual(point, "RIGHT")
  assertEqual(rel, h)
  assertEqual(relPoint, "RIGHT")
  assertEqual(x, -W.DRAG_HANDLE.HELP_INSET)
end)

test("draghandle: the label is drawn in the same face it is measured in, and one field sets both", function()
  -- red under: a label DRAWN in a hardcoded face and MEASURED in a separate `measureFont`, so a
  -- host that set one and not the other measured a width the strip never drew and could run its
  -- own label into the mark. One field or neither.
  local askedFor
  W.__DragHandleMeasurer = function(face) askedFor = face; return geomFrame() end
  local h = W.DragHandle(mocks.UIParent, baseSpec({ labelFont = "GameFontHighlight" }))
  h:Measure()
  assertEqual(h.label.__face, "GameFontHighlight", "the FontString is created in the host's face")
  assertEqual(askedFor, "GameFontHighlight", "and the measurer is asked for the same one")

  askedFor = nil
  local plain = W.DragHandle(mocks.UIParent, baseSpec())
  plain:Measure()
  assertEqual(plain.label.__face, "GameFontNormalSmall", "and the default is one face too")
  T.assertNil(askedFor, "the measurer is left to its own default rather than handed a second one")
end)

test("draghandle: the label is bounded by the reserve on both sides, and never wraps", function()
  -- red under: a lone CENTER point, which is what both copies drew. A FontString anchored only at
  -- its center has no width of its own and grows both ways, so a label longer than the strip runs
  -- under the mark and out past the gold edge. Bounded at RESERVE -- the same number Measure()
  -- spends on each side -- it truncates inside its own half of the strip instead.
  local h = W.DragHandle(mocks.UIParent, baseSpec())
  local D = W.DRAG_HANDLE
  local point, rel, relPoint, x = h.label:GetPoint(1)
  assertEqual(point, "LEFT")
  assertEqual(rel, h)
  assertEqual(relPoint, "LEFT")
  assertEqual(x, D.RESERVE)
  local point2, _, relPoint2, x2 = h.label:GetPoint(2)
  assertEqual(point2, "RIGHT")
  assertEqual(relPoint2, "RIGHT")
  assertEqual(x2, -D.RESERVE)
  assertEqual(h.label.__justifyH, "CENTER", "equal bounds and a centered justify is still centered")
  assertFalse(h.label.__wordWrap, "a bounded FontString wraps by default, and two lines do not fit")
  assertEqual(h.label.__maxLines, 1)
end)

test("draghandle: a label far longer than the strip cannot reach the mark", function()
  -- WHEN THIS HAPPENS, since Measure() otherwise sizes the strip to its own label: a host calls
  -- SetLabel and does not call ApplyWidth again, which SetLabel deliberately leaves to the host
  -- because geometry beside a protected frame is the host's to schedule. A client that cannot
  -- build a measurer at all is the same case with a measured width of 0.
  stubMeasurer()
  local h = W.DragHandle(mocks.UIParent, baseSpec())
  local D = W.DRAG_HANDLE
  local width = h:ApplyWidth()
  h:SetLabel(string.rep("Very Long Container Name ", 8))
  assertTrue(h:Measure() > width * 3, "the text now wants far more room than the strip has")
  assertEqual(h:GetWidth(), width, "and the strip has not grown, because the host has not asked")
  -- The label's own right bound, against the art's left edge, on the strip as it stands.
  local labelRight = width - D.RESERVE
  local artLeft = width - D.HELP_INSET - D.HELP_HIT + D.HELP_GUTTER
  assertEqual(artLeft - labelRight, D.HELP_CLEAR,
    "the clearance in front of the mark survives a label of any length")
end)

test("draghandle: it wears the host's help art, and falls to Blizzard's without any", function()
  local host = W.DragHandle(mocks.UIParent, baseSpec({ helpIcon = HOST_HELP }))
  assertEqual(host.help.icon.__texture, HOST_HELP)
  -- The rung a host with no LibKa0s-Media lands on. Red under: a library that reaches for
  -- Media.Icon itself, which cannot work from a vendored copy.
  local bare = W.DragHandle(mocks.UIParent, baseSpec())
  assertEqual(bare.help.icon.__texture, HELP_FALLBACK)
end)

-- ── The width, which the mark's size feeds ───────────────────────────────────

test("draghandle: Measure is the label plus the reserve each side of it keeps clear, twice", function()
  -- RESERVE is spent TWICE on purpose: once on the right, where it pays for the mark's inset, its
  -- frame and the clearance in front of its art, and once on the left as the matching empty gap,
  -- which is what keeps the label optically centered. Both hosts wrote this expression out at a
  -- call site; neither does now, so the constants and the arithmetic cannot drift apart again.
  stubMeasurer()
  local h = W.DragHandle(mocks.UIParent, baseSpec())
  local D = W.DRAG_HANDLE
  assertEqual(h:Measure(), 5 * 6 + D.RESERVE * 2)
  assertEqual(h:Measure(), 88)
end)

test("draghandle: the reserve is its own terms, so the clearance beside the label can be changed alone", function()
  -- THE COMPLAINT WAS ABOUT THE GAP, NOT ONLY THE MARK. Both copies spent
  -- PAD / 2 + HELP - HELP_INSET = 8px between the label and the mark, and because the mark's
  -- footprint sat on both sides of that expression, shrinking the art from 14 to 12 left the 8
  -- exactly where it was. HELP_CLEAR is that gap, named, and RESERVE is computed from it.
  -- red under: a typed RESERVE, or a PAD the clearance hides inside.
  local D = W.DRAG_HANDLE
  assertEqual(D.HELP_CLEAR, 12, "label edge to the mark's ink")
  assertEqual(D.RESERVE, D.HELP_INSET + D.HELP_HIT - D.HELP_GUTTER + D.HELP_CLEAR)
  assertEqual(D.RESERVE, 29)
  -- The gutter is EXACT, never floored: the art is placed by SetPoint CENTER, which splits
  -- HELP_HIT - HELP in half whatever its parity, so a floored term would advertise a clearance the
  -- layout does not draw as soon as the two differ by an odd amount.
  assertEqual(D.HELP_GUTTER, (D.HELP_HIT - D.HELP) / 2, "the arithmetic agrees with the SetPoint")
  -- The geometry the player sees, read back off the frames rather than off the table: with the
  -- strip at its natural width, the label's right edge to the art's left edge.
  stubMeasurer()
  local h = W.DragHandle(mocks.UIParent, baseSpec())
  local width = h:ApplyWidth()
  local labelRight = width / 2 + (5 * 6) / 2
  local artLeft = width - D.HELP_INSET - D.HELP_HIT + D.HELP_GUTTER
  assertEqual(artLeft - labelRight, 12, "12px of clear space, where both copies drew 8")
end)

test("draghandle: ApplyWidth floors the natural width at the host's minimum and returns it", function()
  -- ConsumableMaster's floor is the bar's width and AuraMaster's is one element; a strip already
  -- wider than the floor sees neither.
  stubMeasurer()
  local h = W.DragHandle(mocks.UIParent, baseSpec())
  assertEqual(h:ApplyWidth(200), 200, "a wide bar floors it")
  assertEqual(h:GetWidth(), 200)
  assertEqual(h:ApplyWidth(40), 88, "a narrow one does not")
  assertEqual(h:ApplyWidth(), 88, "and no floor at all is the natural width")
end)

test("draghandle: SetLabel re-texts and re-measures, and touches no geometry of its own", function()
  -- Geometry around a protected frame is the HOST's to schedule; a widget that resized itself here
  -- would poke that frame mid-fight from inside the library.
  stubMeasurer()
  local h = W.DragHandle(mocks.UIParent, baseSpec())
  h:ApplyWidth()
  h:SetLabel("Buffs  TEST")
  assertEqual(h.label:GetText(), "Buffs  TEST")
  assertEqual(h:Measure(), 11 * 6 + 58)
  assertEqual(h:GetWidth(), 88, "the width is unchanged until the host asks for it")
  h:ApplyWidth()
  assertEqual(h:GetWidth(), 124)
end)

test("draghandle: a measurer the client cannot build is a width of 0, not a raise", function()
  W.__DragHandleMeasurer = function() return nil end
  local h = W.DragHandle(mocks.UIParent, baseSpec())
  assertEqual(h:Measure(), W.DRAG_HANDLE.RESERVE * 2)
end)

test("draghandle: the host's numeric guard is what reads every measurement", function()
  -- AuraMaster passes NS.Secrets.NumberOr because its label hangs off an anchor that inherits
  -- secret geometry; without the seam the guard would be decorative in the one host that needs it.
  stubMeasurer()
  local seen = 0
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    number = function(v, fallback) seen = seen + 1; return tonumber(v) or fallback end,
  }))
  h:Measure()
  assertTrue(seen > 0, "every read goes through it")
end)

-- ── The drag, and the mark that must not be a dead zone ──────────────────────

test("draghandle: dragging the strip moves the host's frame and reports both ends", function()
  local moved = geomFrame()
  local log = {}
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    moveFrame = moved,
    onDragStart = function() log[#log + 1] = "start" end,
    onDragStop  = function() log[#log + 1] = "stop" end,
  }))
  h:__fire("OnDragStart")
  assertTrue(moved.__moving, "the MOVE FRAME moves, not the strip")
  h:__fire("OnDragStop")
  assertFalse(moved.__moving)
  assertEqual(table.concat(log, ","), "start,stop")
end)

test("draghandle: canDrag refuses, and a refused drag stops nothing either", function()
  -- AuraMaster refuses an attached container and refuses in combat; ConsumableMaster refuses a
  -- locked bar. A stop that ran anyway would save a position no drag had changed.
  local moved, stops = geomFrame(), 0
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    moveFrame = moved,
    canDrag = function() return false end,
    onDragStop = function() stops = stops + 1 end,
  }))
  h:__fire("OnDragStart")
  assertFalse(moved.__moving or false)
  h:__fire("OnDragStop")
  assertEqual(stops, 0)
end)

test("draghandle: the strip's drag scripts reach the help mark, so the '?' is not a dead zone", function()
  -- red under: a mark built without the strip's scripts, which is what ConsumableMaster shipped —
  -- a left-drag that started on its "?" moved nothing at all.
  local moved = geomFrame()
  local h = W.DragHandle(mocks.UIParent, baseSpec({ moveFrame = moved }))
  assertEqual(h.help:GetScript("OnDragStart"), h:GetScript("OnDragStart"))
  assertEqual(h.help:GetScript("OnDragStop"), h:GetScript("OnDragStop"))
  assertEqual(h.help.__drags[1], "LeftButton")
  h.help:__fire("OnDragStart")
  assertTrue(moved.__moving, "and firing it on the mark really moves the frame")
end)

-- ── The right-click, which one host has and the other does not ───────────────

test("draghandle: a host that passes no right-click leaves both frames unregistered", function()
  -- ConsumableMaster registers none. A button registered for a click it does nothing with swallows
  -- that click, so "no handler" has to mean "no registration" rather than "an empty handler".
  local h = W.DragHandle(mocks.UIParent, baseSpec())
  assertEqual(#h.__clicks, 0)
  assertEqual(#h.help.__clicks, 0)
  T.assertNil(h:GetScript("OnClick"))
  T.assertNil(h.help:GetScript("OnClick"))
end)

test("draghandle: a host that passes one gets it on the strip and on the mark", function()
  local fired = 0
  local h = W.DragHandle(mocks.UIParent, baseSpec({ onRightClick = function() fired = fired + 1 end }))
  assertEqual(h.__clicks[1], "RightButtonUp")
  assertEqual(h.help.__clicks[1], "RightButtonUp")
  h:__fire("OnClick", "RightButton")
  assertEqual(fired, 1)
  h:__fire("OnClick", "LeftButton")
  assertEqual(fired, 1, "a left click on the strip is the drag's, not the menu's")
  h.help:__fire("OnClick")
  assertEqual(fired, 2, "and the mark passes it through")
end)

-- ── The tooltip's shape ──────────────────────────────────────────────────────

test("draghandle: no tooltip descriptor means no tooltip at all", function()
  local h = W.DragHandle(mocks.UIParent, baseSpec())
  local seen = hover(h)
  T.assertNil(seen.owner)
  assertEqual(#seen.lines, 0)
end)

test("draghandle: the three bands are a gold title, white body lines, then a spacer and gray footer", function()
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    tooltip = {
      title  = "Macro bar",
      body   = { "Drag this handle to move the bar.", "Drag a button onto another to swap them." },
      footer = { "Only Consumable Master macros can sit on this bar." },
    },
  }))
  local seen = hover(h)
  assertEqual(#seen.lines, 5)
  assertEqual(seen.lines[1].text, "Macro bar")
  assertEqual(table.concat(seen.lines[1].color, ","), "1,0.82,0")
  assertEqual(seen.lines[2].text, "Drag this handle to move the bar.")
  assertEqual(table.concat(seen.lines[2].color, ","), "1,1,1")
  assertEqual(seen.lines[4].text, " ", "one blank line separates the footer, and only when there is one")
  assertEqual(seen.lines[5].text, "Only Consumable Master macros can sit on this bar.")
  assertEqual(table.concat(seen.lines[5].color, ","), "0.6,0.6,0.6")
end)

test("draghandle: with no surviving footer line there is no spacer either", function()
  -- red under: a spacer emitted from the descriptor rather than from what survived the hover.
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    tooltip = { title = "Buffs", body = { "Drag to move." }, footer = { function() return nil end } },
  }))
  local seen = hover(h)
  assertEqual(#seen.lines, 2)
  assertEqual(seen.lines[2].text, "Drag to move.")
end)

test("draghandle: the mark shows the same tooltip the strip does", function()
  local h = W.DragHandle(mocks.UIParent, baseSpec({ tooltip = { title = "Buffs" } }))
  assertEqual(hover(h.help).lines[1].text, "Buffs")
end)

test("draghandle: a body line that answers nil is dropped, not drawn empty", function()
  -- AuraMaster's "Attached — …" line is present only while the container is attached.
  local attached = false
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    tooltip = {
      title = "Buffs",
      body  = { "Drag to move. Right-click for settings.",
                function() return attached and "Attached — set its offsets on the Layout page." or nil end },
    },
  }))
  assertEqual(#hover(h).lines, 2)
  attached = true
  assertEqual(#hover(h).lines, 3)
end)

test("draghandle: a footer line is re-evaluated on EVERY hover, not captured at build time", function()
  -- ConsumableMaster's last line reads "Locked. Unlock the bar…" or "Lock the bar…" off the live
  -- config. red under: a descriptor whose strings are resolved once, in the constructor — the
  -- tooltip would then tell a player to unlock a bar they had already unlocked, forever.
  local locked, calls = true, 0
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    tooltip = {
      title = "Macro bar",
      footer = { function()
        calls = calls + 1
        return locked and "Locked. Unlock the bar to drag this handle — /cm unlock."
          or "Lock the bar to hide this handle — /cm lock."
      end },
    },
  }))
  local first = hover(h)
  assertEqual(first.lines[3].text, "Locked. Unlock the bar to drag this handle — /cm unlock.")
  locked = false
  local second = hover(h)
  assertEqual(second.lines[3].text, "Lock the bar to hide this handle — /cm lock.")
  assertEqual(calls, 2, "called once per hover, and only on hover")
end)

test("draghandle: the owner is the host's call, because for one host it is not a style choice", function()
  -- AuraMaster's anchor inherits DisableUntrustedLayoutScriptsTemplate and the restriction reaches
  -- every frame under it, so the client REFUSES SetOwner on the strip or the mark. It must own by
  -- UIParent at the cursor. A widget that hard-coded the ConsumableMaster reading would leave that
  -- host with no tooltip at all, and only in-game.
  local tip = { title = "Buffs" }
  local cursor = W.DragHandle(mocks.UIParent, baseSpec({ tooltip = tip, tooltipOwner = "cursor" }))
  local seenCursor = hover(cursor)
  assertEqual(seenCursor.owner, mocks.UIParent)
  assertEqual(seenCursor.anchor, "ANCHOR_CURSOR")

  local own = W.DragHandle(mocks.UIParent, baseSpec({ tooltip = tip }))
  local seenSelf = hover(own)
  assertEqual(seenSelf.owner, own, "the default owns by the hovered frame")
  assertEqual(seenSelf.anchor, "ANCHOR_TOP")
  -- AND THE MARK OWNS BY THE MARK. red under: an owner taken from the strip on every hover, which
  -- is what the first draft did while four places documented the opposite.
  assertEqual(hover(own.help).owner, own.help, "the mark is a hovered frame too")

  local anchored = W.DragHandle(mocks.UIParent, baseSpec({ tooltip = tip, tooltipAnchor = "ANCHOR_TOPRIGHT" }))
  assertEqual(hover(anchored).anchor, "ANCHOR_TOPRIGHT")
end)

test("draghandle: a second descriptor gives the mark its own tooltip, owner and anchor", function()
  -- ConsumableMaster titles its strip "Consumable Master" and its mark "Macro bar", with different
  -- bodies and different anchors. red under: one descriptor for both frames, which would have
  -- silently merged two tooltips that host draws today -- and it is the host this widget exists
  -- for, so "adopt it and lose one" was never an option.
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    tooltip     = { title = "Consumable Master", body = { "Drag to move the bar." } },
    helpTooltip = {
      title  = "Macro bar",
      body   = { "Drag a button onto another to swap them." },
      anchor = "ANCHOR_TOPRIGHT",
    },
  }))
  local strip = hover(h)
  assertEqual(strip.lines[1].text, "Consumable Master")
  assertEqual(strip.anchor, "ANCHOR_TOP", "the strip keeps the spec-level default")

  local mark = hover(h.help)
  assertEqual(mark.lines[1].text, "Macro bar")
  assertEqual(mark.lines[2].text, "Drag a button onto another to swap them.")
  assertEqual(mark.owner, h.help)
  assertEqual(mark.anchor, "ANCHOR_TOPRIGHT", "and the descriptor's own anchor wins")
end)

test("draghandle: a descriptor may own by the cursor while its neighbor owns by the frame", function()
  -- The owner is per descriptor as well as per spec, because the two frames are separately
  -- restricted: nothing in the collection needs this split today, and the field is where it is so
  -- a host that hits AuraMaster's SetOwner refusal on one frame only is not stuck.
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    tooltip     = { title = "Strip" },
    helpTooltip = { title = "Mark", owner = "cursor" },
  }))
  assertEqual(hover(h).owner, h)
  assertEqual(hover(h.help).owner, mocks.UIParent)
  assertEqual(hover(h.help).anchor, "ANCHOR_CURSOR")
end)

test("draghandle: a line may carry its own color, so a gold line in a white band stays gold", function()
  -- AuraMaster draws its conditional "Attached — …" line GOLD, in the body, with no blank line
  -- above it. red under: three bands of one color each, under which adoption would have recolored
  -- that line white or pushed it into the gray footer behind a spacer -- a visual change nobody
  -- asked for, smuggled in under a refactor.
  local attached = true
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    tooltip = {
      title = "Buffs",
      body  = {
        "Drag to move. Right-click for settings.",
        { function() return attached and "Attached — set its offsets on the Layout page." or nil end,
          1, 0.82, 0 },
      },
    },
  }))
  local seen = hover(h)
  assertEqual(#seen.lines, 3)
  assertEqual(seen.lines[2].text, "Drag to move. Right-click for settings.")
  assertEqual(table.concat(seen.lines[2].color, ","), "1,1,1", "the band's own color, unchanged")
  assertEqual(seen.lines[3].text, "Attached — set its offsets on the Layout page.")
  assertEqual(table.concat(seen.lines[3].color, ","), "1,0.82,0")
  -- And a colored entry whose function answers nil is still dropped, spacer arithmetic included.
  attached = false
  assertEqual(#hover(h).lines, 2)
end)

-- ── The chrome ───────────────────────────────────────────────────────────────

test("draghandle: the strip is a plain Button with a fill, never a BackdropTemplate", function()
  -- Under an anchor attached to another frame the strip's size can read SECRET, and SetBackdrop
  -- does arithmetic on the size on every set and every resize. Four rectangles read nothing.
  -- ConsumableMaster's handle was a BackdropTemplate and loses it here; the pixels are the same,
  -- the hazard is not.
  local h = W.DragHandle(mocks.UIParent, baseSpec())
  T.assertNil(h.__template)
  assertEqual(table.concat(h.bg.__colorTexture, ","), "0,0,0,0.75")
end)

test("draghandle: a host with its own edge painter gets its own pixels", function()
  local seen
  W.DragHandle(mocks.UIParent, baseSpec({
    edge = function(frame, size, r, g, b, a) seen = { frame = frame, size = size, r = r, g = g, b = b, a = a } end,
  }))
  assertTrue(seen ~= nil, "it is called instead of the widget's own strips")
  assertEqual(seen.size, 1)
  assertEqual(table.concat({ seen.r, seen.g, seen.b, seen.a }, ","), "1,0.82,0,0.6")
end)
