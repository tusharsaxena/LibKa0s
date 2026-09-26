-- tests/test_widgets_reorderlist.lua — LibKa0s-Widgets-1.0: ReorderList (minor 8), its drag, its
-- handles and its row boxes.
--
-- ── WHY A SUITE OF ITS OWN ────────────────────────────────────────────────────────────────────
--
-- `layout-§1`. tests/test_widgets.lua was 1493 lines, seven from the 1500-line cap, and issue #37
-- named this split: by widget family, the ReorderList and row-box cases first. They moved here
-- unchanged, in their original order, and run right after that suite. What a drag borrows from the
-- host and gives back is tests/test_widgets_reorder.lua, and the unlocked strip is
-- tests/test_widgets_draghandle.lua.
--
-- ── WHY IT BUILDS ITS OWN FRAMES ──────────────────────────────────────────────────────────────
--
-- For the reason tests/test_widgets.lua gives at length. The factory and the per-case `test` that
-- installs it are tests/fixture_geom.lua's, the same copy that suite uses.

local T = _G.LK_TEST
local assertEqual = T.assertEqual
local assertTrue  = T.assertTrue
local assertFalse = T.assertFalse
local mocks       = T.mocks

local W = T.widgets

local Geom = dofile("tests/fixture_geom.lua")
local geomFrame, test = Geom.geomFrame, Geom.test

-- ── ReorderList (minor 8) ─────────────────────────────────────────────────────────────────────
--
-- IT OWNS A GESTURE, NOT A LIST, so these cases hand it bare frames and ask only about the drag.
-- There is no row content to assert on and deliberately so: the two adopting lists draw completely
-- different rows, and a widget that had opinions about them could serve neither.
--
-- THE DRAG IS DRIVEN THROUGH ITS REAL SCRIPTS -- press, move, release -- with mocks.setCursor and
-- mocks.setMouseDown standing in for the pointer. Asserting by calling the internals would pass
-- just as happily with the handle wired to nothing, which is precisely how two earlier
-- implementations of this shipped doing nothing at all.

