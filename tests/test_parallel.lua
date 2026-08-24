-- tests/test_parallel.lua — the partition the parallel runner fans its suites out over.
--
-- `--jobs N` re-invokes the SAME runner as N children, each given `--shard I/N`, and adds their
-- counts up. Everything about that arrangement is observable and loud except one thing: the
-- partition itself. If `shardRange` drops an index, those suites run NOWHERE and the run is green
-- having tested less than it says; if it repeats one, those cases are counted TWICE and the total
-- goes up while coverage does not. Neither shows up as a failure, which is exactly the shape
-- testing-§12 is about — so the partition is asserted directly rather than inferred from a run.
--
-- The properties below are checked across every (total, shards) pair in a range rather than on a
-- couple of hand-picked cases, because the interesting bugs live at the boundaries: fewer suites
-- than shards, an exact division, and a remainder of exactly one.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local Kit = dofile("tests/_kit/framework.lua")
local shardRange = Kit.__shardRange

--- Every index a full fan-out of `shards` shards covers, in the order the driver would print them.
local function cover(total, shards)
  local seen = {}
  for i = 1, shards do
    local first, last = shardRange(total, i, shards)
    for n = first, last do seen[#seen + 1] = n end
  end
  return seen
end

test("parallel: every suite lands in exactly one shard, for every split", function()
  for total = 0, 24 do
    for shards = 1, 8 do
      local seen = cover(total, shards)
      assertEqual(#seen, total,
        ("total=%d shards=%d covered %d indices, expected %d")
          :format(total, shards, #seen, total))
      local count = {}
      for _, n in ipairs(seen) do count[n] = (count[n] or 0) + 1 end
      for n = 1, total do
        assertEqual(count[n], 1,
          ("total=%d shards=%d: index %d was covered %s times, expected exactly 1")
            :format(total, shards, n, tostring(count[n])))
      end
    end
  end
end)

test("parallel: the shards concatenate back into the original order", function()
  -- This is what lets the driver relay shard 1's output, then shard 2's, and produce a transcript
  -- byte-identical to a serial run. Round-robin assignment would not have this property.
  for total = 0, 24 do
    for shards = 1, 8 do
      local seen = cover(total, shards)
      for i = 1, #seen do
        assertEqual(seen[i], i,
          ("total=%d shards=%d: position %d held index %d — the slices are not contiguous and "
            .. "in order"):format(total, shards, i, seen[i]))
      end
    end
  end
end)

test("parallel: the split is balanced to within one suite", function()
  for total = 1, 24 do
    for shards = 1, 8 do
      local smallest, largest
      for i = 1, shards do
        local first, last = shardRange(total, i, shards)
        local size = last - first + 1
        if not smallest or size < smallest then smallest = size end
        if not largest or size > largest then largest = size end
      end
      assertTrue(largest - smallest <= 1,
        ("total=%d shards=%d: shard sizes span %d..%d — an unbalanced split wastes the fan-out")
          :format(total, shards, smallest, largest))
    end
  end
end)

test("parallel: more shards than suites yields empty shards, not overlapping ones", function()
  -- The driver caps `jobs` at the suite count, so this is defense in depth rather than a live path.
  -- An empty shard must be EMPTY (last < first), never a silent duplicate of a neighbor.
  local first, last = shardRange(3, 5, 5)
  assertTrue(last < first,
    ("shard 5 of 5 over 3 suites must be empty; got %d..%d"):format(first, last))
  assertEqual(#cover(3, 5), 3, "the non-empty shards must still cover every suite exactly once")
end)
