-- tests/test_options_render.lua — LibKa0s-Options-1.0's page registry and its refresh tiers:
-- RefreshAllPanels' registry-wide fan-out, RegisterOptionsPage and CreateOptionsPanel, the
-- combat-refusing OpenOptionsPanel, SetRenderer's draw-on-first-show gate, RefreshScalars against
-- a full re-render, and RefreshPanel. The combat lock on a page itself is
-- tests/test_options_combat.lua.
--
-- Peeled whole from tests/test_options.lua (issue #35), every case moved unchanged, so that suite
-- leaves layout-§1's 1000-1500 band. The seam follows the module: these cases read
-- LibKa0s/OptionsRegistry.lua's page queue and the ctx's render gate, and nothing in
-- tests/test_options.lua reads anything defined here.
--
-- Every case builds its own host through tests/fixture_options.lua, so no case can be made to pass
-- by another one's leftovers — the page registry is deliberately process-lived state.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local mocks = T.mocks
local Fixture = dofile("tests/fixture_options.lua")

local lib = T.options

-- ── RefreshAllPanels: every registered panel ───────────────────────────────────────────────

test("options: RefreshAllPanels runs every registered panel's refreshers, isolating a thrower",
  function()
  local O = Fixture.new()
  local bad  = O.CreatePanel("TestPanelN", "Test N", {})
  local good = O.CreatePanel("TestPanelO", "Test O", {})
  local ran = 0
  bad.refreshers[1]  = function() error("dead widget") end
  good.refreshers[1] = function() ran = ran + 1 end
  assertTrue(pcall(O.RefreshAllPanels), "one dead panel must not break the others")
  assertEqual(ran, 1)
end)

-- ── the page registry, CreateOptionsPanel and the combat-refusing open ─────────────────────

test("options: registered page builders run in registration order, once, at CreateOptionsPanel",
  function()
  local O, rec = Fixture.new()
  local seen = {}
  O.RegisterOptionsPage("general", "General", function() seen[#seen + 1] = "general" end)
  O.RegisterOptionsPage("bar", "Bar", function() seen[#seen + 1] = "bar" end)
  assertEqual(#seen, 0, "registration alone builds nothing")
  O.CreateOptionsPanel()
  assertEqual(table.concat(seen, ","), "general,bar")
  assertEqual(rec.validated, 1, "and the host's schema validator ran once, before the builders")
end)

test("options: CreateOptionsPanel hands the host the AceGUI it resolved", function()
  -- library-stack-§4: resolve once, then read the upvalue. The host stashes it for its own page
  -- files, so the library has to hand it over rather than keep it private.
  local got
  local O = Fixture.new{ onAceGUI = function(ag) got = ag end }
  O.CreateOptionsPanel()
  assertTrue(got ~= nil, "the callback fired")
  assertEqual(got, O.AceGUI, "with the same handle the instance kept")
end)

test("options: CreateOptionsPanel says so and returns when AceGUI is missing", function()
  local O, rec = Fixture.new()
  local saved = mocks.__libs["AceGUI-3.0"]
  mocks.__libs["AceGUI-3.0"] = nil
  local built = 0
  O.RegisterOptionsPage("general", "General", function() built = built + 1 end)
  local ok, err = pcall(O.CreateOptionsPanel)
  mocks.__libs["AceGUI-3.0"] = saved
  if not ok then error(err) end
  assertEqual(built, 0, "no page was built")
  assertTrue(table.concat(rec.chat, "\n"):find("AceGUI", 1, true) ~= nil,
    "and the user is told which library is missing: " .. table.concat(rec.chat, "\n"))
end)

test("options: the main canvas is registered under the host's brand", function()
  local O = Fixture.new()
  O.CreateOptionsPanel()
  assertTrue(mocks.__mainPanel ~= nil, "a canvas category was registered")
  assertEqual(mocks.__mainPanel.name, "Test Host",
    "panel.name is what Blizzard renders in the category tree")
  assertEqual(mocks.__mainPanel.titleText, "Test Host",
    "and the main page's own header is unprefixed")
end)

test("options: the main page's body is deferred to its first OnShow, and built once", function()
  -- AceGUI lays children out against the parent's CURRENT width, which is zero at enable time.
  local built = 0
  local O = Fixture.new{ buildMain = function() built = built + 1 end }
  O.CreateOptionsPanel()
  assertEqual(built, 0, "nothing is drawn at registration")
  mocks.__mainPanel:__fire("OnShow")
  assertEqual(built, 1)
  mocks.__mainPanel:__fire("OnShow")
  assertEqual(built, 1, "a second show must not stack a second copy of the body")
end)

-- ── the page registry and the two refresh tiers ────────────────────────────────────────────

test("options: a raising page builder costs that page and no other", function()
  -- Unguarded, one throwing builder killed every page after it in the list, and the user saw a
  -- half-registered options tree with nothing naming which page did it.
  local O, rec = Fixture.new()
  local built = {}
  O.RegisterOptionsPage("first",  "First",  function() built[#built + 1] = "first" end)
  O.RegisterOptionsPage("broken", "Broken", function() error("boom") end)
  O.RegisterOptionsPage("third",  "Third",  function() built[#built + 1] = "third" end)
  O.CreateOptionsPanel()

  assertEqual(#built, 2, "the two healthy pages both built")
  assertEqual(built[2], "third", "including the one AFTER the failure")
  assertEqual(#O.__pages(), 2, "and only those two are recorded as built")
  local text = table.concat(rec.chat, "\n")
  assertTrue(text:find("broken", 1, true) ~= nil, "the report names the failing page: " .. text)
end)

test("options: a page registered after the build is built immediately", function()
  -- Queued behind a drain that has already happened, it would silently never appear.
  local O = Fixture.new()
  O.CreateOptionsPanel()
  local ran = 0
  O.RegisterOptionsPage("late", "Late", function() ran = ran + 1 end)
  assertEqual(ran, 1, "built on registration rather than queued")
  assertEqual(#O.__pages(), 1)
end)

test("options: SetRenderer draws on first show, and not again", function()
  local O = Fixture.new()
  local ctx = O.CreatePanel("LateP", "Late", { pageKey = "late" })
  local drawn = 0
  O.SetRenderer(ctx, function() drawn = drawn + 1 end)
  assertEqual(drawn, 0, "nothing is drawn at registration")
  ctx.panel:__fire("OnShow")
  assertEqual(drawn, 1)
  ctx.panel:__fire("OnShow")
  assertEqual(drawn, 1, "a second show must not stack a second copy of the body")
end)

test("options: a panel shown during combat is covered, not drawn, and the window is NOT closed",
  function()
  -- The Blizzard AddOns sidebar reaches a panel without going through OpenOptionsPanel, so this
  -- is the path a user is most likely to take mid-fight. Through minor 21 the OnShow closed the
  -- settings window, which ran Blizzard's close-and-commit path tainted (anti-pattern #88); from
  -- minor 22 the page is covered instead. tests/test_options_combat.lua has the whole lock.
  local O, rec = Fixture.new()
  local ctx = O.CreatePanel("CombatP", "Combat", { pageKey = "combat" })
  local drawn = 0
  O.SetRenderer(ctx, function() drawn = drawn + 1 end)

  local before = mocks.__settingsClosed
  mocks.InCombatLockdown = function() return true end
  ctx.panel:__fire("OnShow")
  mocks.InCombatLockdown = function() return false end

  assertEqual(drawn, 0, "the body is not drawn under lockdown")
  assertEqual(mocks.__settingsClosed, before, "and the settings window is left alone")
  assertTrue(ctx.__combatCover:IsShown(), "the page is covered instead")
  local text = table.concat(rec.chat, "\n")
  assertTrue(text:lower():find("combat", 1, true) ~= nil, "the notice says why: " .. text)
end)

test("options: a raising renderer is reported, not propagated", function()
  -- Inside AceGUI's own dispatch, a raise would take the click handling of every widget on the
  -- frame down with it.
  local O, rec = Fixture.new()
  local ctx = O.CreatePanel("BoomP", "Boom", { pageKey = "boom" })
  O.SetRenderer(ctx, function() error("render exploded") end)
  local ok = pcall(function() ctx.panel:__fire("OnShow") end)
  assertTrue(ok, "the OnShow itself survives")
  assertTrue(table.concat(rec.chat, "\n"):find("boom", 1, true) ~= nil, "and the page is named")
end)

test("options: RefreshScalars re-syncs a shown page and flags a hidden one dirty", function()
  local O = Fixture.new()
  local shown  = O.CreatePanel("ShownP",  "Shown",  { pageKey = "shown"  })
  local hidden = O.CreatePanel("HiddenP", "Hidden", { pageKey = "hidden" })
  local drew, synced = 0, 0
  O.SetRenderer(shown,  function() drew = drew + 1 end)
  O.SetRenderer(hidden, function() drew = drew + 1 end)
  shown.refreshers[#shown.refreshers + 1] = function() synced = synced + 1 end
  shown.panel:Show(); hidden.panel:Hide()
  shown._rendered = true

  O.RefreshScalars()
  assertEqual(synced, 1, "the shown page's refreshers ran")
  assertEqual(drew, 0, "and nothing was rebuilt")
  assertTrue(hidden._dirty, "the hidden page is flagged rather than refreshed")
end)

test("options: a dirty hidden page re-renders on its next show", function()
  -- The whole point of the flag: deferring the work is only correct if it actually happens later.
  local O = Fixture.new()
  local ctx = O.CreatePanel("DirtyP", "Dirty", { pageKey = "dirty" })
  local drew = 0
  O.SetRenderer(ctx, function() drew = drew + 1 end)
  ctx.panel:Show(); ctx.panel:__fire("OnShow")
  assertEqual(drew, 1)
  ctx.panel:Hide()
  O.RefreshAllPanels()
  assertEqual(drew, 1, "hidden pages are not rebuilt in place")
  ctx.panel:Show(); ctx.panel:__fire("OnShow")
  assertEqual(drew, 2, "and the deferred rebuild lands on the next show")
end)

test("options: the two tiers differ — one re-renders, the other only re-syncs", function()
  local O = Fixture.new()
  local ctx = O.CreatePanel("TiersP", "Tiers", { pageKey = "tiers" })
  local drew, synced = 0, 0
  O.SetRenderer(ctx, function() drew = drew + 1 end)
  ctx.refreshers[#ctx.refreshers + 1] = function() synced = synced + 1 end
  ctx.panel:Show()
  ctx._rendered = true

  O.RefreshScalars()
  assertEqual(drew, 0); assertEqual(synced, 1)
  O.RefreshAllPanels()
  assertEqual(drew, 1, "the structural tier re-runs the renderer")
end)

test("options: RefreshPanel touches ONE page, on both tiers", function()
  -- The reason it exists: a host whose page repaints off its own message bus wants this page, not a
  -- sweep of every registered one.
  local O = Fixture.new()
  local mine  = O.CreatePanel("MineP",  "Mine",  { pageKey = "mine"  })
  local other = O.CreatePanel("OtherP", "Other", { pageKey = "other" })
  local drewMine, drewOther, syncedMine = 0, 0, 0
  O.SetRenderer(mine,  function() drewMine  = drewMine  + 1 end)
  O.SetRenderer(other, function() drewOther = drewOther + 1 end)
  mine.refreshers[#mine.refreshers + 1] = function() syncedMine = syncedMine + 1 end
  mine.panel:Show(); other.panel:Show()
  mine._rendered, other._rendered = true, true

  O.RefreshPanel(mine, false)
  assertEqual(syncedMine, 1, "the scalar tier ran this page's refreshers")
  assertEqual(drewMine, 0, "and did not rebuild it")
  O.RefreshPanel(mine, true)
  assertEqual(drewMine, 1, "the structural tier re-runs this page's renderer")
  assertEqual(drewOther, 0, "and no other registered page was touched")
end)

test("options: RefreshPanel defers a hidden page to its next show", function()
  -- The bug this API was published for: a host hand-rolling this branch guessed the flag name, so
  -- its page marked something nothing read and never re-rendered. The caller must not have to know
  -- whether the page is on screen.
  local O = Fixture.new()
  local ctx = O.CreatePanel("DeferP", "Defer", { pageKey = "defer" })
  local drew = 0
  O.SetRenderer(ctx, function() drew = drew + 1 end)
  ctx.panel:Show(); ctx.panel:__fire("OnShow")
  assertEqual(drew, 1)

  ctx.panel:Hide()
  O.RefreshPanel(ctx, true)
  assertEqual(drew, 1, "a hidden page is not rebuilt in place")
  assertTrue(ctx._dirty, "it is flagged with the LIBRARY's flag, which is the whole point")
  ctx.panel:Show(); ctx.panel:__fire("OnShow")
  assertEqual(drew, 2, "and the deferred rebuild lands on the next show")
end)

test("options: RefreshPanel ignores a non-ctx rather than raising", function()
  local O = Fixture.new()
  assertTrue(pcall(O.RefreshPanel, nil, true), "nil is a no-op")
  assertTrue(pcall(O.RefreshPanel, "notactx", false), "so is a non-table")
end)

test("options: a ctx that never went through SetRenderer keeps the old ungated behavior",
  function()
  -- The migration seam, and the most important case in this block: a host adopting the registry
  -- one page at a time keeps working, and so does one that never adopts it at all.
  local O = Fixture.new()
  local ctx = O.CreatePanel("LegacyP", "Legacy", {})
  local synced = 0
  ctx.refreshers[#ctx.refreshers + 1] = function() synced = synced + 1 end
  ctx.panel:Hide()                        -- hidden, and still refreshed
  O.RefreshScalars()
  assertEqual(synced, 1, "no renderer means no gate")
  O.RefreshAllPanels()
  assertEqual(synced, 2, "on both tiers")
end)

test("options: OpenOptionsPanel REFUSES under combat and does not defer-and-replay", function()
  -- options-ui-§2. Settings.OpenToCategory is protected; calling it under lockdown taints the
  -- panel for the session. Deferring to PLAYER_REGEN_ENABLED is the other wrong answer — a panel
  -- that opens itself the instant combat drops steals focus during post-pull recovery.
  local O, rec = Fixture.new()
  O.CreateOptionsPanel()
  local opened = 0
  local savedOpen, savedCombat = mocks.Settings.OpenToCategory, mocks.InCombatLockdown
  mocks.Settings.OpenToCategory = function() opened = opened + 1 end
  mocks.InCombatLockdown = function() return true end
  local ok, err = pcall(O.OpenOptionsPanel)
  mocks.Settings.OpenToCategory, mocks.InCombatLockdown = savedOpen, savedCombat
  if not ok then error(err) end

  assertEqual(opened, 0, "the protected call must not be made")
  local joined = table.concat(rec.chat, "\n")
  assertTrue(joined:find("combat", 1, true) ~= nil, "and the refusal says why: " .. joined)
end)

test("options: OpenOptionsPanel opens the registered category out of combat", function()
  local O = Fixture.new()
  O.CreateOptionsPanel()
  local openedWith
  local savedOpen = mocks.Settings.OpenToCategory
  mocks.Settings.OpenToCategory = function(id) openedWith = id end
  local ok, err = pcall(O.OpenOptionsPanel)
  mocks.Settings.OpenToCategory = savedOpen
  if not ok then error(err) end
  assertEqual(openedWith, 1, "the ID the canvas registration handed back")
end)

test("options: :New refuses a descriptor with no mainPanelName", function()
  -- The one descriptor field whose entire purpose is lost in silence: a nil yields
  -- CreateFrame("Frame", nil), an anonymous canvas /framestack cannot attribute to the host, with
  -- no error and nothing visible in game.
  local _, rec = Fixture.new()
  local d = {}
  for k, v in pairs(rec.d) do d[k] = v end
  d.mainPanelName = nil
  local err = T.assertError(function() lib:New(d) end,
    "an anonymous canvas fails silently, so it must fail loudly at :New instead")
  assertTrue(err:find("mainPanelName", 1, true) ~= nil, "the error names the field: " .. err)
end)

test("options: a host that omits print still sees the combat refusal in the chat frame", function()
  -- Core, DebugLog and Slash all fall back to DEFAULT_CHAT_FRAME:AddMessage. Options discarding
  -- instead made a refused open indistinguishable from a dead keybind (options-ui-§2).
  local _, rec = Fixture.new()
  local d = {}
  for k, v in pairs(rec.d) do d[k] = v end
  d.print = nil
  local O = lib:New(d)

  local chat, got = mocks.DEFAULT_CHAT_FRAME, {}
  rawset(chat, "AddMessage", function(_, line) got[#got + 1] = line end)
  local savedCombat = mocks.InCombatLockdown
  mocks.InCombatLockdown = function() return true end
  local ok, err = pcall(O.OpenOptionsPanel)
  mocks.InCombatLockdown = savedCombat
  rawset(chat, "AddMessage", nil)
  if not ok then error(err) end

  assertTrue(table.concat(got, "\n"):find("combat", 1, true) ~= nil,
    "the refusal must be visible, not discarded: " .. table.concat(got, "\n"))
end)

test("options: CreateOptionsPanel is idempotent in both the category and the refreshers",
  function()
  -- Public, cheap to call twice (a login plus a profile change), and nothing in the API says it
  -- may not be. A second run would add a duplicate Blizzard category and permanently double the
  -- RefreshAllPanels fan-out.
  local O = Fixture.new()
  local registered, ran = 0, 0
  local savedReg = mocks.Settings.RegisterAddOnCategory
  mocks.Settings.RegisterAddOnCategory = function() registered = registered + 1 end
  O.RegisterOptionsPage("general", "General", function()
    local ctx = O.CreatePanel("TestPanelIdem", "General", { pageKey = "general" })
    ctx.refreshers[1] = function() ran = ran + 1 end
  end)
  O.CreateOptionsPanel()
  O.CreateOptionsPanel()
  mocks.Settings.RegisterAddOnCategory = savedReg

  assertEqual(registered, 1, "a second call must not register a second Blizzard category")
  O.RefreshAllPanels()
  assertEqual(ran, 1, "and must not double the refresher fan-out")
end)

test("options: OpenOptionsPanel is a silent no-op before CreateOptionsPanel has run", function()
  -- `/at config` before PLAYER_LOGIN, or on a build where the canvas API is unavailable. There is
  -- no category to open and nothing has gone wrong.
  local O, rec = Fixture.new()
  assertTrue(pcall(O.OpenOptionsPanel))
  assertEqual(#rec.chat, 0)
end)
