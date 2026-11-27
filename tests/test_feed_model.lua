-- tests/test_feed_model.lua -- LibKa0s-Feed-1.0's pure half (FeedModel.lua, `lib.__model`).
--
-- No frames: every case calls the model on plain tables. The snapshot's defaults and its reads,
-- the slot and nudge math (and their round trip), row heights and the stack's layout, the phase
-- machine, merge and drain.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local F = dofile("tests/fixture_feed.lua")

local function model()
  local _, Feed = F.env()
  return Feed.__model, Feed
end

local function near(a, b, eps) return type(a) == "number" and math.abs(a - b) <= (eps or 1e-9) end

local function assertNear(a, b, msg, eps)
  assertTrue(near(a, b, eps), (msg or "") .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end

-- == the snapshot =============================================================================

test("feed model: an empty descriptor snapshots every published default", function()
  local M, Feed = model()
  local cfg = M.Snapshot({})
  local L, m, s = cfg.layout, cfg.motion, cfg.style
  assertEqual(L.slot, "BOTTOMRIGHT")
  assertEqual(L.x, 0); assertEqual(L.y, 0)
  assertEqual(L.grow, "UP")
  assertEqual(L.shown, Feed.SHOWN)
  assertEqual(L.width, Feed.WIDTH)
  assertEqual(L.rowHeight, Feed.ROW_HEIGHT)
  assertEqual(L.iconSize, Feed.ICON_SIZE)
  assertEqual(L.padding, Feed.PADDING)
  assertEqual(L.gap, Feed.GAP)
  assertEqual(L.align, "left"); assertEqual(L.iconSide, "left")
  assertEqual(L.scale, 1)
  assertEqual(m.enter, "fade")
  assertEqual(m.enterTime, Feed.ENTER_TIME)
  assertEqual(m.hold, Feed.HOLD)
  assertEqual(m.fadeTime, Feed.FADE_TIME)
  assertEqual(m.mergeWindow, Feed.MERGE_WINDOW)
  assertTrue(m.pulse); assertFalse(m.timerBar); assertTrue(m.smooth); assertTrue(m.pin)
  assertTrue(m.rightDismiss)
  assertEqual(m.settle, 0)
  for _, k in ipairs({ "bgFromSkin", "borderStyleFromSkin", "borderColorFromSkin", "fontFromSkin",
    "fontSizeFromSkin", "fontShadowFromSkin", "fontColorFromSkin", "barFromSkin", "glowColorFromSkin" }) do
    assertTrue(s[k] == true, k .. " defaults to the skin")
  end
  assertFalse(s.borderTint); assertFalse(s.borderClass); assertFalse(s.fontClass)
  assertEqual(cfg.maxQueue, Feed.MAX_QUEUE)
  -- Nothing at all, too.
  assertEqual(M.Snapshot(nil).layout.slot, "BOTTOMRIGHT")
end)

test("feed model: garbage values fall back to the defaults, and unknown keys are ignored", function()
  local M, Feed = model()
  local cfg = M.Snapshot({
    layout = { slot = "MIDDLE", x = "far", y = 0 / 0, grow = "SIDEWAYS", shown = -3, width = -1,
      rowHeight = math.huge, padding = -2, gap = "x", align = 1, iconSide = true, scale = 0, bogus = 1 },
    motion = { enter = "spin", enterTime = -1, hold = "long", fadeTime = 0 / 0, mergeWindow = -5,
      pulse = "yes", timerBar = 1, smooth = {}, pin = 0, rightDismiss = "no", settle = -1 },
    style = { bgFromSkin = "no", bgType = "plaid", bgColor = { "r" }, borderSize = -1, fontSize = 0 },
    maxQueue = 0,
  })
  local L, m, s = cfg.layout, cfg.motion, cfg.style
  assertEqual(L.slot, "BOTTOMRIGHT"); assertEqual(L.x, 0); assertEqual(L.y, 0)
  assertEqual(L.grow, "UP"); assertEqual(L.shown, 1, "a shown under 1 clamps to 1")
  assertEqual(L.width, Feed.WIDTH); assertEqual(L.rowHeight, Feed.ROW_HEIGHT)
  assertEqual(L.padding, Feed.PADDING); assertEqual(L.gap, Feed.GAP)
  assertEqual(L.align, "left"); assertEqual(L.iconSide, "left"); assertEqual(L.scale, 1)
  assertNil(L.bogus, "an unknown key is not carried")
  assertEqual(m.enter, "fade"); assertEqual(m.enterTime, Feed.ENTER_TIME); assertEqual(m.hold, Feed.HOLD)
  assertEqual(m.fadeTime, Feed.FADE_TIME); assertEqual(m.mergeWindow, Feed.MERGE_WINDOW)
  assertTrue(m.pulse); assertFalse(m.timerBar); assertTrue(m.smooth); assertTrue(m.pin)
  assertTrue(m.rightDismiss); assertEqual(m.settle, 0)
  assertTrue(s.bgFromSkin); assertEqual(s.bgType, "solid")
  assertEqual(table.concat(s.bgColor, ","), table.concat(M.BG_COLOR, ","))
  assertEqual(s.borderSize, 1); assertEqual(s.fontSize, M.FONT_SIZE)
  assertEqual(cfg.maxQueue, Feed.MAX_QUEUE)
end)

test("feed model: good values are kept, clamped where the contract clamps", function()
  local M, Feed = model()
  local cfg = M.Snapshot({
    layout = { slot = "TOPLEFT", x = 900, y = -900, grow = "DOWN", shown = 40, width = 280,
      rowHeight = 40, iconSize = 60, padding = 4, gap = 0, align = "right", iconSide = "right", scale = 1.5 },
    motion = { enter = "left", enterTime = 0.5, hold = 2, fadeTime = 0, mergeWindow = 0, pulse = false,
      timerBar = true, smooth = false, pin = false, rightDismiss = false, settle = 1.5 },
    style = { bgFromSkin = false, bgType = "gradient", bgColor = { r = 1, g = 0, b = 0 },
      borderColor = { 0, 1, 0, 0.5 }, borderTint = true, fontFlags = "OUTLINE" },
    maxQueue = 3.7,
  })
  local L, m, s = cfg.layout, cfg.motion, cfg.style
  assertEqual(L.slot, "TOPLEFT")
  assertEqual(L.x, Feed.NUDGE_MAX); assertEqual(L.y, -Feed.NUDGE_MAX)
  assertEqual(L.grow, "DOWN"); assertEqual(L.shown, Feed.SHOWN_MAX)
  assertEqual(L.width, 280); assertEqual(L.rowHeight, 40); assertEqual(L.padding, 4); assertEqual(L.gap, 0)
  assertEqual(L.iconSize, 32, "clamped to the row's inner height, 40 - 2 * 4")
  assertEqual(L.align, "right"); assertEqual(L.iconSide, "right"); assertEqual(L.scale, 1.5)
  assertEqual(m.enter, "left"); assertEqual(m.enterTime, 0.5); assertEqual(m.hold, 2)
  assertEqual(m.fadeTime, 0); assertEqual(m.mergeWindow, 0)
  assertFalse(m.pulse); assertTrue(m.timerBar); assertFalse(m.smooth); assertFalse(m.pin)
  assertFalse(m.rightDismiss); assertEqual(m.settle, 1.5)
  assertFalse(s.bgFromSkin); assertEqual(s.bgType, "gradient")
  assertEqual(table.concat(s.bgColor, ","), "1,0,0,1", "r/g/b keys read, alpha 1")
  assertEqual(table.concat(s.borderColor, ","), "0,1,0,0.5")
  assertTrue(s.borderTint); assertEqual(s.fontFlags, "OUTLINE")
  assertEqual(cfg.maxQueue, 3, "floored")
  -- "none" forces a zero enter whatever enterTime says.
  assertEqual(M.Snapshot({ motion = { enter = "none", enterTime = 2 } }).motion.enterTime, 0)
end)

test("feed model: each group is a value or a getter, and a getter that raises answers nothing", function()
  local M = model()
  local n = 0
  local cfg = M.Snapshot({
    layout = function() n = n + 1; return { slot = "TOP" } end,
    motion = function() n = n + 1; return { hold = 9 } end,
    style = function() error("boom") end,
    maxQueue = function() return 4 end,
  })
  assertEqual(n, 2, "each getter read once")
  assertEqual(cfg.layout.slot, "TOP")
  assertEqual(cfg.motion.hold, 9)
  assertTrue(cfg.style.bgFromSkin, "the raising getter reads as an empty table")
  assertEqual(cfg.maxQueue, 4)
  -- A getter answering something other than a table is an empty table, too.
  assertEqual(M.Snapshot({ layout = function() return 7 end }).layout.slot, "BOTTOMRIGHT")
end)

-- == the slot and the nudge ===================================================================

test("feed model: SlotOffset adds each slot's inset, inward from the screen edge", function()
  local M, Feed = model()
  local I = Feed.SLOT_INSET
  local want = {
    TOPLEFT = { I, -I }, TOP = { 0, -I }, TOPRIGHT = { -I, -I },
    LEFT = { I, 0 }, CENTER = { 0, 0 }, RIGHT = { -I, 0 },
    BOTTOMLEFT = { I, I }, BOTTOM = { 0, I }, BOTTOMRIGHT = { -I, I },
  }
  for _, slot in ipairs(Feed.SLOTS) do
    local s, ox, oy = M.SlotOffset(slot, 10, -7)
    assertEqual(s, slot)
    assertEqual(ox, 10 + want[slot][1], slot .. " x")
    assertEqual(oy, -7 + want[slot][2], slot .. " y")
  end
  assertEqual(M.Origin("TOPLEFT", "UP"), "BOTTOMLEFT")
  assertEqual(M.Origin("TOP", "DOWN"), "TOP")
  assertEqual(M.Origin("RIGHT", "DOWN"), "TOPRIGHT")
  assertEqual(M.Origin("CENTER", "UP"), "BOTTOM")
end)

--- The rect, in UIParent units, of a container w by h (already scaled) anchored by its origin
--- at `slot` with offsets ox, oy on a W by H screen.
local function rectFor(slot, grow, ox, oy, w, h, W, H)
  local slotX = slot:find("LEFT") and 0 or slot:find("RIGHT") and W or W / 2
  local slotY = slot:find("BOTTOM") and 0 or slot:find("TOP") and H or H / 2
  local originX, originY = slotX + ox, slotY + oy
  local left
  if slot:find("LEFT") then left = originX
  elseif slot:find("RIGHT") then left = originX - w
  else left = originX - w / 2 end
  local bottom = grow == "UP" and originY or originY - h
  return left, bottom, left + w, bottom + h
end

test("feed model: NudgeFromRect round-trips SlotOffset for every slot, both grows and two scales", function()
  local M, Feed = model()
  local W, H = 1920, 1080
  for _, slot in ipairs(Feed.SLOTS) do
    for _, grow in ipairs({ "UP", "DOWN" }) do
      for _, scale in ipairs({ 1, 1.5 }) do
        local x, y = 37, -52
        local _, ox, oy = M.SlotOffset(slot, x, y)
        local l, b, r, t = rectFor(slot, grow, ox, oy, 320 * scale, 160 * scale, W, H)
        local nx, ny = M.NudgeFromRect(slot, grow, l, b, r, t, W, H)
        local tag = slot .. "/" .. grow .. "/" .. scale
        assertNear(nx, x, tag .. " x")
        assertNear(ny, y, tag .. " y")
      end
    end
  end
end)

test("feed model: NudgeFromRect clamps to plus or minus NUDGE_MAX", function()
  local M, Feed = model()
  local N = Feed.NUDGE_MAX
  local x, y = M.NudgeFromRect("BOTTOMLEFT", "UP", 1500, 1000, 1820, 1100, 1920, 1080)
  assertEqual(x, N); assertEqual(y, N)
  x, y = M.NudgeFromRect("TOPRIGHT", "DOWN", -900, -900, -580, -700, 1920, 1080)
  assertEqual(x, -N); assertEqual(y, -N)
end)

-- == heights and layout =======================================================================

test("feed model: RowHeight never goes under rowHeight, and sums the filled lines", function()
  local M = model()
  local layout = { rowHeight = 48, padding = 6 }
  assertEqual(M.RowHeight({ title = "x", lines = { {}, {}, {} } }, layout, 12, 10), 48, "the floor")
  -- 6*2 + 14 + 3 lines of 12 + sub 12 = 74
  local spec = { title = "x", sub = "s",
    lines = { { left = "a" }, { right = "b" }, { left = "", right = "" } } }
  assertEqual(M.RowHeight(spec, layout, 12, 10), 6 * 2 + 14 + 3 * 12, "two lines and the sub")
  spec.lines[3].left = "c"
  assertEqual(M.RowHeight(spec, layout, 12, 10), 6 * 2 + 14 + 4 * 12, "three lines and the sub")
  assertEqual(M.RowHeight(spec, { rowHeight = 100, padding = 6 }, 12, 10), 100, "a tall floor wins")
end)

test("feed model: Layout stacks mixed heights with the gap, newest at 0", function()
  local M = model()
  local entries = { { h = 48 }, { h = 74 }, { h = 50 } }
  local height = M.Layout(entries, { gap = 5 })
  assertEqual(entries[1].targetY, 0)
  assertEqual(entries[2].targetY, 53)
  assertEqual(entries[3].targetY, 53 + 74 + 5)
  assertEqual(height, 53 + 74 + 5 + 50)
  assertEqual(M.Layout({}, { gap = 5 }), 1, "an empty stack is 1 high")
end)

-- == the phase machine ========================================================================

local function motion(over)
  local M = model()
  local m = M.Snapshot({ motion = over or {} }).motion
  return M, m
end

test("feed model: the fade enter eases out over enterTime", function()
  local M, m = motion({ enter = "fade", enterTime = 0.25 })
  local e = { t = 0, h = 48 }
  local a, dx, dy, bar, done = M.Advance(e, m, 0.125, false)
  assertNear(a, 1 - 0.5 * 0.5, "half way is 0.75")
  assertEqual(dx, 0); assertEqual(dy, 0); assertEqual(bar, 1); assertFalse(done)
  assertEqual(e.phase, "enter")
end)

test("feed model: the four slides start a full width or height away, at full alpha", function()
  local M, m = motion({ enter = "left", enterTime = 0.2 })
  local cases = { left = { -300, 0 }, right = { 300, 0 }, up = { 0, 50 }, down = { 0, -50 } }
  for dir, want in pairs(cases) do
    m.enter = dir
    local e = { t = 0, h = 50 }
    local a, dx, dy = M.Advance(e, m, 0, false, 300)
    assertEqual(a, 1, dir .. " alpha")
    assertNear(dx, want[1], dir .. " dx"); assertNear(dy, want[2], dir .. " dy")
    -- Half way: (1 - k) of the distance, k = 0.75.
    local _, hx, hy = M.Advance(e, m, 0.1, false, 300)
    assertNear(hx, want[1] * 0.25, dir .. " dx half"); assertNear(hy, want[2] * 0.25, dir .. " dy half")
  end
end)

test("feed model: an enter of none is no enter at all", function()
  local M, m = motion({ enter = "none", enterTime = 1 })
  local e = { t = 0, h = 48 }
  local a, dx, dy, bar = M.Advance(e, m, 0, false)
  assertEqual(a, 1); assertEqual(dx, 0); assertEqual(dy, 0); assertEqual(bar, 1)
  assertEqual(e.phase, "hold")
end)

test("feed model: hold draws the exact bar, then the fade, then done", function()
  local M, m = motion({ enterTime = 0.25, hold = 4, fadeTime = 1 })
  local e = { t = 0.25, h = 48 }
  local a, _, _, bar = M.Advance(e, m, 1, false)
  assertEqual(a, 1); assertEqual(e.phase, "hold")
  assertNear(bar, 1 - (1.25 - 0.25) / 4, "bar = 1 - (t - enter) / hold")
  a, _, _, bar = M.Advance(e, m, 3.5, false)   -- t = 4.75, half the fade
  assertEqual(e.phase, "fade")
  assertNear(a, 0.5, "half faded"); assertEqual(bar, 0)
  local done
  a, _, _, _, done = M.Advance(e, m, 0.5, false)
  assertTrue(done, "past the fade"); assertEqual(a, 0)
  -- fadeTime 0 vanishes at the end of the hold.
  local M2, m2 = motion({ enterTime = 0, hold = 1, fadeTime = 0 })
  local e2 = { t = 0, h = 48 }
  local _, _, _, _, d2 = M2.Advance(e2, m2, 1, false)
  assertTrue(d2, "no fade, gone")
end)

test("feed model: a drop fades from the alpha it had over DROP_FADE, whatever pauses", function()
  local M, m = motion()
  local e = { t = 0, phase = "drop", a0 = 0.6, h = 48 }
  local a, _, _, bar, done = M.Advance(e, m, 0.1, true)
  assertNear(a, 0.6 * 0.5, "half the drop, from 0.6")
  assertEqual(bar, 0); assertFalse(done)
  _, _, _, _, done = M.Advance(e, m, 0.1, true)
  assertTrue(done, "released at DROP_FADE")
end)

test("feed model: a sticky entry stops at the end of its enter and draws no bar", function()
  local M, m = motion({ enterTime = 0.25, hold = 1, fadeTime = 1 })
  local e = { t = 0, sticky = true, h = 48 }
  local a, _, _, bar, done = M.Advance(e, m, 60, false)
  assertEqual(e.t, 0.25, "t clamped at enterTime")
  assertEqual(a, 1); assertNil(bar, "no bar"); assertFalse(done)
  assertEqual(e.phase, "hold")
end)

test("feed model: paused stops t, but not the pulse", function()
  local M, m = motion({ enterTime = 0.25, hold = 4 })
  local e = { t = 1, pulse = 0.6, h = 48 }
  M.Advance(e, m, 0.1, true)
  assertEqual(e.t, 1, "t held")
  assertNear(e.pulse, 0.5, "the pulse ran")
  M.Advance(e, m, 0.1, false)
  assertNear(e.t, 1.1, "t moves once unpaused")
  M.Advance(e, m, 5, true)
  assertEqual(e.pulse, 0, "the pulse never goes under 0")
end)

-- == merge and drain ==========================================================================

test("feed model: a merge inside the window restarts the hold without replaying the enter", function()
  local M, m = motion({ enterTime = 0.25, hold = 4, fadeTime = 1, mergeWindow = 3 })
  local e = { t = 4.6, phase = "fade", alpha = 0.3, payload = { n = 1 }, lastAt = 10, h = 48 }
  local seen
  local ok, err = M.Merge(e, { n = 2 }, "k", m, 12, function(old, new, key)
    seen = key
    return { n = old.n + new.n }
  end)
  assertTrue(ok); assertNil(err)
  assertEqual(seen, "k")
  assertEqual(e.payload.n, 3, "the reducer's answer")
  assertEqual(e.lastAt, 12)
  assertEqual(e.t, 0.25, "back to the start of the hold")
  assertEqual(e.phase, "hold"); assertEqual(e.alpha, 1, "a fading row snaps back")
  assertEqual(e.pulse, 0.6, "PULSE_TIME")
  -- While entering, the enter keeps running.
  local e2 = { t = 0.1, phase = "enter", payload = 1, lastAt = 0, h = 48 }
  M.Merge(e2, 2, nil, m, 1, nil)
  assertEqual(e2.t, 0.1, "the enter is kept"); assertEqual(e2.phase, "enter")
  assertEqual(e2.payload, 2, "no reducer: the newer payload replaces")
end)

test("feed model: no merge outside the window, with mergeWindow 0, or into a dropping entry", function()
  local M, m = motion({ mergeWindow = 3 })
  local e = { t = 1, phase = "hold", payload = 1, lastAt = 0, h = 48 }
  assertFalse(M.Merge(e, 2, "k", m, 3.5, nil), "outside the window")
  assertEqual(e.payload, 1)
  local drop = { t = 0, phase = "drop", payload = 1, lastAt = 0, h = 48 }
  assertFalse(M.Merge(drop, 2, "k", m, 0.5, nil), "a dropping entry never merges")
  local _, m0 = motion({ mergeWindow = 0 })
  assertFalse(M.Merge(e, 2, "k", m0, 0, nil), "a zero window never merges")
end)

test("feed model: a merge into a waiting entry takes only the payload and the time", function()
  local M, m = motion({ mergeWindow = 3 })
  local e = { phase = "wait", payload = 1, lastAt = 0 }
  assertTrue(M.Merge(e, 2, "k", m, 1, nil))
  assertEqual(e.payload, 2); assertEqual(e.lastAt, 1)
  assertNil(e.t, "no clock started"); assertNil(e.pulse, "no pulse")
end)

test("feed model: a raising reducer keeps the newer payload and hands back its error", function()
  local M, m = motion()
  local e = { t = 1, phase = "hold", payload = 1, lastAt = 0, h = 48 }
  local ok, err = M.Merge(e, 2, "k", m, 1, function() error("bad merge") end)
  assertTrue(ok)
  assertTrue(tostring(err):find("bad merge", 1, true) ~= nil, "the error")
  assertEqual(e.payload, 2)
end)

test("feed model: a reducer answering nil keeps the newer payload", function()
  local M, m = motion()
  local e = { t = 1, phase = "hold", payload = 1, lastAt = 0, h = 48 }
  local ok, err = M.Merge(e, 2, "k", m, 1, function() return nil end)
  assertTrue(ok); assertNil(err)
  assertEqual(e.payload, 2, "merge(old, new, key) or new")
end)

test("feed model: Drain presents only the newest n, oldest first, and frees the rest", function()
  local M = model()
  local waiting = { { key = 1 }, { key = 2 }, { key = 3 }, { key = 4 } }
  local present, freed = {}, {}
  assertEqual(M.Drain(waiting, 3, present, freed), 3)
  assertEqual(#waiting, 0, "emptied")
  assertEqual(present[1].key, 2); assertEqual(present[2].key, 3); assertEqual(present[3].key, 4)
  assertEqual(#freed, 1); assertEqual(freed[1].key, 1)
  local p2, f2 = {}, {}
  assertEqual(M.Drain({ { key = "a" } }, 5, p2, f2), 1, "fewer waiting than n")
  assertEqual(#f2, 0)
end)
