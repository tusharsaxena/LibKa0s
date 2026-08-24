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
  local f = { __shown = true, __w = 0, __h = 0, __scripts = {}, __points = {}, __events = {} }
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
  -- EVENTS ARE REAL, not swallowed by the catch-all below. New at minor 5: the menu closes on
  -- GLOBAL_MOUSE_DOWN rather than by intercepting the click, so "is it listening?" and "what does
  -- it do when the event arrives?" are the two questions the whole change turns on. Against the
  -- catch-all every RegisterEvent would silently answer the frame itself and both would be
  -- unaskable.
  function f:RegisterEvent(e) self.__events[e] = true; return self end
  function f:UnregisterEvent(e) self.__events[e] = nil; return self end
  function f:IsEventRegistered(e) return self.__events[e] or false end
  -- The cursor. The client answers this from where the mouse actually is; a suite has to say so.
  -- Defaults to FALSE, which is the honest default: most clicks in these cases are outside.
  function f:IsMouseOver() return self.__mouseOver or false end
  function f:SetTexture(p) self.__texture = p; return self end
  function f:SetFont(p, s, fl) self.__font = { p, s, fl }; return self end
  -- A FONTSTRING WITH NO FONT RAISES ON SetText, exactly as the client does — and a FontString
  -- built FROM A TEMPLATE has one, which is why the check keys on `__font or __template` rather
  -- than on `__font` alone. A bare CreateFontString() is the case that has to be caught.
  --
  -- This fidelity was missing for a release and it cost a load in a consuming addon: the glyph
  -- FontString was created bare and given its text on the next line, and the client answered
  -- `FontString:SetText(): Font not set` at BuildFrame — taking the addon down before a window
  -- existed. Every case in this file passed, because this stub happily stored the string.
  function f:SetText(t)
    if self.__objectType == "FontString" and not (self.__font or self.__template) then
      error("FontString:SetText(): Font not set", 2)
    end
    self.__text = t
    return self
  end
  function f:GetText() return self.__text end
  -- A PROPORTIONAL-ISH width, 6px per character, so the width arithmetic has real numbers to run
  -- on; it is the same rule the measuring stub further down uses.
  function f:GetStringWidth() return #(self.__text or "") * 6 end
  -- A TEXTURE IS ITS OWN WIDGET. The catch-all would answer CreateTexture with the frame itself,
  -- and this widget sizes a button and then sizes the art inside it — so the button would measure
  -- 12px and every width rule below would be measuring the arrow.
  function f:CreateTexture() return geomFrame() end
  -- AND SO IS A FONTSTRING, for the SetText rule above to mean anything: answered with the frame
  -- itself, a row's label, its glyph and the button would be one object carrying one `__font`, and
  -- a glyph that never had a face of its own would look like one that did.
  function f:CreateFontString(_, _, template)
    local fs = geomFrame()
    fs.__objectType = "FontString"
    fs.__template = template
    return fs
  end
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

-- The font template makeMenuRow builds a row's label AND its glyph from. Spelled out here rather
-- than imported, so a change to it in Widgets.lua has to be made deliberately in both places.
local ROW_TEMPLATE = "GameFontHighlightSmall"

-- A recording stand-in for a row's FontString. CreateFontString still falls through the factory's
-- catch-all above and answers with the frame itself, which conflates a row's label, its glyph and
-- the button itself; these keep the three apart so the paint rules are observable at all. (Only
-- CreateTexture was given its own identity up there, because only the arrow's size was doing
-- arithmetic damage.)
--- @param template string|nil  the font template the real row builds this FontString from, if any;
---   a bare one raises on SetText, as the client does and as the factory above now does.
local function fakeFS(template)
  local r = { points = {}, template = template }
  function r:SetText(t)
    if not (self.font or self.template) then error("FontString:SetText(): Font not set", 2) end
    self.text = t
  end
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
  -- Both FontStrings carry a template, because makeMenuRow builds both from one. The seeded rows
  -- mirror the real ones rather than improve on them: the case that pins the template itself is
  -- "A pooled row survives a paint with no face at all", which builds REAL rows.
  local b = { fs = fakeFS(ROW_TEMPLATE), glyph = fakeFS(ROW_TEMPLATE), points = {}, scripts = {} }
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

