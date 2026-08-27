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
  -- The handle's tint, which is what the hover cases read.
  function f:SetVertexColor(r, g, b, a) self.__vertexColor = { r, g, b, a or 1 }; return self end
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
  -- A NUMBER, because ReorderList divides the cursor by it. The catch-all below would answer the
  -- frame itself, the library guards on the answer being a number, and the guard rather than the
  -- drag is what every case would then be testing.
  function f:GetEffectiveScale() return 1 end
  -- PARENTAGE IS REAL, because releasing a handle is defined as taking it OFF the host's frame and
  -- the catch-all would answer the frame itself for both of these.
  function f:SetParent(p) self.__parent = p; return self end
  function f:GetParent() return self.__parent end
  -- ALPHA IS REAL. ReorderList fades the row you picked up, and against the catch-all GetAlpha
  -- would answer the frame itself -- so `< 1` would raise rather than assert.
  function f:SetAlpha(a) self.__alpha = a; return self end
  function f:GetAlpha() return self.__alpha or 1 end
  -- POINTS ARE REAL, so a case can ask what the insertion line was anchored TO. The line's whole
  -- contract is that it is anchored to the target row rather than positioned by arithmetic, and
  -- against the catch-all that claim is unfalsifiable.
  function f:ClearAllPoints() self.__points = {}; return self end
  function f:SetPoint(point, rel, relPoint, x, y)
    if type(rel) == "number" or rel == nil then
      self.__points[#self.__points + 1] = { point = point, relativeTo = nil, x = rel, y = relPoint }
    else
      self.__points[#self.__points + 1] =
        { point = point, relativeTo = rel, relativePoint = relPoint, x = x, y = y }
    end
    return self
  end
  function f:GetPoint(i)
    local pt = self.__points[i or 1]
    if not pt then return nil end
    return pt.point, pt.relativeTo, pt.relativePoint, pt.x, pt.y
  end
  function f:GetNumPoints() return #self.__points end
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

-- Forwards CreateFrame's arguments onto the frame the same way testkit/mock_base.lua does, so a
-- case can ask what a frame was NAMED. Widgets is where that matters most: the copy window's
-- scroll frame carries a global name (minor 7) precisely because UIPanelScrollFrameTemplate
-- derives its scrollbar children's names from it.
local geomCreateFrame = function(frameType, name, parent, template)
  local f = geomFrame()
  f.__frameType, f.__name, f.__parent = frameType, name, parent
  if template ~= nil then f.__template = template end
  return f
end
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

-- ── the copy window ──────────────────────────────────────────────────────────────────────
--
-- There is no file I/O in WoW, so every "copy this out" surface in the collection ends in a frame
-- holding a selectable multi-line EditBox. There were FOUR before this member: BankLedger's,
-- LootHistory's, MultiMeters' and the debug log's — and BankLedger's and LootHistory's were the
-- same 52 lines with the addon name substituted.
--
-- The cases below pin the two things a fifth author would have had to rediscover: the descriptor's
-- defaults, and the ORDER inside Show, which is load-bearing (highlighting before the frame is
-- shown selects nothing).
--
-- The plan's block named the library `widgets` and aliased `test`; in this file the library is `W`
-- and `test` is the geometry-installing wrapper defined at the head, so both are used directly.

test("widgets: CopyWindow answers nil with no client", function()
  -- Headless, CreateFrame is a mock, so this asserts the guard exists rather than the absence.
  -- The real degraded path is a host loaded with no UI at all.
  local saved = mocks.CreateFrame
  mocks.CreateFrame = nil
  assertEqual(W.CopyWindow({ addonName = "TestHost" }), nil)
  mocks.CreateFrame = saved
end)

test("widgets: CopyWindow requires an addon name", function()
  assertEqual(W.CopyWindow({}), nil)
  assertEqual(W.CopyWindow(nil), nil)
end)

test("widgets: CopyWindow fills in the collection's defaults", function()
  local win = W.CopyWindow({ addonName = "TestHost" })
  assertTrue(win ~= nil, "a handle came back")
  local d = win.__descriptor
  assertEqual(d.name, "TestHostCopyWindow")
  assertEqual(d.width, 640)
  assertEqual(d.height, 420)
  assertEqual(d.fontSize, 10)
  assertEqual(d.title, "Export")
end)

test("widgets: CopyWindow honours an overridden descriptor", function()
  local win = W.CopyWindow({
    addonName = "TestHost", name = "MyCopyBox", width = 500, height = 300,
    title = "Export \226\128\148 Ctrl+C, then Esc", fontSize = 12,
  })
  local d = win.__descriptor
  assertEqual(d.name, "MyCopyBox")
  assertEqual(d.width, 500)
  assertEqual(d.fontSize, 12)
end)

test("widgets: the frame is built once and reused", function()
  local win = W.CopyWindow({ addonName = "TestHost" })
  win:Show("first")
  local f = win:GetFrame()
  win:Hide()
  win:Show("second")
  assertTrue(win:GetFrame() == f, "a second Show must not build a second frame — frames are never "
    .. "destroyed in WoW, so a rebuild per open leaks one per open")
end)

test("widgets: Show puts the text in the box and leaves it shown", function()
  local win = W.CopyWindow({ addonName = "TestHost" })
  win:Show("a,b,c\r\n1,2,3\r\n")
  assertEqual(win:GetText(), "a,b,c\r\n1,2,3\r\n")
  assertTrue(win:GetFrame().__shown, "the frame is up")
end)

test("widgets: Show sets the text BEFORE it highlights", function()
  -- The order is the reason this is worth sharing. Highlighting before the frame is shown selects
  -- nothing, and focusing before the text is set leaves the cursor wherever the last export left
  -- it. Recorded by spying on the EditBox rather than by reading the source.
  local win = W.CopyWindow({ addonName = "TestHost" })
  win:Show("seed")
  local edit, order = win:GetFrame().edit, {}
  local realSetText, realHighlight = edit.SetText, edit.HighlightText
  edit.SetText = function(s, t) order[#order + 1] = "SetText"; return realSetText(s, t) end
  edit.HighlightText = function(s) order[#order + 1] = "HighlightText"; return realHighlight(s) end
  win:Show("payload")
  edit.SetText, edit.HighlightText = realSetText, realHighlight
  assertEqual(table.concat(order, ","), "SetText,HighlightText")
end)

test("widgets: the frame registers for Esc under its global name", function()
  local before = #mocks.UISpecialFrames
  local win = W.CopyWindow({ addonName = "TestHost", name = "EscapeMe" })
  win:Show("x")
  local found = false
  for i = before + 1, #mocks.UISpecialFrames do
    if mocks.UISpecialFrames[i] == "EscapeMe" then found = true end
  end
  assertTrue(found, "the global name is in UISpecialFrames, or Esc does not close it")
end)

test("widgets: anchorTo is consulted on EVERY show", function()
  -- Not once at build: the popup has to follow a window the user moved between exports.
  local asked = 0
  local win = W.CopyWindow({
    addonName = "TestHost",
    anchorTo = function() asked = asked + 1; return nil end,
  })
  win:Show("one"); win:Hide(); win:Show("two")
  assertEqual(asked, 2)
end)

test("widgets: CopyWindow names the scroll frame when asked (minor 7)", function()
  -- UIPanelScrollFrameTemplate derives its scrollbar children's names from the parent's, so an
  -- anonymous scroll frame leaves them unnamed. The three adopters shipped without this and the
  -- debug log's hand-rolled copy window was the one that got it right — which is what surfaced it
  -- when that window was converged onto this member.
  local win = W.CopyWindow({ addonName = "TestHost", scrollName = "TestHostExportScroll" })
  local f = win:GetFrame()
  assertEqual(f.scroll.__name, "TestHostExportScroll")
end)

test("widgets: CopyWindow leaves the scroll frame anonymous when not asked", function()
  -- The field is additive and OPTIONAL: every caller written before minor 7 keeps the frame it
  -- already had, rather than silently acquiring a global.
  local win = W.CopyWindow({ addonName = "TestHost" })
  local f = win:GetFrame()
  assertEqual(f.scroll.__name, nil)
end)

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
  row.frame:__fire("OnUpdate", 0.1)

  mocks.setMouseDown("LeftButton", false)
  row.frame:__fire("OnUpdate", 0.1)
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
  -- poll that ended on `not held` would finish the drag with zero rows travelled -- no error, no
  -- message, and indistinguishable from a press that was never received. It has to see the button
  -- HELD before it may act on it being released.
  local list, rows, log = reorderList(5)
  local row = rows[1]

  mocks.setMouseDown("LeftButton", false)
  mocks.setCursor(0, 1000)
  row.handle:__fire("OnMouseDown")

  mocks.setCursor(0, 1000 - 2 * list.stride)
  row.frame:__fire("OnUpdate", 0.1)
  assertEqual(#log.moved, 0, "the poll ended a drag it never saw begin")

  row.handle:__fire("OnMouseUp")
  assertEqual(#log.moved, 1, "OnMouseUp did not complete the drag")
  assertEqual(log.moved[1][2], 3, "the distance travelled was thrown away")
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
  row.frame:__fire("OnUpdate", 0.1)

  row.handle:__fire("OnDragStop")
  row.handle:__fire("OnMouseUp")
  mocks.setMouseDown("LeftButton", false)
  row.frame:__fire("OnUpdate", 0.1)

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
  row.frame:__fire("OnUpdate", 0.1)
  assertFalse(select(5, ghost:GetPoint(1)) == firstY, "the ghost did not follow the cursor")
  assertTrue(row.frame:GetAlpha() < 1, "the row it came from must fade behind it")

  mocks.setMouseDown("LeftButton", false)
  row.frame:__fire("OnUpdate", 0.1)
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
  row.frame:__fire("OnUpdate", 0.1)

  assertTrue(list.line:IsShown(), "the line must be visible during a drag")
  local _, relativeTo = list.line:GetPoint(1)
  assertEqual(relativeTo, rows[3].frame, "the line is not against the drop target")

  mocks.setMouseDown("LeftButton", false)
  row.frame:__fire("OnUpdate", 0.1)
  assertFalse(list.line:IsShown(), "the line must go away when the drag ends")
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
  row.frame:__fire("OnUpdate", 0.1)

  assertTrue(list.line:IsShown(), "a clamped drag must still say where it would land")
  local _, relativeTo = list.line:GetPoint(1)
  assertEqual(relativeTo, rows[3].frame, "clamped to its own index, so the line sits on itself")

  mocks.setMouseDown("LeftButton", false)
  row.frame:__fire("OnUpdate", 0.1)
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
  row.frame:__fire("OnUpdate", 0.1)

  list:Cancel()
  assertFalse(W.__DragGhost:IsShown(), "the ghost outlived the list it was describing")
  assertFalse(list.line:IsShown())
  assertEqual(row.frame:GetAlpha(), 1, "the picked-up row must come back to full opacity")

  mocks.setMouseDown("LeftButton", false)
  row.frame:__fire("OnUpdate", 0.1)
  assertEqual(#log.moved, 0, "a cancelled drag must not land after the fact")
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
  rows[1]:__fire("OnUpdate", 0.1)
  mocks.setMouseDown("LeftButton", false)
  rows[1]:__fire("OnUpdate", 0.1)
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
  parent:__fire("OnUpdate", 0.1)
  mocks.setMouseDown("LeftButton", false)
  parent:__fire("OnUpdate", 0.1)

  assertEqual(#moved, 1, "the handle drove a dead controller, so nothing moved -- this is the freeze")
  assertEqual(moved[1][2], 2)
end)

test("widgets: the handle takes the hover colour and drops it again", function()
  -- The handle has to say it is a control before you press it. The tint is the host's to choose;
  -- the default is the collection's gold, so a host that says nothing matches every other list.
  local parent = geomFrame()
  local list = W.ReorderList({ stride = 30, handleTooltip = "Drag to move" })
  local handle = list:AddRow(parent, {})

  handle:__fire("OnEnter")
  local r, g, b = handle.art.__vertexColor[1], handle.art.__vertexColor[2], handle.art.__vertexColor[3]
  assertEqual(r, 1); assertEqual(g, 0.82); assertEqual(b, 0)

  handle:__fire("OnLeave")
  assertEqual(handle.art.__vertexColor[1], 0.7, "the handle must go back to its rest colour")
end)

test("widgets: a host may override both handle colours", function()
  local parent = geomFrame()
  local list = W.ReorderList({
    stride           = 30,
    handleColor      = { 0.2, 0.3, 0.4 },
    handleHoverColor = { 0.9, 0.1, 0.1 },
  })
  local handle = list:AddRow(parent, {})
  assertEqual(handle.art.__vertexColor[1], 0.2, "the rest colour was not the host's")

  handle:__fire("OnEnter")
  assertEqual(handle.art.__vertexColor[1], 0.9, "the hover colour was not the host's")
end)

test("widgets: only the handle starts a drag", function()
  -- Rows in these lists carry other controls -- a remove button, a score button, a toggle glyph --
  -- and a row draggable anywhere would swallow presses aimed at those. They sit pixels apart.
  local _, rows = reorderList(3)
  assertTrue(rows[1].handle:GetScript("OnMouseDown") ~= nil, "the handle must start the drag")
  assertEqual(rows[1].frame:GetScript("OnMouseDown"), nil, "the row itself must not")
end)
