-- tests/fixture_geom.lua — the geometry frame factory the LibKa0s-Widgets-1.0 suites share:
-- tests/test_widgets.lua (the flat dropdown, its shared menu and the copy window) and
-- tests/test_widgets_reorderlist.lua (ReorderList's drag, its handles and its row boxes).
--
-- Moved out of tests/test_widgets.lua, unchanged, when issue #37 split that suite by widget family.
-- One copy rather than two, for the reason tests/fixture_ids.lua gives: a factory that drifted
-- between the suites would make one suite's case prove something another's does not. Why the
-- factory exists at all, and why it is installed per case, is tests/test_widgets.lua's header.
--
-- Loaded as `dofile("tests/fixture_geom.lua")`, which answers `geomFrame` (one bare frame),
-- `createFrame` (the CreateFrame stand-in), `uiParent` (the UIParent stand-in) and `test` (a case
-- registrar whose body runs with those two installed, and with whatever was there put back).

local T = _G.LK_TEST
local rawTest = T.test
local mocks   = T.mocks

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
  -- THE ROW BOX'S PAINT, recorded rather than swallowed. A box is a fill plus four 1px edges, and
  -- against the catch-all every SetColorTexture would answer the frame itself -- so "did this row
  -- get the dimmed variant?" would be unaskable and every box case below would pass against
  -- nothing at all.
  function f:SetColorTexture(r, g, b, a)
    self.__colorTexture = { r, g, b, a }
    return self
  end
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

return { geomFrame = geomFrame, createFrame = geomCreateFrame, uiParent = geomUIParent, test = test }
