-- tests/fixture_skin_ace.lua — the bench tests/test_skin_ace.lua runs on: tests/fixture_skin_paint.lua's
-- paint-recorder environment with SkinAce.lua and the Options major loaded, a working
-- hooksecurefunc, and the kit's AceGUI fake turned into a POOLED one whose widgets carry AceGUI's
-- real anatomy.
--
-- WHY A POOL. The kit's AceGUI fake never hands a released widget out again (testkit/mock_base.lua,
-- its Release comment), and the whole promise SkinAce.lua makes is about the next acquirer of the
-- SAME object: one addon's skin must not ride a pooled widget into another addon's hands. So
-- Create here takes a released widget of that type back first, as AceGUI's objPools do, and runs
-- its OnAcquire; Release is the kit's (callbacks fired, the widget's own OnRelease run, the bags
-- wiped) and then parks the widget.
--
-- WHY THE ANATOMY. SkinAce paints AceGUI's own fields (`checkbg`, `check`, `text`, `slider`,
-- `editbox`, `dropdown`, `button_cover`, `pullout`, ...), so each widget built here is the kit's
-- recorder widget dressed with those fields on paint-recorder frames, and the methods that touch
-- them (SetDisabled, SetValue, SetType, SetFontObject, OnAcquire, the Dropdown's OnRelease and its
-- pull-out's Open / Close) do what AceGUI-3.0 minor 41's do to them, colors included, as instance
-- fields so a post-hook can wrap them.
--
-- WHY A REAL hooksecurefunc. The kit's is a no-op (mock_base.lua), which is right for suites that
-- never ask; SkinAce's durability hooks are exactly the thing under test here.

local F = dofile("tests/fixture_skin_paint.lua")

local A = {}

A.OWNER, A.OTHER = "LootHistory", "BankLedger"
A.FILES = { "Core", "Skin", "SkinOwnerTokens", "SkinDefs", "SkinPaint", "SkinPaintExtras", "SkinPaintControls", "SkinAce", "Pool",
            "Options", "OptionsRegistry", "OptionsWidgets", "OptionsIds", "OptionsIdList", "OptionsTabs",
            "OptionsCombat", "OptionsCompose", "OptionsScroll", "OptionsNav", "OptionsDrawer", "OptionsKeybinds" }
A.LSM = { ["font:Ka0s Expressway"] = "Fonts\\Expressway.ttf", ["font:Ka0s Fira Sans"] = "Fonts\\FiraSans.ttf" }

--- A hooksecurefunc that hooks: `t[name]` becomes the original, then `fn`, with the same arguments.
local function realHook(m)
  return function(a, b, c)
    local t, name, fn = a, b, c
    if type(a) == "string" then t, name, fn = m, a, b end
    local orig = t[name]
    assert(type(orig) == "function", "hooksecurefunc: no function " .. tostring(name))
    t[name] = function(...)
      local r = { orig(...) }
      fn(...)
      return unpack(r)
    end
  end
end

-- ── the anatomy ──────────────────────────────────────────────────────────────────────────────

local function tex(f, layer) return f:CreateTexture(nil, layer or "ARTWORK") end
local function fs(f, layer) return f:CreateFontString(nil, layer or "OVERLAY") end

--- Template pieces as a template's parentKeys give them.
local function pieces(f)
  f.Left, f.Middle, f.Right = tex(f, "BACKGROUND"), tex(f, "BACKGROUND"), tex(f, "BACKGROUND")
end

local function templateButton(m, parent)
  local b = m.CreateFrame("Button", nil, parent)
  pieces(b)
  local label = fs(b)
  rawset(b, "GetFontString", function() return label end)
  return b, label
end

local STOCK_BACKDROP = { bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1 }

local function backdropFrame(m, kind, parent, fill, edge)
  local f = m.CreateFrame(kind, nil, parent, "BackdropTemplate")
  f:SetBackdrop(STOCK_BACKDROP)
  f:SetBackdropColor(unpack(fill))
  f:SetBackdropBorderColor(unpack(edge))
  return f
end

local DRESS = {}

function DRESS.CheckBox(_, w, f)
  w.checkbg, w.check, w.highlight = tex(f, "ARTWORK"), tex(f, "OVERLAY"), tex(f, "HIGHLIGHT")
  w.text = fs(f)
  w.SetType = function(self, t)
    local size = t == "radio" and 16 or 24
    self.checkbg:SetSize(size, size)
  end
  w.SetDisabled = function(self, d)
    self.disabled = d
    if d then self.text:SetTextColor(0.5, 0.5, 0.5) else self.text:SetTextColor(1, 1, 1) end
  end
  w.SetValue = function(self, v)
    self.checked = v
    if v then self.check:Show() else self.check:Hide() end
    self:SetDisabled(self.disabled)
  end
  w.SetLabel = function(self, v) self.text:SetText(v) end
  w.OnAcquire = function(self)
    self:SetType()
    self:SetValue(false)
    self:SetDisabled(nil)
  end
end

function DRESS.Slider(m, w, f)
  w.label = fs(f)
  local sl = backdropFrame(m, "Slider", f, { 0, 0, 0, 0.8 }, { 1, 1, 1, 1 })
  local thumb = tex(sl, "OVERLAY")
  rawset(sl, "GetThumbTexture", function() return thumb end)
  w.slider, w.thumb = sl, thumb
  w.lowtext, w.hightext = fs(sl), fs(sl)
  local eb = backdropFrame(m, "EditBox", f, { 0, 0, 0, 0.5 }, { 0.3, 0.3, 0.3, 0.8 })
  eb:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1) end)
  eb:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8) end)
  w.editbox = eb
  w.SetDisabled = function(self, d)
    self.disabled = d
    local c = d and { 0.5, 0.5, 0.5 } or { 1, 0.82, 0 }
    self.label:SetTextColor(unpack(c))
    self.lowtext:SetTextColor(d and 0.5 or 1, d and 0.5 or 1, d and 0.5 or 1)
    self.hightext:SetTextColor(d and 0.5 or 1, d and 0.5 or 1, d and 0.5 or 1)
  end
  w.OnAcquire = function(self) self:SetDisabled(false) end
