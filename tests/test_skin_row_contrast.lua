-- tests/test_skin_row_contrast.lua — the list-row, section-header and hot-mark contrast floors of
-- LibKa0s-Skin-1.0's nine skins, in CIE L*.
--
-- Peeled out of tests/test_skin_defs.lua at SR2-L1 (Ka0sAddonsCommonTasks
-- docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/SR2_SMOKE_ROUND2.md), unchanged, on the seam CLAUDE.md's band
-- census named for that suite (its re-check trigger, the next contrast floor added, fired with
-- SR2-L1's title-bar hover floors). The cases are LibKa0s#82 and #84's stripe, hover, selection and
-- hot-mark floors and SR-L4's section-header band.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local MAJOR = "LibKa0s-Skin-1.0"

local KEYS = { "ka0s", "obsidian", "azeroth", "glass", "contrast", "ember", "wow", "midnight",
  "forever" }

local function skinLib() return T.mocks.LibStub(MAJOR) end

local function colorKey(c)
  return type(c) == "table" and ("%.3f,%.3f,%.3f,%.3f"):format(c[1], c[2], c[3], c[4] or 1) or tostring(c)
end

-- WCAG 2 relative luminance and contrast ratio, alpha ignored (a fill's own color).
local function channel(c)
  if c <= 0.03928 then return c / 12.92 end
  return ((c + 0.055) / 1.055) ^ 2.4
end
local function luminance(c)
  return 0.2126 * channel(c[1]) + 0.7152 * channel(c[2]) + 0.0722 * channel(c[3])
end
local function contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  if la < lb then la, lb = lb, la end
  return (la + 0.05) / (lb + 0.05)
end

-- A color over another, by its alpha (the client's blend), opaque.
local function over(top, under)
  local a = top[4] or 1
  return { top[1] * a + under[1] * (1 - a), top[2] * a + under[2] * (1 - a), top[3] * a + under[3] * (1 - a), 1 }
end

local function sameColor(c, want, label)
  assertTrue(type(c) == "table", label .. ": no color")
  for i = 1, #want do
    assertTrue(math.abs(c[i] - want[i]) < 0.005, ("%s component %d: %s, want %s"):format(label, i, tostring(c[i]), tostring(want[i])))
  end
end

--- The largest channel difference of two opaque colors.
local function apart(x, y)
  return math.max(math.abs(x[1] - y[1]), math.abs(x[2] - y[2]), math.abs(x[3] - y[3]))
end

local BLACK = { 0, 0, 0 }

-- How far a skin's alternate row stands off its window, in a channel (SF-L3 set 5%; R3-L5 of
-- Ka0sAddonsCommonTasks docs/2026-11-02-SMOKE_ROUND3 raises it to 8%, image 95).
local STRIPE_STEP = 0.08

--- CIE L* (0-100) of an opaque color: lightness alone, the axis LibKa0s#82 and #84 ask about. CIE76
--- ΔE is no use here: it scores Forever's gold heading against its tan hot mark at 41, a pair the
--- owner saw "nearly disappear".
local function lstar(c)
  local y = luminance(c)
  if y > 216 / 24389 then return 116 * y ^ (1 / 3) - 16 end
  return y * 24389 / 27
end
local function dL(a, b) return math.abs(lstar(a) - lstar(b)) end

--- Every color a window's body draws: its flat `win.bg`, and both stops of its gradient when it has
--- one, each over black (the world behind a translucent window at its darkest).
local function windowStops(t)
  local stops = { { "win.bg", over(t["win.bg"], BLACK) } }
  if type(t["win.bgTop"]) == "table" and type(t["win.bgBottom"]) == "table" then
    stops[2] = { "win.bgTop", over(t["win.bgTop"], BLACK) }
    stops[3] = { "win.bgBottom", over(t["win.bgBottom"], BLACK) }
  end
  return stops
end

-- The row and mark floors of LibKa0s#82 and #84 (Ka0sAddonsCommonTasks
-- docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS, design 3.4, research R5 section 4), in CIE L*, every wash
-- composited over each window stop.
local STRIPE_DL, HOVER_DL, HOVER_STRIPE_DL, HOT_REST_DL, HOT_HEAD_DL, SEL_HOVER_DL = 6, 12, 3, 10, 10, 6

-- High Contrast's heading is yellow at L* 90.7, so no hot mark can be 10 lighter; its white hot
-- stands 9.3 off it, and ΔE 91 apart in hue. Signed off by the owner (ruling Q2 of the bundle above).
local HOT_HEAD_EXEMPT = { contrast = "High Contrast's white hot on its yellow heading, the owner's Q2" }

test("skin defs: alternate rows show in every skin", function()
  -- SF-L3, images 53 and 54. red under: Obsidian's 2% white or High Contrast's #0D0D0D, which no
  -- eye separates from the window.
  -- R3-L5, image 95: Obsidian's 6% white, 5.8% off its window, was still hardly visible, and every
  -- dark skin on the same 6% (Glass, Ember, WoW Default, WoW Midnight, WoW Forever) or Azeroth's 7%
  -- parchment sat as faint. red under any of them below a visible 8% in a channel.
  -- LibKa0s#84: Ka0s Default's own 3% white, exempt until then, stood 3 L* off its window against
  -- ~10 for every other skin, and its rows ran together. Every skin, Ka0s Default included, is held
  -- to 6 L*; the eight keep the 8% channel floor too (Ka0s Default's .08 white over a .92 window is
  -- 7.6% in a channel and 9 L*). red under: Ka0s Default's 3% stripe.
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local t = Skin:ResolveSkin(key)
    for _, stop in ipairs(windowStops(t)) do
      local win = stop[2]
      local d = dL(over(t["list.stripe"], win), win)
      assertTrue(d >= STRIPE_DL, ("%s: the stripe stands %.1f L* off %s, want >= %d"):format(
        key, d, stop[1], STRIPE_DL))
    end
    if key ~= "ka0s" then
      local win = over(t["win.bg"], BLACK)
      local step = apart(over(t["list.stripe"], win), win)
      assertTrue(step >= STRIPE_STEP, ("%s: the stripe stands %.1f%% off the window, want %d%%"):format(
        key, step * 100, STRIPE_STEP * 100))
    end
  end
  local o = Skin:ResolveSkin("obsidian")
  assertEqual(colorKey(o["list.stripe"]), "1.000,1.000,1.000,0.090", "Obsidian's stripe, 9% white")
end)

test("skin defs: a hovered row still stands off an alternate row", function()
  -- R3-L5. A hovered plain row is the body text at its alpha over the window; at 10% it stood 3% off
  -- a 6% stripe. red under: a stripe raised to 9% under a 10% hover, which reads as a stripe.
  -- LibKa0s#84: Ka0s Default is held too, in L*, now its stripe rises to 8%.
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local t = Skin:ResolveSkin(key)
    if key ~= "ka0s" then
      local win = over(t["win.bg"], BLACK)
      local step = apart(over(t["list.hover"], win), over(t["list.stripe"], win))
      assertTrue(step >= 0.03, ("%s: a hovered row %.1f%% off a striped one"):format(key, step * 100))
    end
    for _, stop in ipairs(windowStops(t)) do
      local win = stop[2]
      local d = dL(over(t["list.hover"], win), over(t["list.stripe"], win))
      assertTrue(d >= HOVER_STRIPE_DL, ("%s: a hovered row %.1f L* off a striped one on %s, want >= %d")
        :format(key, d, stop[1], HOVER_STRIPE_DL))
    end
  end
end)

test("skin defs: a hovered row shows on its window in every skin", function()
  -- LibKa0s#82 and #84: Ka0s Default's gold hover at .10 stood 9 L* off its window, against 13 to 19
  -- for every other skin. red under: Ka0s Default's gold .10.
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local t = Skin:ResolveSkin(key)
    for _, stop in ipairs(windowStops(t)) do
      local win = stop[2]
      local d = dL(over(t["list.hover"], win), win)
      assertTrue(d >= HOVER_DL, ("%s: the hover wash stands %.1f L* off %s, want >= %d"):format(
        key, d, stop[1], HOVER_DL))
    end
  end
end)

test("skin defs: Ka0s Default's selected row stands off its hovered one", function()
  -- LibKa0s#84: hover and selection are one gold in Ka0s Default, told apart by alpha alone, so a
  -- hover raised to .16 needs a selection raised with it. red under: the hover at .16 over a
  -- selection left at .18.
  local t = skinLib():ResolveSkin("ka0s")
  for _, stop in ipairs(windowStops(t)) do
    local win = stop[2]
    local d = dL(over(t["list.sel"], win), over(t["list.hover"], win))
    assertTrue(d >= SEL_HOVER_DL, ("ka0s: selected %.1f L* off hovered, want >= %d"):format(d, SEL_HOVER_DL))
  end
  sameColor(t["list.stripe"], { 1, 1, 1, 0.08 }, "Ka0s Default's stripe, 8% white")
  sameColor(t["list.hover"], { 1, 0.82, 0, 0.16 }, "Ka0s Default's hover, gold .16")
  sameColor(t["list.sel"], { 1, 0.82, 0, 0.26 }, "Ka0s Default's selection, gold .26")
end)

-- The section-header band's floors (SR-L4 of Ka0sAddonsCommonTasks docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS,
-- smoke round 1's ruling 5), in CIE L*, the band composited over each window stop as the rows are.
-- A band DARKER than the plain row (Skill Master's block header, the reference the owner passed) is
-- held to 1.5 off it: over black a dark band can stand at most L*(window) off its row, Obsidian's
-- window is L* 2.8, and Skill Master's black .35 on Ka0s Default's window stands 1.6 off, a look the
-- owner passed. A band LIGHTER than the row is a wash like the stripe and is held to the stripe's own 6.
-- Against the stripe and the hover it is held to 6, the stripe's floor off its row: a band nearer a
-- stripe than a stripe is to a row reads as one more stripe. Its text is held 45 off it, which is
-- about WCAG's 4.5:1 on bands this dark.
local HEADER_DARK_ROW_DL, HEADER_STRIPE_DL, HEADER_HOVER_DL, HEADER_TEXT_DL = 1.5, 6, 6, 45

test("skin defs: a section header's band stands off a row, a stripe and a hover in every skin", function()
  -- SR-L4: Ka0s Default's band, white .04, sat between its plain row and its .08 stripe (4.2 and 4.8
  -- L* off them), so DropWatcher's group headers read as rows. red under: that band, or seven of the
  -- eight's mockup bands, each a lighter wash under 6 off its row or its stripe (Obsidian #101012 2.0
  -- over its row, WoW Default white .07 2.1 off its stripe). WoW Forever's black .35, the one dark
  -- mockup band, passes as it was: 2.5 under its row on its gradient's dark stop, 13.9 off a stripe.
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local t = Skin:ResolveSkin(key)
    for _, stop in ipairs(windowStops(t)) do
      local win = stop[2]
      local band = over(t["list.header.bg"], win)
      local rise = lstar(band) - lstar(win)
      if rise < 0 then
        assertTrue(-rise >= HEADER_DARK_ROW_DL, ("%s: the header band sits %.1f L* under a row on %s, want >= %.1f")
          :format(key, -rise, stop[1], HEADER_DARK_ROW_DL))
      else
        assertTrue(rise >= HEADER_STRIPE_DL, ("%s: the header band sits %.1f L* over a row on %s, want >= %d")
          :format(key, rise, stop[1], HEADER_STRIPE_DL))
      end
      local d = dL(band, over(t["list.stripe"], win))
      assertTrue(d >= HEADER_STRIPE_DL, ("%s: the header band %.1f L* off a stripe on %s, want >= %d")
        :format(key, d, stop[1], HEADER_STRIPE_DL))
      d = dL(band, over(t["list.hover"], win))
      assertTrue(d >= HEADER_HOVER_DL, ("%s: the header band %.1f L* off a hovered row on %s, want >= %d")
        :format(key, d, stop[1], HEADER_HOVER_DL))
    end
  end
  sameColor(Skin:ResolveSkin("ka0s")["list.header.bg"], { 0, 0, 0, 0.35 },
    "Ka0s Default's band is Skill Master's block header, black .35")
end)

