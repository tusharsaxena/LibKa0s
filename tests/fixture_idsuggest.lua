-- tests/fixture_idsuggest.lua — the bench the IdInput-suggestion suites share:
-- tests/test_options_idsuggest.lua (ordering, ranks, picking, closing, sources and based host
-- kinds) and tests/test_options_idsuggest_frames.lua (the dropdown's frames).
--
-- Moved out of tests/test_options_idsuggest.lua, unchanged but for the panel name, when the
-- 2026-09-26 automated-tests sweep split that suite on its case seams. One copy rather than two, for
-- the reason tests/fixture_ids.lua gives.
--
-- Loaded as `dofile("tests/fixture_idsuggest.lua")(prefix)`: `prefix` names the throwaway panels,
-- so two suites' benches never hand CreatePanel the same frame name.

local T = _G.LK_TEST
local test = T.test
local Fixture = dofile("tests/fixture_options.lua")
local mocks = T.mocks

local ZEPHYR = "Potion of the Hushed Zephyr"

return function(prefix)
  --- A case with every frame CreateFrame hands out recorded (`made`), on empty id records and an
  --- empty timer queue, both emptied again however it ends.
  local function suggestCase(name, fn)
    test(name, function()
      local real = mocks.CreateFrame
      local made = {}
      mocks.CreateFrame = function(...)
        local f = real(...)
        made[#made + 1] = f
        return f
      end
      mocks.clearIdRecords()
      mocks.__timers = {}
      local ok, err = pcall(fn, made)
      mocks.CreateFrame = real
      mocks.clearIdRecords()
      mocks.__timers = {}
      if not ok then error(err, 0) end
    end)
  end

  local seq = 0
  --- One IdInput on a fresh instance and page, recording every onAdd.
  local function input(made, spec, O)
    O = O or Fixture.new()
    seq = seq + 1
    local ctx = O.CreatePanel(prefix .. seq, "Suggest " .. seq, {})
    local added = {}
    spec.onAdd = spec.onAdd or function(id) added[#added + 1] = id end
    local _, eb, add, status = O.IdInput(ctx, nil, spec)
    return { O = O, ctx = ctx, eb = eb, add = add, status = status, added = added, made = made }
  end

  --- The dropdown: the one frame carrying `rows`.
  local function dropdown(made)
    for _, f in ipairs(made) do
      if type(f.rows) == "table" then return f end
    end
  end

  local function shown(b)
    local dd = dropdown(b.made)
    return dd ~= nil and dd:IsShown()
  end

  --- Type into the box as AceGUI's EditBox reports it, then let the debounce run.
  local function typeText(b, text)
    b.eb:SetText(text)
    b.eb:__fire("OnTextChanged", text)
    mocks.__fireTimers()
  end

  --- The ids the dropdown's visible rows carry, in order; "" while it is hidden.
  local function shownIds(b)
    if not shown(b) then return "" end
    local ids = {}
    for _, row in ipairs(dropdown(b.made).rows) do
      if row:IsShown() and row.entry then ids[#ids + 1] = row.entry.id end
    end
    return table.concat(ids, ",")
  end

  local function press(b, key) b.eb.editbox:__fire("OnArrowPressed", key) end

  --- The three ranks, cached, with their crafted-quality tiers.
  local function seedZephyr()
    for tier, id in ipairs({ 191395, 191396, 191397 }) do
      mocks.addIdRecord("item", id, ZEPHYR, 4638, nil, 1)
      mocks.setCraftedQuality(id, tier)
    end
  end
  local function zephyrs() return { 191397, 191395, 191396 } end

  --- ConsumableMaster's shape: digits taken itself, a name handed to O.ResolveId("item"), and any
  --- id `refuse` names refused as not found. `extra` fields go onto the kind.
  local function hostKind(O, extra, refuse)
    local k = { noun = "item", plural = "items", resolve = function(text, candidates)
      local id, name = tonumber(text:match("^%d+$")), nil
      if not id then id, name = O.ResolveId("item", text, candidates) end
      if id == nil then return nil, name end
      if refuse and refuse[id] then return nil, "notFound" end
      return id, name
    end }
    for key, v in pairs(extra or {}) do k[key] = v end
    return k
  end

  return {
    ZEPHYR = ZEPHYR, suggestCase = suggestCase, input = input, dropdown = dropdown, shown = shown,
    typeText = typeText, shownIds = shownIds, press = press, seedZephyr = seedZephyr,
    zephyrs = zephyrs, hostKind = hostKind,
  }
end
