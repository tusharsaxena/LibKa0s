-- Loads library source files headlessly: each file's chunk is called with no arguments and given
-- an environment where WoW globals resolve to the mock set, falling back to _G.

local Loader = {}

local function makeEnv(mocks)
  return setmetatable({}, {
    __index = function(_, k)
      local v = mocks[k]
      if v ~= nil then return v end
      return _G[k]
    end,
    -- Writes land in _G so the host's SavedVariables global and any StaticPopupDialogs
    -- registration behave like the real client.
    __newindex = function(_, k, v) _G[k] = v end,
  })
end

function Loader.load(path, mocks)
  local chunk, err = loadfile(path)
  if not chunk then error("loadfile(" .. path .. "): " .. tostring(err)) end
  setfenv(chunk, makeEnv(mocks))
  return chunk()
end

--- Load library source held in a string rather than read straight off disk. The multi-copy tests
--- need two builds of the same file at different LibStub minors, which only exists as a patched
--- copy of the real source — loading the real file twice would just re-run minor 1.
function Loader.loadSource(src, chunkname, mocks)
  local chunk, err = loadstring(src, chunkname)
  if not chunk then error("loadstring(" .. tostring(chunkname) .. "): " .. tostring(err)) end
  setfenv(chunk, makeEnv(mocks))
  return chunk()
end

function Loader.loadAll(paths, mocks)
  for _, p in ipairs(paths) do
    Loader.load(p, mocks)
  end
end

return Loader
