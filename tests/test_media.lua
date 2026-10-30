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

-- How many faces FONTS ships, and how many of them draw Cyrillic and so land on a ruRU client. Every
-- count below reads these, so a payload change moves two numbers here rather than one per case.
-- Minor 10: JetBrains Mono, fifteen skin faces (Oxanium's two and Fira Sans Regular left; Fira Sans
-- Medium and Prototype came), of which twelve and JetBrains Mono draw Cyrillic.
local FONT_COUNT, RU_COUNT = 16, 13

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

test("media: every name in TEXTURES, BORDERS and BACKGROUNDS has a file, and every file a name", function()
  -- Same both-directions check the icons get, and it matters more here: a texture name is a LSM key
  -- a PROFILE STORES, so a catalog entry with no file behind it is a saved setting that resolves to
  -- nothing on the next login. The three catalogs share the folder (minor 6), so a file counts as
  -- named when any of them names it.
  local files = listing("LibKa0s/media/textures")
  assertTrue(files ~= nil, "could not list LibKa0s/media/textures")

  local named = {}
  for _, catalog in ipairs({ "TEXTURES", "BORDERS", "BACKGROUNDS" }) do
    assertTrue(type(media[catalog]) == "table", catalog .. " is missing")
    for name, entry in pairs(media[catalog] or {}) do
      named[entry.file] = true
      assertTrue(files[entry.file] == true,
        catalog .. "['" .. name .. "'] names " .. entry.file .. ", which is not on disk")
    end
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
  assertEqual(n, 15, "one gradient, three underlines, three overlines, Ka0s Default's bar and seven skins' bars")
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
  assertEqual(fonts, RU_COUNT, "JetBrains Mono and the Cyrillic skin faces; Atkinson and Prototype are western only")
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
  assertEqual(fonts, FONT_COUNT, "JetBrains Mono, held by the other copy, and every skin face")
  assertEqual(store.font["JetBrains Mono"], first, "the first registration stays")
end)

