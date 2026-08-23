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

test("media: every name in TEXTURES has a file, and every file has a name", function()
  -- Same both-directions check the icons get, and it matters more here: a texture name is a LSM key
  -- a PROFILE STORES, so a catalog entry with no file behind it is a saved setting that resolves to
  -- nothing on the next login.
  local files = listing("LibKa0s/media/textures")
  assertTrue(files ~= nil, "could not list LibKa0s/media/textures")

  local named = {}
  for name, entry in pairs(media.TEXTURES) do
    named[entry.file] = true
    assertTrue(files[entry.file] == true,
      "TEXTURES['" .. name .. "'] names " .. entry.file .. ", which is not on disk")
  end
  for file in pairs(files) do
    if file:match("%.tga$") then
      assertTrue(named[file] == true, "media/textures/" .. file .. " ships but nothing names it")
    end
  end
end)

test("media: Texture builds the vendored path, WITHOUT the extension", function()
  -- One rule for every path this module answers; see Icon.
  assertEqual(media.Texture("MythicMeters", "Ka0s Underline 2"),
    "Interface\\AddOns\\MythicMeters\\libs\\LibKa0s\\media\\textures\\underline-2")
  assertEqual(media.Texture("MythicMeters", "Ka0s Gradient"),
    "Interface\\AddOns\\MythicMeters\\libs\\LibKa0s\\media\\textures\\gradient")
  assertEqual(media.Texture("MythicMeters", "Ka0s Sideline 3"), nil)
  assertEqual(media.Texture(nil, "Ka0s Gradient"), nil)
end)

test("media: the texture keys are the labels a player reads", function()
  -- The dropdown shows the key. A key that reads like a filename -- `underline-2` -- is a setting
  -- nobody can pick on purpose, so the pairing between label and file is asserted rather than
  -- assumed: every key is prefixed, spaced and title-cased, and every file is not.
  local n = 0
  for name, entry in pairs(media.TEXTURES) do
    n = n + 1
    assertTrue(name:find("^Ka0s ") ~= nil, "'" .. name .. "' does not read as a Ka0s label")
    assertTrue(entry.file:find("%u") == nil and entry.file:find(" ") == nil,
      "'" .. entry.file .. "' does not read as a path")
  end
  assertEqual(n, 7, "the family is one gradient plus three underlines and three overlines")
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

test("media: RegisterLSM registers every font and every texture, by catalog name", function()
  local byKind = { font = {}, statusbar = {} }
  T.mocks.__libs["LibSharedMedia-3.0"] = {
    MediaType = { FONT = "font", STATUSBAR = "statusbar" },
    Register = function(_, kind, key, path)
      byKind[kind] = byKind[kind] or {}
      byKind[kind][key] = path
      return true
    end,
  }

  local fonts, bars = media.RegisterLSM("MythicMeters")
  T.mocks.__libs["LibSharedMedia-3.0"] = nil

  local wantFonts, wantBars = 0, 0
  for name in pairs(media.FONTS) do
    wantFonts = wantFonts + 1
    assertEqual(byKind.font[name], media.Font("MythicMeters", name),
      "the face registered under '" .. name .. "' is not the one the catalog names")
  end
  -- THE KEY IS THE LABEL, and this is the assertion that keeps it that way: a profile stores the
  -- key, so registering a texture under its filename would store a setting that reads as a path in
  -- every dropdown that shows it.
  for name in pairs(media.TEXTURES) do
    wantBars = wantBars + 1
    assertEqual(byKind.statusbar[name], media.Texture("MythicMeters", name),
      "the texture registered under '" .. name .. "' is not the one the catalog names")
  end
  assertEqual(fonts, wantFonts)
  assertEqual(bars, wantBars)
end)

test("media: no LibSharedMedia is 0 registrations, not an error", function()
  -- An addon that does not carry LSM still wants its icons, so this degrades rather than raising.
  T.mocks.__libs["LibSharedMedia-3.0"] = nil
  local fonts, bars = media.RegisterLSM("MythicMeters")
  assertEqual(fonts, 0)
  assertEqual(bars, 0)
end)
