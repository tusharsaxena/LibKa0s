-- tests/test_options_idsuggest_frames.lua — LibKa0s-Options-1.0's IdInput suggestions: the
-- dropdown's frames. One dropdown per instance, pooled boxes, released boxes, focus, and the
-- dropdown's width and caps.
--
-- Split out of tests/test_options_idsuggest.lua, which was 1002 lines and in `layout-§1`'s
-- 1000-1500 band, in the 2026-09-26 automated-tests sweep. The cases moved unchanged, in their
-- original order, and run right after that suite; the bench they share is
-- tests/fixture_idsuggest.lua. How a case finds the dropdown and reads its rows is that suite's
-- header.

local T = _G.LK_TEST
local assertEqual, assertTrue, assertFalse, assertNil =
  T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")
local mocks = T.mocks

local S = dofile("tests/fixture_idsuggest.lua")("SuggestFramesBench")
local ZEPHYR, suggestCase, input, dropdown, shown = S.ZEPHYR, S.suggestCase, S.input, S.dropdown, S.shown
local typeText, shownIds, press, seedZephyr, zephyrs = S.typeText, S.shownIds, S.press, S.seedZephyr, S.zephyrs
local hostKind = S.hostKind

-- ── frames ───────────────────────────────────────────────────────────────────────────────────