end

--- The Dropdown-Pullout, pooled on its own as AceGUI pools it.
local pulloutPool = setmetatable({}, { __mode = "k" })
local function acquirePullout(m, dd)
  local list = pulloutPool[m] or {}
  pulloutPool[m] = list
  local po = table.remove(list)
  if not po then
    po = { items = {}, userdata = {} }
    po.frame = backdropFrame(m, "Frame", m.UIParent, { 0, 0, 0, 1 }, { 1, 1, 1, 1 })
    po.slider = m.CreateFrame("Slider", nil, po.frame)
    local thumb = tex(po.slider, "OVERLAY")
    rawset(po.slider, "GetThumbTexture", function() return thumb end)
    po.Open = function(self) self.frame:Show() end
    po.Close = function(self) self.frame:Hide() end
    po.Clear = function(self) for i = #self.items, 1, -1 do self.items[i] = nil end end
    po.AddItem = function(self, item) self.items[#self.items + 1] = item end
  end
  po.userdata.obj = dd
  return po
end
local function releasePullout(m, po)
  po:Clear()
  po.userdata.obj = nil
  local list = pulloutPool[m] or {}
  pulloutPool[m] = list
  list[#list + 1] = po
end

--- One pull-out item: a frame with its text and highlight, as Dropdown-Item-* carry them.
function A.item(m, label)
  local f = m.CreateFrame("Button", nil, m.UIParent)
  local item = { frame = f, text = fs(f), highlight = tex(f, "OVERLAY") }
  item.text:SetTextColor(1, 1, 1)
  item.text:SetText(label)
  return item
end

function DRESS.Dropdown(m, w, f)
  local dd = m.CreateFrame("Frame", nil, f)
  pieces(dd)
  w.dropdown = dd
  w.button_cover = m.CreateFrame("Button", nil, f)
  w.text, w.label = fs(dd), fs(f)
  w.SetDisabled = function(self, d)
    self.disabled = d
    if d then self.text:SetTextColor(0.5, 0.5, 0.5) else self.text:SetTextColor(1, 1, 1) end
  end
  w.OnAcquire = function(self)
    self.pullout = acquirePullout(m, self)
  end
  w.OnRelease = function(self)
    if self.pullout.frame:IsShown() then self.pullout:Close() end
    releasePullout(m, self.pullout)
    self.pullout = nil
    self:SetDisabled(false)
  end
end

function DRESS.EditBox(m, w, f)
  local eb = m.CreateFrame("EditBox", nil, f)
  pieces(eb)
  w.editbox, w.label = eb, fs(f)
  w.button = templateButton(m, eb)
  w.SetDisabled = function(self, d)
    self.disabled = d
    if d then self.label:SetTextColor(0.5, 0.5, 0.5) else self.label:SetTextColor(1, 0.82, 0) end
  end
  w.OnAcquire = function(self) self:SetDisabled(false) end
end

function DRESS.MultiLineEditBox(m, w, f)
  w.label = fs(f)
  w.button = templateButton(m, f)
  w.scrollBG = backdropFrame(m, "Frame", f, { 0, 0, 0, 1 }, { 0.4, 0.4, 0.4, 1 })
  w.editBox = m.CreateFrame("EditBox", nil, f)
end

function DRESS.Button(_, w, f)
  pieces(f)
  w.text = fs(f)
  local label = w.text
  rawset(f, "GetFontString", function() return label end)
  w.SetDisabled = function(self, d)
    self.disabled = d
    if d then self.text:SetTextColor(0.5, 0.5, 0.5) else self.text:SetTextColor(1, 0.82, 0) end
  end
  w.OnAcquire = function(self) self:SetDisabled(false) end
end

function DRESS.Heading(_, w, f)
  w.label, w.left, w.right = fs(f, "BACKGROUND"), tex(f, "BACKGROUND"), tex(f, "BACKGROUND")
  w.label:SetTextColor(1, 0.82, 0)
end

local function labelDress(_, w, f)
  w.label, w.image = fs(f, "BACKGROUND"), tex(f, "BACKGROUND")
  w.SetFontObject = function(self, font) self.label:SetFontObject(font or "GameFontHighlightSmall") end
  w.SetColor = function(self, r, g, b) self.label:SetTextColor(r or 1, g or 1, b or 1) end
  w.OnAcquire = function(self)
    self:SetFontObject()
    self:SetColor()
  end
end
DRESS.Label = labelDress
DRESS.InteractiveLabel = labelDress

function DRESS.Icon(_, w, f)
  w.label, w.image = fs(f, "BACKGROUND"), tex(f, "BACKGROUND")
end

function DRESS.ColorPicker(_, w, f)
  w.colorSwatch, w.text = tex(f, "OVERLAY"), fs(f)
  w.text:SetTextColor(1, 1, 1)
end

function DRESS.InlineGroup(m, w, f)
  w.titletext = fs(f)
  local border = backdropFrame(m, "Frame", f, { 0.1, 0.1, 0.1, 0.5 }, { 0.4, 0.4, 0.4, 1 })
  local content = m.CreateFrame("Frame", nil, border)
  rawset(content, "GetParent", function() return border end)
  w.content = content
end

function DRESS.ScrollFrame(m, w, f)
  local sb = m.CreateFrame("Slider", nil, f)
  tex(sb, "BACKGROUND")
  w.scrollbar = sb
end

-- A host's own widget type with a stock type's anatomy: AuraMaster's AuraMasterDropdown is AceGUI's
-- Dropdown constructor with its own type name (a second pool) and its closed text justified LEFT on
-- every acquisition (AuraMaster settings/OptionsSetup.lua, NS.RegisterDropdownWidget).
A.HOST_DROPDOWN = "AuraMasterDropdown"
DRESS[A.HOST_DROPDOWN] = function(m, w, f)
  DRESS.Dropdown(m, w, f)
  local acquire = w.OnAcquire
  w.OnAcquire = function(self)
    acquire(self)
    self.text:SetJustifyH("LEFT")
  end
end

-- ── the TreeGroup (AceGUI's TreeGroup v49) ────────────────────────────────────────────────────

--- The two font objects UpdateButton hands a row: GameFontNormal for a first-level row, and
--- GameFontHighlightSmall for a deeper one. Named, as the client's are, so a restore hands them back.
local function namedFontObject(name, size)
  return { name = name, size = size, GetName = function(self) return self.name end,
           GetFont = function(self) return "Fonts\\FRIZQT__.TTF", self.size, "" end }
end
A.ROW_FONT = { normal = namedFontObject("GameFontNormal", 12), small = namedFontObject("GameFontHighlightSmall", 10) }

--- One tree row as OptionsListButtonTemplate gives it: its `text`, its highlight texture (shown while
--- LockHighlight holds it), its plus/minus toggle; `obj` is the widget, as CreateButton sets it.
local function treeButton(m, w)
  local b = m.CreateFrame("Button", nil, w.treeframe)
  b.obj = w
  local label, hl = fs(b), tex(b, "HIGHLIGHT")
  b.text = label
  hl:Hide()
  rawset(b, "GetFontString", function() return label end)
  rawset(b, "GetHighlightTexture", function() return hl end)
  rawset(b, "LockHighlight", function() hl:Show() end)
  rawset(b, "UnlockHighlight", function() hl:Hide() end)
  b.toggle = m.CreateFrame("Button", nil, b)
  return b
end

--- UpdateButton: the row's level, its selection and the font its level takes, colors included (a
--- first-level row reads gold, a deeper one and a selected one white).
local function updateButton(b, line, selected)
  b.level, b.selected, b.value = line.level, selected, line.value
  if selected then b:LockHighlight() else b:UnlockHighlight() end
  local first = line.level == 1
  b.text:SetFontObject(first and A.ROW_FONT.normal or A.ROW_FONT.small)
  if first and not selected then b.text:SetTextColor(1, 0.82, 0) else b.text:SetTextColor(1, 1, 1) end
  b.text:SetText(line.text)
end

--- The TreeGroup's frames and the methods that touch them. A tree here is a flat list of lines
--- `{ value, text, level }`, already expanded: RefreshTree lays one row button per line, making
--- the buttons it lacks, and hides the rest, as AceGUI's does.
function DRESS.TreeGroup(m, w, f)
  w.treeframe = backdropFrame(m, "Frame", f, { 0.1, 0.1, 0.1, 0.5 }, { 0.4, 0.4, 0.4, 1 })
  w.dragger = backdropFrame(m, "Frame", w.treeframe, { 1, 1, 1, 0 }, { 1, 1, 1, 1 })
  local sb = m.CreateFrame("Slider", nil, w.treeframe)
  local bg = tex(sb, "BACKGROUND")
  bg:SetColorTexture(0, 0, 0, 0.4)
  local thumb = tex(sb, "OVERLAY")
  rawset(sb, "GetThumbTexture", function() return thumb end)
  w.scrollbar, w.scrollbg = sb, bg
  w.border = backdropFrame(m, "Frame", f, { 0.1, 0.1, 0.1, 0.5 }, { 0.4, 0.4, 0.4, 1 })
  w.content = m.CreateFrame("Frame", nil, w.border)
  w.buttons, w.localstatus = {}, {}
  w.treeframe.obj, w.dragger.obj, sb.obj = w, w, w
  w.RefreshTree = function(self)
    local lines = self.tree or {}
    for i, line in ipairs(lines) do
      local b = self.buttons[i] or treeButton(m, self)
      self.buttons[i] = b
      updateButton(b, line, self.localstatus.selected == line.value)
      b:Show()
    end
    for i = #lines + 1, #self.buttons do self.buttons[i]:Hide() end
  end
  w.SetTree = function(self, tree)
    self.tree = tree
    self:RefreshTree()
  end
  w.SelectByValue = function(self, value)
    self.localstatus.selected = value
    self:RefreshTree()
  end
  w.OnAcquire = function(self) self.localstatus = {} end
  w.OnRelease = function(self)
    self.tree, self.status = nil, nil
    self.localstatus = {}
  end
end

local FRAME_TYPE ={ CheckBox = "Button", Button = "Button", Icon = "Button", ColorPicker = "Button" }

local function dress(m, w, wtype)
  local f = m.CreateFrame(FRAME_TYPE[wtype] or "Frame", nil, m.UIParent)
  w.frame = f
  f.obj = w
  w.__dressed = true
  if DRESS[wtype] then DRESS[wtype](m, w, f) end
end
A.dress = dress

--- Make the kit's AceGUI fake pool its widgets, dressed in AceGUI's anatomy. Answers the fake.
function A.pool(m)
  local ace = m.__libs["AceGUI-3.0"]
  local pools = {}
  local create, release = ace.Create, ace.Release
  ace.__pools = pools
  ace.Create = function(self, wtype)
    local pool = pools[wtype]
    local w = pool and table.remove(pool)
    if w then
      w.__released, w.isQueuedForRelease = nil, nil
      self.__created[#self.__created + 1] = w
    else
      w = create(self, wtype)
      if not w.__dressed then dress(m, w, wtype) end   -- a registered constructor dressed its own
    end
    if w.OnAcquire then w:OnAcquire() end
    return w
  end
  ace.Release = function(self, w)
    release(self, w)
    pools[w.type] = pools[w.type] or {}
    table.insert(pools[w.type], w)
  end
  return ace
end

--- A fresh environment: the recorder, the Skin major with SkinAce.lua, the Options major, a working
--- hooksecurefunc, an error handler that records, and the pooled AceGUI fake. `lsm` installs the
--- LibSharedMedia fake (A.LSM by default when true). Answers m, Skin, the Options major, AceGUI.
function A.env(opts)
  opts = opts or {}
  local lsm = opts.lsm == true and A.LSM or opts.lsm
  local m, Skin = F.env({ files = opts.files or A.FILES, lsm = lsm })
  m.hooksecurefunc = realHook(m)
  m.__errors = {}
  m.geterrorhandler = function() return function(e) m.__errors[#m.__errors + 1] = tostring(e) end end
  local ace = A.pool(m)
  return m, Skin, m.LibStub("LibKa0s-Options-1.0", true), ace
end

local seq = 0
--- An Options instance for a host named `owner` (nil: no addonName).
function A.instance(lib, owner)
  seq = seq + 1
  local store = {}
  return lib:New({
    parentTitle = "Ace Host", mainPanelName = "AceHostMain" .. seq, addonName = owner,
    print = function() end,
    get = function(path) return store[path] end,
    set = function(path, value) store[path] = value end,
    applyDefault = function() end,
    rowsForPage = function() return {} end,
    allRows = function() return {} end,
  }), store
end

--- A stable picture of a widget's stock look: every frame of it (the widget's frame and the frames
--- under it, the Skin major's own holders left out) with its backdrop colors, and every region on
--- them that no primitive made with its alpha, colors and font object. Two acquisitions that look
--- the same answer the same string.
function A.snapshot(m, Skin, w)
  local out, seen = {}, {}
  local function fmt(v)
    if type(v) ~= "table" then return tostring(v) end
    if v[1] == nil then return "nil" end
    local parts = {}
    for i = 1, #v do parts[i] = type(v[i]) == "number" and string.format("%.3f", v[i]) or tostring(v[i]) end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  local function walk(f)
    if type(f) ~= "table" or seen[f] or Skin.__ours[f] then return end
    seen[f] = true
    out[#out + 1] = "frame bd=" .. fmt({ f:GetBackdropColor() }) .. " edge=" .. fmt({ f:GetBackdropBorderColor() })
      .. " bdt=" .. tostring(f:GetBackdrop())
    for _, r in ipairs({ f:GetRegions() }) do
      if type(r) == "table" and not Skin.__ours[r] and type(r.GetObjectType) == "function" then
        local s = m.__paint(r)
        local txt = s.kind == "FontString" and fmt({ r:GetTextColor() }) or "-"
        out[#out + 1] = string.format("  %s a=%.3f col=%s vtx=%s txt=%s fo=%s", s.kind, r:GetAlpha(),
          fmt(s.color), fmt({ r:GetVertexColor() }), txt, tostring(s.fontObject))
      end
    end
    for _, c in ipairs({ f:GetChildren() }) do walk(c) end
  end
  walk(w.frame)
  return table.concat(out, "\n")
end

A.F = F
return A
