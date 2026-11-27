-- tests/test_verdict_golden.lua -- LibKa0s-Verdict-1.0 against the golden verdict table: the same
-- plain-data table Ka0s Drop Watcher's own tests/test_verdict_golden.lua drives its engine over
-- (DropWatcher#19, its plan task A1), copied here unchanged as tests/fixtures/verdict_golden.lua
-- (its header holds the shape). A move that changes one verdict fails on one side or the other.
--
-- The kernel half (`cases`) runs lib.Evaluate with the case's client named in `opts.client`, so
-- every case runs on either kit profile (the client is the caller's here; a case's `profile` is
-- Drop Watcher's, where the off-spec module initializes on Retail alone). A `collect` case runs
-- lib.Collect.Verdict and a `weights` scorer is lib.Score.WeightsScorer: both land with the
-- collection and score files (plan task B2), and until then each such case is a declared skip.
-- The read half (`me`) lands with the instance API (B2).

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local V = T.mocks.LibStub("LibKa0s-Verdict-1.0")
local GOLDEN = dofile("tests/fixtures/verdict_golden.lua")

-- -- the comparison ----------------------------------------------------------------------------

local function reasonKeys(res)
  local out = {}
  for i, r in ipairs(res.reasons or {}) do out[i] = r.key end
  return out
end

local function expectFields(got, want, label)
  for k, v in pairs(want or {}) do assertEqual(got[k], v, label .. "." .. k) end
end

local function check(res, expect, label)
  if expect.none then
    assertEqual(res, nil, label .. ": no verdict")
    return
  end
  assertTrue(type(res) == "table", label .. ": a verdict")
  assertEqual(res.verdict, expect.verdict, label .. ": verdict")
  assertEqual(table.concat(reasonKeys(res), ","), table.concat(expect.reasonKeys or {}, ","), label .. ": reasons")
  expectFields(res, expect.fields, label)
  for key, detail in pairs(expect.details or {}) do
    local found
    for _, r in ipairs(res.reasons) do if r.key == key then found = r.detail end end
    assertEqual(found, detail, label .. ": " .. key .. " detail")
  end
  if expect.offSpec then
    assertTrue(type(res.offSpec) == "table", label .. ": an off-spec part")
    expectFields(res.offSpec, expect.offSpec, label .. ".offSpec")
  end
end

-- -- the kernel half -----------------------------------------------------------------------------

local function scorerOf(spec)
  if spec == nil then return nil end
  if spec.kind == "table" then
    return function(f) return type(f) == "table" and spec.scores[f.itemID] or nil end
  end
  if spec.kind == "weights" then return V.Score.WeightsScorer(spec.weights) end
  error("unknown scorer kind " .. tostring(spec.kind))
end

local function optsOf(data, client)
  local out = {}
  for k, v in pairs(data or {}) do out[k] = v end
  out.scorer = scorerOf(data and data.scorer)
  out.client = client
  return out
end

local function candidateOf(data)
  if type(data) ~= "table" then return data end
  local out = {}
  for k, v in pairs(data) do out[k] = v end
  if type(data.offSpecGear) == "table" then
    local map = data.offSpecGear
    out.offSpecGear = function(specID) return map[specID] end
  end
  return out
end

-- The file a case needs that has not landed yet, as a declared skip's reason; nil when it runs.
local function pendingOf(case)
  if case.via == "collect" and not V.Collect then
    return "lib.Collect lands with VerdictCollect.lua (Item Search split plan, task B2)"
  end
  local scorer = case.opts and case.opts.scorer
  if scorer and scorer.kind == "weights" and not V.Score then
    return "lib.Score lands with VerdictScore.lua (Item Search split plan, task B2)"
  end
  return nil
end

test("verdict golden: the table is Drop Watcher's, every kernel case named once", function()
  local seen = {}
  for _, case in ipairs(GOLDEN.cases) do
    assertTrue(not seen[case.name], "a case named twice: " .. case.name)
    seen[case.name] = true
    assertTrue(case.client == "retail" or case.client == "forever", case.name .. ": a client")
  end
  assertEqual(#GOLDEN.cases, 48, "the kernel half's 48 cases (DropWatcher plan task A1)")
end)

for _, case in ipairs(GOLDEN.cases) do
  test("verdict golden kernel: " .. case.name, function()
    local res
    if case.via == "collect" then
      res = V.Collect.Verdict(case.facts, case.forced == true)
    else
      res = V.Evaluate(case.facts, candidateOf(case.candidate), optsOf(case.opts, case.client))
    end
    check(res, case.expect, case.name)
  end, pendingOf(case))
end