--- Populate the pool with the widget's OWN rows — no recording stand-ins seeded at all.
---
--- Everything above drives `fakeRow`s, which is what makes the paint rules observable; the price is
--- that makeMenuRow itself never runs, so how a row is BUILT is untested by every case that uses
--- them. This is the path that builds one, and the one that catches a FontString created without a
--- font.
local function populateBuilt(dd, opts)
  dd:SetOptions(opts)
  MENU.buttons = {}
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

-- ── The glyph FontString always has a font ────────────────────────────────────
--
-- paintMenuRow sets the glyph's FACE only when the dropdown named one AND the row carries a glyph,
-- but it calls SetText on that FontString on EVERY row of EVERY paint. So a glyph FontString built
-- bare has no font at the moment its text is first set, and the client answers
-- `FontString:SetText(): Font not set` — on the first click, in every host, including one that
-- passes a face (its glyphless rows take the same route). makeMenuRow builds it from a template
-- for that reason; the two cases below are what makes that a rule rather than a line of code.
--
-- They build REAL rows, not stand-ins: it is the CREATION that is under test.

test("A row built with no face at all paints without raising", function()
  local dd = W.Dropdown(mocks.UIParent, 110, { check = HOST_CHECK })   -- no glyphFont
  dd:SetMulti(true)
  local rows = populateBuilt(dd, MENU_OPTS)
  -- The text is still WRITTEN — that unconditional SetText is the whole hazard — and the row is
  -- simply not shown. Reaching this line at all is the assertion: under a bare FontString the
  -- SetText inside Populate raises and the case never gets here.
  assertEqual(rows[3].glyph.__text, "\226\150\178", "the glyph's text is written on every paint")
  assertEqual(rows[3].glyph:IsShown(), false, "and the column is dropped, as it is documented to be")
end)

test("A glyphless row paints without raising even when the host DID name a face", function()
  -- The half of the bug that reaches a host doing everything right: the face is set only on a row
  -- that has a glyph, so rows 1 and 2 here reach SetText having never been given one.
  local dd = W.Dropdown(mocks.UIParent, 110, { check = HOST_CHECK, glyphFont = HOST_FONT })
  dd:SetMulti(true)
  local rows = populateBuilt(dd, MENU_OPTS)
  assertEqual(rows[1].glyph.__text, "")
  assertEqual(rows[3].glyph.__font[1], HOST_FONT, "and a glyphed row still takes the host's face")
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

-- ── lib.CloseMenu (new at minor 2) ────────────────────────────────────────────
--
-- A host cannot close the shared popup itself: the menu is a process-wide singleton parented to
-- UIParent (see EnsureMenu above), built lazily by the FIRST dropdown any addon in the process
-- opens, and no host frame holds a reference to it. Before this function existed, a host that
-- closed its own window by any route that was not a click on the dropdown — Escape, a slash
-- command — left the menu ORPHANED at FULLSCREEN_DIALOG: still shown, floating over the game, with
-- nothing left to hide it. The click-catcher only ever helped when the player actually clicked.

test("Widgets.CloseMenu hides an open menu", function()
  local dd = W.Dropdown(mocks.UIParent, 110)
  dd:SetOptions({ { value = "x", label = "X" } })
  dd:__fire("OnClick")
  assertTrue(MENU:IsShown(), "opening the dropdown showed the shared menu")
  W.CloseMenu()
  assertEqual(MENU:IsShown(), false)
end)

test("Widgets.CloseMenu is a no-op when the menu is already hidden", function()
  local dd = W.Dropdown(mocks.UIParent, 110)
  dd:SetOptions({ { value = "x", label = "X" } })
  dd:__fire("OnClick")
  W.CloseMenu()
  assertEqual(MENU:IsShown(), false, "closed by the first call")
  -- A second call on an already-hidden menu must not error, and must leave it hidden.
  local ok = pcall(W.CloseMenu)
  assertTrue(ok, "closing an already-hidden menu must not raise")
  assertEqual(MENU:IsShown(), false)
end)

test("Widgets.CloseMenu is a no-op when no dropdown has ever opened the menu", function()
  -- A fresh library instance, in its own mock set, so its file-local `menu` is genuinely still nil
  -- — the shared W above already had its menu built by the file-scope capture at the top of this
  -- file, so it cannot exercise this path. See tests/test_core.lua's Perf-degradation cases for
  -- the same fresh-mocks-plus-fresh-load shape.
  local Loader     = dofile("tests/_kit/loader.lua")
  local buildMocks = dofile("tests/wow_mock.lua")
  local fresh = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, fresh)
  Loader.load("LibKa0s/Widgets.lua", nil, fresh)
  local freshWidgets = fresh.LibStub("LibKa0s-Widgets-1.0")
  local ok = pcall(freshWidgets.CloseMenu)
  assertTrue(ok, "closing before anything has ever opened must not raise")
end)

