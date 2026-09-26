-- tests/fixture_ids.lua — the benches the id-surface suites share: tests/test_options_ids.lua
-- (OptionsIds.lua), and tests/test_options_idlist.lua and tests/test_options_idlist_layout.lua
-- (OptionsIdList.lua).
--
-- Moved out of tests/test_options_widgets.lua with the cases that use them, when issue #32 peeled
-- the id surface out of LibKa0s/OptionsWidgets.lua and #33 peeled its cases with it. One copy
-- rather than three, because the three suites draw the same host, the same id records and the
-- same list bench, and a bench that drifted between them would make one suite's case prove
-- something another's does not.
--
-- Loaded as `dofile("tests/fixture_ids.lua")(prefix)`: `prefix` names the throwaway panels, so
-- two suites' benches never hand CreatePanel the same frame name.

local T = _G.LK_TEST
local assertTrue = T.assertTrue
local Fixture = dofile("tests/fixture_options.lua")
local mocks = T.mocks

return function(prefix)
  --- A host, a throwaway panel and a parent container, so a maker can be driven in isolation.
  local panelSeq = 0
  local function bench(overrides)
    local O, rec = Fixture.new(overrides)
    panelSeq = panelSeq + 1
    local ctx = O.CreatePanel(prefix .. panelSeq, "Bench " .. panelSeq, {})
    return O, rec, ctx
  end

  --- Run `fn` with AceGUI absent, restoring it afterwards. The instance resolves AceGUI once, at
  --- New() time, so the library has to be built inside this (see tests/test_options_widgets.lua).
  local function withoutAceGUI(fn)
    local saved = T.mocks.__libs["AceGUI-3.0"]
    T.mocks.__libs["AceGUI-3.0"] = nil
    local ok, err = pcall(fn)
    T.mocks.__libs["AceGUI-3.0"] = saved
    if not ok then error(err) end
  end

  --- Reset the kit's id records to a known set: two spells, four items (one uncached, one the client
  --- answers no quality for, the others Common and Legendary), and three currencies, two of which
  --- share a name.
  local function seedIds()
    mocks.clearIdRecords()
    mocks.addIdRecord("spell", 21562, "Power Word: Fortitude", 135987)
    mocks.addIdRecord("spell", 774, "Rejuvenation", 136081)
    mocks.addIdRecord("item", 6948, "Hearthstone", 134414, nil, 1)
    mocks.addIdRecord("item", 2589, "Linen Cloth", 132889, true, 1)
    mocks.addIdRecord("item", 19019, "Thunderfury", 135349, nil, 5)
    mocks.addIdRecord("item", 777001, "Nameless Quality", 1)
    mocks.addIdRecord("currency", 3008, "Valorstones", 5872049)
    mocks.addIdRecord("currency", 2914, "Crest", 5872050)
    mocks.addIdRecord("currency", 2915, "Crest", 5872051)
  end

  --- One IdInput on a throwaway page, recording every onAdd.
  local function inputBench(spec)
    local O, rec, ctx = bench()
    seedIds()
    local added = {}
    spec = spec or {}
    spec.kind = spec.kind or "spell"
    spec.onAdd = spec.onAdd or function(id) added[#added + 1] = id end
    local group, eb, add, status = O.IdInput(ctx, nil, spec)
    return { O = O, rec = rec, ctx = ctx, group = group, eb = eb, add = add, status = status,
             added = added }
  end

  --- Type into an edit box the way AceGUI's does, then press Enter.
  local function typeEnter(eb, text)
    eb:SetText(text)
    eb:__fire("OnEnterPressed", text)
  end

  --- The CONTENT width listBench draws a list into unless the test names another. Comfortably above
  --- every floor in the ID_COLUMNS_MAX table (the widest is two columns in the default style, ~584px
  --- of content), because almost every test below is about how entries PACK and not about what a
  --- canvas can pay for. Declared rather than inherited: the kit's fake ScrollFrame publishes a 400px
  --- `content.original_width` (tests/_kit/mock_base.lua), which the always-shown-scrollbar patch turns
  --- into a 380px content -- narrower than two columns need, so a bench that took the fake's own
  --- number would draw every multi-column case at one column and prove nothing about packing.
  local LIST_BENCH_WIDTH = 1000

  --- One IdList on a throwaway page. `entries` is the host's list; every callback is recorded.
  ---
  --- `contentWidth` is the canvas the list is measured against: a number writes it onto the scroll's
  --- content frame before the list is drawn (`content.width` is the field AceGUI's Flow measures its
  --- children against and the one AceGUI's ScrollFrame writes from OnWidthSet, so setting it is the
  --- harness equivalent of a panel having been laid out that wide), nothing at all takes
  --- LIST_BENCH_WIDTH, and `false` leaves the scroll UNMEASURED -- the state a page drawn before its
  --- panel was ever given a size is in.
  --- `hostOverrides` (minor 29) goes to the DESCRIPTOR rather than to the list: `addonName` is what
  --- the help mark's art ladder resolves LibKa0s-Media-1.0 from, and it is an instance-level field,
  --- so a case about the default glyph has to build its host with one.
  local function listBench(entries, spec, contentWidth, hostOverrides)
    local O, rec, ctx = bench(hostOverrides)
    seedIds()
    local log = { added = {}, removed = {}, toggled = {}, rebuilt = 0 }
    ctx.rebuild = function() log.rebuilt = log.rebuilt + 1 end
    spec = spec or {}
    spec.kind = spec.kind or "spell"
    spec.entries = spec.entries or function() return entries end
    spec.onAdd = function(id) log.added[#log.added + 1] = id end
    spec.onRemove = function(id) log.removed[#log.removed + 1] = id end
    spec.onToggle = function(id, on) log.toggled[#log.toggled + 1] = { id, on } end
    local content = O.EnsureScroll(ctx).content
    -- An explicit branch, not `X and nil or Y`: that idiom cannot yield nil, because `and nil`
    -- makes the whole left side false and control falls through to the right side every time.
    if contentWidth == false then
      content.width = nil        -- the bench answers no width at all: the 'unmeasured' case
    else
      content.width = contentWidth or LIST_BENCH_WIDTH
    end
    local lines = O.IdList(ctx, spec)
    return O, rec, ctx, lines, log
  end

  --- The entry ROWS an IdList actually added to the scroll, in order -- the groups whose first child
  --- is an entry's name or its X, which is every group the list added except the input line. The
  --- returned `lines` table cannot answer this on its own once entries share a row: it has one
  --- element per ENTRY, and at two columns the same row is in it twice.
  local function listRows(O, ctx)
    local rows = {}
    for _, w in ipairs(O.EnsureScroll(ctx).children) do
      local first = w.children and w.children[1]
      if first and (first.type == "InteractiveLabel" or first.type == "Icon") then
        rows[#rows + 1] = w
      end
    end
    return rows
  end

  --- The input group an IdList drew: the first SimpleGroup in the scroll holding an EditBox.
  local function listInput(O, ctx)
    for _, w in ipairs(O.EnsureScroll(ctx).children) do
      if w.children and w.children[1] and w.children[1].type == "EditBox" then
        return w.children[1], w.children[2], w.children[3]
      end
    end
  end

  --- Run `fn(requests)` with every C_Item.RequestLoadItemDataByID counted per id (and in total, as
  --- `requests.total`), on an empty timer queue; the real request is put back however `fn` ends.
  local function countingLoads(fn)
    local requests = { total = 0 }
    local realRequest = mocks.C_Item.RequestLoadItemDataByID
    mocks.C_Item.RequestLoadItemDataByID = function(id)
      requests.total = requests.total + 1
      requests[id] = (requests[id] or 0) + 1
      realRequest(id)
    end
    mocks.__timers = {}
    local ok, err = pcall(fn, requests)
    mocks.C_Item.RequestLoadItemDataByID = realRequest
    assertTrue(ok, tostring(err))
  end

  return {
    bench = bench, withoutAceGUI = withoutAceGUI, seedIds = seedIds,
    inputBench = inputBench, typeEnter = typeEnter, LIST_BENCH_WIDTH = LIST_BENCH_WIDTH,
    listBench = listBench, listRows = listRows, listInput = listInput, countingLoads = countingLoads,
  }
end
