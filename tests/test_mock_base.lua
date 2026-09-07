-- tests/test_mock_base.lua — the shared mock's geometry surface, and the default it does NOT change.
--
-- The kit's frame stub answered `GetHeight()` with 0 for every frame and defined no `SetAtlas` at
-- all, which made one whole class of assertion unwritable in ten repositories at once. The strip in
-- `OptionsWidgets.lua` measures its row pitch off the UNSELECTED tab art — `tabArtHeight()` asks a
-- probe texture to take an atlas at its own size and reads the height back — so under the old stub
-- that measurement always came back 0, always took the `L.TAB_H` fallback, and every
-- `options-ui-§13` geometry-invariance case passed without ever measuring anything. Four addons
-- filed the missing case and not one of them could write it.
--
-- WHAT THIS REVISION ADDS, AND WHAT IT DELIBERATELY DOES NOT. The surface arrives; the default does
-- not move. `SetAtlas` records what it was told and `GetHeight` goes on answering 0 until a test
-- arms the frame with `__setGeom`, so a suite that never mentions geometry sees exactly what it saw
-- before. That is not a nicety: production code calls `SetAtlas` itself, on a probe texture no test
-- holds a handle to, and a `SetAtlas` that armed geometry on its own would switch the pitch
-- measurement on in every suite in the collection at once — the flip, arriving by accident, a
-- revision early. It was written that way first here, and three of this repo's own widget cases went
-- red inside a minute; that is the evidence the arming exists on.
--
-- The first two cases below are the ones that matter. They pin the default and they pin what moves
-- it, which together are the entire claim that nine consumers can take this and count nothing.
--
-- These cases drive the mock through `T.mocks`, the built environment this repo's own suites use,
-- rather than dofile'ing the kit directly: the published atlas table has to be reachable from a
-- consumer's finished mock or it is of no use to the nine, and reaching it that way is the check.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local mocks = T.mocks

--- A bare frame from the mock, the way production code gets one.
local function frame()
  return mocks.CreateFrame("Frame", nil, mocks.UIParent)
end

test("mock: a frame that was never armed answers zero, dressed or not", function()
  -- The additive contract, and the line kit 16 crosses on purpose. Roughly 308 test files across
  -- the collection rest on this answer; if this case ever goes red without somebody meaning it to,
  -- the flip has arrived early and nine suites are about to disagree with their own trend lines.
  local f = frame()
  assertEqual(f:GetHeight(), 0, "an unarmed frame's height")
  assertEqual(f:GetWidth(), 0, "an unarmed frame's width")

  f:SetAtlas("Options_Tab_Middle", true)
  assertEqual(f:GetHeight(), 0, "still zero after production dresses it at the art's own size")
  assertEqual(f:GetWidth(), 0, "width likewise")
end)

test("mock: __setGeom is the opt-in, and the only thing that arms a frame", function()
  local f = frame()
  f:__setGeom(120, 37)
  assertEqual(f:GetHeight(), 37, "height after __setGeom")
  assertEqual(f:GetWidth(), 120, "width after __setGeom")
  -- Per frame, not per environment: arming one frame must not arm its neighbours, or the opt-in is
  -- a global switch wearing a method's clothes.
  assertEqual(frame():GetHeight(), 0, "a sibling frame is unaffected")
end)

test("mock: an armed frame takes its height from the published atlas table", function()
  local sizes = mocks.__atlasSizes
  assertTrue(type(sizes) == "table", "the kit publishes __atlasSizes")
  local want = sizes["Options_Tab_Middle"]
  assertTrue(type(want) == "table", "Options_Tab_Middle is published")

  -- Arm first, then let the code under test dress it — which is how a real measurement case will
  -- read: the test owns the switch, production owns the atlas.
  local tex = frame():__setGeom()
  tex:SetAtlas("Options_Tab_Middle", true)
  assertEqual(tex:GetHeight(), want[2], "height after SetAtlas(..., true)")
  assertEqual(tex:GetWidth(), want[1], "width after SetAtlas(..., true)")
  -- Read off the published table rather than a literal on purpose: these figures are the kit's
  -- fixture, not a measurement taken from a client, and a case pinned to the literal 28 is a case
  -- that goes red for the wrong reason the day a real measurement corrects the fixture.
end)

test("mock: SetAtlas records the name whether or not a size was asked for", function()
  -- Which art a widget dressed itself in is worth asserting on its own, and needs no arming: this
  -- is what a repo's tab suite hand-rolls a whole texture object to observe today.
  local f = frame()
  f:SetAtlas("Options_Tab_Middle")
  assertEqual(f.__atlas, "Options_Tab_Middle", "the atlas name is recorded without useAtlasSize")

  local g = frame()
  g:SetAtlas("Options_Tab_Active_Middle", true)
  assertEqual(g.__atlas, "Options_Tab_Active_Middle", "and with it")
end)

test("mock: an atlas the table does not publish leaves geometry alone", function()
  -- The real client draws nothing for an unknown atlas rather than resizing to zero, and a stub
  -- that answered 0 here would be indistinguishable from a frame nobody ever dressed.
  local f = frame():__setGeom(10, 20)
  f:SetAtlas("Options_Tab_NoSuchThing", true)
  assertNil(mocks.__atlasSizes["Options_Tab_NoSuchThing"], "the fixture really has no such entry")
  assertEqual(f:GetHeight(), 20, "the height it already had survives")
  assertEqual(f.__atlas, "Options_Tab_NoSuchThing", "the name is still recorded")
end)

test("mock: the selected and unselected tab atlases are published at different heights", function()
  -- This is the property the whole selection-invariance class of case rests on. The client does not
  -- draw `Options_Tab_Active_*` at the height it draws `Options_Tab_*`, and a fixture that answered
  -- one number for every atlas could not fail an invariance assertion — which is exactly how
  -- anti-patterns #70 shipped green the first time.
  local sizes = mocks.__atlasSizes
  local off, on = sizes["Options_Tab_Middle"], sizes["Options_Tab_Active_Middle"]
  assertTrue(type(off) == "table" and type(on) == "table", "both families are published")
  assertTrue(off[2] ~= on[2],
    "the two tab atlas families must not share a height, or an invariance case cannot fail")
end)