test("Widgets.CloseMenu leaves the unregistering to the menu's own OnHide", function()
  local dd = W.Dropdown(mocks.UIParent, 110)
  dd:SetOptions({ { value = "x", label = "X" } })
  dd:__fire("OnClick")
  assertTrue(MENU:IsEventRegistered("GLOBAL_MOUSE_DOWN"), "opening the dropdown started the listen")
  W.CloseMenu()
  -- The mock's Hide() does not auto-invoke OnHide the way the real client does — the same gap
  -- test_debuglog.lua's "showing and hiding the console tells the host" case works around by
  -- firing the script explicitly. Firing it here exercises the wiring CloseMenu relies on rather
  -- than duplicating it: EnsureMenu's menu:SetScript("OnHide", ...) is what drops the event
  -- registration, which is why CloseMenu itself never unregisters anything. Until minor 4 the same
  -- sentence was true of menu.catcher, which this replaces.
  assertTrue(MENU:IsEventRegistered("GLOBAL_MOUSE_DOWN"),
    "CloseMenu hides; it does not reach past OnHide to unregister")
  MENU:__fire("OnHide")
  assertFalse(MENU:IsEventRegistered("GLOBAL_MOUSE_DOWN"))
end)

-- ── Preset rows and the collapsed label (new at minor 4) ──────────────────────
--
-- A PRESET is a row whose value is not one of the values it selects. "Character: Current" picks
-- the current player's key; the row's own value is the string "current", which is nobody's key.
-- Through minor 3 the widget had no way to express that: `rowSelected` could only ask whether the
-- row's own value was in the set, so a preset row was the one row in the menu that could never
-- light up even when it was exactly what the dropdown was showing, and `ToggleSelected` could only
-- toggle the row's own value into the set, so clicking it filtered on the literal string.
--
-- LootHistory's copy of this widget had both seams and its Character filter needed them; they came
-- upstream at the adoption rather than being worked around in the host, which is the bargain the
-- adoption prompt's closing section strikes.

local PRESET_OPTS = {
  { value = "all", label = "Character: All" },
  -- The preset. `isActive` is true exactly when the selection is {Ayla} and nothing else.
  { value = "current", label = "Character: Current",
    isActive = function(dd)
      local sel = dd._selected or {}
      if not sel.Ayla then return false end
      for k in pairs(sel) do if k ~= "Ayla" then return false end end
      return true
    end },
  { value = "Ayla", label = "Ayla" },
  { value = "Borin", label = "Borin" },
}

--- A multi-select dropdown carrying the preset options above and the preset handler that goes with
--- them: clicking "current" REPLACES the selection with the current player rather than toggling
--- the literal string "current" into it.
local function presetDropdown()
  local dd = menuDropdown(true, 146)
  dd.presets = { current = function(d) d._selected = { Ayla = true } end }
  return dd
end

test("A preset row lights up when its own predicate says so", function()
  local dd = presetDropdown()
  dd:SetSelected({ Ayla = true })
  local rows = populate(dd, PRESET_OPTS)
  -- Row 2 is the preset. Its value, "current", is in no selection and never will be — through
  -- minor 3 this row was permanently gray.
  assertEqual(rows[2].fs.color[1], 1, "the preset row is gold")
  assertEqual(rows[2].fs.color[2], 0.82)
end)

test("A preset row stays dark when its predicate says the selection is something else", function()
  local dd = presetDropdown()
  dd:SetSelected({ Borin = true })
  local rows = populate(dd, PRESET_OPTS)
  assertFalse(rows[2].fs.color[1] == 1 and rows[2].fs.color[2] == 0.82,
    "the selection is not exactly the current player, so the preset is not active")
  assertEqual(rows[4].fs.color[1], 1, "Borin's own row is the gold one")
end)

test("isActive is asked INSTEAD of the selection set, not alongside it", function()
  -- A row that carries a predicate is describing a state the set does not express, so its answer
  -- is final in both directions: this one is selected and says no.
  local dd = menuDropdown(true, 110)
  dd:SetSelected({ BANK = true })
  local rows = populate(dd, {
    { value = "all", label = "All" },
    { value = "BANK", label = "Bank", isActive = function() return false end },
  })
  assertFalse(rows[2].fs.color[1] == 1 and rows[2].fs.color[2] == 0.82,
    "the predicate overrides membership of _selected")
end)

