-- tests/fixture_widgets.lua — the benches the OptionsWidgets.lua suites share:
-- tests/test_options_widgets.lua (the schema-row makers), tests/test_options_choicegrid.lua
-- (O.ChoiceGrid), tests/test_options_flow.lua (the two-column flow engine and the tabbed page) and
-- tests/test_options_landing.lua (O.TextRow and O.BuildLandingPage). tests/test_options_tabbed.lua
-- (OptionsTabs.lua's tabbed page and banner action) borrows the bench too.
--
-- Moved out of tests/test_options_widgets.lua with the cases that use them, when issue #33 split
-- that suite on its own case seams. One copy rather than four, for the reason tests/fixture_ids.lua
-- gives: a bench that drifted between the suites would make one suite's case prove something
-- another's does not.
--
-- Loaded as `dofile("tests/fixture_widgets.lua")(prefix)`: `prefix` names the throwaway panels, so
-- two suites' benches never hand CreatePanel the same frame name.

local T = _G.LK_TEST
local Fixture = dofile("tests/fixture_options.lua")

return function(prefix)
  --- A host, a throwaway panel and a parent container, so a maker can be driven in isolation.
  local panelSeq = 0
  local function bench(overrides)
    local O, rec = Fixture.new(overrides)
    panelSeq = panelSeq + 1
    local ctx = O.CreatePanel(prefix .. panelSeq, "Bench " .. panelSeq, {})
    return O, rec, ctx
  end

  --- Run `fn` with AceGUI absent, restoring it afterwards.
  ---
  --- The instance resolves AceGUI ONCE, at New() time (`LibKa0s/Options.lua:217`), so the library
  --- has to be built INSIDE this: flipping the mock after Fixture.new leaves the instance holding
  --- the handle it already resolved, and the degraded path never runs. Save-and-restore rather
  --- than assign-and-hope, copied from `tests/test_options.lua`'s own missing-AceGUI case.
  local function withoutAceGUI(fn)
    local saved = T.mocks.__libs["AceGUI-3.0"]
    T.mocks.__libs["AceGUI-3.0"] = nil
    local ok, err = pcall(fn)
    T.mocks.__libs["AceGUI-3.0"] = saved
    if not ok then error(err) end
  end

  return { bench = bench, withoutAceGUI = withoutAceGUI }
end
