-- tests/test_widgets_teststrip.lua — LibKa0s-Widgets-1.0: `lib.TestStrip` (minors 13 and
-- 14), the mode strip a window lays between its chrome and its data (#48): test mode, or a
-- simulation (`opts.kind = "sim"`, minor 14).
--
-- Every case runs under the geometry factory tests/fixture_geom.lua installs (the reason is
-- tests/test_widgets.lua's header), wrapped once more here by `recording`: the geometry frame
-- answers its catch-all for the mouse, the justification, the word wrap, SetAllPoints and HookScript, so a case
-- could not ask whether the constructor enabled the mouse or whether a host's wrap stuck. The
-- wrapper rawsets a recorder for exactly those, on the strip and on the regions it builds, and
-- nothing else.

local T = _G.LK_TEST
local assertEqual = T.assertEqual
local assertTrue  = T.assertTrue
local assertFalse = T.assertFalse
local mocks       = T.mocks
local W = T.widgets

local Geom = dofile("tests/fixture_geom.lua")
local test = Geom.test

local HOST_ICON = "Interface\\AddOns\\Host\\libs\\LibKa0s\\media\\icons\\info"

--- Add the recorders this suite reads to one frame or region.
local function record(f)
  rawset(f, "EnableMouse", function(self, v)
    self.__mouseCalls = (self.__mouseCalls or 0) + 1
    self.__mouse = v and true or false
  end)
  rawset(f, "IsMouseEnabled", function(self) return self.__mouse or false end)
  rawset(f, "SetJustifyH", function(self, v) self.__justifyH = v end)
  rawset(f, "SetWordWrap", function(self, v) self.__wordWrap = v end)
  rawset(f, "SetAllPoints", function(self, rel) self.__allPoints = rel or true end)
  -- Chained as the client chains a hook: the script that was set runs first.
  rawset(f, "HookScript", function(self, name, hook)
    local prev = self.__scripts[name]
    self.__scripts[name] = function(...)
      if prev then prev(...) end
      return hook(...)
    end
  end)
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

--- Run `fn()` with every frame CreateFrame builds carrying the recorders above.
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

-- ── birth ────────────────────────────────────────────────────────────────────────────────────

test("TestStrip: born hidden, unanchored and 18 tall, with its regions", function()
  recording(function()
    local s = W.TestStrip(mocks.UIParent, { text = "TEST MODE", icon = HOST_ICON })
    assertEqual(s.__frameType, "Frame")
    assertTrue(s.__parent == mocks.UIParent, "parented to the host's frame")
    assertFalse(s:IsShown())
    assertEqual(s:GetNumPoints(), 0)
    assertEqual(s:GetHeight(), 18)
    assertEqual(W.TEST_STRIP.HEIGHT, 18)
    assertTrue(s.__fill ~= nil, "the fill is stored")
    assertTrue(s.__icon ~= nil, "the icon is stored")
    assertTrue(s.text ~= nil, "the text is public")
    -- The internals are not the contract: no public `fill` / `icon` fields.
    assertEqual(rawget(s, "fill"), nil)
    assertEqual(rawget(s, "icon"), nil)
  end)
end)

test("TestStrip: the fill is the collection's amber at 12%, on all points", function()
  recording(function()
    local s = W.TestStrip(mocks.UIParent)
    local c = s.__fill.__colorTexture
    assertEqual(c[1], 1.00); assertEqual(c[2], 0.65); assertEqual(c[3], 0.15); assertEqual(c[4], 0.12)
    assertEqual(s.__fill.__layer, "BACKGROUND")
    assertTrue(s.__fill.__allPoints == s, "the fill covers the strip, all points")
    assertEqual(s.__fill:GetNumPoints(), 0)
  end)
end)

-- ── the icon ─────────────────────────────────────────────────────────────────────────────────

test("TestStrip: an icon path draws a 12x12 mark at LEFT+6, text on its RIGHT+6", function()
  recording(function()
    local s = W.TestStrip(mocks.UIParent, { text = "x", icon = HOST_ICON })
    assertEqual(s.__icon.__texture, HOST_ICON)
    assertEqual(s.__icon.__layer, "ARTWORK")
    assertEqual(s.__icon:GetWidth(), 12)
    assertEqual(s.__icon:GetHeight(), 12)
    local ip = point(s.__icon, 1)
    assertEqual(ip.point, "LEFT"); assertTrue(ip.rel == s, "anchored to the strip")
    assertEqual(ip.relPoint, "LEFT"); assertEqual(ip.x, 6)
    local tp = point(s.text, 1)
    assertEqual(tp.point, "LEFT"); assertTrue(tp.rel == s.__icon, "anchored to the icon")
    assertEqual(tp.relPoint, "RIGHT"); assertEqual(tp.x, 6)
  end)
end)

test("TestStrip: no icon leaves __icon nil and the text at the strip's LEFT+6", function()
  recording(function()
    local s = W.TestStrip(mocks.UIParent, { text = "x" })
    assertEqual(s.__icon, nil)
    local tp = point(s.text, 1)
    assertEqual(tp.point, "LEFT"); assertTrue(tp.rel == s, "anchored to the strip")
    assertEqual(tp.relPoint, "LEFT"); assertEqual(tp.x, 6)
    -- Anything that is not a path or a fileID is no icon, not a fallback.
    assertEqual(W.TestStrip(mocks.UIParent, { icon = true }).__icon, nil)
  end)
end)

test("TestStrip: a numeric fileID is an icon too", function()
  recording(function()
    local s = W.TestStrip(mocks.UIParent, { icon = 134400 })
    assertEqual(s.__icon.__texture, 134400)
  end)
end)

-- ── the text ─────────────────────────────────────────────────────────────────────────────────

test("TestStrip: the text is GameFontNormalSmall, RIGHT at -6, LEFT-justified, no wrap", function()
  recording(function()
    local s = W.TestStrip(mocks.UIParent, { text = "x" })
    assertEqual(s.text.__template, "GameFontNormalSmall")
    assertEqual(s.text.__layer, "OVERLAY")
    assertEqual(s.text:GetNumPoints(), 2)
    local rp = point(s.text, 2)
    assertEqual(rp.point, "RIGHT"); assertTrue(rp.rel == s, "anchored to the strip")
    assertEqual(rp.relPoint, "RIGHT"); assertEqual(rp.x, -6)
    assertEqual(s.text.__justifyH, "LEFT")
    assertEqual(s.text.__wordWrap, false)
  end)
end)

test("TestStrip: opts.text is set; nil, non-table opts and non-string text give ''", function()
  recording(function()
    assertEqual(W.TestStrip(mocks.UIParent, { text = "TEST MODE" }).text:GetText(), "TEST MODE")
    assertEqual(W.TestStrip(mocks.UIParent).text:GetText(), "")
    assertEqual(W.TestStrip(mocks.UIParent, "TEST MODE").text:GetText(), "")
    assertEqual(W.TestStrip(mocks.UIParent, { text = 42 }).text:GetText(), "")
  end)
end)

-- ── what the host owns ───────────────────────────────────────────────────────────────────────

test("TestStrip: the constructor never enables the mouse; a host's tooltip hook runs", function()
  recording(function()
    local s = W.TestStrip(mocks.UIParent, { text = "x" })
    assertEqual(s.__mouseCalls, nil)
    assertFalse(s:IsMouseEnabled())
    local entered = 0
    s:EnableMouse(true)
    s:HookScript("OnEnter", function() entered = entered + 1 end)
    s:__fire("OnEnter")
    assertTrue(s:IsMouseEnabled())
    assertEqual(entered, 1)
  end)
end)

test("TestStrip: a host's SetHeight and SetWordWrap stick", function()
  recording(function()
    local s = W.TestStrip(mocks.UIParent, { text = "x" })
    s:SetHeight(30)
    s.text:SetWordWrap(true)
    s.text:SetText("a longer two-line variant")
    s:SetPoint("TOPLEFT", mocks.UIParent, "TOPLEFT", 0, -2)
    s:Show()
    assertEqual(s:GetHeight(), 30)
    assertEqual(s.text.__wordWrap, true)
    assertEqual(s.text:GetText(), "a longer two-line variant")
    assertEqual(s.text:GetNumPoints(), 2)
  end)
end)

test("TestStrip: a write to TEST_STRIP.HEIGHT does not move the next strip", function()
  recording(function()
    local saved = W.TEST_STRIP.HEIGHT
    W.TEST_STRIP.HEIGHT = 99
    local ok, err = pcall(function()
      assertEqual(W.TestStrip(mocks.UIParent):GetHeight(), 18)
    end)
    W.TEST_STRIP.HEIGHT = saved
    if not ok then error(err, 0) end
  end)
end)

test("TestStrip: TEST_STRIP publishes HEIGHT and no RESERVE", function()
  assertEqual(W.TEST_STRIP.HEIGHT, 18)
  assertEqual(W.TEST_STRIP.RESERVE, nil)
end)

test("TestStrip: two strips share no regions", function()
  recording(function()
    local a = W.TestStrip(mocks.UIParent, { text = "a", icon = HOST_ICON })
    local b = W.TestStrip(mocks.UIParent, { text = "b", icon = HOST_ICON })
    assertTrue(a ~= b, "two frames")
    assertTrue(a.__fill ~= b.__fill, "two fills")
    assertTrue(a.__icon ~= b.__icon, "two icons")
    assertTrue(a.text ~= b.text, "two texts")
    assertEqual(a.text:GetText(), "a")
    assertEqual(b.text:GetText(), "b")
  end)
end)

-- ── the simulation flavor (minor 14) ─────────────────────────────────────────────────────────

local function fillOf(s) return s.__fill.__colorTexture end

local function assertFill(s, r, g, b, a, label)
  local c = fillOf(s)
  assertEqual(c[1], r, label); assertEqual(c[2], g, label)
  assertEqual(c[3], b, label); assertEqual(c[4], a, label)
end

test("TestStrip: kind = 'sim' fills the collection's simulation cyan at 12% and reads 'sim'", function()
  recording(function()
    local s = W.TestStrip(mocks.UIParent, { text = "SIMULATION", kind = "sim" })
    assertFill(s, 0.35, 0.80, 1.00, 0.12, "sim fill")
    assertTrue(s.__fill.__allPoints == s, "the fill covers the strip, all points")
    assertEqual(s.__fill.__layer, "BACKGROUND")
    assertEqual(s.kind, "sim")
  end)
end)

test("TestStrip: the default and every kind that is not 'sim' give the amber and 'test'", function()
  recording(function()
    local cases = {
      { label = "no opts" },
      { label = "kind nil", opts = { text = "x" } },
      { label = "kind 'test'", opts = { kind = "test" } },
      { label = "kind 42", opts = { kind = 42 } },
      { label = "kind 'Sim'", opts = { kind = "Sim" } },
      { label = "kind 'preview'", opts = { kind = "preview" } },
    }
    for _, c in ipairs(cases) do
      local s = W.TestStrip(mocks.UIParent, c.opts)
      assertFill(s, 1.00, 0.65, 0.15, 0.12, c.label)
      assertEqual(s.kind, "test", c.label)
    end
  end)
end)

test("TestStrip: a sim strip has a test strip's height, icon, text, anchors, state and mouse", function()
  recording(function()
    local t = W.TestStrip(mocks.UIParent, { text = "x", icon = HOST_ICON })
    local s = W.TestStrip(mocks.UIParent, { text = "x", icon = HOST_ICON, kind = "sim" })
    for _, strip in ipairs({ t, s }) do
      assertEqual(strip:GetHeight(), 18)
      assertFalse(strip:IsShown())
      assertEqual(strip:GetNumPoints(), 0)
      assertEqual(strip.__mouseCalls, nil)
      assertFalse(strip:IsMouseEnabled())
      assertEqual(strip.__icon.__texture, HOST_ICON)
      assertEqual(strip.__icon.__layer, "ARTWORK")
      assertEqual(strip.__icon:GetWidth(), 12)
      assertEqual(strip.__icon:GetHeight(), 12)
      local ip = point(strip.__icon, 1)
      assertEqual(ip.point, "LEFT"); assertTrue(ip.rel == strip, "icon on the strip")
      assertEqual(ip.relPoint, "LEFT"); assertEqual(ip.x, 6)
      assertEqual(strip.text.__template, "GameFontNormalSmall")
      assertEqual(strip.text.__layer, "OVERLAY")
      assertEqual(strip.text:GetNumPoints(), 2)
      local lp, rp = point(strip.text, 1), point(strip.text, 2)
      assertEqual(lp.point, "LEFT"); assertTrue(lp.rel == strip.__icon, "text on the icon")
      assertEqual(lp.relPoint, "RIGHT"); assertEqual(lp.x, 6)
      assertEqual(rp.point, "RIGHT"); assertTrue(rp.rel == strip, "text on the strip")
      assertEqual(rp.relPoint, "RIGHT"); assertEqual(rp.x, -6)
      assertEqual(strip.text.__justifyH, "LEFT")
      assertEqual(strip.text.__wordWrap, false)
      assertEqual(strip.text:GetText(), "x")
    end
  end)
end)

test("TestStrip: a test strip and a sim strip side by side share no regions", function()
  recording(function()
    local t = W.TestStrip(mocks.UIParent, { text = "t", icon = HOST_ICON })
    local s = W.TestStrip(mocks.UIParent, { text = "s", icon = HOST_ICON, kind = "sim" })
    assertTrue(t ~= s, "two frames")
    assertTrue(t.__fill ~= s.__fill, "two fills")
    assertTrue(t.__icon ~= s.__icon, "two icons")
    assertTrue(t.text ~= s.text, "two texts")
    assertFill(t, 1.00, 0.65, 0.15, 0.12, "the test strip keeps the amber")
    assertFill(s, 0.35, 0.80, 1.00, 0.12, "the sim strip keeps the cyan")
    assertEqual(t.kind, "test")
    assertEqual(s.kind, "sim")
  end)
end)

test("TestStrip: a write to strip.kind after birth does not repaint the fill", function()
  recording(function()
    local t = W.TestStrip(mocks.UIParent)
    local s = W.TestStrip(mocks.UIParent, { kind = "sim" })
    t.kind = "sim"
    s.kind = "test"
    assertFill(t, 1.00, 0.65, 0.15, 0.12, "birth-only: still amber")
    assertFill(s, 0.35, 0.80, 1.00, 0.12, "birth-only: still cyan")
  end)
end)
