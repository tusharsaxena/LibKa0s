-- tests/fixture_media.lua -- the bench the media picker suites share: tests/test_options_media.lua
-- (the Ka0sMedia_* types) and tests/test_options_skin_picker_rows.lua (the skin picker's rows, LK-A3
-- of Ka0sAddonsCommonTasks docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES). Moved out of the first,
-- unchanged but for loading OptionsSkinPicker.lua, so the two cannot drift. See the first's header
-- for why the bench is shaped as it is.
--
-- Loaded as `dofile("tests/fixture_media.lua")`. Every env() is a fresh client.

local A = dofile("tests/fixture_skin_ace.lua")
local Loader = dofile("tests/_kit/loader.lua")

local FACE = { ["Ka0s Expressway"] = "Fonts\\Expressway.ttf", ["Ka0s Fira Sans"] = "Fonts\\FiraSans.ttf",
               ["Ka0s Prototype"] = "Fonts\\Prototype.ttf" }
local LSM = {
  ["font:Ka0s Expressway"] = FACE["Ka0s Expressway"], ["font:Ka0s Fira Sans"] = FACE["Ka0s Fira Sans"],
  ["font:Ka0s Prototype"] = FACE["Ka0s Prototype"],
  ["statusbar:Smooth"] = "Tex\\Smooth", ["statusbar:Flat"] = "Tex\\Flat",
  ["border:Glass"] = "Tex\\GlassEdge", ["background:Solid"] = "Tex\\Solid",
  ["sound:Ding"] = "Sound\\Ding.ogg",
}
local BASE_FONT = "Fonts\\BASE.TTF"

--- Give the fixture's pull-out what AceGUI's has: callbacks, OnOpen, OnClose, an item walk, a releasing
--- Clear.
local function fullPullout(ace, po)
  if po.__full then return end
  po.__full = true
  po.events = {}
  po.SetCallback = function(self, name, fn) self.events[name] = fn end
  po.IterateItems = function(self) return ipairs(self.items) end
  po.Open = function(self)
    self.frame:Show()
    if self.events.OnOpen then self.events.OnOpen(self, "OnOpen") end
  end
  po.Close = function(self)
    self.frame:Hide()
    if self.events.OnClose then self.events.OnClose(self, "OnClose") end
  end
  po.Clear = function(self)
    for i = #self.items, 1, -1 do
      ace:Release(self.items[i])
      self.items[i] = nil
    end
  end
end

--- AceGUIWidget-DropDown.lua's methods, on the fixture's anatomy.
local function stockDropdown(m, ace)
  local w = m.__makeAceGUIWidget("Dropdown")
  A.dress(m, w, "Dropdown")
  w.text:SetFont(BASE_FONT, 10, "")
  local acquire, release = w.OnAcquire, w.OnRelease
  w.OnRelease = function(self)
    release(self)
    self.value, self.list, self.open = nil, nil, nil
    self:SetText("")
  end
  w.OnAcquire = function(self)
    acquire(self)
    fullPullout(ace, self.pullout)
    self.pullout.events.OnOpen = function(this) this.userdata.obj.open = true end
    self.pullout.events.OnClose = function(this) this.userdata.obj.open = nil end
    self.list = {}
  end
  w.ClearFocus = function(self)
    if self.open then self.pullout:Close() end
  end
  w.SetText = function(self, text) self.text:SetText(text or "") end
  w.SetValue = function(self, value)
    self:SetText(self.list[value] or "")
    self.value = value
  end
  w.GetValue = function(self) return self.value end
  local function addRow(self, value, text, itemType)
    local item = ace:Create(itemType or "Dropdown-Item-Toggle")
    item.userdata = item.userdata or {}
    item.userdata.value = value
    item:SetText(text)
    self.pullout:AddItem(item)
  end
  w.SetList = function(self, list, order, itemType)
    self.list = list or {}
    self.pullout:Clear()
    for _, key in ipairs(order or {}) do addRow(self, key, list[key], itemType) end
  end
  w.AddItem = function(self, value, text, itemType)
    self.list[value] = text
    addRow(self, value, text, itemType)
  end
  return w
end

local function stockItem(m)
  local w = m.__makeAceGUIWidget("Dropdown-Item-Toggle")
  A.dress(m, w, "Dropdown-Item-Toggle")
  local item = A.item(m, "")
  w.frame, w.text, w.highlight = item.frame, item.text, item.highlight
  w.text:SetFont(BASE_FONT, 10, "")
  w.SetText = function(self, text) self.text:SetText(text or "") end
  w.OnAcquire = function() end
  w.OnRelease = function(self) self.frame:Hide() end
  return w
end

--- A client whose AceGUI carries the stock Dropdown. `opts.noLsm` leaves LibSharedMedia out.
local function env(opts)
  opts = opts or {}
  local files = {}
  for i, f in ipairs(A.FILES) do files[i] = f end
  files[#files + 1] = "OptionsAppearance"
  files[#files + 1] = "OptionsSkinPicker"
  files[#files + 1] = "OptionsSkinPickerRows"
  local m, Skin, lib, ace = A.env({ files = files, lsm = not opts.noLsm and LSM or nil })
  Loader.load("LibKa0s/OptionsMedia.lua", nil, m)
  -- The kit's SetText overwrites `text`, the field the fixture's Button keeps its FontString in; the
  -- Skin tab's buttons set their words before anything reads it.
  local create = ace.Create
  ace.Create = function(self, wtype, ...)
    local w = create(self, wtype, ...)
    if wtype == "Button" then w.SetText = function() end end
    return w
  end
  ace.ClearFocus = function(self)      -- AceGUI-3.0.lua's: the widget drops it, then the mark goes
    if self.FocusedWidget then
      self.FocusedWidget:ClearFocus()
      self.FocusedWidget = nil
    end
  end
  if not opts.noBase then
    ace:RegisterWidgetType("Dropdown", function() return stockDropdown(m, ace) end, 41)
    ace:RegisterWidgetType("Dropdown-Item-Toggle", function() return stockItem(m) end, 1)
  end
  if not opts.noLsm then
    local L = m.LibStub("LibSharedMedia-3.0", true)
    L.HashTable = function(_, kind)
      local out = {}
      for k, v in pairs(LSM) do
        local name = k:match("^" .. kind .. ":(.+)$")
        if name then out[name] = v end
      end
      return out
    end
  end
  return m, Skin, lib, ace
end

return { A = A, env = env, stockDropdown = stockDropdown, FACE = FACE, LSM = LSM, BASE_FONT = BASE_FONT }
