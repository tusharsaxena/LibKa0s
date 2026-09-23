-- tests/test_widgets_reorder.lua — LibKa0s-Widgets-1.0: what a ReorderList drag borrows, and gives
-- back. New at Widgets minor 10.
--
-- ── WHY A SUITE OF ITS OWN ────────────────────────────────────────────────────────────────────
--
-- `layout-§1`. tests/test_widgets.lua was 1493 lines when these cases were written, seven from the
-- 1500-line cap, so they take the exit tests/test_widgets_draghandle.lua took at v1.48.0.
--
-- ── WHAT THESE CASES PIN ──────────────────────────────────────────────────────────────────────
--
-- The pooled-frame invariant Widgets.lua states over its handle pool, applied to the two things a
-- drag borrowed from the host until minor 9 and did not give back:
--
--   the POLL, which was `row.frame:SetScript("OnUpdate", ...)` on the host's own row frame and was
--   cleared with nil, wiping any OnUpdate the host had set there. It now runs on the ghost, a frame
--   this library owns.
--
--   the DROP LINE, which was cached on the container as `__ka0sDropLine`. Both shipped consumers
--   hand over an AceGUI-pooled container, so the line rode back into AceGUI's pool colored for the
--   first list that ever drew on it. It now comes from a library free list, per drag, recolored for
--   the list that is dragging, and goes back on drop and on Cancel.
--
-- ── WHY IT BUILDS ITS OWN FRAMES ──────────────────────────────────────────────────────────────
--
-- For the reason tests/test_widgets.lua gives at length: the kit's base stub answers GetParent,
-- GetScript and CreateTexture with the frame itself, and every claim here is a claim about one of
-- those. The factory is installed per case, because the kit collects every suite before it runs
-- any case.

local T = _G.LK_TEST
local rawTest     = T.test
local assertEqual = T.assertEqual
local assertTrue  = T.assertTrue
local assertFalse = T.assertFalse
local mocks       = T.mocks

local W = T.widgets