--- A list of `n` bare rows, plus a log of what it asked its host for.
local function reorderList(n, opts)
  local log = { moved = {}, said = {} }
  opts = opts or {}
  opts.stride = opts.stride or 30
  opts.onMove = function(from, to) log.moved[#log.moved + 1] = { from, to } end
  opts.debug  = function(fmt, ...) log.said[#log.said + 1] = fmt:format(...) end

  local list = W.ReorderList(opts)
  local rows = {}
  for i = 1, n do
    local frame = geomFrame()
    frame:SetSize(200, 30)
    rows[i] = { frame = frame, handle = list:AddRow(frame, { ghostText = "row " .. i }) }
  end
  list:Finish(geomFrame())
  return list, rows, log
end

--- Grab row `from` by its handle, move `rows` rows DOWN, and release. Screen y falls downward.
local function drag(list, rows, from, n)
  local row = rows[from]
  mocks.setMouseDown("LeftButton", true)
  mocks.setCursor(0, 1000)
  row.handle:__fire("OnMouseDown")

  mocks.setCursor(0, 1000 - n * list.stride)
  W.__DragGhost:__fire("OnUpdate", 0.1)

  mocks.setMouseDown("LeftButton", false)
  W.__DragGhost:__fire("OnUpdate", 0.1)
end

test("widgets: ReorderList reports where a drag landed", function()
  local list, rows, log = reorderList(5)
  drag(list, rows, 1, 2)
  assertEqual(#log.moved, 1)
  assertEqual(log.moved[1][1], 1)
  assertEqual(log.moved[1][2], 3, "two rows down from index 1 is index 3")
end)

test("widgets: ReorderList says nothing for a drag that lands where it started", function()
  -- Reporting one would have the host rewrite its list and repaint for no change at all.
  local list, rows, log = reorderList(5)
  drag(list, rows, 2, 0)
  assertEqual(#log.moved, 0)
end)

test("widgets: ReorderList clamps a flat list to its own ends", function()
  local list, rows, log = reorderList(5)
  drag(list, rows, 4, 9)
  assertEqual(log.moved[1][2], 5, "a flat list clamps at the last row and nowhere else")
end)

test("widgets: ReorderList keeps a drag inside its group when a boundary is set", function()
  -- MultiMeters' Columns page is the one list with two groups: a shown column may not be dragged
  -- among the hidden ones, because the tick is what moves a row between them and a drag that
  -- crossed would have to silently turn a column off.
  local list, rows, log = reorderList(5, { boundary = 3 })
  drag(list, rows, 1, 4)
  assertEqual(log.moved[1][2], 3, "clamped to the last row of the first group")

  local list2, rows2, log2 = reorderList(5, { boundary = 3 })
  drag(list2, rows2, 5, -4)
  assertEqual(log2.moved[1][2], 4, "clamped to the first row of the second group")
end)

test("widgets: a boundary of 0 or the row count is one flat list", function()
  -- Both are degenerate ways of saying "there is no divide", and a clamp that treated either as a
  -- real group would pin every row where it stood.
  for _, b in ipairs({ 0, 5 }) do
    local list, rows, log = reorderList(5, { boundary = b })
    drag(list, rows, 1, 4)
    assertEqual(log.moved[1][2], 5, "boundary " .. b .. " must not divide anything")
  end
end)

test("widgets: a poll that never reports the button held cannot kill the drag", function()
  -- If IsMouseButtonDown is unavailable, protected, or simply not true yet on the first frame, a
  -- poll that ended on `not held` would finish the drag with zero rows traveled -- no error, no
  -- message, and indistinguishable from a press that was never received. It has to see the button
  -- HELD before it may act on it being released.
  local list, rows, log = reorderList(5)
  local row = rows[1]

  mocks.setMouseDown("LeftButton", false)
  mocks.setCursor(0, 1000)
  row.handle:__fire("OnMouseDown")

  mocks.setCursor(0, 1000 - 2 * list.stride)
  W.__DragGhost:__fire("OnUpdate", 0.1)
  assertEqual(#log.moved, 0, "the poll ended a drag it never saw begin")

  row.handle:__fire("OnMouseUp")
  assertEqual(#log.moved, 1, "OnMouseUp did not complete the drag")
  assertEqual(log.moved[1][2], 3, "the distance traveled was thrown away")
end)

test("widgets: every start path begins one drag and every end path completes it once", function()
  -- Which of these a client actually sends turned out not to be worth betting on. Both helpers are
  -- idempotent, so whichever order they arrive in, one grab begins once and completes once.
  local list, rows, log = reorderList(5)
  local row = rows[1]

  mocks.setMouseDown("LeftButton", true)
  mocks.setCursor(0, 1000)
  row.handle:__fire("OnDragStart")          -- the threshold path, first
  row.handle:__fire("OnMouseDown")          -- and the immediate one, second
  mocks.setCursor(0, 1000 - 2 * list.stride)
  W.__DragGhost:__fire("OnUpdate", 0.1)

  row.handle:__fire("OnDragStop")
  row.handle:__fire("OnMouseUp")
  mocks.setMouseDown("LeftButton", false)
  W.__DragGhost:__fire("OnUpdate", 0.1)

  assertEqual(#log.moved, 1, "one grab must produce exactly one reorder")
  assertEqual(log.moved[1][2], 3, "a second start must not reset the origin mid-drag")
end)

test("widgets: ReorderList carries a copy of the row under the cursor", function()
  -- The feedback the gesture actually needed. Without it nothing moves with the pointer, so a
  -- working drag and a broken one look the same from where the player is sitting.
  local list, rows = reorderList(5)
  local row = rows[2]

  mocks.setMouseDown("LeftButton", true)
  mocks.setCursor(0, 1000)
  row.handle:__fire("OnMouseDown")

  local ghost = W.__DragGhost
  assertTrue(ghost ~= nil, "no ghost was built")
  assertTrue(ghost:IsShown(), "the ghost must appear as soon as the row is grabbed")
  assertEqual(ghost.text:GetText(), "row 2", "the ghost must read as the row it came from")
  assertFalse(ghost.__mouseEnabled,
    "a ghost that takes the mouse eats the release that ends the drag")

  local firstY = select(5, ghost:GetPoint(1))
  mocks.setCursor(0, 1000 - 2 * list.stride)
  W.__DragGhost:__fire("OnUpdate", 0.1)
  assertFalse(select(5, ghost:GetPoint(1)) == firstY, "the ghost did not follow the cursor")
  assertTrue(row.frame:GetAlpha() < 1, "the row it came from must fade behind it")

  mocks.setMouseDown("LeftButton", false)
  W.__DragGhost:__fire("OnUpdate", 0.1)
  assertFalse(ghost:IsShown(), "the ghost must be put away when the drag ends")
end)

test("widgets: the insertion line is ANCHORED to the target row", function()
  -- The index comes from the cursor, but where that index sits on screen is a question only the
  -- frames can answer -- and anchoring asks it without reading a single coordinate back.
  local list, rows = reorderList(5)
  local row = rows[1]

  mocks.setMouseDown("LeftButton", true)
  mocks.setCursor(0, 1000)
  row.handle:__fire("OnMouseDown")
  mocks.setCursor(0, 1000 - 2 * list.stride)
  W.__DragGhost:__fire("OnUpdate", 0.1)

  assertTrue(list.line:IsShown(), "the line must be visible during a drag")
  local _, relativeTo = list.line:GetPoint(1)
  assertEqual(relativeTo, rows[3].frame, "the line is not against the drop target")

  mocks.setMouseDown("LeftButton", false)
  W.__DragGhost:__fire("OnUpdate", 0.1)
  T.assertNil(list.line, "the line must go back to the pool when the drag ends")
end)

test("widgets: a clamped drag still shows the line, stopped at the divide", function()
  -- A clamped drop writes nothing, so the line stopping is the only feedback there is. Without it
  -- a working clamp is indistinguishable from a broken drag -- which is how it was first reported.
  local list, rows, log = reorderList(5, { boundary = 3 })
  local row = rows[3]

  mocks.setMouseDown("LeftButton", true)
  mocks.setCursor(0, 1000)
  row.handle:__fire("OnMouseDown")
  mocks.setCursor(0, 1000 - 3 * list.stride)
  W.__DragGhost:__fire("OnUpdate", 0.1)

  assertTrue(list.line:IsShown(), "a clamped drag must still say where it would land")
  local _, relativeTo = list.line:GetPoint(1)
  assertEqual(relativeTo, rows[3].frame, "clamped to its own index, so the line sits on itself")

  mocks.setMouseDown("LeftButton", false)
  W.__DragGhost:__fire("OnUpdate", 0.1)
  assertEqual(#log.moved, 0, "a clamped drag must not report a move")
end)

test("widgets: Cancel stops a drag in flight and puts the chrome away", function()
  -- A host must call this when it repaints. A ghost left floating over a list that has already
  -- changed is worse than no feedback: it names a row that may not be there any more.
  local list, rows, log = reorderList(5)
  local row = rows[1]

  mocks.setMouseDown("LeftButton", true)
  mocks.setCursor(0, 1000)
  row.handle:__fire("OnMouseDown")
  mocks.setCursor(0, 1000 - 2 * list.stride)
  W.__DragGhost:__fire("OnUpdate", 0.1)

  list:Cancel()
  assertFalse(W.__DragGhost:IsShown(), "the ghost outlived the list it was describing")
  T.assertNil(list.line, "Cancel must give the line back to the pool")
  assertEqual(row.frame:GetAlpha(), 1, "the picked-up row must come back to full opacity")

  mocks.setMouseDown("LeftButton", false)
  W.__DragGhost:__fire("OnUpdate", 0.1)
  assertEqual(#log.moved, 0, "a canceled drag must not land after the fact")
end)

test("widgets: Cancel takes every handle OFF the host's frame", function()
  -- THE ORPHAN BUG. Both consumers hand over frames their UI framework POOLS, and AceGUI's pool is
  -- process-wide: a released container goes to whatever asks next, which was an unrelated part of
  -- the page. A handle still parented and still shown therefore turned up on "Drag to action bar",
  -- on an ID entry row, on a dropdown -- frames the list has nothing to do with.
  --
  -- So the library owns its handles and gives them back on Cancel: hidden, unanchored, and
  -- reparented off the host's frame in one step.
  -- red under: caching the handle on the host frame, or Cancel leaving it parented.
  local parent = geomFrame()
  local list = W.ReorderList({ stride = 30 })
  local handle = list:AddRow(parent, {})

  assertEqual(handle:GetParent(), parent, "the handle must be parented to the row while live")
  assertTrue(handle:IsShown())

  list:Cancel()
  assertFalse(handle:IsShown(), "a released handle must not be visible")
  assertFalse(handle:GetParent() == parent,
    "a released handle is still on the host's frame, which the host is about to hand back to a pool")
end)

test("widgets: a released handle is reused rather than a second one built", function()
  -- The other half: releasing has to return it to a free list, or every render leaks a frame.
  local parent = geomFrame()

  local first = W.ReorderList({ stride = 30 })
  local h1 = first:AddRow(parent, {})
  first:Cancel()

  local second = W.ReorderList({ stride = 30 })
  local h2 = second:AddRow(parent, {})
  assertEqual(h2, h1, "the released handle was not taken back off the free list")
  assertEqual(h2:GetParent(), parent, "and it must be re-parented to the row it now serves")
end)

test("widgets: a row may be registered with no handle at all", function()
  -- `draggable = false`. The row still counts for indices and still anchors the insertion line --
  -- it is a place a drag can LAND, just not one a drag can start from. MultiMeters' hidden columns
  -- are that case: they have an order among themselves that nothing can act on, and offering a
  -- handle for it was offering a gesture with no meaning.
  local rows = {}
  for i = 1, 4 do rows[i] = geomFrame(); rows[i]:SetSize(200, 30) end

  local moved = {}
  local list = W.ReorderList({
    stride   = 30,
    boundary = 2,
    onMove   = function(from, to) moved[#moved + 1] = { from, to } end,
  })
  local h1 = list:AddRow(rows[1], {})
  list:AddRow(rows[2], {})
  assertEqual(list:AddRow(rows[3], { draggable = false }), nil, "a non-draggable row gets no handle")
  assertEqual(list:AddRow(rows[4], { draggable = false }), nil)
  list:Finish(geomFrame())

  assertEqual(#list.rows, 4, "every row still counts, or the indices and the line go wrong")
  assertEqual(#list.handles, 2, "only the draggable rows may hold a handle")

  -- And the draggable ones still behave, clamped to their own group.
  mocks.setMouseDown("LeftButton", true)
  mocks.setCursor(0, 1000)
  h1:__fire("OnMouseDown")
  mocks.setCursor(0, 1000 - 3 * 30)
  W.__DragGhost:__fire("OnUpdate", 0.1)
  mocks.setMouseDown("LeftButton", false)
  W.__DragGhost:__fire("OnUpdate", 0.1)
  assertEqual(moved[1][2], 2, "a draggable row still clamps to the last of its own group")
end)

test("widgets: a reused handle drives the LIVE controller, not the one it was built for", function()
  -- The other half, and the half that actually freezes: a handle whose scripts close over the row
  -- they were wired with keeps pointing at a dead controller no matter how many renders pass.
  -- Reading `handle.__row` at FIRE time is what makes a stale handle impossible.
  -- red under: SetScript closing over `row`.
  local parent = geomFrame()
  parent:SetSize(200, 30)

  local first = W.ReorderList({ stride = 30 })
  first:AddRow(parent, {})
  first:AddRow(geomFrame(), {})
  first:Cancel()

  -- A second controller over the same pooled parent, with a live onMove.
  local moved = {}
  local second = W.ReorderList({
    stride = 30,
    onMove = function(from, to) moved[#moved + 1] = { from, to } end,
  })
  local handle = second:AddRow(parent, {})
  local other  = geomFrame(); other:SetSize(200, 30)
  second:AddRow(other, {})
  second:Finish(geomFrame())

  mocks.setMouseDown("LeftButton", true)
  mocks.setCursor(0, 1000)
  handle:__fire("OnMouseDown")
  mocks.setCursor(0, 1000 - 30)
  W.__DragGhost:__fire("OnUpdate", 0.1)
  mocks.setMouseDown("LeftButton", false)
  W.__DragGhost:__fire("OnUpdate", 0.1)

  assertEqual(#moved, 1, "the handle drove a dead controller, so nothing moved -- this is the freeze")
  assertEqual(moved[1][2], 2)
end)

test("widgets: the handle takes the hover color and drops it again", function()
  -- The handle has to say it is a control before you press it. The tint is the host's to choose;
  -- the default is the collection's gold, so a host that says nothing matches every other list.
  local parent = geomFrame()
  local list = W.ReorderList({ stride = 30, handleTooltip = "Drag to move" })
  local handle = list:AddRow(parent, {})

  handle:__fire("OnEnter")
  local r, g, b = handle.art.__vertexColor[1], handle.art.__vertexColor[2], handle.art.__vertexColor[3]
  assertEqual(r, 1); assertEqual(g, 0.82); assertEqual(b, 0)

  handle:__fire("OnLeave")
  assertEqual(handle.art.__vertexColor[1], 0.7, "the handle must go back to its rest color")
end)

test("widgets: a host may override both handle colors", function()
  local parent = geomFrame()
  local list = W.ReorderList({
    stride           = 30,
    handleColor      = { 0.2, 0.3, 0.4 },
    handleHoverColor = { 0.9, 0.1, 0.1 },
  })
  local handle = list:AddRow(parent, {})
  assertEqual(handle.art.__vertexColor[1], 0.2, "the rest color was not the host's")

  handle:__fire("OnEnter")
  assertEqual(handle.art.__vertexColor[1], 0.9, "the hover color was not the host's")
end)

test("widgets: only the handle starts a drag", function()
  -- Rows in these lists carry other controls -- a remove button, a score button, a toggle glyph --
  -- and a row draggable anywhere would swallow presses aimed at those. They sit pixels apart.
  local _, rows = reorderList(3)
  assertTrue(rows[1].handle:GetScript("OnMouseDown") ~= nil, "the handle must start the drag")
  assertEqual(rows[1].frame:GetScript("OnMouseDown"), nil, "the row itself must not")
end)

-- ── the row box (minor 9, options-ui-§18) ─────────────────────────────────────────────────────
--
-- The box is the half of "a stack of rows reads as blocks you can pick up" that used to live in the
-- consumers: MultiMeters drew a 6% white fill and no border, ConsumableMaster drew nothing. It is
-- the widget's now, on the same pooling terms as the handle.

test("widgets: every registered row gets a fill and four edges", function()
  -- red under: drawing the fill alone, which is what MultiMeters already had and what R1h asked
  -- for a border on top of; or drawing the box only for draggable rows, which reads as a
  -- rendering fault rather than as a rule.
  local rows = {}
  for i = 1, 2 do rows[i] = geomFrame(); rows[i]:SetSize(200, 30) end

  local list = W.ReorderList({ stride = 30 })
  list:AddRow(rows[1], {})
  list:AddRow(rows[2], { draggable = false })

  assertEqual(#list.boxes, 2, "a row that cannot be dragged is still one of the list's blocks")
  for i, box in ipairs(list.boxes) do
    assertEqual(box:GetParent(), rows[i], "the box is parented to the row it sits behind")
    assertTrue(box:IsShown())
    assertEqual(#box.edges, 4, "four edges, one a side")
    assertEqual(box.fill.__colorTexture[4], W.ROW_BOX.FILL[4], "the published fill, not a local one")
    for _, edge in ipairs(box.edges) do
      assertEqual(edge.__colorTexture[4], W.ROW_BOX.EDGE[4], "the published edge alpha")
    end
  end
end)

test("widgets: a dimmed row gets the muted variant, and a pooled box does not carry it over",
function()
  -- `dimmed` is for a row that is present but inert -- a hidden column, a source not being
  -- collected. The second half is the one that actually bites: a box comes off the free list
  -- still painted for whoever it last served.
  -- red under: painting the box once at build time instead of once per render.
  local dim = geomFrame(); dim:SetSize(200, 30)
  local first = W.ReorderList({ stride = 30 })
  first:AddRow(dim, { draggable = false, dimmed = true })
  local box = first.boxes[1]
  assertEqual(box.fill.__colorTexture[4], W.ROW_BOX.FILL_DIM[4])
  assertEqual(box.edges[1].__colorTexture[4], W.ROW_BOX.EDGE_DIM[4])
  first:Cancel()

  local bright = geomFrame(); bright:SetSize(200, 30)
  local second = W.ReorderList({ stride = 30 })
  second:AddRow(bright, { draggable = false })
  assertEqual(second.boxes[1], box, "the released box was not taken back off the free list")
  assertEqual(box.fill.__colorTexture[4], W.ROW_BOX.FILL[4],
    "a reused box kept the previous row's dimming")
  second:Cancel()
end)

test("widgets: Cancel takes every box OFF the host's frame and back to the pool", function()
  -- The same orphan bug the handles have, one frame over: both consumers hand over frames their UI
  -- framework pools, so a box left parented and shown turns up behind something else entirely.
  -- red under: reclaiming the handles and forgetting the boxes -- a fix that looks complete.
  local parent = geomFrame(); parent:SetSize(200, 30)
  local list = W.ReorderList({ stride = 30 })
  list:AddRow(parent, {})
  local box = list.boxes[1]

  list:Cancel()
  assertFalse(box:IsShown(), "a released box must not be visible")
  assertFalse(box:GetParent() == parent,
    "a released box is still on the host's frame, which the host is about to hand back to a pool")
  assertEqual(#list.boxes, 0, "the ledger was drained")

  local reused = W.ReorderList({ stride = 30 })
  reused:AddRow(parent, {})
  assertEqual(reused.boxes[1], box, "a released box must be reused rather than a second one built")
  reused:Cancel()
end)

test("widgets: rowBox = false draws no box at all", function()
  -- The opt-out exists for a consumer that must keep its own, and no consumer in the collection
  -- uses it. It is here so that "the default is ON" is a decision with a visible other side.
  -- red under: reading `opts.rowBox` truthily, which makes an omitted field mean OFF.
  local parent = geomFrame(); parent:SetSize(200, 30)
  local list = W.ReorderList({ stride = 30, rowBox = false })
  list:AddRow(parent, {})
  assertEqual(#list.boxes, 0)

  local onByDefault = W.ReorderList({ stride = 30 })
  onByDefault:AddRow(geomFrame(), {})
  assertEqual(#onByDefault.boxes, 1, "an omitted rowBox means ON")
  onByDefault:Cancel()
end)

test("widgets: the handle owns the collection's 30px gutter unless the host says otherwise",
function()
  -- Row contents start beyond it (options-ui-§8), so the number is published rather than left as a
  -- literal for each consumer to guess at -- MultiMeters was already passing 30 by hand.
  -- red under: leaving the default at 24, which puts every list's contents 6px apart from the
  -- next list's.
  assertEqual(W.ROW_BOX.HANDLE_W, 30)
  local parent = geomFrame(); parent:SetSize(200, 30)
  local list = W.ReorderList({ stride = 30 })
  assertEqual(list:AddRow(parent, {}):GetWidth(), 30)

  local narrow = W.ReorderList({ stride = 30, handleSize = 18 })
  assertEqual(narrow:AddRow(geomFrame(), {}):GetWidth(), 18, "a host may still name its own")
  narrow:Cancel()
  list:Cancel()
end)

test("widgets: a box frame that cannot make textures is skipped rather than raising", function()
  -- The degraded path is real: a headless mock's CreateTexture can answer nil or an inert table,
  -- and every texture path in this file guards on the ANSWER rather than on the method.
  -- red under: calling SetAllPoints on the answer before checking it.
  --
  -- Deliberately NOT canceled, and the free list is DRAINED FIRST. A pooled box was built with
  -- real textures, so a case about a frame that cannot make them has to be handed a new one -- and
  -- a textureless box returned to the shared list would be handed to the next case, which would
  -- then be asserting against a box that was never built.
  local drain = W.ReorderList({ stride = 30 })
  for _ = 1, 64 do drain:AddRow(geomFrame(), { draggable = false }) end

  local saved = mocks.CreateFrame
  mocks.CreateFrame = function(...)
    local f = saved(...)
    function f:CreateTexture() return nil end
    return f
  end
  local ok, err = pcall(function()
    local list = W.ReorderList({ stride = 30 })
    -- draggable = false: the HANDLE's art is unguarded by design and predates this, so a case
    -- about the box must not be answering for it.
    list:AddRow(geomFrame(), { draggable = false })
    assertEqual(#list.boxes, 1, "the box is still ledgered, so Cancel still reclaims it")
    T.assertNil(list.boxes[1].fill, "and it holds no half-built texture to keep positioning")
  end)
  mocks.CreateFrame = saved
  assertTrue(ok, "a textureless frame raised: " .. tostring(err))
end)
