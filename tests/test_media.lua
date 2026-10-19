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

--- The folder one icon set's art sits in, from the repo root.
local function setDir(set)
  if set.dir == "" then return ICON_DIR end
  return ICON_DIR .. "/" .. set.dir
end

--- The set a catalog name belongs to: the one whose prefix it carries, or the unprefixed set.
local function setOf(name)
  local prefix = name:match("^(%l+:)")
  for _, set in ipairs(media.ICON_SETS) do
    if set.prefix == (prefix or "") then return set end
  end
  return nil
end

--- The first catalog name carrying `prefix`.
local function firstWith(prefix)
  for _, name in ipairs(media.ICONS) do
    if name:sub(1, #prefix) == prefix then return name end
  end
  return nil
end

test("media: ICON_SETS names the three sets, each with a prefix, a folder and a license", function()
  -- red under: minor 4, which had one set and no table describing it.
  assertTrue(type(media.ICON_SETS) == "table", "ICON_SETS is missing")
  local ids = {}
  for i, set in ipairs(media.ICON_SETS) do
    ids[i] = set.id
    assertTrue(type(set.prefix) == "string" and type(set.dir) == "string",
      "set " .. tostring(set.id) .. " needs a prefix and a dir")
    assertTrue(type(set.label) == "string" and set.label ~= "", "set " .. set.id .. " has no label")
    assertTrue(type(set.license) == "string" and set.license ~= "",
      "set " .. set.id .. " has no license file")
  end
  assertEqual(table.concat(ids, ","), "open-iconic,phosphor,game-icons")
  assertEqual(media.ICON_SETS[1].prefix, "", "the first set is the unprefixed one")
  assertEqual(media.ICON_SETS[2].prefix, "ph:")
  assertEqual(media.ICON_SETS[3].prefix, "gi:")
end)

test("media: every name in ICONS has a file, and every file has a name, in every set", function()
  -- red under: minor 4's listing, which read media/icons/ one level deep and so skipped every
  -- subfolder without saying so -- the new sets' art would have been unchecked.
  local named = {}
  for _, name in ipairs(media.ICONS) do
    local set = setOf(name)
    assertTrue(set ~= nil, "ICONS names '" .. name .. "', whose prefix no set claims")
    if set then named[set.id .. "/" .. name:sub(#set.prefix + 1)] = true end
  end

  for _, set in ipairs(media.ICON_SETS) do
    local dir = setDir(set)
    local files = listing(dir)
    assertTrue(files ~= nil and next(files) ~= nil,
      "could not list " .. dir .. "; this gate must not pass blind")
    for key in pairs(named) do
      local id, base = key:match("^([^/]+)/(.+)$")
      if id == set.id then
        assertTrue(files[base .. ".tga"] == true,
          "ICONS names '" .. set.prefix .. base .. "' but " .. dir .. "/" .. base .. ".tga is not there")
      end
    end
    for file in pairs(files or {}) do
      local base = file:match("^(.+)%.tga$")
      if base then
        assertTrue(named[set.id .. "/" .. base] == true,
          dir .. "/" .. file .. " ships but nothing in ICONS names it")
      end
    end
  end
end)

test("media: each icon set's license ships beside its art", function()
  -- The notice has to travel with the bytes: a consumer vendors this folder wholesale and never
  -- visits this repo. Open Iconic and Phosphor are MIT; Game-icons is CC BY 3.0, which also needs
  -- the author of every mark and a statement of what was changed, so AUTHORS.txt ships with it.
  for _, set in ipairs(media.ICON_SETS) do
    local files = listing(setDir(set))
    assertTrue(files ~= nil and files[set.license] == true,
      set.license .. " is missing from " .. setDir(set))
  end
  local gi = listing(ICON_DIR .. "/game-icons")
  assertTrue(gi ~= nil and gi["AUTHORS.txt"] == true, "game-icons/AUTHORS.txt is missing")
end)

test("media: the catalog holds every set, not just the first", function()
  -- red under: minor 4's 113 names.
  assertTrue(#media.ICONS > 5000, "ICONS holds " .. #media.ICONS .. " names")
  local per = {}
  for _, name in ipairs(media.ICONS) do
    local set = setOf(name)
    if set then per[set.id] = (per[set.id] or 0) + 1 end
  end
  assertEqual(per["open-iconic"], 224, "113 semantic keys plus the 111 other Open Iconic marks")
  assertTrue((per.phosphor or 0) > 1000, "Phosphor Fill holds " .. tostring(per.phosphor))
  assertTrue((per["game-icons"] or 0) > 3500, "Game-icons holds " .. tostring(per["game-icons"]))
end)

test("media: no Phosphor brand mark ships", function()
  -- The `*-logo` marks are other people's trademarks, not glyphs; the generator drops them.
  for _, name in ipairs(media.ICONS) do
    assertTrue(not (name:find("^ph:") and name:find("%-logo$")), name .. " is a brand mark")
  end
end)

test("media: the first 113 names are minor 4's, in minor 4's order", function()
  -- A consumer stores the full texture path in SavedVariables and share strings, so an existing
  -- name never moves, and the hand-written list stays first.
  assertEqual(media.ICONS[1], "close")
  assertEqual(media.ICONS[113], "shield")
  assertTrue(media.ICONS[114] ~= nil and media.ICONS[114]:find(":") == nil,
    "the other Open Iconic marks follow, unprefixed")
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

test("media: re-attaching the generated catalog never doubles a name, and keeps the table", function()
  -- The paired-file guard lets a newer MediaIcons.lua run again against the same shell, so the
  -- attach must be idempotent; and a host that captured ICONS once must still read all of it.
  local icons, before = media.ICONS, #media.ICONS
  local names, authors = {}, {}
  for i = 114, before do
    names[#names + 1] = icons[i]
    authors[icons[i]] = media.IconAuthor(icons[i])
  end
  media.__SetGeneratedIcons(names, authors)
  media.__SetGeneratedIcons(names, authors)
  assertTrue(media.ICONS == icons, "the table was replaced")
  assertEqual(#media.ICONS, before, "a second attach doubled the catalog")
  assertEqual(media.ICONS[113], "shield")
  local gi = firstWith("gi:")
  assertEqual(media.IconAuthor(gi), authors[gi])
end)

test("media: a prefixed name resolves into its set's folder", function()
  -- red under: minor 4, whose path was the name itself under media\icons, with no subfolder.
  assertEqual(media.Icon("MythicMeters", "ph:sword"),
    "Interface\\AddOns\\MythicMeters\\libs\\LibKa0s\\media\\icons\\phosphor\\sword")
  local gi = firstWith("gi:")
  assertTrue(gi ~= nil, "no gi: name in ICONS")
  if not gi then return end
  assertEqual(media.Icon("MythicMeters", gi),
    "Interface\\AddOns\\MythicMeters\\libs\\LibKa0s\\media\\icons\\game-icons\\" .. gi:sub(4))
  -- and the file behind it is on disk
  local rel = media.Icon("MythicMeters", "ph:sword"):gsub("\\", "/")
    :gsub("^Interface/AddOns/MythicMeters/libs/LibKa0s/", "")
  local fh = io.open("LibKa0s/" .. rel .. ".tga", "rb")
  assertTrue(fh ~= nil, "no file at LibKa0s/" .. rel .. ".tga")
  if fh then fh:close() end
end)

test("media: an unknown prefix, or a set's name without its prefix, answers nil", function()
  assertEqual(media.Icon("MythicMeters", "zz:sword"), nil)
  assertEqual(media.Icon("MythicMeters", "ph:nosuchmark"), nil)
  assertEqual(media.Icon("MythicMeters", "sword"), nil, "Phosphor's sword is ph:sword")
  assertEqual(media.Icon("MythicMeters", "close"),
    "Interface\\AddOns\\MythicMeters\\libs\\LibKa0s\\media\\icons\\close", "close never moves")
end)

test("media: IconAuthor names a Game-icons mark's author, and nothing else's", function()
  -- red under: minor 4, which had no IconAuthor. CC BY attribution is per author.
  assertTrue(type(media.IconAuthor) == "function", "IconAuthor is missing")
  if type(media.IconAuthor) ~= "function" then return end
  local gi = firstWith("gi:")
  assertTrue(gi ~= nil, "no gi: name in ICONS")
  for _, name in ipairs(media.ICONS) do
    if name:find("^gi:") then
      local who = media.IconAuthor(name)
      assertTrue(type(who) == "string" and who ~= "", name .. " has no author")
    end
  end
  assertEqual(media.IconAuthor("ph:sword"), nil)
  assertEqual(media.IconAuthor("close"), nil)
  assertEqual(media.IconAuthor("gi:nosuchmark"), nil)
  assertEqual(media.IconAuthor(nil), nil)
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
    IsValid = function(_, kind, key)
      return byKind[kind] ~= nil and byKind[kind][key] ~= nil
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

--- A LibSharedMedia fake that behaves as the real one does on a NON-WESTERN client: a font with no
--- langmask is refused (LibSharedMedia-3.0's `Register` returns false and stores nothing), and so is
--- a font whose mask lacks the client's locale bit. `clientBit` is that bit (2 for ruRU, 1 for
--- koKR, 128 for a western client), `store` records what actually landed, which `IsValid` reads,
--- and `masks` records the langmask each font was offered.
local function localeLSM(clientBit, store, masks)
  return {
    MediaType = { FONT = "font", STATUSBAR = "statusbar" },
    LOCALE_BIT_koKR = 1, LOCALE_BIT_ruRU = 2, LOCALE_BIT_zhCN = 4, LOCALE_BIT_zhTW = 8,
    LOCALE_BIT_western = 128,
    Register = function(_, kind, key, path, langmask)
      if kind == "font" then
        masks[key] = langmask or "none"
        if not langmask or math.floor(langmask / clientBit) % 2 ~= 1 then return false end
      end
      store[kind] = store[kind] or {}
      if store[kind][key] then return false end
      store[kind][key] = path
      return true
    end,
    IsValid = function(_, kind, key)
      return store[kind] ~= nil and store[kind][key] ~= nil
    end,
  }
end

test("media: RegisterLSM flags the face western+ruRU, so a ruRU client keeps it", function()
  -- red under: minor 3, which passed no langmask. LSM refuses that on every non-western client,
  -- and the count still said 1.
  local store, masks = {}, {}
  T.mocks.__libs["LibSharedMedia-3.0"] = localeLSM(2, store, masks)
  local fonts = media.RegisterLSM("MythicMeters")
  T.mocks.__libs["LibSharedMedia-3.0"] = nil

  assertEqual(masks["JetBrains Mono"], 128 + 2, "the face must be flagged western + ruRU")
  assertEqual(store.font and store.font["JetBrains Mono"],
    media.Font("MythicMeters", "JetBrains Mono"), "the face did not land in LSM")
  assertEqual(fonts, 1)
end)

test("media: RegisterLSM counts only what LibSharedMedia kept", function()
  -- red under: minor 3, which counted every Register call whatever it answered. A koKR client
  -- refuses the face, which has no Hangul, so the count is 0 although Register was asked.
  local store, masks = {}, {}
  T.mocks.__libs["LibSharedMedia-3.0"] = localeLSM(1, store, masks)
  local fonts = media.RegisterLSM("MythicMeters")
  T.mocks.__libs["LibSharedMedia-3.0"] = nil
  assertTrue(masks["JetBrains Mono"] ~= nil, "Register was never asked")
  assertEqual(fonts, 0, "a refused face is not a registered one")

  -- An LSM that refuses everything, statusbars included, answers 0, 0.
  T.mocks.__libs["LibSharedMedia-3.0"] = {
    MediaType = { FONT = "font", STATUSBAR = "statusbar" },
    Register = function() return false end,
    IsValid = function() return false end,
  }
  local f2, b2 = media.RegisterLSM("MythicMeters")
  T.mocks.__libs["LibSharedMedia-3.0"] = nil
  assertEqual(f2, 0)
  assertEqual(b2, 0)
end)

test("media: RegisterLSM counts a face another copy registered first", function()
  -- LSM's first registration wins and a second answers false. The face is still in every dropdown,
  -- so it counts: the question is whether LSM has it, not whether this call put it there.
  local first = "Interface\\AddOns\\Other\\libs\\LibKa0s\\media\\fonts\\JetBrainsMono-Regular.ttf"
  local store, masks = { font = { ["JetBrains Mono"] = first } }, {}
  T.mocks.__libs["LibSharedMedia-3.0"] = localeLSM(128, store, masks)
  local fonts = media.RegisterLSM("MythicMeters")
  T.mocks.__libs["LibSharedMedia-3.0"] = nil
  assertEqual(fonts, 1)
  assertEqual(store.font["JetBrains Mono"], first, "the first registration stays")
end)

test("media: an LSM without the locale bits gets a plain Register", function()
  -- The langmask argument is only offered when LSM publishes the bits to build it from.
  local argc = {}
  T.mocks.__libs["LibSharedMedia-3.0"] = {
    MediaType = { FONT = "font", STATUSBAR = "statusbar" },
    Register = function(_, kind, ...)
      if kind == "font" then argc[#argc + 1] = select("#", ...) end
      return true
    end,
    IsValid = function() return true end,
  }
  local fonts = media.RegisterLSM("MythicMeters")
  T.mocks.__libs["LibSharedMedia-3.0"] = nil
  assertEqual(fonts, 1)
  assertEqual(argc[1], 2, "key and path, and no langmask argument")
end)

test("media: an LSM without IsValid counts every Register call, as minor 3 did", function()
  -- red under: minor 4 before this fix, which called LSM:IsValid unguarded and raised
  -- "attempt to call method 'IsValid' (a nil value)". Consumers' test harnesses fake LSM with
  -- only Register/Fetch/List/HashTable and call RegisterLSM at file load, so re-vendoring must not
  -- break them: with no IsValid to ask, a Register call counts, which is what minor 3 answered.
  local registered = 0
  T.mocks.__libs["LibSharedMedia-3.0"] = {
    MediaType = { FONT = "font", STATUSBAR = "statusbar" },
    Register = function() registered = registered + 1 end,   -- answers nothing, like the fakes
  }
  local ok, fonts, bars = pcall(media.RegisterLSM, "MythicMeters")
  T.mocks.__libs["LibSharedMedia-3.0"] = nil
  assertTrue(ok, "RegisterLSM raised on an LSM without IsValid: " .. tostring(fonts))
  assertEqual(fonts + bars, registered, "every Register call counts when IsValid is absent")
  assertEqual(fonts, 1)
end)

test("media: no LibSharedMedia is 0 registrations, not an error", function()
  -- An addon that does not carry LSM still wants its icons, so this degrades rather than raising.
  T.mocks.__libs["LibSharedMedia-3.0"] = nil
  local fonts, bars = media.RegisterLSM("MythicMeters")
  assertEqual(fonts, 0)
  assertEqual(bars, 0)
end)
