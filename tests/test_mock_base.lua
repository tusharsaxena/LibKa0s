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
-- it, which together are the entire claim that eleven consumers can take this and count nothing.
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
  -- The additive contract, and the line the geometry flip crosses on purpose -- planned at kit 16,
  -- moved to the next revision that ships it alone when 16 carried the Ace-fake fixes (see
  -- docs/api/testkit/version-16-docs.md). Roughly 308 test files across
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

-- ── the Ace fakes: AceGUI:Release, AceEvent's event half, AceConsole's Printf ─────────────────
--
-- Three gaps between the kit's Ace fakes and the real Ace3 libraries, each of which a consumer had
-- to shim locally (LibKa0s#27, #29, #30). Every case below builds a FRESH environment from this
-- repo's own mock builder rather than reusing `T.mocks`, because the recorders under test
-- (`AceGUI.__released`, a target's `__events`) accumulate, and a count read off a shared instance
-- would depend on which suite ran first.

local assertFalse = T.assertFalse
local buildMocks = dofile("tests/wow_mock.lua")

--- A chat-frame stand-in that records every line. A plain table with an `AddMessage` member, which is
--- exactly what AceConsole tests for when it decides whether its first argument is a frame.
local function chatRecorder()
  local rec = { lines = {} }
  function rec:AddMessage(s) self.lines[#self.lines + 1] = s end
  return rec
end

--- Run `fn` with the process global DEFAULT_CHAT_FRAME pointed at `chat`, restoring it however `fn`
--- exits. The kit's console mixins read the global at call time, as AceConsole reads the client's.
local function withChatFrame(chat, fn)
  local saved = rawget(_G, "DEFAULT_CHAT_FRAME")
  rawset(_G, "DEFAULT_CHAT_FRAME", chat)
  local ok, err = pcall(fn)
  rawset(_G, "DEFAULT_CHAT_FRAME", saved)
  if not ok then error(err, 0) end
end

test("mock: AceGUI:Release takes a widget back: flagged, frame hidden, recorded in order", function()
  local AceGUI = buildMocks().LibStub("AceGUI-3.0")
  assertTrue(type(AceGUI.Release) == "function", "the AceGUI fake has a Release")
  local a, b, kept = AceGUI:Create("Dropdown"), AceGUI:Create("Label"), AceGUI:Create("Label")
  a.frame:Show()
  AceGUI:Release(a)
  AceGUI:Release(b)
  assertTrue(a.__released == true and b.__released == true, "a released widget is flagged")
  assertFalse(a.frame:IsShown(), "releasing a widget hides its frame, as the real Release does")
  assertEqual(#AceGUI.__released, 2, "every release is recorded")
  assertTrue(AceGUI.__released[1] == a and AceGUI.__released[2] == b, "in the order it happened")
  assertNil(kept.__released, "a widget nobody released is not flagged")
end)

test("mock: AceGUI:Release fires OnRelease, then drops the children and the callbacks", function()
  -- The real order, and LibKa0s's own OptionsWidgets.lua leans on it: `Fire("OnRelease")` runs
  -- while the widget still has its children and its callbacks, and only then are both cleared.
  local AceGUI = buildMocks().LibStub("AceGUI-3.0")
  local group = AceGUI:Create("SimpleGroup")
  group:AddChild(AceGUI:Create("Label"))
  local seen = {}
  group:SetCallback("OnRelease", function(w, name) seen[#seen + 1] = { w, name, #w.children } end)
  group:SetCallback("OnClick", function() end)
  local callbacks = group.callbacks
  AceGUI:Release(group)
  assertEqual(#seen, 1, "OnRelease fired once")
  assertTrue(seen[1][1] == group, "with the widget as its first argument")
  assertEqual(seen[1][2], "OnRelease", "and the event name as its second, as AceGUI fires it")
  assertEqual(seen[1][3], 1, "while the widget still had its child")
  assertEqual(#group.children, 0, "the children are gone afterwards")
  assertNil(next(group.callbacks), "every callback is dropped, so a pooled widget cannot fire a stale one")
  assertTrue(group.callbacks == callbacks, "cleared in place, so a captured table stays the live one")
end)

test("mock: a Release reached from the widget's own OnRelease is ignored, as AceGUI's guard ignores it", function()
  local AceGUI = buildMocks().LibStub("AceGUI-3.0")
  local w = AceGUI:Create("Label")
  w:SetCallback("OnRelease", function(self) AceGUI:Release(self) end)
  AceGUI:Release(w)
  assertEqual(#AceGUI.__released, 1, "the nested Release recorded nothing")
  assertNil(w.isQueuedForRelease, "the guard is lifted once the release completes")
end)

test("mock: AceGUI:Release(nil) raises, as the real one does", function()
  -- A guard here would be a stub that silently succeeds (fidelity rule 1): the client indexes the
  -- widget on the first line and errors, so a host that can pass nil has a bug the suite must see.
  local AceGUI = buildMocks().LibStub("AceGUI-3.0")
  assertTrue(type(AceGUI.Release) == "function", "the AceGUI fake has a Release to call")
  assertFalse(pcall(AceGUI.Release, AceGUI, nil), "releasing nil raised")
end)

test("mock: releasing a widget twice raises, as AceGUI's delWidget does", function()
  local AceGUI = buildMocks().LibStub("AceGUI-3.0")
  local w = AceGUI:Create("Label")
  AceGUI:Release(w)
  local ok, err = pcall(AceGUI.Release, AceGUI, w)
  assertFalse(ok, "the second release raised")
  assertTrue(tostring(err):find("already released", 1, true) ~= nil, "with the real message")
  assertEqual(#AceGUI.__released, 1, "and was not recorded a second time")
end)

test("mock: widget:Release() is AceGUI:Release(widget), as WidgetBase.Release is", function()
  local AceGUI = buildMocks().LibStub("AceGUI-3.0")
  local w = AceGUI:Create("Label")
  assertTrue(type(w.Release) == "function", "a widget carries the method form")
  w:Release()
  assertTrue(w.__released == true and AceGUI.__released[1] == w, "and it went through AceGUI:Release")
end)

test("mock: AceGUI:Release wipes userdata in place and the size fields, as the real one does", function()
  local AceGUI = buildMocks().LibStub("AceGUI-3.0")
  local w = AceGUI:Create("Label")
  local data = w.userdata
  data.key = "row-7"
  w:SetWidth(120); w:SetHeight(20); w:SetRelativeWidth(0.5)
  w.relWidth, w.relHeight, w.noAutoHeight = 0.5, 0.5, true
  AceGUI:Release(w)
  assertNil(next(w.userdata), "userdata is emptied")
  assertTrue(w.userdata == data, "in place, so a captured table stays the live one")
  for _, k in ipairs({ "width", "height", "relativeWidth", "relWidth", "relHeight", "noAutoHeight" }) do
    assertNil(w[k], k .. " is dropped")
  end
end)

test("mock: an AceEvent embed records game events the way the NewAddon target does", function()
  -- No handler means the method named after the event, so the target must carry one.
  local t = buildMocks().LibStub("AceEvent-3.0"):Embed({ PLAYER_LOGIN = function() end })
  assertTrue(type(t.RegisterEvent) == "function", "the embed carries RegisterEvent")
  local onAura = function() end
  t:RegisterEvent("UNIT_AURA", onAura)
  t:RegisterEvent("PLAYER_LOGIN")
  assertTrue(t.__events.UNIT_AURA == onAura, "a handler is recorded as given")
  assertEqual(t.__events.PLAYER_LOGIN, true, "no handler records true")
  t:UnregisterEvent("UNIT_AURA")
  assertNil(t.__events.UNIT_AURA, "UnregisterEvent drops one registration")
  assertEqual(t.__events.PLAYER_LOGIN, true, "and only that one")
  local live = t.__events
  t:UnregisterAllEvents()
  assertNil(next(t.__events), "UnregisterAllEvents drops every registration")
  assertTrue(t.__events == live, "cleared in place, so a captured table stays the live one")
end)

test("mock: the embed and the NewAddon target share one event implementation", function()
  local M = buildMocks()
  -- The mixin is listed: since revision 17 a named NewAddon embeds exactly what it is told to.
  local addon = M.LibStub("AceAddon-3.0"):NewAddon({}, "Host", "AceEvent-3.0")
  local embed = M.LibStub("AceEvent-3.0"):Embed({})
  for _, name in ipairs({ "RegisterEvent", "UnregisterEvent", "UnregisterAllEvents" }) do
    assertTrue(type(addon[name]) == "function", "the NewAddon target carries " .. name)
    assertTrue(addon[name] == embed[name], name .. " is the same function on both")
  end
end)

test("mock: UnregisterAllEvents leaves an embed's message registrations alone", function()
  -- Real AceEvent keeps events and messages in two CallbackHandler registries, which is exactly why
  -- a module gives its game events a target of their own.
  local t = buildMocks().LibStub("AceEvent-3.0"):Embed({ PLAYER_LOGIN = function() end })
  local heard = 0
  t:RegisterMessage("HOST_CHANGED", function() heard = heard + 1 end)
  t:RegisterEvent("PLAYER_LOGIN")
  t:UnregisterAllEvents()
  t:SendMessage("HOST_CHANGED")
  assertEqual(heard, 1, "the message registration survived UnregisterAllEvents")
end)

test("mock: embedding a target a second time keeps what it had registered", function()
  -- The real registry is keyed by (event, target) and lives in the library, not on the target, so
  -- a second Embed stamps the same mixins and forgets nothing.
  local AceEvent = buildMocks().LibStub("AceEvent-3.0")
  local t = AceEvent:Embed({ PLAYER_LOGIN = function() end })
  t:RegisterEvent("PLAYER_LOGIN")
  local live = t.__events
  AceEvent:Embed(t)
  assertEqual(t.__events.PLAYER_LOGIN, true, "the registration survived the second Embed")
  assertTrue(t.__events == live, "and so did the table")
end)

test("mock: a target reused by a later mock build starts with nothing registered", function()
  -- The real registry lives in the library, so a fresh library sees none of an old one's
  -- registrations. Keyed on the target table, a registry would leak between builds.
  local t = { PLAYER_LOGIN = function() end }
  buildMocks().LibStub("AceEvent-3.0"):Embed(t)
  t:RegisterEvent("PLAYER_LOGIN")
  buildMocks().LibStub("AceEvent-3.0"):Embed(t)
  assertNil(t.__events.PLAYER_LOGIN, "an Embed in a new build forgot the old build's registration")
  local ns = { PLAYER_LOGIN = function() end }
  buildMocks().LibStub("AceAddon-3.0"):NewAddon(ns, "Host", "AceEvent-3.0")
  ns:RegisterEvent("PLAYER_LOGIN")
  buildMocks().LibStub("AceAddon-3.0"):NewAddon(ns, "Host", "AceEvent-3.0")
  assertNil(ns.__events.PLAYER_LOGIN, "and so did a NewAddon in a new build")
end)

test("mock: RegisterEvent refuses what CallbackHandler refuses", function()
  -- A registration the client raises on must not pass headlessly (fidelity rule 1).
  local t = buildMocks().LibStub("AceEvent-3.0"):Embed({ OnLogin = function() end })
  assertFalse(pcall(t.RegisterEvent, t, 42), "an event that is not a string raised")
  assertFalse(pcall(t.RegisterEvent, t, "PLAYER_LOGIN"),
    "no handler and no method named after the event raised")
  assertFalse(pcall(t.RegisterEvent, t, "PLAYER_LOGIN", "OnTypo"), "a method self does not carry raised")
  assertFalse(pcall(t.RegisterEvent, t, "PLAYER_LOGIN", 7), "a handler that is neither raised")
  assertFalse(pcall(t.UnregisterEvent, t, 42), "UnregisterEvent of a non-string raised")
  assertNil(next(t.__events), "and none of them recorded anything")
  t:RegisterEvent("PLAYER_LOGIN", "OnLogin")
  assertEqual(t.__events.PLAYER_LOGIN, "OnLogin", "a method self carries is recorded as given")
end)

test("mock: NewAddon clobbers a custom Printf exactly as it clobbers Print", function()
  -- AceConsole's mixins are Print AND Printf, so an addon that publishes its own NS.Printf must take
  -- it back after NewAddon too. A fake that stamped only Print let an addon that forgot pass.
  local ns = {}
  local mine = function() end
  ns.Print, ns.Printf = mine, mine
  buildMocks().LibStub("AceAddon-3.0"):NewAddon(ns, "Host", "AceConsole-3.0")
  assertTrue(type(ns.Print) == "function" and ns.Print ~= mine, "Print is AceConsole's after NewAddon")
  assertTrue(type(ns.Printf) == "function" and ns.Printf ~= mine, "Printf is AceConsole's after NewAddon")
end)

test("mock: the console mixins print as AceConsole's do, bare, as methods and to a given frame", function()
  local ns = buildMocks().LibStub("AceAddon-3.0"):NewAddon({}, "Host", "AceConsole-3.0")
  local chat, other = chatRecorder(), chatRecorder()
  withChatFrame(chat, function()
    -- Bare: the format string lands in `self`, and the NEXT argument is what gets formatted.
    ns.Printf("%d items", 3)
    -- As a method: `self` is the addon object and the whole argument list is formatted.
    ns:Printf("%d items", 3)
    -- A first argument with an AddMessage member is the frame to print to.
    ns:Printf(other, "%s!", "hi")
    ns:Print(other, "a", "b")
  end)
  local tag = "|cff33ff99" .. tostring(ns) .. "|r:"
  assertEqual(chat.lines[1], "|cff33ff99%d items|r: 3", "a bare Printf")
  assertEqual(chat.lines[2], tag .. " 3 items", "Printf as a method")
  assertEqual(#chat.lines, 2, "nothing addressed to another frame reached the default one")
  assertEqual(other.lines[1], tag .. " hi!", "Printf to a given frame")
  assertEqual(other.lines[2], tag .. " a b", "Print to a given frame")
end)

test("mock: a bare Printf with nothing after the format string raises, as format() does", function()
  -- The real one calls format(...) on what follows `self`; bare, that is nothing at all, and
  -- string.format with no arguments raises. This is the loudest form of the forgotten reclaim.
  local ns = buildMocks().LibStub("AceAddon-3.0"):NewAddon({}, "Host", "AceConsole-3.0")
  assertTrue(type(ns.Printf) == "function", "NewAddon stamped a Printf to call")
  withChatFrame(chatRecorder(), function()
    assertFalse(pcall(ns.Printf, "hello"), "a bare one-argument Printf raised")
  end)
end)

-- ── the id lookups (revision 20) ───────────────────────────────────────────────────────────
--
-- LibKa0s-Options-1.0's IdInput / IdList resolve a typed name through the client, and a suite can
-- only drive that if the mock answers a NAME. OPT-IN, not installed by the base: three consumers
-- reach their Compat fallbacks by clearing C_Spell or C_Item, and a base-level namespace would
-- resolve ahead of theirs and make those branches unreachable (the C_AddOns note in this repo's
-- tests/wow_mock.lua is the same fact). Each case builds a fresh environment, so none of them can
-- leak a record into a later suite.

test("mock: the id lookups are absent until a harness installs them", function()
  local M = dofile("tests/_kit/mock_base.lua")()
  -- red under: installing the namespaces in the base (a consumer's cleared C_Spell would be shadowed)
  assertNil(M.C_Spell, "no spell namespace by default")
  assertNil(M.C_CurrencyInfo, "no currency namespace by default")
  dofile("tests/_kit/mock_ids.lua")(M)
  assertEqual(type(M.C_Spell.GetSpellInfo), "function")
  assertEqual(type(M.C_Item.GetItemInfoInstant), "function")
  assertEqual(type(M.C_Item.GetItemNameByID), "function")
  assertEqual(type(M.C_Item.GetItemQualityByID), "function")
  assertEqual(type(M.C_CurrencyInfo.GetCurrencyInfo), "function")
end)

test("mock: installing the id lookups fills only what a harness has not defined", function()
  local M = dofile("tests/_kit/mock_base.lua")()
  local mine = function() return "mine" end
  M.C_Item = { GetItemInfoInstant = mine, RequestLoadItemDataByID = function() end }
  dofile("tests/_kit/mock_ids.lua")(M)
  -- red under: overwriting the harness's own function (a consumer's item fixture would stop answering)
  assertTrue(M.C_Item.GetItemInfoInstant == mine, "the harness's own function is kept")
  assertEqual(type(M.C_Item.RequestLoadItemDataByID), "function", "and so is everything else on it")
  assertEqual(type(M.C_Item.GetItemNameByID), "function", "only the missing key is filled")
end)

test("mock: a spell record answers by id and by name, the name in any case", function()
  local M = dofile("tests/_kit/mock_base.lua")()
  dofile("tests/_kit/mock_ids.lua")(M)
  M.addIdRecord("spell", 21562, "Power Word: Fortitude", 135987)
  local info = M.C_Spell.GetSpellInfo(21562)
  assertEqual(info.name, "Power Word: Fortitude")
  assertEqual(info.iconID, 135987)
  assertEqual(info.spellID, 21562)
  -- red under: a case-sensitive name match (the client's name lookup ignores case)
  assertEqual(M.C_Spell.GetSpellInfo("power word: FORTITUDE").spellID, 21562)
  assertNil(M.C_Spell.GetSpellInfo("Shadow Word: Pain"), "an unknown name answers nil, as the client does")
  assertNil(M.C_Spell.GetSpellInfo(1), "and so does an unknown id")
end)

test("mock: an uncached item keeps its icon and hides its name until it loads", function()
  local M = dofile("tests/_kit/mock_base.lua")()
  dofile("tests/_kit/mock_ids.lua")(M)
  M.addIdRecord("item", 6948, "Hearthstone", 134414)
  M.addIdRecord("item", 2589, "Linen Cloth", 132889, true)
  local id, _, _, _, icon = M.C_Item.GetItemInfoInstant("hearthstone")
  assertEqual(id, 6948); assertEqual(icon, 134414)
  assertEqual(M.C_Item.GetItemNameByID(6948), "Hearthstone")
  -- red under: answering an uncached item's name (a list could never exercise its load path)
  assertNil(M.C_Item.GetItemNameByID(2589), "no name before the item is cached")
  assertNil(M.C_Item.GetItemInfoInstant("Linen Cloth"), "nor a name lookup")
  assertEqual(select(5, M.C_Item.GetItemInfoInstant(2589)), 132889, "the instant lookup by id still answers")
  M.addIdRecord("item", 2589, "Linen Cloth", 132889)
  assertEqual(M.C_Item.GetItemNameByID(2589), "Linen Cloth", "re-adding it cached is how a load lands")
end)

test("mock: an item record answers its quality by id and by link, and none while uncached", function()
  local M = dofile("tests/_kit/mock_base.lua")()
  dofile("tests/_kit/mock_ids.lua")(M)
  M.addIdRecord("item", 19019, "Thunderfury", 1, nil, 5)
  M.addIdRecord("item", 2589, "Linen Cloth", 132889, true, 1)
  M.addIdRecord("item", 6948, "Hearthstone", 134414)
  -- red under: no quality lookup (an id list could never color an item's name by its quality)
  assertEqual(M.C_Item.GetItemQualityByID(19019), 5)
  assertEqual(M.C_Item.GetItemQualityByID("|cffff8000|Hitem:19019::::|h[Thunderfury]|h|r"), 5,
    "a link is read for its id, as the client reads it")
  assertNil(M.C_Item.GetItemQualityByID(2589), "no quality before the item is cached")
  assertNil(M.C_Item.GetItemQualityByID(6948), "nor for a record seeded with none")
  assertNil(M.C_Item.GetItemQualityByID(1), "nor for an unknown id")
  M.addIdRecord("item", 2589, "Linen Cloth", 132889, nil, 1)
  assertEqual(M.C_Item.GetItemQualityByID(2589), 1, "re-adding it cached lands its quality too")
end)

test("mock: a currency record answers by id, and clearIdRecords empties every kind", function()
  local M = dofile("tests/_kit/mock_base.lua")()
  dofile("tests/_kit/mock_ids.lua")(M)
  M.addIdRecord("currency", 3008, "Valorstones", 5872049)
  local info = M.C_CurrencyInfo.GetCurrencyInfo(3008)
  assertEqual(info.name, "Valorstones"); assertEqual(info.iconFileID, 5872049)
  assertNil(M.C_CurrencyInfo.GetCurrencyInfo(1))
  M.addIdRecord("spell", 1, "One", 1)
  M.clearIdRecords()
  -- red under: a clear that forgets a kind (a record would leak into the next case)
  assertNil(M.C_CurrencyInfo.GetCurrencyInfo(3008))
  assertNil(M.C_Spell.GetSpellInfo(1))
end)

test("mock: the suggestion sources answer what a suite seeds -- bags, spellbook, tiers, subtext", function()
  local M = dofile("tests/_kit/mock_base.lua")()
  assertNil(M.C_Container, "no bag namespace by default")
  dofile("tests/_kit/mock_ids.lua")(M)
  -- red under: the sources installed with the lookups (ConsumableMaster's harness walks its bags
  -- through _G.C_Container, and a mock-level one would resolve ahead of it)
  assertNil(M.C_Container, "the sources wait until a harness asks for them")
  assertNil(M.C_SpellBook); assertNil(M.C_TradeSkillUI)
  assertNil(M.C_Spell.GetSpellSubtext)
  local mine = { GetContainerNumSlots = function() return 99 end }
  M.C_Container = mine
  M.installIdSuggestions()
  assertEqual(M.C_Container.GetContainerNumSlots(0), 99, "a harness's own function is kept")
  M.C_Container.GetContainerNumSlots = nil
  M.C_Container = nil
  M.installIdSuggestions()
  M.addIdRecord("spell", 21562, "Power Word: Fortitude", 135987)
  M.addIdRecord("item", 191395, "Potion of the Hushed Zephyr", 4638, nil, 1)
  M.addIdRecord("item", 2589, "Linen Cloth", 132889, true, 1)
  M.setBagItems(0, { 6948, false, 19019 })
  -- red under: no bag contents (an id input could not suggest what the player carries)
  assertEqual(M.C_Container.GetContainerNumSlots(0), 3)
  assertEqual(M.C_Container.GetContainerItemID(0, 1), 6948)
  assertNil(M.C_Container.GetContainerItemID(0, 2), "an empty slot answers nil")
  assertEqual(M.C_Container.GetContainerNumSlots(1), 0, "a bag nobody seeded is empty")
  M.setSpellBook({ 21562 })
  assertEqual(M.C_SpellBook.GetNumSpellBookSkillLines(), 1)
  local line = M.C_SpellBook.GetSpellBookSkillLineInfo(1)
  assertEqual(line.itemIndexOffset, 0); assertEqual(line.numSpellBookItems, 1)
  local slot = M.C_SpellBook.GetSpellBookItemInfo(1, 0)
  assertEqual(slot.spellID, 21562); assertEqual(slot.itemType, 1); assertEqual(slot.name, "Power Word: Fortitude")
  assertNil(M.C_SpellBook.GetSpellBookItemInfo(1, 1), "the pet bank is empty")
  M.setCraftedQuality(191395, 2)
  M.setReagentQuality(2589, 3)
  M.setSpellSubtext(21562, "Rank 2")
  assertEqual(M.C_TradeSkillUI.GetItemCraftedQualityByItemInfo(191395), 2)
  assertEqual(M.C_TradeSkillUI.GetItemCraftedQualityByItemInfo("item:191395"), 2, "a link is read for its id")
  assertNil(M.C_TradeSkillUI.GetItemReagentQualityByItemInfo(2589), "no tier while the item is uncached")
  assertEqual(M.C_Spell.GetSpellSubtext(21562), "Rank 2")
  assertEqual(M.C_Spell.GetSpellSubtext(1), "", "a spell with no subtext answers the empty string")
  M.clearIdRecords()
  assertEqual(M.C_Container.GetContainerNumSlots(0), 0, "clearIdRecords empties the bags")
  assertEqual(M.C_SpellBook.GetNumSpellBookSkillLines(), 0, "and the spellbook")
  assertNil(M.C_TradeSkillUI.GetItemCraftedQualityByItemInfo(191395), "and the tiers")
end)

test("mock: installIdSuggestions gives an AceGUI EditBox its editbox frame, and nothing else", function()
  local M = dofile("tests/_kit/mock_base.lua")()
  local gui = M.LibStub("AceGUI-3.0")
  -- red under: an editbox in the base (PanelMaster's harness adds its own only when there is none)
  assertNil(gui:Create("EditBox").editbox, "the base's EditBox has no input frame")
  dofile("tests/_kit/mock_ids.lua")(M)
  assertNil(gui:Create("EditBox").editbox, "nor after the lookups alone")
  M.installIdSuggestions()
  local w = gui:Create("EditBox")
  -- red under: no editbox (the keys a player presses in the box could not be driven)
  assertEqual(type(w.editbox), "table")
  assertEqual(w.type, "EditBox"); assertEqual(w.editbox.__frameType, "EditBox")
  local seen
  w.editbox:HookScript("OnArrowPressed", function(_, key) seen = key end)
  w.editbox:__fire("OnArrowPressed", "DOWN")
  assertEqual(seen, "DOWN")
  assertNil(gui:GetWidgetVersion("EditBox"), "registered without a version")
  assertNil(gui:Create("Button").editbox, "only an EditBox has one")

  local N = dofile("tests/_kit/mock_base.lua")()
  local own = function() return { type = "EditBox", mine = true } end
  N.LibStub("AceGUI-3.0").WidgetRegistry.EditBox = own
  dofile("tests/_kit/mock_ids.lua")(N)
  N.installIdSuggestions()
  assertTrue(N.LibStub("AceGUI-3.0"):Create("EditBox").mine, "a harness's own EditBox is kept")
end)

test("mock: an AceGUI widget answers GetText and records SetType and DisableButton", function()
  local w = buildMocks().LibStub("AceGUI-3.0"):Create("EditBox")
  w:SetText("21562")
  -- red under: no GetText (an Add button beside an edit box could not read what was typed)
  assertEqual(w:GetText(), "21562")
  w:DisableButton(true)
  assertTrue(w.buttonDisabled, "the edit box's own Okay button was asked to hide")
  local cb = buildMocks().LibStub("AceGUI-3.0"):Create("CheckBox")
  cb:SetType("radio")
  assertEqual(cb.checkType, "radio")
end)
