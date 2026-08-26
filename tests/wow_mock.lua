-- LibKa0s's WoW-API mock: the shared base (testkit/mock_base.lua, vendored to tests/_kit/) plus the
-- one API the library itself reads that the base deliberately leaves alone.
--
-- Returns a builder so each run gets a fresh, isolated environment. Everything universal — frames,
-- timers, the stopwatch, the Settings canvas API, LibStub, the Ace fakes — lives in the kit and is
-- documented there, including its fidelity rules.
--
-- Note this repo consumes its own kit through tests/_kit/ rather than reaching into testkit/
-- directly. That is deliberate: it makes LibKa0s a consumer on exactly the same terms as every
-- addon, so `diff -r testkit tests/_kit` is the same gate here as it is downstream, and a kit change
-- that breaks a consumer breaks this repo first.

local base = dofile("tests/_kit/mock_base.lua")

return function()
  local M = base()

  -- Addon metadata. Left out of the base on purpose: it is the target of every addon's Compat shim,
  -- and those shims are tested by swapping `_G.C_AddOns` to nil to reach the deprecated-global
  -- fallback. A base-level stub resolves ahead of _G and makes that branch unreachable.
  --
  -- HONEST ABOUT WHICH FIELDS EXIST, and that is the point (fidelity rule 1: a stub that silently
  -- succeeds is worse than no stub). This returned "120007" for ANY field, including "Interface" —
  -- which the real client does NOT expose through this API. So `interface` was pinned by a case
  -- that could only pass, and the field shipped reading 0 in a live capture while the suite stayed
  -- green. It answers only the fields Blizzard actually serves.
  local META = {
    Title   = "Test Host",
    Notes   = "A fixture.",
    Author  = "tests",
    Version = "1.2.3",
  }
  M.C_AddOns = { GetAddOnMetadata = function(_, field) return META[field] end }

  -- The map reader LibKa0s-Env-1.0 sits on. Repo-local rather than in testkit/mock_base.lua: the
  -- kit carries APIs every addon touches, and two addons read a map id.
  M.C_Map = { GetBestMapForUnit = function(unit) return unit == "player" and 2112 or nil end }

  -- Item APIs, repo-local for the same reason C_Map is: two addons read them, not every addon.
  M.__loadRequests = {}
  M.C_Item = {
    RequestLoadItemDataByID = function(id) M.__loadRequests[id] = true end,
  }

  -- The colour table QualityFromLink builds its reverse map out of. Real hex values — the parse is
  -- the thing under test and a made-up palette would test the parser against itself.
  M.ITEM_QUALITY_COLORS = {
    [0] = { hex = "|cff9d9d9d" }, [1] = { hex = "|cffffffff" }, [2] = { hex = "|cff1eff00" },
    [3] = { hex = "|cff0070dd" }, [4] = { hex = "|cffa335ee" }, [5] = { hex = "|cffff8000" },
    [6] = { hex = "|cffe6cc80" }, [7] = { hex = "|cff00ccff" }, [8] = { hex = "|cff00ccff" },
  }
  M.ITEM_QUALITY0_DESC = "Poor"
  M.ITEM_QUALITY1_DESC = "Common"
  M.ITEM_QUALITY2_DESC = "Uncommon"
  M.ITEM_QUALITY3_DESC = "Rare"
  M.ITEM_QUALITY4_DESC = "Epic"
  M.ITEM_QUALITY5_DESC = "Legendary"
  M.ITEM_QUALITY6_DESC = "Artifact"
  M.ITEM_QUALITY7_DESC = "Heirloom"
  M.ITEM_QUALITY8_DESC = "WoW Token"

  -- The client's interface version, which is where `Interface` actually comes from: GetBuildInfo's
  -- FOURTH return. version, build, date, tocversion.
  M.GetBuildInfo = function() return "12.0.7", "60000", "Jul 31 2026", 120007 end

  -- This repo's suites assert that a capture's context records the character's LOCALISED class
  -- name rather than the token, so the fixture character is a Death Knight — the pair where the two
  -- strings differ most obviously. The base defaults to a Mage, where they differ only by case and
  -- a swapped return would go unnoticed.
  M.__context.class      = "Death Knight"
  M.__context.classToken = "DEATHKNIGHT"

  -- ── the pointer ───────────────────────────────────────────────────────────────────────────
  --
  -- LibKa0s-Widgets-1.0's ReorderList reads both on every OnUpdate frame of a drag, and a drag
  -- nothing offline can drive is a drag that ships untested -- which is exactly how two earlier
  -- implementations of it shipped doing nothing at all.
  --
  -- ADDED TO THE SHARED MOCK rather than to one suite's own factory, unlike the geometry stub in
  -- tests/test_widgets.lua. These are new GLOBALS, not changes to how an existing one behaves, so
  -- no suite written against the base can observe the difference; widening frame geometry would
  -- have been a change to all sixteen.
  --
  -- GetCursorPosition answers SCALED coordinates, as the client's does: callers divide by
  -- UIParent:GetEffectiveScale().
  M.__cursorX, M.__cursorY = 0, 0
  M.GetCursorPosition = function() return M.__cursorX, M.__cursorY end
  function M.setCursor(x, y) M.__cursorX, M.__cursorY = x or 0, y or 0 end

  -- The kit's base frame stub answers the frame ITSELF for any method it does not implement, so
  -- an unpatched UIParent:GetEffectiveScale() hands back a table. Every caller here divides by it,
  -- and the library guards on the answer being a number -- so without this the drag refuses to
  -- start and the guard, rather than the drag, is what the suite would be testing.
  M.UIParent.GetEffectiveScale = function() return 1 end

  M.__mouseDown = {}
  M.IsMouseButtonDown = function(button)
    return M.__mouseDown[button or "LeftButton"] and true or false
  end
  function M.setMouseDown(button, down)
    M.__mouseDown[button or "LeftButton"] = down and true or false
  end


  return M
end
