-- tests/test_media.lua — the shipped art and type, and the paths that reach them.
--
-- THE CASE THAT MATTERS MOST IS THE INVENTORY ONE. Every other failure this module can produce is
-- visible: a wrong path draws nothing, a nil answer is a nil answer. But a name in `ICONS` with no
-- file behind it, or a file with no name in front of it, is invisible from both sides — the caller
-- gets a plausible path to a texture that does not exist, and a texture that does not exist draws
-- nothing and RAISES NOTHING in the client. So the catalog is checked against the directory in
-- both directions, which is the one thing no amount of reading the source can tell you.

local T = _G.LK_TEST
local media = T.media
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local ICON_DIR = "LibKa0s/media/icons"
local FONT_DIR = "LibKa0s/media/fonts"

--- The basenames on disk under `dir`, as a set. Lua 5.1 has no directory API and this repo does not
--- depend on LuaFileSystem, so the listing shells out — the same bargain tests/_kit/vendor_sync.lua
--- strikes for the same reason.
local function listing(dir)
  local names = {}
  local pipe = io.popen(('ls -A "%s" 2>/dev/null'):format(dir))
  if not pipe then return nil end
  for line in pipe:lines() do
    local name = line:gsub("[\r\n]+$", "")
    if name ~= "" then names[name] = true end
  end
  pipe:close()
  return names
end

-- ── the catalog against the directory ────────────────────────────────────────────────────

test("media: every name in ICONS has a file, and every file has a name", function()
  local files = listing(ICON_DIR)
  assertTrue(files ~= nil, "could not list " .. ICON_DIR .. "; this gate must not pass blind")

  local named = {}
  for _, name in ipairs(media.ICONS) do
    named[name] = true
    assertTrue(files[name .. ".tga"] == true,
      "ICONS names '" .. name .. "' but " .. ICON_DIR .. "/" .. name .. ".tga is not there")
  end

  for file in pairs(files) do
    local base = file:match("^(.+)%.tga$")
    if base then
      assertTrue(named[base] == true,
        ICON_DIR .. "/" .. file .. " ships but nothing in ICONS names it")
    end
  end
end)

test("media: the icon license ships beside the art", function()
  -- The art is Open Iconic under MIT, and the notice has to travel with the bytes: a consumer
  -- vendors this folder wholesale and never visits this repo.
  local files = listing(ICON_DIR)
  assertTrue(files ~= nil and files["LICENSE-open-iconic.txt"] == true,
    "LICENSE-open-iconic.txt is missing from " .. ICON_DIR)
end)

test("media: every font in FONTS ships with its license", function()
  local files = listing(FONT_DIR)
  assertTrue(files ~= nil, "could not list " .. FONT_DIR)
  local count = 0
  for name, entry in pairs(media.FONTS) do
    count = count + 1
    assertTrue(files[entry.file] == true,
      "FONTS['" .. name .. "'] names " .. entry.file .. ", which is not in " .. FONT_DIR)
    assertTrue(files[entry.license] == true,
      "FONTS['" .. name .. "'] names " .. entry.license .. ", which is not in " .. FONT_DIR)
  end
  assertTrue(count > 0, "FONTS is empty")
end)

test("media: ICONS holds no duplicate", function()
  -- The array is grouped by what a mark is FOR, so one name can be added twice under two headings
  -- without looking wrong. The set built from it would swallow that silently.
  local seen = {}
  for _, name in ipairs(media.ICONS) do
    assertTrue(seen[name] == nil, "ICONS lists '" .. name .. "' twice")
    seen[name] = true
  end
end)

-- ── the paths ──────────────────────────────────────────────────────────────────────────────

test("media: Icon builds the vendored path, WITHOUT the extension", function()
  -- The client appends it, and the consumer that adopted this first records a live-client failure
  -- from the spelling that carries it. A texture that does not load draws nothing and raises
  -- nothing, so this is not a preference.
  -- red under: minor 1, which answered "...\\settings.tga".
  assertEqual(media.Icon("MythicMeters", "settings"),
    "Interface\\AddOns\\MythicMeters\\libs\\LibKa0s\\media\\icons\\settings")
end)

test("media: the file behind an icon path is still <name>.tga on disk", function()
  -- The extensionless path and the file it resolves to are two different strings, and the gap
  -- between them is exactly where a rename would hide.
  local path = media.Icon("MythicMeters", "settings")
  local rel = path:gsub("\\", "/"):gsub("^Interface/AddOns/MythicMeters/libs/LibKa0s/", "")
  local fh = io.open("LibKa0s/" .. rel .. ".tga", "rb")
  assertTrue(fh ~= nil, "no file at LibKa0s/" .. rel .. ".tga")
  if fh then fh:close() end
end)

test("media: Font builds the vendored path from the catalog's own filename", function()
  assertEqual(media.Font("MythicMeters", "JetBrains Mono"),
    "Interface\\AddOns\\MythicMeters\\libs\\LibKa0s\\media\\fonts\\JetBrainsMono-Regular.ttf")
end)

test("media: an unknown name answers nil rather than a plausible path", function()
  -- The whole point of the catalog. A misspelt name built into a path yields a texture that does
  -- not load, and a texture that does not load draws nothing and raises nothing.
  assertEqual(media.Icon("MythicMeters", "nosuchicon"), nil)
  assertEqual(media.Icon("MythicMeters", "Settings"), nil, "the lookup is case-sensitive")
  assertEqual(media.Font("MythicMeters", "Comic Sans"), nil)
end)

test("media: a missing addon name answers nil rather than a path into nowhere", function()
  -- `Interface\AddOns\\libs\...` is a real string that resolves to nothing, which is the failure
  -- mode this module exists to remove.
  assertEqual(media.Icon(nil, "settings"), nil)
  assertEqual(media.Icon("", "settings"), nil)
  assertEqual(media.Font(nil, "JetBrains Mono"), nil)
end)

test("media: a consumer that vendors elsewhere passes its own path", function()
  assertEqual(media.Icon("Elsewhere", "close", "Libs\\Ka0s"),
    "Interface\\AddOns\\Elsewhere\\Libs\\Ka0s\\media\\icons\\close")
  assertEqual(media.VENDOR_PATH, "libs\\LibKa0s", "the default is the collection's convention")
end)

-- ── LibSharedMedia ─────────────────────────────────────────────────────────────────────────

test("media: RegisterLSM registers every font under its catalog name", function()
  local registered = {}
  T.mocks.__libs["LibSharedMedia-3.0"] = {
    MediaType = { FONT = "font" },
    Register = function(_, kind, key, path)
      registered[#registered + 1] = { kind = kind, key = key, path = path }
      return true
    end,
  }

  local n = media.RegisterLSM("MythicMeters")
  T.mocks.__libs["LibSharedMedia-3.0"] = nil

  local expected = 0
  for _ in pairs(media.FONTS) do expected = expected + 1 end
  assertEqual(n, expected)
  assertEqual(#registered, expected)
  assertEqual(registered[1].kind, "font")
  assertTrue(media.FONTS[registered[1].key] ~= nil,
    "registered under '" .. tostring(registered[1].key) .. "', which is not a catalog name")
  assertEqual(registered[1].path, media.Font("MythicMeters", registered[1].key))
end)

test("media: no LibSharedMedia is 0 registrations, not an error", function()
  -- An addon that does not carry LSM still wants its icons, so this degrades rather than raising.
  T.mocks.__libs["LibSharedMedia-3.0"] = nil
  assertEqual(media.RegisterLSM("MythicMeters"), 0)
end)
