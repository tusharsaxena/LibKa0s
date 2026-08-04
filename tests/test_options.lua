-- tests/test_options.lua — LibKa0s-Options-1.0's panel shell: the ctx factory, the panel registry,
-- the lazy Defaults button, the reset/refresh trio, the page registry with its combat-refusing
-- open, the LSM values factory and the always-shown scrollbar patch.
--
-- The widget makers and the two-column flow engine are next door in tests/test_options_widgets.lua.
-- The split follows the files: this suite is Options.lua and OptionsScroll.lua, that one is
-- OptionsWidgets.lua.
--
-- Every case builds its own host through tests/fixture_options.lua, so no case can be made to pass
-- by another one's leftovers — which matters more here than in most suites, because the panel
-- registry is deliberately process-lived state.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local mocks = T.mocks
local Fixture = dofile("tests/fixture_options.lua")

local lib = T.options

-- ── the descriptor and the module identity ─────────────────────────────────────────────────

test("options: the major registers all three of its files", function()
  assertEqual(lib.MODULES.Options, lib.MINOR, "Options.lua is the primary")
  assertTrue(type(lib.MODULES.OptionsWidgets) == "number", "OptionsWidgets.lua attached")
  assertTrue(type(lib.MODULES.OptionsScroll) == "number", "OptionsScroll.lua attached")
end)

test("options: an instance carries the shell, the widget makers and the scroll patch", function()
  local O = Fixture.new()
  for _, name in ipairs({
    "CreatePanel", "EnsureDefaultsButton", "EnsureScroll", "ClearScroll", "Section", "AddSpacer",
    "AttachTooltip", "InlineButtonPair", "RestoreDefaults", "RestoreAllDefaults",
    "RefreshAllPanels", "RefreshScalars", "SetRenderer", "LSMValues",
    "RegisterOptionsPage", "CreateOptionsPanel", "__pages",
    "OpenOptionsPanel", "RenderField", "RenderRows", "RenderSchema", "SessionCheckbox",
    "PatchAlwaysShowScrollbar", "__panels", "__panelFor",
  }) do
    assertTrue(type(O[name]) == "function", name .. " is on the instance")
  end
end)