test("skin defs: a section header's text reads on its band in every skin", function()
  -- SR-L4: a guard for the bands above, green from the start (the closest as built, WoW Forever's
  -- tan on its band over the gradient's light stop, stands 60 off).
  -- red under: a band raised toward its heading color.
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local t = Skin:ResolveSkin(key)
    for _, stop in ipairs(windowStops(t)) do
      local band = over(t["list.header.bg"], stop[2])
      local d = dL(t["list.header.text"], band)
      assertTrue(d >= HEADER_TEXT_DL, ("%s: the header text %.1f L* off its band on %s, want >= %d")
        :format(key, d, stop[1], HEADER_TEXT_DL))
    end
  end
end)

test("skin defs: a mark goes visibly hot from its rest and from a heading in every skin", function()
  -- LibKa0s#82: WoW Forever's hot #C9A07A stood 3.4 L* off its rest #A39E97, and six skins' hot was
  -- their heading color, so a mark resting at `text.heading` (Skill Master's block header) showed no
  -- hover at all. red under: Obsidian, Azeroth, High Contrast, Ember, WoW Default, WoW Midnight or
  -- WoW Forever's hot within 10 L* of its rest, or any hot but High Contrast's within 10 of its
  -- heading.
  local Skin = skinLib()
  for _, key in ipairs(KEYS) do
    local t = Skin:ResolveSkin(key)
    local hot, rest, head = t["icon.hot"], t["icon.tint"], t["text.heading"]
    local d = dL(hot, rest)
    assertTrue(d >= HOT_REST_DL, ("%s: icon.hot %.1f L* off icon.tint, want >= %d"):format(key, d, HOT_REST_DL))
    d = dL(hot, head)
    if HOT_HEAD_EXEMPT[key] then
      assertTrue(d >= 9, ("%s: icon.hot %.1f L* off text.heading, exempt at 9 (%s)"):format(
        key, d, HOT_HEAD_EXEMPT[key]))
    else
      assertTrue(d >= HOT_HEAD_DL, ("%s: icon.hot %.1f L* off text.heading, want >= %d"):format(
        key, d, HOT_HEAD_DL))
    end
    for _, stop in ipairs(windowStops(t)) do
      local ratio = contrast(rest, stop[2])
      assertTrue(ratio >= 3, ("%s: icon.tint contrast %.2f on %s, want >= 3"):format(key, ratio, stop[1]))
    end
  end
  assertEqual(colorKey(Skin:ResolveSkin("forever")["icon.hot"]), "1.000,1.000,1.000,1.000",
    "WoW Forever's hot is white, as its titles and body are")
  local hc = Skin:ResolveSkin("contrast")
  assertEqual(colorKey(hc["icon.tint"]), colorKey({ 0xA0 / 255, 0xA0 / 255, 0xA0 / 255, 1 }), "High Contrast rests at #A0A0A0")
  assertEqual(colorKey(hc["icon.hot"]), "1.000,1.000,1.000,1.000", "High Contrast's hot is white")
end)