test("media: RegisterLSM never offers a key LibSharedMedia already holds", function()
  -- red under: minor 6, which called Register for every key and read IsValid afterwards. The real
  -- LibSharedMedia-3.0 validates a font, border or background FILE before its first-registration-
  -- wins check, and reports a missing one through geterrorhandler. So a later host whose vendored
  -- copy predates the key's art, running a newer copy's RegisterLSM, offered a path into its own
  -- folder where the file is absent, and the player's BugSack filled with "Attempt to register an
  -- invalid font". This fake errors as the real one does: unknown file first, held key second.
  local held, files, calls, errors = {}, {}, {}, {}
  local function hold(kind, key, path)
    held[kind] = held[kind] or {}
    held[kind][key] = path
    files[path] = true
  end
  for name in pairs(media.FONTS) do hold("font", name, media.Font("Other", name)) end
  for name in pairs(media.BORDERS) do hold("border", name, media.Border("Other", name)) end
  for name in pairs(media.BACKGROUNDS) do hold("background", name, media.Background("Other", name)) end
  T.mocks.__libs["LibSharedMedia-3.0"] = {
    MediaType = { FONT = "font", STATUSBAR = "statusbar", BORDER = "border", BACKGROUND = "background" },
    Register = function(_, kind, key, path)
      calls[#calls + 1] = kind .. ":" .. key
      if kind ~= "statusbar" and not files[path] then
        errors[#errors + 1] = "Attempt to register an invalid " .. kind .. " ('" .. path .. "')"
        return false
      end
      held[kind] = held[kind] or {}
      if held[kind][key] then return false end
      held[kind][key] = path
      return true
    end,
    IsValid = function(_, kind, key) return held[kind] ~= nil and held[kind][key] ~= nil end,
  }
  local fonts, bars, borders, backgrounds = media.RegisterLSM("Later")
  T.mocks.__libs["LibSharedMedia-3.0"] = nil

  assertEqual(#errors, 0, "LSM reported an error: " .. tostring(errors[1]))
  for _, call in ipairs(calls) do
    assertTrue(call:find("^statusbar:") ~= nil, "Register was offered a held key: " .. call)
  end
  assertEqual(#calls, 15, "only the fifteen statusbars, which nobody held, are offered")
  assertEqual(fonts, FONT_COUNT, "a held face still counts")
  assertEqual(bars, 15)
  assertEqual(borders, 1, "the held Glass border still counts")
  assertEqual(backgrounds, 1, "the held Glass fill still counts")
  assertEqual(held.font["Ka0s Inter"], media.Font("Other", "Ka0s Inter"), "the first registration stays")
  assertEqual(held.statusbar["Ka0s Gradient"], media.Texture("Later", "Ka0s Gradient"),
    "a key nobody held still lands, at the caller's own folder")
end)

test("media: an LSM without the locale bits gets a plain Register", function()
  -- The langmask argument is only offered when LSM publishes the bits to build it from.
  -- IsValid answers from what landed, not a constant true: from minor 7 a key LSM already holds is
  -- never offered, so an always-true IsValid would see no Register call at all.
  local argc, landed = {}, {}
  T.mocks.__libs["LibSharedMedia-3.0"] = {
    MediaType = { FONT = "font", STATUSBAR = "statusbar" },
    Register = function(_, kind, ...)
      if kind == "font" then argc[#argc + 1] = select("#", ...) end
      landed[kind .. ":" .. tostring((...))] = true
      return true
    end,
    IsValid = function(_, kind, key) return landed[kind .. ":" .. key] == true end,
  }
  local fonts = media.RegisterLSM("MythicMeters")
  T.mocks.__libs["LibSharedMedia-3.0"] = nil
  assertEqual(fonts, FONT_COUNT)
  assertEqual(#argc, FONT_COUNT)
  for i = 1, #argc do assertEqual(argc[i], 2, "key and path, and no langmask argument") end
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
  local ok, fonts, bars, borders, backgrounds = pcall(media.RegisterLSM, "MythicMeters")
  T.mocks.__libs["LibSharedMedia-3.0"] = nil
  assertTrue(ok, "RegisterLSM raised on an LSM without IsValid: " .. tostring(fonts))
  assertEqual(fonts + bars + borders + backgrounds, registered,
    "every Register call counts when IsValid is absent")
  assertEqual(fonts, FONT_COUNT)
end)

test("media: no LibSharedMedia is 0 registrations, not an error", function()
  -- An addon that does not carry LSM still wants its icons, so this degrades rather than raising.
  T.mocks.__libs["LibSharedMedia-3.0"] = nil
  local fonts, bars, borders, backgrounds = media.RegisterLSM("MythicMeters")
  assertEqual(fonts, 0)
  assertEqual(bars, 0)
  assertEqual(borders, 0)
  assertEqual(backgrounds, 0)
end)

-- ── the skin faces and the Glass art (minor 6) ───────────────────────────────────────────

-- The OFL faces the skins name (minor 8: a family per skin, the owner's round-5 notes), by
-- LSM key: the file behind each, its license, and whether it draws Cyrillic.
local SKIN_FACES = {
  ["Ka0s Inter"]              = { file = "Inter-Regular.ttf", license = "Inter-OFL.txt", ru = true },
  ["Ka0s Inter SemiBold"]     = { file = "Inter-SemiBold.ttf", license = "Inter-OFL.txt", ru = true },
  ["Ka0s Nunito"]             = { file = "Nunito-Regular.ttf", license = "Nunito-OFL.txt", ru = true },
  ["Ka0s Nunito SemiBold"]    = { file = "Nunito-SemiBold.ttf", license = "Nunito-OFL.txt", ru = true },
  ["Ka0s Vollkorn"]           = { file = "Vollkorn-Regular.ttf", license = "Vollkorn-OFL.txt", ru = true },
  ["Ka0s Vollkorn Bold"]      = { file = "Vollkorn-Bold.ttf", license = "Vollkorn-OFL.txt", ru = true },
  ["Ka0s Bitter"]             = { file = "Bitter-Regular.ttf", license = "Bitter-OFL.txt", ru = true },
  ["Ka0s Bitter Bold"]        = { file = "Bitter-Bold.ttf", license = "Bitter-OFL.txt", ru = true },
  ["Ka0s Philosopher"]        = { file = "Philosopher-Regular.ttf", license = "Philosopher-OFL.txt", ru = true },
  ["Ka0s Philosopher Bold"]   = { file = "Philosopher-Bold.ttf", license = "Philosopher-OFL.txt", ru = true },
  ["Ka0s Fira Sans SemiBold"] = { file = "FiraSans-SemiBold.ttf", license = "FiraSans-OFL.txt", ru = true },
  ["Ka0s Fira Sans Medium"]   = { file = "FiraSans-Medium.ttf", license = "FiraSans-OFL.txt", ru = true },
  ["Ka0s Atkinson"]           = { file = "AtkinsonHyperlegible-Regular.ttf",
                                  license = "AtkinsonHyperlegible-OFL.txt" },
  ["Ka0s Atkinson Bold"]      = { file = "AtkinsonHyperlegible-Bold.ttf",
                                  license = "AtkinsonHyperlegible-OFL.txt" },
}

-- The families cut from a variable font upstream, whose license records the instancing.
local INSTANCED = { "Inter-OFL.txt", "Nunito-OFL.txt", "Vollkorn-OFL.txt", "Bitter-OFL.txt" }

-- The faces minor 10 retired, no skin naming them any more (the owner's item 7), and their files:
-- Oxanium, Ka0s Default's from minor 9, and Fira Sans Regular, WoW Forever's body until Medium.
local RETIRED = {
  ["Ka0s Oxanium SemiBold"] = "Oxanium-SemiBold.ttf",
  ["Ka0s Oxanium Bold"]     = "Oxanium-Bold.ttf",
  ["Ka0s Fira Sans"]        = "FiraSans-Regular.ttf",
}

-- The faces that ship under terms other than the OFL, each on a recorded owner ruling, by the file
-- that records its terms, with the phrases that file must carry verbatim. Minor 10: Prototype, whose
-- own name table says it is "freely distributed with Prototype.txt", so that text ships unchanged.
local NON_OFL = {
  ["Prototype.txt"] = {
    face = "Ka0s Prototype", file = "Prototype-Regular.ttf",
    phrases = { "free for personal use", "Please include this Prototype.txt file with any redistribution." },
    notice = "freely distributed with Prototype.txt",
  },
}

test("media: FONTS carries every skin face beside JetBrains Mono", function()
  -- red under: minor 5, whose catalog was one monospace face; and minor 6's five, Barlow and Cinzel
  -- among them, which three skins shared. Minor 9 added Oxanium SemiBold and Bold, Ka0s Default's faces;
  -- minor 10 adds Fira Sans Medium and Prototype, and retires Oxanium and Fira Sans Regular.
  local n = 0
  for _ in pairs(media.FONTS) do n = n + 1 end
  assertEqual(n, FONT_COUNT, "JetBrains Mono and every skin face")
  for license, want in pairs(NON_OFL) do
    local entry = media.FONTS[want.face]
    assertTrue(entry ~= nil, "FONTS has no '" .. want.face .. "'")
    if entry then
      assertEqual(entry.file, want.file, want.face .. "'s file")
      assertEqual(entry.license, license, want.face .. "'s license")
      assertEqual(table.concat(entry.langmask or {}, ","), "western", want.face .. " has no Cyrillic")
    end
  end
  local files = listing(FONT_DIR) or {}
  for name, file in pairs(RETIRED) do
    assertTrue(media.FONTS[name] == nil, "FONTS still names the retired '" .. name .. "'")
    assertTrue(files[file] == nil, file .. " still ships, and no skin names it")
  end
  assertTrue(files["Oxanium-OFL.txt"] == nil, "Oxanium's license ships without its faces")
  for name, want in pairs(SKIN_FACES) do
    local entry = media.FONTS[name]
    assertTrue(entry ~= nil, "FONTS has no '" .. name .. "'")
    if entry then
      assertEqual(entry.file, want.file, name .. "'s file")
      assertEqual(entry.license, want.license, name .. "'s license")
    end
  end
end)

test("media: each face names its own locales, and only a face with Cyrillic reaches ruRU", function()
  -- red under: minor 5's one global western+ruRU mask. Atkinson has no Cyrillic, so flagging it ruRU
  -- would draw a Russian player's text as boxes; the six families minor 8 adds all have it.
  for name, entry in pairs(media.FONTS) do
    assertTrue(type(entry.langmask) == "table" and #entry.langmask > 0,
      name .. " carries no langmask list")
  end
  assertEqual(table.concat(media.FONTS["JetBrains Mono"].langmask or {}, ","), "western,ruRU")
  for name, want in pairs(SKIN_FACES) do
    assertEqual(table.concat(media.FONTS[name].langmask or {}, ","), want.ru and "western,ruRU" or "western",
      name .. "'s locales")
  end
end)

local function readFile(path)
  local fh = io.open(path, "rb")
  if not fh then return nil end
  local body = fh:read("*a")
  fh:close()
  return body
end

test("media: every OFL face ships with its license text beside it", function()
  -- red under: minor 10 before NON_OFL, where Prototype.txt is the author's text, not the OFL. A
  -- face off the OFL is let through by its license file's name only, never by a missing check.
  for name, entry in pairs(media.FONTS) do
    local body = readFile(FONT_DIR .. "/" .. entry.license)
    assertTrue(body ~= nil, name .. ": " .. entry.license .. " is missing")
    if body and not NON_OFL[entry.license] then
      assertTrue(body:find("SIL Open Font License, Version 1.1", 1, true) ~= nil,
        entry.license .. " is not the OFL 1.1 text")
    end
  end
  -- Five families ship as static instances cut from upstream's variable fonts; their licenses say so.
  for _, license in ipairs(INSTANCED) do
    local fh = io.open(FONT_DIR .. "/" .. license, "rb")
    local body = fh and fh:read("*a") or ""
    if fh then fh:close() end
    assertTrue(body:find("static instances", 1, true) ~= nil, license .. " does not record the instancing")
  end
end)

test("media: a face off the OFL ships its author's terms verbatim, and the face says the same", function()
  -- Prototype's name table ties its distribution to Prototype.txt; both halves are checked, so a
  -- replaced text or a different cut of the face goes red rather than shipping on a stale ruling.
  for license, want in pairs(NON_OFL) do
    local body = readFile(FONT_DIR .. "/" .. license) or ""
    for _, phrase in ipairs(want.phrases) do
      assertTrue(body:find(phrase, 1, true) ~= nil, license .. " lacks \"" .. phrase .. "\"")
    end
    assertTrue(body:find("SIL Open Font License", 1, true) == nil, license .. " is not the OFL")
    local face = readFile(FONT_DIR .. "/" .. want.file) or ""
    assertTrue(face:find(want.notice, 1, true) ~= nil, want.file .. "'s name table lacks its notice")
  end
end)

test("media: RegisterLSM('X') registers 'Ka0s Inter' under X's own libs folder, each face with its mask", function()
  -- The path is built from the host's name: a vendored copy cannot know its own folder.
  local store, masks = {}, {}
  T.mocks.__libs["LibSharedMedia-3.0"] = localeLSM(128, store, masks)
  local fonts = media.RegisterLSM("X")
  T.mocks.__libs["LibSharedMedia-3.0"] = nil
  assertEqual(store.font and store.font["Ka0s Inter"],
    "Interface\\AddOns\\X\\libs\\LibKa0s\\media\\fonts\\Inter-Regular.ttf")
  for name, want in pairs(SKIN_FACES) do
    assertEqual(masks[name], want.ru and 128 + 2 or 128, name .. "'s mask")
    assertEqual(store.font[name], "Interface\\AddOns\\X\\libs\\LibKa0s\\media\\fonts\\" .. want.file)
  end
  assertEqual(masks["JetBrains Mono"], 128 + 2, "JetBrains Mono keeps western + ruRU")
  for _, want in pairs(NON_OFL) do
    assertEqual(masks[want.face], 128, want.face .. " is western only")
    assertEqual(store.font[want.face], "Interface\\AddOns\\X\\libs\\LibKa0s\\media\\fonts\\" .. want.file)
  end
  assertEqual(fonts, FONT_COUNT)
end)

test("media: a ruRU client keeps every Cyrillic face and is refused the western-only ones", function()
  local store, masks = {}, {}
  T.mocks.__libs["LibSharedMedia-3.0"] = localeLSM(2, store, masks)
  local fonts = media.RegisterLSM("X")
  T.mocks.__libs["LibSharedMedia-3.0"] = nil
  assertEqual(fonts, RU_COUNT, "JetBrains Mono and the Cyrillic faces land on ruRU")
  assertTrue(store.font["Ka0s Atkinson"] == nil, "a western-only face landed on ruRU")
  assertTrue(store.font["Ka0s Prototype"] == nil, "Prototype, western only, landed on ruRU")
  assertTrue(store.font["Ka0s Inter"] ~= nil, "a Cyrillic face was refused on ruRU")
end)

test("media: BORDERS and BACKGROUNDS hold the Glass art, and their paths are extensionless", function()
  -- red under: minor 5, which had neither catalog.
  local border, background = media.BORDERS and media.BORDERS["Ka0s Glass"],
    media.BACKGROUNDS and media.BACKGROUNDS["Ka0s Glass"]
  assertTrue(border ~= nil, "BORDERS has no 'Ka0s Glass'")
  assertTrue(background ~= nil, "BACKGROUNDS has no 'Ka0s Glass'")
  if not (border and background) then return end
  assertEqual(border.file, "glass-border.tga")
  assertEqual(border.edgeSize, 8, "the edge size the 1px stroke and radius 8 are drawn at")
  assertEqual(background.file, "glass-fill.tga")
  assertEqual(background.slice, 8, "the nine-slice margin, the corner radius")
  assertEqual(media.Border("X", "Ka0s Glass"),
    "Interface\\AddOns\\X\\libs\\LibKa0s\\media\\textures\\glass-border")
  assertEqual(media.Background("X", "Ka0s Glass"),
    "Interface\\AddOns\\X\\libs\\LibKa0s\\media\\textures\\glass-fill")
  assertEqual(media.Border("X", "Blizzard Dialog"), nil, "in-client keys are LSM's, not ours")
  assertEqual(media.Background(nil, "Ka0s Glass"), nil)
end)

--- The header of a TGA on disk: image type, width, height, bits per pixel.
local function tgaHeader(path)
  local fh = io.open(path, "rb")
  if not fh then return nil end
  local h = fh:read(18)
  fh:close()
  if not h or #h < 18 then return nil end
  return h:byte(3), h:byte(13) + 256 * h:byte(14), h:byte(15) + 256 * h:byte(16), h:byte(17)
end

local function powerOfTwo(n)
  while n > 1 and n % 2 == 0 do n = n / 2 end
  return n == 1
end

test("media: the Glass art is uncompressed 32-bit TGA, power-of-two on both axes", function()
  local want = { ["glass-fill.tga"] = { 32, 32 }, ["glass-border.tga"] = { 256, 32 } }
  for file, size in pairs(want) do
    local kind, w, h, bpp = tgaHeader("LibKa0s/media/textures/" .. file)
    assertTrue(kind ~= nil, file .. " is not readable")
    assertEqual(kind, 2, file .. " must be uncompressed true-color (type 2)")
    assertEqual(bpp, 32, file .. " needs an alpha channel")
    assertEqual(w, size[1], file .. " width")
    assertEqual(h, size[2], file .. " height")
    assertTrue(powerOfTwo(w) and powerOfTwo(h), file .. " is not power-of-two")
  end
end)

test("media: every statusbar, Ka0s Default's bar among them, is a 256x32 32-bit TGA", function()
  -- Minor 9 adds Ka0s Default, drawn by tools/artwork/bar_textures.py like the other seven: the same
  -- 256x32 canvas, so a frame sized for one is sized for all, and RLE true-color (type 10) as the
  -- tool writes it, or uncompressed (type 2).
  local entry = media.TEXTURES["Ka0s Default"]
  assertTrue(entry ~= nil, "TEXTURES has no 'Ka0s Default'")
  if entry then
    assertEqual(entry.file, "ka0s-default.tga")
    assertTrue(entry.source == nil, "Ka0s Default is generated, so it records no source")
    assertEqual(media.Texture("X", "Ka0s Default"),
      "Interface\\AddOns\\X\\libs\\LibKa0s\\media\\textures\\ka0s-default")
  end
  for name, bar in pairs(media.TEXTURES) do
    local kind, w, h, bpp = tgaHeader("LibKa0s/media/textures/" .. bar.file)
    assertTrue(kind ~= nil, bar.file .. " is not readable")
    assertTrue(kind == 10 or kind == 2, bar.file .. " must be true-color TGA (type 10 or 2), got " .. tostring(kind))
    assertEqual(bpp, 32, name .. " needs an alpha channel")
    assertEqual(w, 256, name .. " width")
    assertEqual(h, 32, name .. " height")
  end
end)

-- Every skin's own bar (minor 9, SO-04): the LSM key, its file, and the skin that draws it. WoW
-- Default keeps the client's Blizzard bar and ships none.
local SKIN_BARS = {
  { "Ka0s Matte", "matte.tga", "obsidian" }, { "Ka0s Parchment", "parchment.tga", "azeroth" },
  { "Ka0s Glass Bar", "glass-bar.tga", "glass" }, { "Ka0s Solid", "solid.tga", "contrast" },
  { "Ka0s Forge", "forge.tga", "ember" }, { "Ka0s Satin", "satin.tga", "midnight" },
  { "Ka0s Classic", "classic.tga", "forever" },
}

--- A 32-bit TGA's pixels as rows of { b, g, r, a }, top row first: RLE (type 10) or raw (type 2).
local function tgaPixels(path)
  local fh = io.open(path, "rb")
  if not fh then return nil end
  local data = fh:read("*a")
  fh:close()
  local kind, w, h = data:byte(3), data:byte(13) + 256 * data:byte(14), data:byte(15) + 256 * data:byte(16)
  local topFirst = data:byte(18) % 64 >= 32
  local pos, flat = 19 + data:byte(1), {}
  local function pixel() local p = { data:byte(pos, pos + 3) }; pos = pos + 4; return p end
  while #flat < w * h do
    if kind == 2 then
      flat[#flat + 1] = pixel()
    else
      local c = data:byte(pos); pos = pos + 1
      if c >= 128 then
        local p = pixel()
        for _ = 1, c - 127 do flat[#flat + 1] = p end
      else
        for _ = 1, c + 1 do flat[#flat + 1] = pixel() end
      end
    end
  end
  local rows = {}
  for r = 1, h do
    local row = {}
    for x = 1, w do row[x] = flat[(r - 1) * w + x] end
    rows[topFirst and r or (h - r + 1)] = row
  end
  return rows, w, h
end

test("media: every skin's own bar is in TEXTURES, opaque and gray, and tiles along the bar", function()
  -- Minor 9 (SO-04, the owner's approved mockup). Opaque, because a bar of data is a fill and not an
  -- overlay; gray, because a texture is tinted by multiplying; every column the same but Parchment's,
  -- whose mottle wraps, so the seam where a wide bar repeats it is no harder than any step inside it.
  -- red under: a skin's bar missing, translucent, tinted, or a Parchment whose blur does not wrap.
  for _, want in ipairs(SKIN_BARS) do
    local name, file = want[1], want[2]
    local entry = media.TEXTURES[name]
    assertTrue(entry ~= nil, "TEXTURES has no '" .. name .. "'")
    assertEqual(entry and entry.file, file, name .. "'s file")
    local rows, w, h = tgaPixels("LibKa0s/media/textures/" .. file)
    assertTrue(rows ~= nil, file .. " is not readable")
    local opaque, gray, flat, seam, step = true, true, true, 0, 0
    for y = 1, h or 0 do
      local row = rows[y]
      for x = 1, w do
        local p = row[x]
        opaque = opaque and p[4] == 255
        gray = gray and p[1] == p[2] and p[2] == p[3]
        flat = flat and p[1] == row[1][1]
        if x > 1 then step = math.max(step, math.abs(p[1] - row[x - 1][1])) end
      end
      seam = math.max(seam, math.abs(row[1][1] - row[w][1]))
    end
    assertTrue(opaque, name .. " is not opaque")
    assertTrue(gray, name .. " is not gray")
    if name == "Ka0s Parchment" then
      assertTrue(not flat, "Parchment's mottle is missing: every column is the same")
      assertTrue(seam <= step, "Parchment shows a seam where it tiles: " .. seam .. " against " .. step)
    else
      assertTrue(flat, name .. "'s columns differ")
    end
  end
  assertTrue(media.TEXTURES["Ka0s Glass"] == nil, "the Glass statusbar is 'Ka0s Glass Bar'; 'Ka0s Glass' is its border")
  local matte = tgaPixels("LibKa0s/media/textures/matte.tga")
  assertEqual(matte[1][1][1], 255, "Matte's lit top row")
  assertEqual(matte[16][1][1], 219, "Matte's face, 0.86")
  assertEqual(matte[32][1][1], 158, "Matte's shaded bottom row, 0.62")
  local solid = tgaPixels("LibKa0s/media/textures/solid.tga")
  assertEqual(solid[1][1][1] + solid[32][256][1], 510, "Solid is white everywhere")
end)

test("media: RegisterLSM registers the Glass border and background, and counts them", function()
  local byKind = {}
  T.mocks.__libs["LibSharedMedia-3.0"] = {
    MediaType = { FONT = "font", STATUSBAR = "statusbar", BORDER = "border", BACKGROUND = "background" },
    Register = function(_, kind, key, path)
      byKind[kind] = byKind[kind] or {}
      byKind[kind][key] = path
      return true
    end,
    IsValid = function(_, kind, key) return byKind[kind] ~= nil and byKind[kind][key] ~= nil end,
  }
  local fonts, bars, borders, backgrounds = media.RegisterLSM("X")
  T.mocks.__libs["LibSharedMedia-3.0"] = nil
  assertEqual(fonts, FONT_COUNT)
  assertEqual(bars, 15)
  assertEqual(borders, 1)
  assertEqual(backgrounds, 1)
  assertEqual(byKind.border and byKind.border["Ka0s Glass"], media.Border("X", "Ka0s Glass"))
  assertEqual(byKind.background and byKind.background["Ka0s Glass"], media.Background("X", "Ka0s Glass"))
end)