test("A preset predicate works on a single-select dropdown too", function()
  local dd = menuDropdown(false, 110)
  dd:SetValue("x", "X")
  local rows = populate(dd, {
    { value = "x", label = "X" },
    { value = "synthetic", label = "Synthetic", isActive = function() return true end },
  })
  assertEqual(rows[2].fs.color[1], 1, "the predicate is consulted before the _value comparison")
end)

test("Clicking a preset row REPLACES the selection instead of toggling into it", function()
  local dd = presetDropdown()
  dd:SetSelected({ Borin = true })
  local rows = populate(dd, PRESET_OPTS)
  rows[2].scripts.OnClick()
  assertTrue(dd._selected.Ayla, "the handler wrote the current player's key")
  assertEqual(dd._selected.Borin, nil, "and replaced what was there rather than adding to it")
  assertEqual(dd._selected.current, nil, "the row's own value never enters the set")
end)

test("A dropdown with no presets toggles exactly as it did at minor 3", function()
  local dd = menuDropdown(true, 110)
  local rows = populate(dd, MENU_OPTS)
  rows[2].scripts.OnClick()
  assertTrue(dd._selected.BANK, "an ordinary value still toggles in")
  rows[1].scripts.OnClick()
  assertEqual(next(dd._selected), nil, "and the 'all' sentinel still clears the set")
end)

test("A preset may override the 'all' sentinel itself", function()
  -- presets is asked before the sentinel, so a host that wants "All" to mean something of its own
  -- can say so. Nothing in the collection does this today; the case pins the ordering.
  local dd = menuDropdown(true, 110)
  dd.presets = { all = function(d) d._selected = { BANK = true } end }
  local rows = populate(dd, MENU_OPTS)
  rows[1].scripts.OnClick()
  assertTrue(dd._selected.BANK, "the host's handler ran instead of the clear")
end)

-- ── The collapsed label ───────────────────────────────────────────────────────

test("The collapsed label takes an active preset's own label", function()
  local dd = presetDropdown()
  dd:SetOptions(PRESET_OPTS)
  dd:SetSelected({ Ayla = true })
  -- Not "Ayla", which is what the one-selection rule below would give: the preset NAMES the whole
  -- selection, so its label is the one the button wears.
  assertEqual(dd.text:GetText(), "Character: Current")
end)

test("A selected value with no option row still counts in the summary", function()
  -- The option lists are data-driven: a character with no rows in the current dataset is not in
  -- the list, and through minor 3 the button then read "Character: All" while the filter was on.
  local dd = menuDropdown(true, 146)
  dd:SetOptions({ { value = "all", label = "Character: All" }, { value = "Borin", label = "Borin" } })
  dd:SetSelected({ Borin = true, Ayla = true })
  assertEqual(dd.text:GetText(), "Character: 2 selected")
end)

test("A single selection with no option row reads as its raw value", function()
  local dd = menuDropdown(true, 146)
  dd:SetOptions({ { value = "all", label = "Character: All" } })
  dd:SetSelected({ Ayla = true })
  assertEqual(dd.text:GetText(), "Ayla")
end)

test("An empty selection still reads as the 'all' sentinel's own label", function()
  local dd = menuDropdown(true, 146)
  dd:SetOptions(PRESET_OPTS)
  dd:SetSelected({})
  assertEqual(dd.text:GetText(), "Character: All")
end)

test("One selection that IS in the option list reads as that row's label", function()
  local dd = menuDropdown(true, 146)
  dd:SetOptions(PRESET_OPTS)
  dd:SetSelected({ Borin = true })
  assertEqual(dd.text:GetText(), "Borin")
end)

