-- tests/fixture_guard.lua — a stand-in runner for tests/test_kit_limits.lua.
--
-- It loads the kit the way every runner does, as its first act, so whatever the guard does on load
-- happens to it -- and then does one small, observable thing, chosen by its first argument. Not a
-- suite (no `test_` prefix), so the inventory gate neither expects it nor runs it.

dofile("tests/_kit/framework.lua")

local mode = arg[1]
if mode == "report" then
  print("depth=" .. tostring(os.getenv("KA0S_KIT_DEPTH")) .. " args=" .. table.concat(arg, ","))
elseif mode == "recurse" then
  -- The failure the guard exists for: a runner that starts itself, through a bare io.popen that
  -- knows nothing about the guard.
  print("depth=" .. tostring(os.getenv("KA0S_KIT_DEPTH")))
  local p = io.popen(arg[-1] .. " tests/fixture_guard.lua recurse 2>&1")
  io.write(p:read("*a"))
  p:close()
elseif mode == "exit" then
  os.exit(tonumber(arg[2]))
elseif mode == "loop" then
  while true do end
end