suggestCase("IdInput suggestions: one dropdown per instance, whatever the renders", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  typeText(b, "zephyr")
  local dd = dropdown(made)
  assertEqual(#dd.rows, 10, "ten pooled rows, built once")
  b.eb:Release()
  local c = input(made, { kind = "item", candidates = zephyrs }, b.O)
  local before = #made   -- after the second page's own frames
  typeText(c, "zephyr")
  -- red under: a dropdown built per render (every redraw would leak eleven frames)
  assertEqual(#made, before, "the second render builds no frame")
  assertTrue(dd:IsShown())
  local count = 0
  for _, f in ipairs(made) do if type(f.rows) == "table" then count = count + 1 end end
  assertEqual(count, 1)
  b.eb.editbox:__fire("OnEscapePressed")
  assertTrue(dd:IsShown(), "the first render's box no longer owns it")
  typeText(c, "zephyr")
  assertEqual(shownIds(c), "191395,191396,191397")
end)

suggestCase("IdInput suggestions: a box pooled into a second render is hooked once", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  local eb = b.eb
  eb:Release()
  -- AceGUI's pool hands the released box to the next render; the kit's factory never reuses one.
  eb.__released = nil
  local gui = mocks.__libs["AceGUI-3.0"]
  local saved = gui.WidgetRegistry.EditBox
  gui.WidgetRegistry.EditBox = function() return eb end
  local ok, c = pcall(input, made, { kind = "item", candidates = zephyrs }, b.O)
  gui.WidgetRegistry.EditBox = saved
  assertTrue(ok, tostring(c))
  assertTrue(c.eb == eb, "the second render drew the pooled box")
  typeText(c, "zephyr")
  press(c, "DOWN")
  -- red under: hooks installed on every render (one Down would move the highlight twice)
  local rows = dropdown(made).rows
  assertTrue(rows[1].selected, "one Down, one row"); assertFalse(rows[2].selected)
end)

suggestCase("IdInput suggestions: a box pooled into another instance wakes no list of the first's", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  typeText(b, ZEPHYR)
  b.eb:__fire("OnEnterPressed", ZEPHYR)
  local first = dropdown(made)
  assertTrue(first:IsShown(), "the first instance's refusal lists the ranks")
  local eb = b.eb
  eb:Release()
  assertFalse(first:IsShown())
  -- AceGUI's pool is global: ANOTHER instance draws the released box. The first instance's hooks
  -- stay on its frames and still map them to the first render's parts.
  eb.__released = nil
  local gui = mocks.__libs["AceGUI-3.0"]
  local saved = gui.WidgetRegistry.EditBox
  gui.WidgetRegistry.EditBox = function() return eb end
  local ok, c = pcall(input, made, { kind = "item", candidates = zephyrs })
  gui.WidgetRegistry.EditBox = saved
  assertTrue(ok, tostring(c))
  assertTrue(c.eb == eb and c.O ~= b.O, "a second instance drew the pooled box")
  typeText(c, ZEPHYR)
  eb.editbox:__fire("OnEditFocusGained")
  -- red under: a released box's parts still allowed to suggest (the first instance's list goes up
  -- under the second instance's box)
  assertFalse(first:IsShown(), "the released render's refused name is not offered again")
end)

suggestCase("IdInput suggestions: a released box lets its render's index go", function(made)
  local icons = setmetatable({}, { __mode = "v" })
  local names = { [1] = "Alpha", [2] = "Beta", [3] = "Gamma" }
  local kind = { noun = "widget", plural = "widgets", resolve = function() return nil, "notFound" end,
                 info = function(id)
                   local icon = { id }
                   icons[id] = icon
                   return names[id], icon
                 end }
  local b = input(made, { kind = kind, candidates = function() return { 1, 2, 3 } end })
  typeText(b, "beta")
  assertEqual(shownIds(b), "2")
  assertTrue(icons[1] ~= nil and icons[3] ~= nil, "the index holds the unmatched entries")
  b.eb:Release()
  collectgarbage("collect"); collectgarbage("collect")
  -- red under: an index kept with the parts the pooled frame still maps to (up to 2000 entries held
  -- until the same instance draws on that frame again)
  assertNil(icons[1], "an entry only the index held is gone")
  assertNil(icons[3])
end)

suggestCase("IdInput suggestions: Enter in a box that no longer owns the dropdown submits its text", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  local c = input(made, { kind = "item", candidates = zephyrs }, b.O)
  typeText(b, "zephyr")
  press(b, "DOWN")
  typeText(c, "zephyr")
  b.eb:__fire("OnEnterPressed", "zephyr")
  -- red under: Enter taking a highlight another box's list replaced (a row the player cannot see)
  assertEqual(#b.added, 0, "the first box's old highlight is not picked")
  assertEqual(shownIds(c), "191395,191396,191397", "the other box keeps its list")
end)

suggestCase("IdInput suggestions: a box that left before the pause shows nothing", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  local function typeThen(away, why)
    b.eb:SetText("zephyr"); b.eb:__fire("OnTextChanged", "zephyr")
    away()
    mocks.__fireTimers()
    -- red under: hooks that act only once their box owns the dropdown (the timer shows it anyway)
    assertFalse(shown(b), why)
  end
  typeThen(function() b.eb.editbox:__fire("OnEditFocusLost") end, "focus lost")
  typeThen(function() b.eb.editbox:__fire("OnEscapePressed") end, "Escape")
  typeThen(function()
    b.eb.editbox:__fire("OnEditFocusLost")
    -- The panel going away is what makes the box not visible in the client, and the frame starts
    -- shown (kit 26), so the hide is performed here rather than assumed from a hidden default.
    b.eb.frame:Hide()
    b.eb.frame:__fire("OnHide")
  end, "focus lost, then the panel hidden (Escape twice)")
  typeText(b, "zephyr")
  assertFalse(shown(b), "a hidden box stays quiet")
  b.eb.frame:Show()
  typeText(b, "zephyr")
  assertEqual(shownIds(b), "191395,191396,191397", "until its panel is shown again")
end)

suggestCase("IdInput suggestions: focus lost to the dropdown itself goes back to the box", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  typeText(b, "zephyr")
  local dd = dropdown(made)
  local focused = 0
  b.eb.editbox.SetFocus = function() focused = focused + 1 end
  dd.IsMouseOver = function() return true end
  b.eb.editbox:__fire("OnEditFocusLost")
  mocks.__fireTimers()
  dd.IsMouseOver = nil
  -- red under: a click on the backdrop or the "+N more" line leaving the box without the keys
  assertEqual(focused, 1, "the box takes the keys back, so Escape still reaches it")
  assertTrue(dd:IsShown())
  b.eb.editbox:__fire("OnEscapePressed")
  assertFalse(dd:IsShown())

  typeText(b, "zephyr")
  dd.IsMouseOver = function() return true end
  b.eb.editbox:__fire("OnEditFocusLost")
  dd.rows[1]:__fire("OnClick")
  mocks.__fireTimers()
  assertEqual(table.concat(b.added, ","), "191395", "a click on a row still picks it")
  assertEqual(focused, 1, "and nothing is focused for a closed list")
end)

suggestCase("IdInput suggestions: one render names at most 2000 ids", function(made)
  local ids = {}
  for i = 1, 2001 do
    ids[i] = 700000 + i
    mocks.addIdRecord("item", ids[i], i == 2000 and "Edge Draught" or i == 2001 and "Past Draught"
      or ("Filler %d"):format(i), 1)
  end
  local b = input(made, { kind = "item", candidates = function() return ids end })
  typeText(b, "draught")
  -- red under: no cap on the index (a host's long list named whole on the first keystroke)
  assertEqual(shownIds(b), "702000", "the 2000th id is in, the 2001st is not")
end)

suggestCase("IdInput suggestions: a raising info costs that id's row, not the list", function(made)
  local kind = { noun = "widget", plural = "widgets", resolve = function() return nil, "notFound" end,
                 info = function(id)
                   if id == 2 then error("boom") end
                   return "Widget " .. id, 100 + id
                 end }
  local b = input(made, { kind = kind, candidates = function() return { 1, 2, 3 } end })
  -- red under: an unguarded info (the debounced update raises, and the list never shows)
  local ok, err = pcall(typeText, b, "widget")
  assertTrue(ok, tostring(err))
  assertEqual(shownIds(b), "1,3")
end)

suggestCase("IdInput suggestions: the dropdown is as wide as the box looks", function(made)
  seedZephyr()
  local b = input(made, { kind = "item", candidates = zephyrs })
  typeText(b, "zephyr")
  local dd = dropdown(made)
  local width
  dd.SetWidth = function(_, w) width = w end
  dd.GetEffectiveScale = function() return 1 end
  b.eb.editbox.GetWidth = function() return 300 end
  b.eb.editbox.GetEffectiveScale = function() return 1.5 end
  typeText(b, "zephy")
  -- red under: the box's width taken at its own scale (a scaled panel's list too narrow or wide)
  assertEqual(width, 450)
  b.eb.editbox.GetEffectiveScale = nil
  typeText(b, "zephyr")
  assertEqual(width, 300, "a scale the client does not answer is taken as the same")
end)

-- The host's TAG on a suggestion row (minor 28). `rank` beside it is the library's own answer about
-- an id and a host cannot supply one; this is the other half: a short word the host knows and the
-- library cannot. Aura Master's case is an id that is a spell's CAST rather than the aura it
-- applies, which matches nothing -- without a tag the host could only correct the player AFTER the
-- pick, which is a correction rather than a choice.
suggestCase("IdInput suggestions: a host kind's suggestTag is appended after the id", function(made)
  seedZephyr()
  local O = Fixture.new()
  local tagged = 191395
  local TAG = "|cffff8000never matches|r"
  local extra = { base = "item", suggestTag = function(id)
    return id == tagged and TAG or nil
  end }
  local b = input(made, { kind = hostKind(O, extra), candidates = zephyrs }, O)
  typeText(b, ZEPHYR)
  local seen = {}
  for _, row in ipairs(dropdown(made).rows) do
    if row.labelText then seen[#seen + 1] = row.labelText end
  end
  local hit, other
  for _, text in ipairs(seen) do
    if text:find(tostring(tagged), 1, true) then hit = text
    elseif text:find("191396", 1, true) then other = text end
  end
  -- red under no tag at all, and red under a tag the library placed inside the name rather than
  -- after the id
  assertTrue(hit ~= nil and hit:find("never matches", 1, true) ~= nil, "the tagged row says so")
  assertTrue(hit:find("|r " .. TAG, 1, true) ~= nil, "after the gray id, in the host's own color")
  assertTrue(other ~= nil and other:find("never matches", 1, true) == nil,
    "and a row the host said nothing about carries nothing")
end)

-- ── combat (OptionsIds minor 3, OptionsCombat minor 2) ──────────────────────────────────────
--
-- The dropdown is parented to UIParent, so the combat cover over a page cannot reach it: before
-- these minors a list left open at the start of combat stayed up over a covered page, with rows the
-- write seam would refuse. O.__releaseOwnedFocus, which closes an AceGUI pullout on the instance's
-- pages, now closes an IdList suggestion list one of those pages opened as well. The events are
-- fired through lib.__combatFrame, as tests/test_options_combat.lua's harness fires them.

local lib = T.options

local function fireCombat(event)
  local f = lib.__combatFrame
  assertTrue(f ~= nil, "the library owns one combat event frame")
  f:__fire("OnEvent", event)
end

--- A suggestion case whose page is on screen, with the library's combat state and the page put
--- back however it ends.
local function combatSuggestCase(name, fn)
  suggestCase(name, function(made)
    local savedLockdown = mocks.InCombatLockdown
    local shownCtx = {}
    local function showPage(ctx)
      ctx.panel:Show(); ctx.panel:__fire("OnShow")
      shownCtx[#shownCtx + 1] = ctx
    end
    local ok, err = pcall(fn, made, showPage)
    mocks.InCombatLockdown = function() return false end
    lib.__combatLocked = false
    for _, ctx in ipairs(shownCtx) do ctx.panel:Hide(); ctx.panel:__fire("OnHide") end
    mocks.InCombatLockdown = savedLockdown
    if not ok then error(err, 0) end
  end)
end

--- One IdInput on a page, its box's frame under the page as AceGUI's AddChild leaves it in the
--- client. The kit's containers record a child without parenting it, and its frames answer
--- GetParent with themselves (fidelity rule 2), so the case says where the box sits.
local function pageInput(made, spec, O)
  local b = input(made, spec, O)
  local panel = b.ctx.panel
  rawset(b.eb.frame, "GetParent", function() return panel end)
  return b
end

combatSuggestCase("IdInput suggestions: the start of combat closes a list a page opened", function(made, showPage)
  seedZephyr()
  -- The minors that brought it: floors, so a later bump for another reason needs no edit here.
  assertTrue((lib.MODULES.OptionsIds or 0) >= 3, "OptionsIds minor " .. tostring(lib.MODULES.OptionsIds))
  assertTrue((lib.MODULES.OptionsCombat or 0) >= 2,
    "OptionsCombat minor " .. tostring(lib.MODULES.OptionsCombat))
  local b = pageInput(made, { kind = "item", candidates = zephyrs })
  showPage(b.ctx)
  typeText(b, "zephyr")
  local dd = dropdown(made)
  assertTrue(dd:IsShown(), "the list is up before combat")
  fireCombat("PLAYER_REGEN_DISABLED")
  mocks.InCombatLockdown = function() return true end
  -- red under: a release that closes only an AceGUI pullout (the list stays up over the cover)
  assertFalse(dd:IsShown(), "the list closes with the page covered")
  dd.rows[1]:__fire("OnClick")
  assertEqual(#b.added, 0, "and no box owns it any more, so a stale row picks nothing")
end)

combatSuggestCase("IdInput suggestions: a list another page's box opened is not this release's",
  function(made)
  seedZephyr()
  local b = pageInput(made, { kind = "item", candidates = zephyrs })
  local other = b.O.CreatePanel("SuggestFramesOther", "Suggest other", {})
  typeText(b, "zephyr")
  local dd = dropdown(made)
  assertTrue(type(b.O.__closeOwnedSuggest) == "function", "the instance carries the member")
  b.O.__closeOwnedSuggest({ other })
  -- red under: a close that ignores the panels it is handed (any list of the instance goes)
  assertTrue(dd:IsShown(), "a box under none of the panels keeps its list")
  b.O.__closeOwnedSuggest({ other, b.ctx })
  assertFalse(dd:IsShown(), "the box's own page closes it")
end)

combatSuggestCase("IdInput suggestions: a focused pullout and the list both close at combat start",
  function(made, showPage)
  seedZephyr()
  local b = pageInput(made, { kind = "item", candidates = zephyrs })
  showPage(b.ctx)
  typeText(b, "zephyr")
  local dd = dropdown(made)
  local AceGUI = b.O.AceGUI
  local cleared = 0
  local frame = mocks.CreateFrame("Frame", nil, b.ctx.panel)
  rawset(frame, "GetParent", function() return b.ctx.panel end)
  AceGUI.FocusedWidget = { frame = frame, ClearFocus = function() end }
  AceGUI.ClearFocus = function(self) cleared = cleared + 1; self.FocusedWidget = nil end
  local ok, err = pcall(fireCombat, "PLAYER_REGEN_DISABLED")
  AceGUI.ClearFocus, AceGUI.FocusedWidget = nil, nil
  if not ok then error(err, 0) end
  mocks.InCombatLockdown = function() return true end
  assertEqual(cleared, 1, "the pullout on this page was closed")
  -- red under: the release returning once it has closed the pullout (the list is skipped)
  assertFalse(dd:IsShown(), "and so was the list")
end)

combatSuggestCase("IdInput suggestions: leaving combat does not reopen a list combat closed",
  function(made, showPage)
  seedZephyr()
  local b = pageInput(made, { kind = "item", candidates = zephyrs })
  showPage(b.ctx)
  typeText(b, "zephyr")
  assertTrue(shown(b), "the list is up before combat")
  fireCombat("PLAYER_REGEN_DISABLED")
  mocks.InCombatLockdown = function() return true end
  assertFalse(shown(b), "combat closed it")
  mocks.InCombatLockdown = function() return false end
  fireCombat("PLAYER_REGEN_ENABLED")
  mocks.__fireTimers()
  -- red under: an end of combat that re-shows the last owner's list (the page's refreshers or a
  -- remembered owner putting it back up with no keystroke)
  assertFalse(shown(b), "the end of combat puts nothing back up")
  typeText(b, "zephyr")
  assertEqual(shownIds(b), "191395,191396,191397", "the box's next keystroke lists again")
end)