test("A preset row survives a REAL row build", function()
  -- Not a seeded stand-in: makeMenuRow runs, and the predicate is asked on a row this widget built
  -- itself. The seeded cases above cannot catch a row whose construction raises.
  local dd = presetDropdown()
  dd:SetSelected({ Ayla = true })
  local rows = populateBuilt(dd, PRESET_OPTS)
  assertEqual(#rows, 4, "one real row per option")
  assertEqual(rows[2].fs:GetText(), "|T" .. HOST_CHECK .. ":0|t Character: Current",
    "the active preset draws the tick, built rows and all")
end)

-- ── Closing on a click ANYWHERE, without eating it (new at minor 5) ───────────
--
-- Through minor 4 the menu was dismissed by a full-screen `Button` at FULLSCREEN strata, shown
-- alongside it. Two consequences, and both were defects:
--
-- 1. A Button with no `RegisterForClicks` takes `LeftButtonUp` ONLY. A right-click anywhere while
--    a menu was open landed on the catcher, found no handler, and was SWALLOWED — the menu stayed
--    open and whatever was underneath never heard the click. LootHistory is the first host with a
--    right-click surface on the same window as a dropdown, which is why it survived from minor 1.
-- 2. Even the left-click it did handle was eaten. Dismissing a menu cost a click that did nothing
--    else.
--
-- The catcher is gone. The menu listens for GLOBAL_MOUSE_DOWN while it is shown and closes itself
-- when the press was neither on the menu nor on the dropdown it dropped from. Nothing intercepts
-- anything, so the click reaches whatever is under the cursor — which is the behavior the issue
-- asked for and the visible change of this version.

--- A shown menu, dropped from a fresh dropdown, with the cursor recorded as somewhere else.
local function openMenu()
  local dd = W.Dropdown(mocks.UIParent, 110)
  dd:SetOptions({ { value = "x", label = "X" }, { value = "y", label = "Y" } })
  dd:__fire("OnClick")
  MENU.__mouseOver = false
  dd.__mouseOver = false
  return dd
end

test("The menu builds no click-catcher at all", function()
  openMenu()
  assertEqual(MENU.catcher, nil,
    "nothing is parked over the screen to intercept a click")
end)

test("An open menu listens for a mouse press anywhere", function()
  openMenu()
  assertTrue(MENU:IsEventRegistered("GLOBAL_MOUSE_DOWN"),
    "the menu hears the click instead of catching it")
end)

test("A RIGHT-click outside closes the menu", function()
  -- The defect this version exists for. Through minor 4 this click was swallowed and the menu
  -- stayed open.
  openMenu()
  MENU:__fire("OnEvent", "GLOBAL_MOUSE_DOWN", "RightButton")
  assertEqual(MENU:IsShown(), false)
end)

test("A LEFT-click outside closes the menu", function()
  openMenu()
  MENU:__fire("OnEvent", "GLOBAL_MOUSE_DOWN", "LeftButton")
  assertEqual(MENU:IsShown(), false)
end)

test("Any other mouse button closes it too", function()
  -- No button is enumerated anywhere in the widget, so a mouse with more of them behaves the same.
  openMenu()
  MENU:__fire("OnEvent", "GLOBAL_MOUSE_DOWN", "Button4")
  assertEqual(MENU:IsShown(), false)
end)

test("A press ON the menu does not close it", function()
  -- Otherwise the menu would close under the player's own row click, before the row was released.
  openMenu()
  MENU.__mouseOver = true
  MENU:__fire("OnEvent", "GLOBAL_MOUSE_DOWN", "LeftButton")
  assertTrue(MENU:IsShown(), "clicking a row must not dismiss the menu out from under it")
end)

test("A press on the dropdown that dropped it does not close it", function()
  -- The dropdown's own OnClick is the toggle. If the press closed the menu first, the release
  -- would find it hidden and re-open it, and the menu would be impossible to close by its button.
  local dd = openMenu()
  dd.__mouseOver = true
  MENU:__fire("OnEvent", "GLOBAL_MOUSE_DOWN", "LeftButton")
  assertTrue(MENU:IsShown(), "the press is left for the button's own toggle to handle")
  dd:__fire("OnClick")
  assertEqual(MENU:IsShown(), false, "and the toggle still closes it")
end)

test("A press on a DIFFERENT dropdown still closes the menu", function()
  -- Only the owner is exempt. A second dropdown's press closes the first menu; that dropdown's own
  -- OnClick then opens its own, which is how exactly one menu stays open process-wide.
  local first = openMenu()
  local other = W.Dropdown(mocks.UIParent, 110)
  other:SetOptions({ { value = "z", label = "Z" } })
  other.__mouseOver = true
  assertTrue(first ~= other)
  MENU:__fire("OnEvent", "GLOBAL_MOUSE_DOWN", "LeftButton")
  assertEqual(MENU:IsShown(), false)
end)

test("An event that is not GLOBAL_MOUSE_DOWN is ignored", function()
  openMenu()
  MENU:__fire("OnEvent", "PLAYER_REGEN_DISABLED")
  assertTrue(MENU:IsShown(), "the menu closes on a mouse press, not on whatever else arrives")
end)

mocks.CreateFrame, mocks.UIParent = realCreateFrame, realUIParent