--- A frame stub modeling parentage, scripts, points, alpha and the color a texture was painted.
local function geomFrame()
  local f = { __shown = true, __w = 0, __h = 0, __scripts = {}, __points = {} }
  function f:SetSize(w, h) self.__w, self.__h = w, h; return self end
  function f:SetWidth(w) self.__w = w; return self end
  function f:SetHeight(h) self.__h = h; return self end
  function f:GetWidth() return self.__w end
  function f:Show() self.__shown = true; return self end
  function f:Hide() self.__shown = false; return self end
  function f:IsShown() return self.__shown end
  function f:SetScript(k, fn) self.__scripts[k] = fn; return self end
  function f:GetScript(k) return self.__scripts[k] end
  function f:__fire(k, ...) local fn = self.__scripts[k]; if fn then return fn(self, ...) end end
  function f:SetParent(p) self.__parent = p; return self end
  function f:GetParent() return self.__parent end
  function f:SetAlpha(a) self.__alpha = a; return self end
  function f:GetAlpha() return self.__alpha or 1 end
  function f:GetEffectiveScale() return 1 end
  function f:ClearAllPoints() self.__points = {}; return self end
  function f:SetPoint(point, rel, relPoint, x, y)
    self.__points[#self.__points + 1] =
      { point = point, relativeTo = rel, relativePoint = relPoint, x = x, y = y }
    return self
  end
  function f:GetPoint(i)
    local pt = self.__points[i or 1]
    if not pt then return nil end
    return pt.point, pt.relativeTo, pt.relativePoint, pt.x, pt.y
  end
  function f:SetText(t) self.__text = t; return self end
  function f:GetText() return self.__text end
  function f:SetColorTexture(r, g, b, a) self.__colorTexture = { r, g, b, a }; return self end
  -- A TEXTURE IS ITS OWN FRAME, so the color painted on a line's texture is not the line's own.
  function f:CreateTexture() return geomFrame() end
  function f:CreateFontString() return geomFrame() end
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

local function test(name, fn)
  return rawTest(name, function()
    local savedCF, savedUI = mocks.CreateFrame, mocks.UIParent
    mocks.CreateFrame, mocks.UIParent = geomCreateFrame, geomUIParent
    local ok, err = pcall(fn)
    mocks.CreateFrame, mocks.UIParent = savedCF, savedUI
    if not ok then error(err, 0) end
  end)
end

--- A list of `n` rows on `container`, with every onMove recorded.
local function reorderList(n, container, opts)
  local moved = {}
  opts = opts or {}
  opts.stride = 30
  opts.onMove = function(from, to) moved[#moved + 1] = { from, to } end
  local list = W.ReorderList(opts)
  local rows = {}
  for i = 1, n do
    local frame = geomFrame()
    frame:SetSize(200, 30)
    rows[i] = { frame = frame, handle = list:AddRow(frame, { ghostText = "row " .. i }) }
  end
  list:Finish(container)
  return list, rows, moved
end

--- Press row `from`'s handle and move the cursor `n` rows down, polling once. The drag is left
--- in flight; `release` ends it.
local function grab(list, rows, from, n)
  mocks.setMouseDown("LeftButton", true)
  mocks.setCursor(0, 1000)
  rows[from].handle:__fire("OnMouseDown")
  mocks.setCursor(0, 1000 - n * list.stride)
  W.__DragGhost:__fire("OnUpdate", 0.1)
end

local function release()
  mocks.setMouseDown("LeftButton", false)
  W.__DragGhost:__fire("OnUpdate", 0.1)
end

--- The color the line frame's texture was last painted, as "r,g,b,a".
---
--- Read through `line.tex`, the library's own field, because the line pool is process-wide: the
--- frame a case gets may have been built under another suite's factory, and only the library's
--- reference to its texture is the same whichever factory built it.
local function lineColor(line)
  local tex = line and line.tex
  return tex and tex.__colorTexture and table.concat(tex.__colorTexture, ",")
end

test("reorder: a host OnUpdate on a row frame survives a drag start and end", function()
  -- red under: the poll being SetScript("OnUpdate") on row.frame, cleared with nil at the drop.
  local list, rows, moved = reorderList(4, geomFrame())
  local hostTick = function() end
  rows[1].frame:SetScript("OnUpdate", hostTick)

  grab(list, rows, 1, 2)
  assertEqual(rows[1].frame:GetScript("OnUpdate"), hostTick,
    "the drag replaced the host's own OnUpdate on the row frame")

  release()
  assertEqual(#moved, 1, "the poll on the ghost must still see the release and land the drag")
  assertEqual(moved[1][2], 3)
  assertEqual(rows[1].frame:GetScript("OnUpdate"), hostTick,
    "the drop cleared the host's own OnUpdate on the row frame")
end)

test("reorder: a row frame with no OnUpdate is never given one", function()
  local list, rows = reorderList(3, geomFrame())
  grab(list, rows, 1, 1)
  T.assertNil(rows[1].frame:GetScript("OnUpdate"), "the drag wrote a script onto a host frame")
  release()
  T.assertNil(rows[1].frame:GetScript("OnUpdate"))
end)

test("reorder: two lists with different lineColor show their own color on one pooled container",
  function()
  -- The shape of the defect: AceGUI hands the same container to the next list that asks, and a
  -- line cached on it keeps the first list's color. red under: the line cached on the container.
  local container = geomFrame()

  local red, redRows = reorderList(3, container, { lineColor = { 1, 0, 0, 1 } })
  grab(red, redRows, 1, 1)
  assertEqual(lineColor(red.line), "1,0,0,1")
  release()
  red:Cancel()

  local blue, blueRows = reorderList(3, container, { lineColor = { 0, 0, 1, 1 } })
  grab(blue, blueRows, 1, 1)
  assertTrue(blue.line ~= nil, "no line during the second list's drag")
  assertEqual(lineColor(blue.line), "0,0,1,1", "the second list drew in the first list's color")
  release()
  blue:Cancel()
end)

test("reorder: the drop line is released after Cancel", function()
  -- red under: the line cached on the container, where Cancel only hid it.
  local container = geomFrame()
  local list, rows, moved = reorderList(4, container)
  grab(list, rows, 1, 2)

  local line = list.line
  assertTrue(line ~= nil and line:IsShown(), "the line must be visible during a drag")
  assertEqual(line:GetParent(), container, "the line lives on the container while it is live")

  list:Cancel()
  assertFalse(line:IsShown(), "a released line must not be visible")
  assertFalse(line:GetParent() == container,
    "the released line is still on a container its host is about to hand back to a pool")
  T.assertNil(list.line, "the controller still holds a line it gave back")
  T.assertNil(container.__ka0sDropLine, "the line is cached on the host's container")

  release()
  assertEqual(#moved, 0, "a canceled drag must not land after the fact")
end)

test("reorder: the drop line goes back at the drop, and the next drag reuses it", function()
  local container = geomFrame()
  local list, rows = reorderList(4, container)
  grab(list, rows, 1, 2)
  local line = list.line
  release()

  T.assertNil(list.line, "the drop kept the line")
  assertFalse(line:IsShown())
  assertFalse(line:GetParent() == container, "the drop left the line on the host's container")

  -- A second drag, on another list and another container, takes the same frame back rather than
  -- building one per drag.
  local other = geomFrame()
  local next, nextRows = reorderList(4, other)
  grab(next, nextRows, 2, 1)
  assertEqual(next.line, line, "a released line was not reused")
  assertEqual(next.line:GetParent(), other)
  release()
  list:Cancel()
  next:Cancel()
end)