test("options: two instances own separate panel registries", function()
  -- Every host gets its own; a lib-level registry would have one addon's Defaults button refresh
  -- another addon's widgets.
  local A = Fixture.new()
  local B = Fixture.new()
  A.CreatePanel("SepA", "Sep A", {})
  assertEqual(#A.__panels(), 1)
  assertEqual(#B.__panels(), 0, "the second host's registry is untouched by the first's panel")
end)

-- ── CreatePanel + the registry ─────────────────────────────────────────────────────────────

test("options: CreatePanel returns a ctx wired to a panel, a body and an empty refresher list",
  function()
  local O = Fixture.new()
  local ctx = O.CreatePanel("TestPanelA", "Test A", { pageKey = "general" })
  assertTrue(ctx.panel ~= nil, "ctx carries the canvas frame")
  assertTrue(ctx.body ~= nil, "and its body child")
  assertEqual(ctx.pageKey, "general")
  assertEqual(#ctx.refreshers, 0)
  assertNil(ctx.scroll, "the AceGUI scroll frame stays lazy until first render")
end)

test("options: CreatePanel names the panel with the plain title for the category tree", function()
  -- The header FontString gets the "<Parent> > <Page>" breadcrumb; panel.name is what Blizzard
  -- renders in the left tree and must stay unprefixed or the tree reads doubled up.
  local O = Fixture.new()
  local ctx = O.CreatePanel("TestPanelB", "Test B", {})
  assertEqual(ctx.panel.name, "Test B")
end)

test("options: CreatePanel starts the panel hidden and registers it", function()
  local O = Fixture.new()
  local ctx = O.CreatePanel("TestPanelC", "Test C", {})
  assertFalse(ctx.panel:IsShown(), "Blizzard shows the canvas when its category is selected")
  assertEqual(O.__panels()[1], ctx, "and the ctx joined the registry")
end)

test("options: the header title takes the parent breadcrumb, and isMain opts out", function()
  local O = Fixture.new()
  local sub  = O.CreatePanel("TestPanelD", "Bar", {})
  local main = O.CreatePanel("TestPanelE", "Test Host", { isMain = true })
  assertTrue(sub.panel.titleText:find("Test Host", 1, true) ~= nil,
    "a sub-page is prefixed with the host's brand: " .. tostring(sub.panel.titleText))
  assertTrue(sub.panel.titleText:find("Bar", 1, true) ~= nil, "and with its own name")
  assertEqual(main.panel.titleText, "Test Host",
    "the main page renders unprefixed, or it would read 'Test Host > Test Host'")
end)

test("options: __panelFor finds a registered page by key", function()
  local O = Fixture.new()
  O.CreatePanel("TestPanelF1", "One", { pageKey = "general" })
  local bar = O.CreatePanel("TestPanelF2", "Two", { pageKey = "bar" })
  assertEqual(O.__panelFor("bar"), bar)
  assertNil(O.__panelFor("nosuchpage"))
end)

-- ── the lazy Defaults button ───────────────────────────────────────────────────────────────

test("options: CreatePanel only DECLARES the Defaults button, never builds it", function()
  -- options-ui-§5: the widget must be created on first OnShow, after every addon (including UI
  -- skinners hooking AceGUI:RegisterAsWidget) has loaded. Building it here is a load-order race
  -- that renders the button unskinned for the rest of the session.
  local O = Fixture.new()
  local ctx = O.CreatePanel("TestPanelG", "Test G", { defaultsButton = true })
  assertTrue(ctx.panel.wantsDefaultsButton, "the intent is recorded")
  assertNil(ctx.panel.defaultsBtn, "but no widget exists yet")
end)

test("options: CreatePanel records no Defaults intent when the page did not ask", function()
  local O = Fixture.new()
  assertFalse(O.CreatePanel("TestPanelH", "Test H", {}).panel.wantsDefaultsButton)
end)

test("options: EnsureDefaultsButton builds it once, wires the parked handler, then no-ops",
  function()
  local O = Fixture.new()
  local ctx = O.CreatePanel("TestPanelI", "Test I",
    { defaultsButton = true, defaultsTooltip = "Reset this page" })
  local clicked = 0
  ctx.panel.defaultsOnClick = function() clicked = clicked + 1 end

  O.EnsureDefaultsButton(ctx.panel)
  local btn = ctx.panel.defaultsBtn
  assertTrue(btn ~= nil, "the first call builds it")
  assertEqual(btn.text, "Defaults")
  assertTrue(btn.callbacks.OnClick ~= nil, "the handler parked on the panel got wired to it")
  assertTrue(btn.callbacks.OnEnter ~= nil, "and the tooltip is attached")

  O.EnsureDefaultsButton(ctx.panel)
  assertEqual(ctx.panel.defaultsBtn, btn, "a second call reuses the same widget")

  btn.callbacks.OnClick(btn, "OnClick")
  assertEqual(clicked, 1)
end)

test("options: EnsureDefaultsButton is a safe no-op without AceGUI and on a nil panel", function()
  local O, rec = Fixture.new()
  local ctx = O.CreatePanel("TestPanelJ", "Test J", { defaultsButton = true })
  local saved = O.AceGUI
  O.AceGUI = nil
  local ok = pcall(O.EnsureDefaultsButton, ctx.panel)
  O.AceGUI = saved
  assertTrue(ok, "must not raise when AceGUI is absent")
  assertNil(ctx.panel.defaultsBtn, "and must not half-build anything")
  assertTrue(pcall(O.EnsureDefaultsButton, nil), "must not raise on a nil panel")
  assertEqual(#rec.chat, 0, "and says nothing — this is a build-order path, not a user error")
end)

test("options: EnsureDefaultsButton leaves a panel that never wanted one alone", function()
  local O = Fixture.new()
  local ctx = O.CreatePanel("TestPanelK", "Test K", {})
  O.EnsureDefaultsButton(ctx.panel)
  assertNil(ctx.panel.defaultsBtn)
end)

test("options: EnsureDefaultsButton survives a vendored copy whose widget makers never attached",
  function()
  -- A partial vendor (OptionsWidgets.lua absent) leaves the instance without O.AttachTooltip. The
  -- shell reaches for it at CALL time precisely so that state stays survivable, and the closing
  -- comment on lib:New says so of BOTH cross-file reaches — so both must be guarded, or the first
  -- panel OnShow raises from inside the library itself.
  local savedWidgets = lib.__AttachWidgets
  lib.__AttachWidgets = nil
  local O = Fixture.new()
  lib.__AttachWidgets = savedWidgets

  assertNil(O.AttachTooltip, "the widget makers really are absent from this instance")
  local ctx = O.CreatePanel("TestPanelK2", "Test K2", { defaultsButton = true })
  local ok, err = pcall(O.EnsureDefaultsButton, ctx.panel)
  assertTrue(ok, "the shell must not raise on a half-vendored copy: " .. tostring(err))
  assertTrue(ctx.panel.defaultsBtn ~= nil, "and the button is still built, just without a tooltip")
end)

-- ── RestoreDefaults / RestoreAllDefaults / RefreshAllPanels ────────────────────────────────

test("options: RestoreDefaults resets every row on the named page and no other", function()
  local O, rec = Fixture.new()
  rec.store.barWidth = 333
  rec.store.locked   = true
  O.RestoreDefaults("bar")
  assertEqual(rec.store.barWidth, 200, "the bar page went back to its default")
  assertEqual(rec.store.locked, true, "a general-page value survives a bar-page reset")
end)

test("options: RestoreDefaults runs the ctx refreshers, and survives one that throws", function()
  -- Refreshers touch live AceGUI widgets; one dead widget must not abort the rest of the reset.
  local O = Fixture.new()
  local ctx = O.CreatePanel("TestPanelL", "Test L", { pageKey = "bar" })
  local ran = 0
  ctx.refreshers[1] = function() error("dead widget") end
  ctx.refreshers[2] = function() ran = ran + 1 end
  assertTrue(pcall(O.RestoreDefaults, "bar", ctx), "RestoreDefaults must not propagate")
  assertEqual(ran, 1, "the refresher after the failing one still ran")
end)

test("options: RestoreDefaults on a page with no rows is a harmless no-op", function()
  local O = Fixture.new()
  assertTrue(pcall(O.RestoreDefaults, "nosuchpage"))
end)

test("options: RestoreDefaults resets a page across EVERY filter value, unlike RenderSchema",
  function()
  -- The asymmetry is DELIBERATE and pinned here so nobody "fixes" it: a page's Defaults button
  -- resets the whole page, every filter value, while the panel in front of the user renders one at
  -- a time. AbsorbTracker's tests/test_helpers.lua asserts the same thing across all three units,
  -- and it is where /at reset <page> went when the CLI form was removed. Threading ctx.unit into
  -- RestoreDefaults would silently narrow a host's reset.
  local O, rec = Fixture.new()
  rec.store.unitPlayerScale = 9
  rec.store.unitTargetScale = 9
  local ctx = O.CreatePanel("TestPanelU", "Units", { pageKey = "units" })
  ctx.unit = "player"                      -- the filter the panel is currently rendering

  O.RestoreDefaults("units", ctx)
  assertEqual(rec.store.unitPlayerScale, 1, "the rendered filter's row was reset")
  assertEqual(rec.store.unitTargetScale, 1,
    "and so was every other filter value's — a Defaults button is page-scoped, not unit-scoped")

  local shown = rec.d.rowsForPage("units", ctx.unit)
  assertEqual(#shown, 1, "while the render path, which DOES pass the filter, sees one unit's rows")
  assertEqual(shown[1].path, "unitPlayerScale")
end)

test("options: RestoreAllDefaults resets every row, then fires the host's afterRestoreAll",
  function()
  local O, rec = Fixture.new()
  rec.store.barWidth = 333
  rec.store.locked   = true
  O.RestoreAllDefaults()
  assertEqual(rec.store.barWidth, 200)
  assertEqual(rec.store.locked, false)
  assertEqual(rec.restoredAll, 1,
    "the host hook is what clears state no schema row owns — a dragged frame position")
end)

test("options: RestoreAllDefaults fires afterRestoreAll BEFORE refreshing the panels", function()
  -- The hook exists to mutate state (AbsorbTracker clears every saved bar position through it), so
  -- a refresh that ran first would paint the panel from the pre-hook values.
  local order = {}
  local O = Fixture.new{ afterRestoreAll = function() order[#order + 1] = "hook" end }
  local ctx = O.CreatePanel("TestPanelM", "Test M", {})
  ctx.refreshers[1] = function() order[#order + 1] = "refresh" end
  O.RestoreAllDefaults()
  assertEqual(table.concat(order, ","), "hook,refresh")
end)

test("options: RestoreAllDefaults honours the host's skipRestoreAll veto", function()
  -- AbsorbTracker's profiles page: resetting it would delete user data, so it must never be swept
  -- up in a global reset. The library takes the predicate rather than knowing the page name.
  local O, rec = Fixture.new{ skipRestoreAll = function(row) return row.page == "bar" end }
  rec.store.barWidth = 333
  rec.store.locked   = true
  O.RestoreAllDefaults()
  assertEqual(rec.store.barWidth, 333, "the vetoed page was skipped")
  assertEqual(rec.store.locked, false, "and every other page was still reset")
end)

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
  -- Ka0s standard §3.4: resolve once, then read the upvalue. The host stashes it for its own page
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

test("options: a panel shown during combat closes the window and does not render", function()
  -- The Blizzard AddOns sidebar reaches a panel without going through OpenOptionsPanel, so this
  -- is the path a user is most likely to take mid-fight and the one that had no guard at all.
  local O, rec = Fixture.new()
  local ctx = O.CreatePanel("CombatP", "Combat", { pageKey = "combat" })
  local drawn = 0
  O.SetRenderer(ctx, function() drawn = drawn + 1 end)

  local before = mocks.__settingsClosed
  mocks.InCombatLockdown = function() return true end
  ctx.panel:__fire("OnShow")
  mocks.InCombatLockdown = function() return false end

  assertEqual(drawn, 0, "the body is not drawn under lockdown")
  assertEqual(mocks.__settingsClosed, before + 1, "and the settings window is closed")
  local text = table.concat(rec.chat, "\n")
  assertTrue(text:lower():find("combat", 1, true) ~= nil, "the refusal says why: " .. text)
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

test("options: a ctx that never went through SetRenderer keeps the old ungated behaviour",
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

-- ── LSMValues ──────────────────────────────────────────────────────────────────────────────

test("options: LSMValues returns a DEFERRED closure, not a snapshot", function()
  -- Every LSM-backed row evaluates this inside a schema-row literal at FILE LOAD, long before
  -- LibSharedMedia has been populated by the addons that register into it. Returning a table here
  -- would freeze the media list at whatever was registered first.
  local O, rec = Fixture.new()
  local values = O.LSMValues("statusbar")
  assertEqual(type(values), "function")
  rec.lsm = { HashTable = function(_, kind)
    assertEqual(kind, "statusbar", "the media type is carried through to the call")
    return { Blizzard = "path/a", Smooth = "path/b" }
  end }
  local out = values()
  assertEqual(out.Blizzard, "Blizzard", "keyed on the name, valued with the name (an AceGUI list)")
  assertEqual(out.Smooth, "Smooth")
end)

test("options: LSMValues offers a None placeholder rather than an empty list", function()
  -- Empty was the old answer and it made the row unusable, not merely unpopulated: a dropdown
  -- with no options cannot be opened, and the CLI's allowed-values check refuses every value —
  -- including the one already stored. A host whose media library has not loaded yet gets a row
  -- it can still see and still set.
  local O = Fixture.new()
  local out = O.LSMValues("font")()
  assertEqual(type(out), "table")
  assertEqual(out.None, "None", "the placeholder is offered")
  local n = 0
  for _ in pairs(out) do n = n + 1 end
  assertEqual(n, 1, "and it is the only entry")
end)

-- ── the always-shown scrollbar patch (OptionsScroll.lua) ───────────────────────────────────

test("options: EnsureScroll is lazy, created once, and patched", function()
  local O = Fixture.new()
  local ctx = O.CreatePanel("TestPanelP", "Test P", {})
  assertNil(ctx.scroll, "no scroll frame until something is rendered")
  local first = O.EnsureScroll(ctx)
  assertEqual(O.EnsureScroll(ctx), first, "subsequent calls reuse it")
  assertTrue(first._ka0sAlwaysScrollbar, "OptionsScroll.lua patched it")
  assertTrue(first.scrollBarShown, "the scrollbar and its gutter stay shown across pages")
  assertEqual(first.content.width, first.content.original_width - 20,
    "the content is inset by the gutter so every page's right edge lines up")
end)

test("options: the scrollbar patch is idempotent", function()
  local O = Fixture.new()
  local scroll = O.EnsureScroll(O.CreatePanel("TestPanelQ", "Test Q", {}))
  local patched = scroll.FixScroll
  O.PatchAlwaysShowScrollbar(scroll)
  assertEqual(scroll.FixScroll, patched, "a second patch must not wrap the override again")
end)

test("options: FixScroll disables the bar when the content fits, enables it when it does not",
  function()
  local O = Fixture.new()
  local scroll = O.EnsureScroll(O.CreatePanel("TestPanelR", "Test R", {}))
  -- The stub's GetHeight always answers 0, so both heights are rawset here rather than driven
  -- through setters the stub does not implement.
  scroll.scrollbar.Disable = function(s) s.__disabled = true  end
  scroll.scrollbar.Enable  = function(s) s.__disabled = false end
  scroll.scrollframe.GetHeight = function() return 200 end

  scroll.content.GetHeight = function() return 50 end        -- fits
  scroll:FixScroll()
  assertTrue(scroll.scrollbar.__disabled, "nothing to scroll, so the bar greys out")
  assertTrue(scroll.scrollBarShown, "but it is still SHOWN \226\128\148 that is the patch's point")

  scroll.content.GetHeight = function() return 1000 end      -- overflows
  scroll.localstatus.offset = 100
  scroll:FixScroll()
  assertFalse(scroll.scrollbar.__disabled, "overflowing content re-enables it")
end)

test("options: OnRelease restores AceGUI's own FixScroll and clears the marker", function()
  -- AceGUI pools ScrollFrames. A widget handed back still carrying our override would take it into
  -- whichever addon recycles it next.
  local O = Fixture.new()
  local scroll = O.EnsureScroll(O.CreatePanel("TestPanelS", "Test S", {}))
  local stock = scroll.__stockFixScroll
  assertTrue(stock ~= nil, "the patch kept the original to hand back")
  scroll:OnRelease()
  assertEqual(scroll.FixScroll, stock, "AceGUI's own implementation is back")
  assertNil(scroll._ka0sAlwaysScrollbar, "and the marker is gone, so a re-acquire re-patches")
end)

-- ── the Blizzard canvas contract (Options minor 5) ─────────────────────────────────────────
--
-- Blizzard's Settings window calls three methods on a frame handed to
-- RegisterCanvasLayout(Sub)category: OnCommit when the user applies, OnDefault from the window's own
-- footer defaults control, and OnRefresh on re-show. The library declared none of them until minor
-- 5, so every host on it shipped a canvas whose footer Defaults control did nothing — three of them
-- did, without noticing, because the header Defaults button the library DOES build kept working and
-- looked equivalent.
--
-- OnCommit and OnRefresh are inert by design rather than by omission: a host's writes land
-- immediately through its own write seam (options-ui-§41), and SetRenderer already owns re-show, so
-- a second refresh path would race the renderer it duplicates.

test("options: CreatePanel stamps the three Blizzard canvas callbacks", function()
  local O = Fixture.new()
  local ctx = O.CreatePanel("TestPanelCanvas1", "Canvas 1", {})
  -- rawget, because a real canvas Frame answers a missing key from its metatable. "Already there"
  -- has to mean THIS function put it there.
  assertEqual(type(rawget(ctx.panel, "OnCommit")), "function")
  assertEqual(type(rawget(ctx.panel, "OnRefresh")), "function")
  assertEqual(type(rawget(ctx.panel, "OnDefault")), "function")
end)

test("options: OnCommit and OnRefresh are inert and safe to call", function()
  local O = Fixture.new()
  local ctx = O.CreatePanel("TestPanelCanvas2", "Canvas 2", {})
  -- Called through rawget. The mock's frame stub answers ANY PascalCase key with a no-op, so
  -- `ctx.panel.OnCommit()` would run happily whether or not the library set anything — a case that
  -- cannot fail, which is worse than no case.
  rawget(ctx.panel, "OnCommit")()
  rawget(ctx.panel, "OnRefresh")()
end)

test("options: OnDefault forwards to a defaultsOnClick parked AFTER CreatePanel", function()
  -- The ordering is the whole reason this is a forwarder rather than an assignment. Every consumer
  -- parks its click handler on the panel AFTER CreatePanel returns — the button does not exist yet,
  -- so there is nowhere else to put it — and a `panel.OnDefault = panel.defaultsOnClick` inside
  -- CreatePanel would capture nil forever while looking perfectly correct.
  local O = Fixture.new()
  local ctx = O.CreatePanel("TestPanelCanvas3", "Canvas 3", { defaultsButton = true })
  local clicked = 0
  ctx.panel.defaultsOnClick = function() clicked = clicked + 1 end
  ctx.panel.OnDefault()
  assertEqual(clicked, 1, "the footer control must reach the page's real defaults action")
end)

test("options: OnDefault and the header Defaults button run the SAME action", function()
  -- Not identity — OnDefault is a forwarder — but one implementation, which is what identity was
  -- ever a proxy for. Two defaults controls that can drift is the thing this prevents.
  local O = Fixture.new()
  local ctx = O.CreatePanel("TestPanelCanvas4", "Canvas 4", { defaultsButton = true })
  local calls = {}
  ctx.panel.defaultsOnClick = function() calls[#calls + 1] = "action" end
  O.EnsureDefaultsButton(ctx.panel)
  ctx.panel.OnDefault()
  ctx.panel.defaultsBtn:__fire("OnClick")
  assertEqual(#calls, 2, "both routes reach it")
end)

test("options: a page with no defaults action still has a callable, inert OnDefault", function()
  -- The main/landing page. Blizzard's footer control is not per-page, so it can be clicked while a
  -- page that manages nothing is open, and a nil OnDefault there is exactly the error surface this
  -- change exists to close.
  local O = Fixture.new()
  local ctx = O.CreatePanel("TestPanelCanvas5", "Canvas 5", { isMain = true })
  assertNil(rawget(ctx.panel, "defaultsOnClick"))
  rawget(ctx.panel, "OnDefault")()   -- must not raise, and must be the LIBRARY's, not the stub's
end)

-- ── the landing-page layout constants, and what the shell does NOT do with them ─────────────
--
-- Four constants promoted out of three hosts that each carried a private Helpers.BuildMainContent
-- over the same values. The body is O.BuildLandingPage (tested next door in
-- tests/test_options_widgets.lua); the shell's half is that `d.buildMain` stayed the ONLY main-page
-- seam. The promotion is a renderer a host may CALL — not a descriptor field the shell sniffs for
-- and wires up on the host's behalf — so lib:New answers exactly what it answered at minor 5.

test("options: the landing constants are published on lib.LAYOUT at the promoted values", function()
  -- The three hosts agreed on all four before the promotion. Changing one silently re-spaces every
  -- landing page in the collection at once, which is exactly why they are pinned rather than left
  -- to read as arbitrary.
  assertEqual(lib.LAYOUT.LANDING_LOGO, 300)
  assertEqual(lib.LAYOUT.LANDING_GAP_LOGO, 8)
  assertEqual(lib.LAYOUT.LANDING_GAP_DESC, 12)
  assertEqual(lib.LAYOUT.LANDING_GAP_HEAD, 6)
end)

test("options: LANDING_GAP_HEAD and SECTION_BOTTOM_SPACER are the same gap", function()
  -- BuildLandingPage does not emit LANDING_GAP_HEAD itself: O.Section already puts
  -- SECTION_BOTTOM_SPACER under every heading, and a second spacer would double the gap the hosts
  -- render. That only holds while the two numbers agree, so the agreement is the assertion.
  assertEqual(lib.LAYOUT.LANDING_GAP_HEAD, lib.LAYOUT.SECTION_BOTTOM_SPACER)
end)

test("options: a host wires the landing body itself, through the buildMain it always had",
  function()
  -- The supported route, and the only one. O.BuildLandingPage is an ordinary renderer, so a host
  -- reaches it the same way it reaches any other main-page body.
  local O
  local spec = {
    notes = "A fixture.",
    sections = { { heading = "Slash Commands", rows = function() return { "/x help" } end } },
  }
  O = Fixture.new{ buildMain = function(ctx) O.BuildLandingPage(ctx, spec) end }
  O.CreateOptionsPanel()
  mocks.__mainPanel:__fire("OnShow")

  -- The main ctx stays private to the shell, so the page is read back through the widgets the
  -- AceGUI factory handed out.
  local texts = {}
  for _, w in ipairs(O.AceGUI.__created) do
    if w.type == "Heading" or w.type == "Label" then texts[#texts + 1] = tostring(w.text) end
  end
  local joined = table.concat(texts, "|")
  assertTrue(joined:find("Slash Commands|/x help", 1, true) ~= nil,
    "the landing body drew through the host's own buildMain: " .. joined)
end)

test("options: the shell installs no main renderer of its own, whatever else the descriptor carries",
  function()
  -- The regression this pins: a shell that reads some OTHER descriptor field and installs a
  -- renderer from it changes what lib:New DOES for a descriptor that never asked for one. A host's
  -- unrecognised keys are the host's business, and an unrecognised key is not a request to draw.
  local O = Fixture.new{ landing = {
    notes    = "never drawn",
    sections = { { heading = "Never Drawn", rows = function() return { "/x help" } end } },
  } }
  O.CreateOptionsPanel()
  local before = #O.AceGUI.__created
  mocks.__mainPanel:__fire("OnShow")
  assertEqual(#O.AceGUI.__created, before,
    "nothing was rendered, and nothing raised — buildMain is the only main-page seam")
end)

test("options: the shell never writes buildMain onto the host's descriptor", function()
  -- The descriptor is the HOST's table. A library that fills fields in on it makes "what did I
  -- declare?" unanswerable from the host's own source, and two instances over one shared descriptor
  -- would each see the other's installation.
  local _, rec = Fixture.new()
  rec.instance.CreateOptionsPanel()
  assertNil(rec.d.buildMain)
end)

test("options: a descriptor with no buildMain draws no main body", function()
  local O = Fixture.new()
  O.CreateOptionsPanel()
  local before = #O.AceGUI.__created
  mocks.__mainPanel:__fire("OnShow")
  assertEqual(#O.AceGUI.__created, before, "nothing was rendered, and nothing raised")
end)

-- ── the scrollbar patch's handle resolution ────────────────────────────────────────────────
--
-- The kit's scrollbar has no name and no thumb, so the enable/disable case above reaches only
-- scrollbar:Enable / :Disable — the thumb tint and the two step buttons were never exercised, which
-- is precisely the code the two mirrored branches duplicated.

--- A widget shaped like AceGUI's ScrollFrame, with a NAMED scrollbar, a thumb and the two step
--- buttons Blizzard parents to a named bar. Every call is appended to one ordered log, because
--- which calls fired and in what ORDER is the contract; counters would report the same totals for a
--- correct patch and one that tinted before it disabled.
local function namedScrollFixture()
  local log = {}
  local function note(what) return function() log[#log + 1] = what end end

  local thumb = { SetVertexColor = function(_, r, g, b, a)
    log[#log + 1] = ("thumb:%s,%s,%s,%s"):format(r, g, b, a)
  end }
  local sb = mocks.__stubFrame()
  sb.GetName          = function() return "LK_TestScrollBar" end
  sb.GetThumbTexture  = function() return thumb end
  sb.Enable           = note("bar:Enable")
  sb.Disable          = note("bar:Disable")
  sb.SetValue         = function(_, v) log[#log + 1] = "bar:SetValue" .. tostring(v) end

  _G.LK_TestScrollBarScrollUpButton   = { Enable = note("up:Enable"),   Disable = note("up:Disable") }
  _G.LK_TestScrollBarScrollDownButton = { Enable = note("down:Enable"), Disable = note("down:Disable") }

  local scroll = {
    scrollbar   = sb,
    scrollframe = mocks.__stubFrame(),
    content     = mocks.__stubFrame(),
    localstatus = { offset = 0 },
  }
  scroll.content.original_width = 400
  function scroll:FixScroll() end
  function scroll:SetScroll(v) self.scrolledTo = v end

  local function cleanup()
    _G.LK_TestScrollBarScrollUpButton   = nil
    _G.LK_TestScrollBarScrollDownButton = nil
  end
  return scroll, log, cleanup
end

test("options: a disabled bar parks the thumb, dims it, and disables both step buttons", function()
  local O = Fixture.new()
  local scroll, log, cleanup = namedScrollFixture()
  O.PatchAlwaysShowScrollbar(scroll)

  scroll.scrollframe.GetHeight = function() return 200 end
  scroll.content.GetHeight     = function() return 50 end    -- fits, so nothing to scroll
  local before = #log
  scroll:FixScroll()
  cleanup()

  local fired = {}
  for i = before + 1, #log do fired[#fired + 1] = log[i] end
  -- SetValue first and unguarded, then the bar, then the tint, then the two buttons. The trailing
  -- SetValue0 is FixScroll's own, after setEnabled has run.
  assertEqual(table.concat(fired, " "),
    "bar:SetValue0 bar:Disable thumb:0.5,0.5,0.5,0.6 up:Disable down:Disable bar:SetValue0")
end)

test("options: an enabled bar tints the thumb white and enables both step buttons", function()
  local O = Fixture.new()
  local scroll, log, cleanup = namedScrollFixture()
  O.PatchAlwaysShowScrollbar(scroll)

  scroll.scrollframe.GetHeight = function() return 200 end
  scroll.content.GetHeight     = function() return 1000 end  -- overflows
  local before = #log
  scroll:FixScroll()
  cleanup()

  local fired = {}
  for i = before + 1, #log do fired[#fired + 1] = log[i] end
  assertEqual(fired[1], "bar:Enable", "the bar first")
  assertEqual(fired[2], "thumb:1,1,1,1", "then the tint")
  assertEqual(fired[3], "up:Enable")
  assertEqual(fired[4], "down:Enable")
end)

test("options: a state change fires once, not once per FixScroll", function()
  -- MoveScroll reads currentEnabled to swallow wheel input on a dead bar, so the short-circuit is
  -- load-bearing as well as cheap.
  local O = Fixture.new()
  local scroll, log, cleanup = namedScrollFixture()
  O.PatchAlwaysShowScrollbar(scroll)

  scroll.scrollframe.GetHeight = function() return 200 end
  scroll.content.GetHeight     = function() return 50 end
  scroll:FixScroll()
  local after = #log
  scroll:FixScroll()
  cleanup()
  -- The second pass re-runs FixScroll's own SetValue(0) and nothing else: setEnabled saw no change.
  assertEqual(#log - after, 1, "no second Disable, no second tint, no second button pass")
end)

test("options: a nameless scrollbar resolves no step buttons and still patches", function()
  -- Headless, and in game before a bar has been named. Every handle below the scrollbar is
  -- optional, and a patch that assumed otherwise would raise inside AceGUI's layout pass.
  local O = Fixture.new()
  local scroll = O.EnsureScroll(O.CreatePanel("TestPanelNameless", "Nameless", {}))
  assertTrue(scroll._ka0sAlwaysScrollbar, "patched")
  scroll.scrollframe.GetHeight = function() return 200 end
  scroll.content.GetHeight     = function() return 1000 end
  assertTrue(pcall(scroll.FixScroll, scroll), "and driving it raises on none of the nil handles")
end)
