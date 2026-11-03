-- tests/test_options_pullout_close.lua — OptionsCombat minor 4: an AceGUI dropdown's pullout on a
-- Ka0s surface closes on a mouse press outside it (R4-L1 of Ka0sAddonsCommonTasks
-- docs/2026-11-03-SMOKE_ROUND4/, the owner's item 1, image 1).
--
-- Stock AceGUI has no outside-click close: a pullout closes only through AceGUI:ClearFocus, which
-- AceGUI's own containers call and no Ka0s settings canvas or window does. So the library hooks
-- AceGUI:SetFocus, the one call every Dropdown, Ka0sMedia_* picker and AuraMasterDropdown makes right
-- after its pullout opens, and while a pullout on a Ka0s surface is open it LISTENS for
-- GLOBAL_MOUSE_DOWN on one hidden frame. A press over neither the pullout nor its own dropdown
-- clears the focus, which closes the pullout the way AceGUI's Frame container does. Nothing is
-- caught or swallowed. Another author's AceGUI dropdown keeps AceGUI's behavior (the lead's call 1).
--
-- The AceGUI here is a fake with AceGUI-3.0 minor 41's SetFocus / ClearFocus semantics, and the
-- hooksecurefunc is a real one for the length of each case (the kit's is a no-op).

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse
local mocks = T.mocks
local lib = T.options
local Skin = T.skin

local MOUSE_DOWN = "GLOBAL_MOUSE_DOWN"

--- A hooksecurefunc that hooks: `t[name]` becomes the original, then `fn`, with the same arguments.
local function realHook(t, name, fn)
  local orig = t[name]
  assert(type(orig) == "function", "hooksecurefunc: no function " .. tostring(name))
  t[name] = function(...)
    local r = { orig(...) }
    fn(...)
    return unpack(r)
  end
end

-- ── the bench ────────────────────────────────────────────────────────────────────────────────

--- A frame under `parent` that answers GetParent and IsMouseOver (`__mouseOver`), which the kit's
--- frames answer with the frame itself.
local function frameUnder(parent)
  local f = mocks.CreateFrame("Frame", nil, parent)
  rawset(f, "GetParent", function() return parent end)
  f.__mouseOver = false
  rawset(f, "IsMouseOver", function(self) return self.__mouseOver == true end)
  return f
end

--- AceGUI-3.0's focus pair, as minor 41 writes it.
local function fakeAceGUI()
  local ace = { cleared = 0 }
  function ace:SetFocus(widget)
    if self.FocusedWidget and self.FocusedWidget ~= widget then
      self.FocusedWidget:ClearFocus()
    end
    self.FocusedWidget = widget
  end
  function ace:ClearFocus()
    self.cleared = self.cleared + 1
    if self.FocusedWidget then
      self.FocusedWidget:ClearFocus()
      self.FocusedWidget = nil
    end
  end
  return ace
end

--- An AceGUI Dropdown on `parent`: its frame, a pullout parented to UIParent (as AceGUI's is), and
--- the toggle, ClearFocus and release AceGUIWidget-DropDown.lua (widget version 36) write.
local function dropdown(ace, parent)
  local w = { frame = frameUnder(parent) }
  local pullout = { frame = frameUnder(mocks.UIParent), closes = 0 }
  -- The scrollbar: parented to the pullout's scroll frame, inside the pullout's bounds.
  pullout.scrollFrame = frameUnder(pullout.frame)
  pullout.slider = frameUnder(pullout.scrollFrame)
  function pullout:Close() self.closes = self.closes + 1; w.open = nil end
  w.pullout = pullout
  function w:ClearFocus() if self.open then self.open = nil; self.pullout:Close() end end
  --- Dropdown_TogglePullout on a closed dropdown: open, then SetFocus.
  function w:Toggle()
    if self.open then
      self.open = nil
      self.pullout:Close()
      ace:ClearFocus()
    else
      self.open = true
      ace:SetFocus(self)
    end
  end
  --- OnRelease: close an open pullout, release it, drop the field (AceGUI:Release).
  function w:Release()
    if self.open then self.pullout:Close() end
    self.pullout = nil
  end
  return w
end

local function watch() return lib.__pulloutWatch end
local function listening()
  local f = watch()
  return f ~= nil and f:IsEventRegistered(MOUSE_DOWN)
end
local function press(button)
  local f = watch()
  if f then f:__fire("OnEvent", MOUSE_DOWN, button or "LeftButton") end
end

--- A Ka0s settings page on screen: a ctx the library watches combat for (lib.__pageShown).
local function kaosPage()
  local ctx = { panel = frameUnder(mocks.UIParent) }
  ctx.body = frameUnder(ctx.panel)
  lib.__shownPages[ctx] = true
  return ctx
end

--- A Ka0s window: a frame the Skin major painted with Shell (Core.ApplySkin / S.Shell's record).
local function kaosWindow()
  local f = frameUnder(mocks.UIParent)
  Skin.painted[f] = { owner = "LibKa0sSkinTester", seq = 0, calls = { Shell = { n = 0 } }, order = { "Shell" } }
  return f
end

--- One case on a clean bench: a real hooksecurefunc, no hook record, the watcher quiet, and a fresh
--- fake AceGUI armed. Everything is put back however the case ends.
local function pulloutCase(name, fn)
  test(name, function()
    local saved = {
      hook = mocks.hooksecurefunc, rec = lib.__pulloutHook, combat = mocks.InCombatLockdown,
      pages = {},
    }
    for ctx in pairs(lib.__shownPages) do saved.pages[ctx] = true end
    mocks.hooksecurefunc = realHook
    lib.__pulloutHook = nil
    local ace = fakeAceGUI()
    local ok, err = pcall(function()
      assertTrue(type(lib.__armPulloutClose) == "function", "OptionsCombat minor 4 arms the close")
      lib.__armPulloutClose(ace, 41)
      fn(ace)
    end)
    if watch() then watch():UnregisterEvent(MOUSE_DOWN) end
    lib.__pulloutAce = nil
    for ctx in pairs(lib.__shownPages) do
      if not saved.pages[ctx] then lib.__shownPages[ctx] = nil end
    end
    mocks.hooksecurefunc, lib.__pulloutHook, mocks.InCombatLockdown = saved.hook, saved.rec, saved.combat
    if not ok then error(err, 0) end
  end)
end

-- ── the close ────────────────────────────────────────────────────────────────────────────────

pulloutCase("pullout close: opening a dropdown on a Ka0s page listens for a press", function(ace)
  local w = dropdown(ace, kaosPage().body)
  w:Toggle()
  assertTrue(listening(), "GLOBAL_MOUSE_DOWN is registered while the pullout is open")
  assertTrue(watch():IsShown() == false, "the watcher is a hidden frame: it catches nothing")
end)

pulloutCase("pullout close: a press outside closes it, with any button", function(ace)
  for _, button in ipairs({ "LeftButton", "RightButton", "Button4" }) do
    local w = dropdown(ace, kaosPage().body)
    ace.cleared = 0
    w:Toggle()
    press(button)
    assertEqual(ace.cleared, 1, button .. ": the focus is cleared once")
    assertFalse(w.open, button .. ": the pullout is closed")
    assertEqual(w.pullout.closes, 1, button .. ": through the pullout's own Close")
    assertFalse(listening(), button .. ": and the press is no longer listened for")
  end
end)

pulloutCase("pullout close: a press on the pullout (a row) does not close it", function(ace)
  local w = dropdown(ace, kaosPage().body)
  w:Toggle()
  w.pullout.frame.__mouseOver = true
  press()
  assertTrue(w.open, "a row press picks; closing first would lose the pick")
  assertEqual(ace.cleared, 0)
  assertTrue(listening(), "still listening")
end)

pulloutCase("pullout close: a press on the pullout's scrollbar does not close it", function(ace)
  -- The slider sits inside the pullout's bounds, so the pullout frame answers IsMouseOver for it.
  local w = dropdown(ace, kaosPage().body)
  w:Toggle()
  w.pullout.slider.__mouseOver = true
  w.pullout.frame.__mouseOver = true
  press()
  assertTrue(w.open, "dragging the scrollbar keeps the list open")
  assertTrue(listening())
end)

pulloutCase("pullout close: a press on the owning dropdown does not close it", function(ace)
  -- The dropdown's own release is the toggle; closing on the press would let it reopen.
  local w = dropdown(ace, kaosPage().body)
  w:Toggle()
  w.frame.__mouseOver = true
  press()
  assertTrue(w.open)
  assertEqual(ace.cleared, 0)
  w:Toggle()
  assertFalse(w.open, "the release then toggles it closed")
  press()
  assertFalse(listening(), "and the next press lets go")
end)

pulloutCase("pullout close: a dropdown on a Ka0s window closes too", function(ace)
  local window = kaosWindow()
  local cell = frameUnder(frameUnder(window))
  local w = dropdown(ace, cell)
  w:Toggle()
  assertTrue(listening())
  press()
  assertFalse(w.open, "the Skin Tester showroom's AceGUI samples close")
  Skin.painted[window] = nil
end)

pulloutCase("pullout close: an AceDBOptions Profiles dropdown under a Ka0s page closes", function(ace)
  -- AceConfigDialog draws the profile manager into a SimpleGroup parented to the page's body.
  local ctx = kaosPage()
  local container = frameUnder(ctx.body)
  local content = frameUnder(container)
  local group = frameUnder(content)
  local w = dropdown(ace, group)
  w:Toggle()
  press()
  assertFalse(w.open)
end)

-- ── other authors' dropdowns ─────────────────────────────────────────────────────────────────

pulloutCase("pullout close: another author's AceGUI dropdown keeps AceGUI's behavior", function(ace)
  local w = dropdown(ace, frameUnder(mocks.UIParent))
  w:Toggle()
  assertFalse(listening(), "nothing is registered for a dropdown on no Ka0s surface")
  press()
  assertTrue(w.open, "and it stays open")
  assertEqual(ace.cleared, 0)
end)

pulloutCase("pullout close: focus moving to another author's dropdown lets go, closing nothing",
  function(ace)
  local ours = dropdown(ace, kaosPage().body)
  ours:Toggle()
  local theirs = dropdown(ace, frameUnder(mocks.UIParent))
  theirs:Toggle()
  assertFalse(ours.open, "AceGUI's SetFocus closed ours, as stock")
  press()
  assertTrue(theirs.open, "the other author's pullout is left open")
  assertEqual(ace.cleared, 0)
  assertFalse(listening(), "and the watcher let go")
end)

pulloutCase("pullout close: a focus taker with no pullout registers nothing", function(ace)
  local box = { frame = frameUnder(kaosPage().body), ClearFocus = function() end }
  ace:SetFocus(box)
  assertFalse(listening(), "an EditBox's focus is not a pullout")
end)

-- ── closed by another route ──────────────────────────────────────────────────────────────────

pulloutCase("pullout close: a pullout closed by a pick or the toggle lets go on the next press",
  function(ace)
  local w = dropdown(ace, kaosPage().body)
  w:Toggle()
  w.pullout:Close()          -- an item pick closes the pullout; the focus stays
  press()
  assertEqual(ace.cleared, 0, "nothing is cleared twice")
  assertFalse(listening())
end)

pulloutCase("pullout close: the library's own closers leave a press that only lets go", function(ace)
  -- O.__releaseOwnedFocus (combat start) and the skin picker's dropFocus both clear the focus.
  local w = dropdown(ace, kaosPage().body)
  w:Toggle()
  ace:ClearFocus()
  ace.cleared = 0
  press()
  assertFalse(w.open)
  assertEqual(ace.cleared, 0)
  assertFalse(listening())
end)

pulloutCase("pullout close: a widget released while open is not touched", function(ace)
  -- A page rebuild releases the dropdown; AceGUI.FocusedWidget still names the pooled object.
  local w = dropdown(ace, kaosPage().body)
  w:Toggle()
  w:Release()
  assertTrue(ace.FocusedWidget == w, "AceGUI does not drop the focus on a release")
  press()
  assertEqual(ace.cleared, 0, "a released widget is not cleared")
  assertFalse(listening())
end)

pulloutCase("pullout close: a widget released and acquired again, closed, is not touched", function(ace)
  local w = dropdown(ace, kaosPage().body)
  w:Toggle()
  w:Release()
  w.pullout = { frame = frameUnder(mocks.UIParent), Close = function() end }   -- OnAcquire
  press()
  assertEqual(ace.cleared, 0)
  assertFalse(listening())
end)

pulloutCase("pullout close: the panel hiding closes the pullout, and the next press lets go",
  function(ace)
  -- Dropdown_OnHide closes the pullout but never clears AceGUI.FocusedWidget; the page's hide
  -- drops the ctx from the shown pages.
  local ctx = kaosPage()
  local w = dropdown(ace, ctx.body)
  w:Toggle()
  w.pullout:Close()
  lib.__shownPages[ctx] = nil
  assertTrue(listening(), "still registered until the next press")
  press()
  assertEqual(ace.cleared, 0)
  assertFalse(listening())
end)

pulloutCase("pullout close: a hidden page's dropdown left open is not a Ka0s surface", function(ace)
  local ctx = kaosPage()
  local w = dropdown(ace, ctx.body)
  w:Toggle()
  lib.__shownPages[ctx] = nil
  press()
  assertEqual(ace.cleared, 0, "a page off screen is not the library's to act on")
  assertFalse(listening())
end)

-- ── two dropdowns ────────────────────────────────────────────────────────────────────────────

pulloutCase("pullout close: a second dropdown opening reads the current focus", function(ace)
  local ctx = kaosPage()
  local a, b = dropdown(ace, ctx.body), dropdown(ace, ctx.body)
  a:Toggle()
  b:Toggle()
  assertFalse(a.open, "AceGUI closed the first")
  assertTrue(b.open)
  assertTrue(listening())
  b.pullout.frame.__mouseOver = true
  press()
  assertTrue(b.open, "a press on the second's pullout is not outside")
  b.pullout.frame.__mouseOver = false
  press()
  assertFalse(b.open, "an outside press closes the second")
  assertEqual(ace.cleared, 1)
end)

-- ── the hook ─────────────────────────────────────────────────────────────────────────────────

pulloutCase("pullout close: arming twice hooks once", function(ace)
  local hooked = ace.SetFocus
  assertFalse(lib.__armPulloutClose(ace, 41), "the second arm is refused")
  assertTrue(ace.SetFocus == hooked, "SetFocus is not wrapped again")
end)

pulloutCase("pullout close: a newer AceGUI minor is hooked again", function(ace)
  ace.SetFocus = fakeAceGUI().SetFocus          -- the upgrade redefines SetFocus
  assertTrue(lib.__armPulloutClose(ace, 42), "the new minor is hooked")
  local w = dropdown(ace, kaosPage().body)
  w:Toggle()
  assertTrue(listening())
end)

pulloutCase("pullout close: another addon's hook on SetFocus is not hooked over", function(ace)
  local ours = ace.SetFocus
  realHook(ace, "SetFocus", function() end)      -- an AceGUI skin hooks after us
  local theirs = ace.SetFocus
  assertFalse(lib.__armPulloutClose(ace, 41), "keyed on the AceGUI and its minor, not the function")
  assertTrue(ace.SetFocus == theirs and theirs ~= ours)
end)

pulloutCase("pullout close: no AceGUI, nothing armed", function()
  assertFalse(lib.__armPulloutClose({}, 1), "an AceGUI with no SetFocus")
end)

-- ── robustness ───────────────────────────────────────────────────────────────────────────────

pulloutCase("pullout close: a ClearFocus that raises keeps the handler alive", function(ace)
  local w = dropdown(ace, kaosPage().body)
  w:Toggle()
  ace.ClearFocus = function() error("boom") end
  local ok = pcall(press)
  assertTrue(ok, "the error does not escape the event handler")
  assertFalse(listening())
end)

pulloutCase("pullout close: an outside press in combat still closes it", function(ace)
  mocks.InCombatLockdown = function() return true end
  local w = dropdown(ace, kaosPage().body)
  w:Toggle()
  press()
  assertFalse(w.open, "the pullout and the watcher are plain frames")
end)

pulloutCase("pullout close: the handler is looked up on lib when the press arrives", function(ace)
  local w = dropdown(ace, kaosPage().body)
  w:Toggle()
  local saved, seen = lib.__OnPulloutPress, 0
  lib.__OnPulloutPress = function() seen = seen + 1 end
  local ok, err = pcall(press)
  lib.__OnPulloutPress = saved
  if not ok then error(err, 0) end
  assertEqual(seen, 1, "a newer copy's handler is the one that runs")
  assertTrue(w.open)
end)
