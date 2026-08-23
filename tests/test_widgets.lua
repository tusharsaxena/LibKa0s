-- tests/test_widgets.lua — LibKa0s-Widgets-1.0: the flat dropdown and its shared popup menu.
--
-- MOVED, not written. Every case below the divider came out of
-- BankLedger/tests/test_browser.lua, where this widget lived and where these rules were learned.
-- They are carried across verbatim so that "the library behaves as the addon did" is a claim the
-- suite makes rather than one a reviewer takes on trust; the cases ABOVE the divider are new, and
-- cover the three things the move introduced — injected art, an injected face, and their fallbacks.
--
-- ── WHY THIS FILE BUILDS ITS OWN FRAMES ───────────────────────────────────────────────────────
--
-- The kit's base stub returns 0 from GetWidth, no-ops SetSize and answers CreateTexture with the
-- frame itself. This widget sizes a button, then sizes a 12x12 arrow inside it, then measures the
-- button — so against the base stub every dropdown reports 12px wide and the "never narrower than
-- its own button" rule is unobservable. BankLedger's own mock models geometry for exactly this
-- reason.
--
-- The factory is installed HERE rather than in tests/wow_mock.lua deliberately: fifteen other
-- suites in this repo are written against the base's behavior, and widening the shared mock to
-- suit one of them is a change to all sixteen.
--
-- ── WHY IT IS INSTALLED TWICE ─────────────────────────────────────────────────────────────────
--
-- The kit COLLECTS EVERY SUITE BEFORE IT RUNS ANY CASE (tests/_kit/framework.lua's header). So
-- file-level code here runs while this file is being read, and every case body runs much later,
-- after all sixteen suites have been read and after the restore at the foot of this file. A factory
-- installed only at file scope would therefore be gone by the time the first case body executes,
-- and every case below would silently be measuring the base stub again.
--
-- So it goes on twice: once at file scope, for the file-level block that captures the shared menu
-- on its first open, and once per case, by the local `test` below, which swaps it in around the
-- body and puts back whatever was there before. The swap is per-case rather than suite-wide because
-- the runner interleaves nothing but it also promises nothing about order, and a mock left
-- installed is a mock the next suite inherits.

local T = _G.LK_TEST
local rawTest     = T.test
local assertEqual = T.assertEqual
local assertTrue  = T.assertTrue
local assertFalse = T.assertFalse
local mocks       = T.mocks

-- The library is reached through the mock's LibStub rather than a bare global: the loader gives the
-- LIBRARY chunks an environment where WoW globals resolve to the mock set, but a suite file is
-- plainly dofile'd, so `LibStub` is not a global here.
local W = T.widgets

-- A frame stub that models the geometry this widget does arithmetic on, and gives a texture its own
-- identity. Lifted from BankLedger/tests/wow_mock.lua, which grew it for this widget.
local function geomFrame()
  local f = { __shown = true, __w = 0, __h = 0, __scripts = {}, __points = {} }
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
  function f:SetTexture(p) self.__texture = p; return self end
  function f:SetFont(p, s, fl) self.__font = { p, s, fl }; return self end
  function f:SetText(t) self.__text = t; return self end
  function f:GetText() return self.__text end
  -- A TEXTURE IS ITS OWN WIDGET. The catch-all would answer CreateTexture with the frame itself,
  -- and this widget sizes a button and then sizes the art inside it — so the button would measure
  -- 12px and every width rule below would be measuring the arrow.
  function f:CreateTexture() return geomFrame() end
  setmetatable(f, { __index = function(_, k)
    if type(k) == "string" and k:match("^%u") then return function() return f end end
    return nil
  end })
  return f
end

local geomCreateFrame = function() return geomFrame() end
local geomUIParent    = geomFrame()

local realCreateFrame, realUIParent = mocks.CreateFrame, mocks.UIParent
mocks.CreateFrame = geomCreateFrame
mocks.UIParent    = geomUIParent

--- Register a case whose body runs with the geometry factory installed, and with whatever was
--- installed before it put back afterwards. See the header: without this every body would run
--- against the base stub.
local function test(name, fn)
  return rawTest(name, function()
    local savedCF, savedUI = mocks.CreateFrame, mocks.UIParent
    mocks.CreateFrame, mocks.UIParent = geomCreateFrame, geomUIParent
    local ok, err = pcall(fn)
    mocks.CreateFrame, mocks.UIParent = savedCF, savedUI
    -- Level 0: the message already carries the caller's file:line from the assertion that raised
    -- it, and a skip is a sentinel table that must be rethrown unchanged.
    if not ok then error(err, 0) end
  end)
end

local CHEVRON_FALLBACK = "Interface\\Buttons\\Arrow-Down-Up"
local CHECK_FALLBACK   = "Interface\\Buttons\\UI-CheckBox-Check"
local HOST_CHEVRON     = "Interface\\AddOns\\Host\\media\\icons\\chevron-down"
local HOST_CHECK       = "Interface\\AddOns\\Host\\media\\icons\\confirm"
local HOST_FONT        = "Interface\\AddOns\\Host\\media\\fonts\\JetBrainsMono-Regular.ttf"
-- A SECOND host, with its own face and no art of its own. The point of the library is that these
-- two can be open in one process, so the cases at the foot of this file drive both through the one
-- shared row pool.
local OTHER_FONT       = "Interface\\AddOns\\Other\\media\\fonts\\CascadiaMono-Regular.ttf"
local CHECK_FALLBACK_MARKUP = "|T" .. CHECK_FALLBACK .. ":0|t "

-- ── The injection seam (new at the move) ──────────────────────────────────────

test("Widgets.Dropdown draws the host's chevron when it is given one", function()
  local dd = W.Dropdown(mocks.UIParent, 110, { chevron = HOST_CHEVRON })
  assertEqual(dd.arrow.__texture, HOST_CHEVRON)
end)

test("Widgets.Dropdown falls to Blizzard's arrow with no host art", function()
  -- The rung a host with no LibKa0s-Media lands on. Red under: a library that
  -- reaches for Media.Icon itself, which cannot work from a vendored copy.
  local dd = W.Dropdown(mocks.UIParent, 110)
  assertEqual(dd.arrow.__texture, CHEVRON_FALLBACK)
end)

test("Widgets.Dropdown builds its tick markup from the host's check art", function()
  local dd = W.Dropdown(mocks.UIParent, 110, { check = HOST_CHECK })
  assertEqual(dd.__check, "|T" .. HOST_CHECK .. ":0|t ")
  local bare = W.Dropdown(mocks.UIParent, 110)
  assertEqual(bare.__check, "|T" .. CHECK_FALLBACK .. ":0|t ")
end)

test("Two dropdowns can carry different art without either winning", function()
  -- The reason the tick moved off a file-local: one popup menu is shared by every
  -- dropdown in the process, and that process now spans addons.
  local a = W.Dropdown(mocks.UIParent, 110, { check = HOST_CHECK })
  local b = W.Dropdown(mocks.UIParent, 110)
  assertFalse(a.__check == b.__check, "each dropdown keeps its own host's art")
end)

-- ── Moved verbatim from BankLedger/tests/test_browser.lua:469-662 ─────────────
--
-- The popup every dropdown drops is one shared frame behind two file-locals (the singleton and
-- EnsureMenu), so the only way in is the way the game takes: build a real dropdown and fire its
-- OnClick. The menu is the first frame that call creates, and the kit collects every suite before
-- it runs any case, so nothing else can have opened a dropdown first — the assert in the first
-- case below is what fails if that ever stops being true.
local MENU
do
  local dd = W.Dropdown(mocks.UIParent, 110, { check = HOST_CHECK, glyphFont = HOST_FONT })
  dd:SetMulti(true)
  dd:SetOptions({})   -- empty: the width loop is what needs the measuring stub installed below
  local made, savedCreateFrame = {}, mocks.CreateFrame
  mocks.CreateFrame = function(...)
    local f = savedCreateFrame(...)
    made[#made + 1] = f
    return f
  end
  dd:__fire("OnClick")
  mocks.CreateFrame = savedCreateFrame
  MENU = made[1]
  -- The mock's CreateFontString hands back the frame itself, so the real measuring FontString
  -- reports a table rather than a width and the width loop would raise on the first option. Stand
  -- in a stub that measures 6px per character: the widths asserted below are that stub's
  -- arithmetic, and what is being pinned is the +pad / cap / floor rules around it.
  if MENU then
    MENU.measure = {
      SetText = function(self, t) self._t = t or "" end,
      GetStringWidth = function(self) return #(self._t or "") * 6 end,
      Hide = function() end,
    }
  end
end

-- The tick markup Populate prefixes to a selected multi-select row, as Widgets.lua spells it.
-- Duplicated here on purpose: if the markup changes shape this suite must fail rather than follow
-- it silently. The path is now the HOST's, injected above, which is the whole point of the move —
-- the library has no art of its own to name here.
local CHECK = "|T" .. HOST_CHECK .. ":0|t "

-- A recording stand-in for a row's FontString. CreateFontString still falls through the factory's
-- catch-all above and answers with the frame itself, which conflates a row's label, its glyph and
-- the button itself; these keep the three apart so the paint rules are observable at all. (Only
-- CreateTexture was given its own identity up there, because only the arrow's size was doing
-- arithmetic damage.)
local function fakeFS()
  local r = { points = {} }
  function r:SetText(t) self.text = t end
  function r:SetTextColor(a, b, c) self.color = { a, b, c } end
  function r:SetShown(v) self.shown = v and true or false end
  function r:ClearAllPoints() self.points = {} end
  function r:SetPoint(p, x, y) self.points[#self.points + 1] = { p, x, y } end
  -- New at the move: the face is set on every paint rather than once at row creation, so the row's
  -- glyph has to record it for the two cases at the foot of this file to see.
  function r:SetFont(p, s, f) self.font = { p, s, f } end
  return r
end

-- A recording stand-in for a pooled row button.
local function fakeRow()
  local b = { fs = fakeFS(), glyph = fakeFS(), points = {}, scripts = {} }
  function b:SetWidth(w) self.width = w end
  function b:ClearAllPoints() self.points = {} end
  function b:SetPoint(p, x, y) self.points[#self.points + 1] = { p, x, y } end
  function b:SetScript(k, fn) self.scripts[k] = fn end
  function b:Show() self.shown = true end
  function b:Hide() self.shown = false end
  return b
end

-- Seed `n` recording rows into the shared pool, then populate it. Seeding is not a shortcut: rows
-- are pooled on the menu and reused across dropdowns, so this IS the path every dropdown after the
-- first one takes, and it is the one that can leak a stale glyph or color.
local function populate(dd, opts, n)
  dd:SetOptions(opts)
  MENU.buttons = {}
  for i = 1, (n or #opts) do MENU.buttons[i] = fakeRow() end
  MENU:Populate(dd)
  return MENU.buttons
end

--- Populate the pool AGAIN, from a different dropdown, WITHOUT re-seeding the rows.
---
--- This is the shape the whole per-paint argument rests on and the one `populate` cannot express:
--- the rows are the SAME objects the previous dropdown just painted, so anything paintMenuRow fails
--- to write is visibly the previous host's. Two dropdowns through one pool is the process the
--- library created by existing — before the lift the pool was private to one addon.
local function repopulate(dd, opts)
  dd:SetOptions(opts)
  MENU:Populate(dd)
  return MENU.buttons
end

-- BankLedger's mock resolved CreateTexture to the frame itself, so the dropdown's 12x12 arrow
-- overwrote the button's own size on the way out of MakeDropdown, and the width had to be
-- re-asserted after building or every dropdown reported 12px wide. The factory at the head of this
-- file gives a texture its own identity instead, so the SetWidth below is now belt-and-braces
-- rather than load-bearing. It stays because the moved block moves whole.
local function menuDropdown(multi, width)
  local dd = W.Dropdown(mocks.UIParent, width or 110, { check = HOST_CHECK, glyphFont = HOST_FONT })
  dd:SetWidth(width or 110)
  dd:SetMulti(multi)
  return dd
end

local MENU_OPTS = {
  { value = "all", label = "All" },
  { value = "BANK", label = "Bank", color = { 0.4, 0.6, 1 } },
  { value = "GUILD_BANK", label = "Guild", glyph = "\226\150\178" },
}

test("Browser menu: Populate shows one row per option and sizes the menu to them", function()
  assertTrue(MENU ~= nil and MENU.buttons ~= nil, "the shared menu was captured on its first open")
  local dd = menuDropdown(true)
  local rows = populate(dd, MENU_OPTS)
  assertEqual(#MENU.buttons, 3)
  for i = 1, 3 do
    assertEqual(rows[i].shown, true, "row " .. i .. " is shown")
    assertEqual(rows[i].width, MENU.__w, "every row spans the menu")
    assertEqual(rows[i].points[1][1], "TOPLEFT")
    assertEqual(rows[i].points[1][3], -4 - (i - 1) * 16, "rows stack on a 16px pitch")
  end
  assertEqual(MENU.__h, 3 * 16 + 8, "height is the rows plus the 4px inset top and bottom")
end)

test("Browser menu: a freak label is capped at 320px", function()
  local dd = menuDropdown(false)
  populate(dd, { { value = "x", label = string.rep("W", 200) } })
  assertEqual(MENU.__w, 320)
end)

test("Browser menu: the menu is never narrower than 90px, nor than its own dropdown", function()
  local narrow = menuDropdown(false, 40)
  populate(narrow, { { value = "x", label = "A" } })
  assertEqual(MENU.__w, 90, "the floor holds even under a 40px dropdown")

  local wide = menuDropdown(false, 200)
  populate(wide, { { value = "x", label = "A" } })
  assertEqual(MENU.__w, 200, "and it never undercuts the button it drops from")
end)

test("Browser menu: rows are POOLED — a shorter dropdown hides the spares, never rebuilds", function()
  local dd = menuDropdown(true)
  local rows = populate(dd, { MENU_OPTS[1], MENU_OPTS[2] }, 3)
  assertEqual(#MENU.buttons, 3, "the third row is kept for the next dropdown")
  assertEqual(rows[3].shown, false, "and it is hidden rather than left on screen")
end)

test("Browser menu: multi-select ticks 'all' exactly when nothing is selected", function()
  local dd = menuDropdown(true)
  local rows = populate(dd, MENU_OPTS)
  assertEqual(rows[1].fs.text, CHECK .. "All", "an empty set IS 'All'")
  assertEqual(rows[2].fs.text, "Bank")

  dd:SetSelected({ BANK = true })
  rows = populate(dd, MENU_OPTS)
  assertEqual(rows[1].fs.text, "All", "'all' loses its tick once a real value is picked")
  assertEqual(rows[2].fs.text, CHECK .. "Bank")
end)

test("Browser menu: single-select marks the active value and never draws a tick", function()
  local dd = menuDropdown(false)
  dd._value = "BANK"
  local rows = populate(dd, MENU_OPTS)
  assertEqual(rows[2].fs.text, "Bank", "no tick markup on a single-select menu")
  assertEqual(rows[2].fs.color[1], 1, "the active value still goes gold")
  assertEqual(rows[2].fs.color[2], 0.82)
end)

test("Browser menu: selected rows go gold, the rest keep the value's own color", function()
  local dd = menuDropdown(true)
  local rows = populate(dd, MENU_OPTS)
  assertEqual(rows[1].fs.color[1], 1, "the selected row is gold")
  assertEqual(rows[1].fs.color[2], 0.82)
  assertEqual(rows[2].fs.color[1], 0.4, "an unselected row keeps its store/direction/class color")
  assertEqual(rows[3].fs.color[1], 0.9, "and a colorless one falls back to gray")
end)

test("Browser menu: a glyphed row shows its glyph and indents its text past it", function()
  local dd = menuDropdown(true)
  local rows = populate(dd, MENU_OPTS)
  assertEqual(rows[3].glyph.text, "\226\150\178")
  assertEqual(rows[3].glyph.shown, true)
  assertEqual(rows[3].fs.points[1][2], 22, "the label clears the glyph")
  assertEqual(rows[2].glyph.text, "", "a glyphless row is repainted blank, not left stale")
  assertEqual(rows[2].glyph.shown, false)
  assertEqual(rows[2].fs.points[1][2], 8, "and starts at the margin")
end)

test("Browser menu: clicking a multi-select row toggles it and leaves the menu open", function()
  local dd = menuDropdown(true)
  local reported
  dd.onMultiSelect = function(set) reported = set end
  local rows = populate(dd, MENU_OPTS)
  MENU:Show()
  rows[2].scripts.OnClick()
  assertEqual(dd._selected.BANK, true)
  assertEqual(MENU:IsShown(), true, "several values can be picked in one visit")
  assertEqual((reported or {}).BANK, true, "the owner is told about the new set")
end)

test("Browser menu: clicking a single-select row sets the value and closes the menu", function()
  local dd = menuDropdown(false)
  local reported
  dd.onSelect = function(v) reported = v end
  local rows = populate(dd, MENU_OPTS)
  MENU:Show()
  rows[2].scripts.OnClick()
  assertEqual(dd._value, "BANK")
  assertEqual(MENU:IsShown(), false)
  assertEqual(reported, "BANK")
end)

-- ── The glyph face, which is the move's one behavioral change ─────────────────

test("A glyphed row is painted in the host's face on every pass", function()
  local dd = W.Dropdown(mocks.UIParent, 110, { glyphFont = HOST_FONT })
  dd:SetMulti(true)
  local rows = populate(dd, MENU_OPTS)
  assertEqual(rows[3].glyph.font[1], HOST_FONT, "the face comes from the dropdown, not the pool")
end)

test("A host that names no face gets no glyph column", function()
  -- Rather than SetFont(nil), which raises, or a glyph in the row's own
  -- proportional face, which is a replacement box.
  local dd = W.Dropdown(mocks.UIParent, 110, { check = HOST_CHECK })
  dd:SetMulti(true)
  local rows = populate(dd, MENU_OPTS)
  assertEqual(rows[3].glyph.shown, false)
end)

-- ── Two hosts, one row pool ───────────────────────────────────────────────────
--
-- The pair below is what makes the per-paint rule an ASSERTION rather than a comment. Each case
-- paints the same pooled rows from one dropdown and then from a second carrying different art, and
-- asserts the SECOND one won. A single-dropdown case cannot tell the two implementations apart:
-- with only one dropdown in the process, "set once at creation from the first dd" and "set on every
-- paint from this dd" produce identical rows.

test("A second dropdown repaints the pooled rows in ITS face, not the first one's", function()
  local first = W.Dropdown(mocks.UIParent, 110, { glyphFont = HOST_FONT })
  first:SetMulti(true)
  local rows = populate(first, MENU_OPTS)
  assertEqual(rows[3].glyph.font[1], HOST_FONT, "the first host's face reaches the pool")

  local second = W.Dropdown(mocks.UIParent, 110, { glyphFont = OTHER_FONT })
  second:SetMulti(true)
  rows = repopulate(second, MENU_OPTS)
  assertEqual(rows[3].glyph.font[1], OTHER_FONT,
    "and the second host's face replaces it — a face set at row creation would still read as the "
    .. "first host's, which is the regression the move exists to prevent")
end)

test("A second dropdown ticks the pooled rows with ITS art, not the first one's", function()
  local first = menuDropdown(true)   -- carries HOST_CHECK
  local rows = populate(first, MENU_OPTS)
  assertEqual(rows[1].fs.text, CHECK .. "All", "the first host's tick reaches the pool")

  -- No check art at all: the second host is one with no LibKa0s-Media, on the Blizzard rung.
  local second = W.Dropdown(mocks.UIParent, 110, { glyphFont = HOST_FONT })
  second:SetMulti(true)
  rows = repopulate(second, MENU_OPTS)
  assertEqual(rows[1].fs.text, CHECK_FALLBACK_MARKUP .. "All",
    "and the second host's tick replaces it — red under a file-local markup, and red under any "
    .. "read that took the tick from the pool rather than from the dropdown being painted")
end)

mocks.CreateFrame, mocks.UIParent = realCreateFrame, realUIParent
