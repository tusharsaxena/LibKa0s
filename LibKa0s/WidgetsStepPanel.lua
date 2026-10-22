-- LibKa0s-Widgets-1.0 — the step panel: a render-only, clickable list of steps, each a status dot,
-- a label and the slash command that does the same thing (minor 1, #53).
--
-- ── WHY THIS IS A LIBRARY WIDGET ─────────────────────────────────────────────────────────────
--
-- Perf drew it first (`PerfPanel.lua`: a run of five steps and a cancel row, one clickable at a
-- time, the typed command beside each so the panel teaches the slash form while you click), and
-- DropWatcher's simulator drew the same panel again in `modules/SimPanel.lua`, row for row and
-- pixel for pixel, with a picker under it. `LibKa0s-Sim-1.0` brings that simulator to LootHistory
-- and BankLedger, and a third copy of one panel is the drift the library exists to end.
--
-- ── WHY RENDER-ONLY ──────────────────────────────────────────────────────────────────────────
--
-- The objection on #53 was that the two panels have the same shape and not the same semantics: a
-- perf run is a strict sequence with a cancel that is always offered, a simulation lets a click run
-- ahead to any later step and stops rather than cancels. So the widget owns the SHAPE and none of
-- the semantics. A row arrives as data — `{ key?, label, command, state, actionable, tip? }` — from
-- the host's `rows()`, and `actionable` is the host's answer, never derived from `state` here. The
-- six states (done, used, ready, busy, locked, cancel) are only the palette's keys; what puts a row
-- in one is Perf's and Sim's business, and no new state is ever added here. A click re-reads
-- `rows()` and re-checks `actionable` at the clicked index before it reaches `onClick`, because a
-- row painted actionable may have stopped being so between the paint and the click.
--
-- ── WHAT IT IS NOT ───────────────────────────────────────────────────────────────────────────
--
-- No state logic, no slash knowledge, no saved position. There is no `place` and no `onDragStop`
-- (the owner's 2026-10-22 scope, C.7): the panel sits at CENTER -320, set once at build, and a
-- caller that wants it elsewhere, or wants to save where it was dragged, positions or hooks the
-- frame itself (`Frame()`). Resizing is always width-only: the row count decides the height, so
-- height a player added would be empty space. The done mark is the host's art (`check`), because
-- this file is vendored and cannot know which addon folder holds an icon.
--
-- ── THE HEIGHT BOUNDS ────────────────────────────────────────────────────────────────────────
--
-- `Core.MakeResizable` is call-once and pins a widthOnly frame's min and max height at the height
-- it had THEN (Core.lua's `resolveBounds`). A row count that changes later would leave the grip
-- clamping to the old height, so on every Refresh where the count moved the panel re-pins its own
-- height bounds, guarded the way Core's `setBounds` is (`SetResizeBounds`, else the old
-- `SetMinResize` / `SetMaxResize` pair). No Core API changes for it (C.5).
--
-- A secondary file of the Widgets major, paired on the shell's minor like WidgetsDragHandle.lua,
-- and floored on Core 9 for `MakeResizable` rather than feature-detecting it: with an older Core the
-- file returns and `StepPanel` is absent.

local lib = LibStub and LibStub("LibKa0s-Widgets-1.0", true)
if not lib then return end

-- The attach-file floor: MakeResizable arrived at Core minor 9.
local core = LibStub("LibKa0s-Core-1.0", true)
local NEEDS_CORE = 9
if not core or (core.MINOR or 0) < NEEDS_CORE then return end

local STEP_PANEL_MINOR = 1
-- Paired on the SHELL's minor as well as this file's own; see WidgetsDragHandle.lua for why.
if lib.__stepPanelMinor and lib.__stepPanelMinor >= STEP_PANEL_MINOR
  and lib.__stepPanelShellMinor == lib.MINOR then return end
lib.__stepPanelMinor      = STEP_PANEL_MINOR
lib.__stepPanelShellMinor = lib.MINOR

lib.MODULES = lib.MODULES or {}
lib.MODULES.WidgetsStepPanel = STEP_PANEL_MINOR

-- Perf's geometry, palette and command color, copied byte-identical from PerfPanel.lua (its
-- comments with them), so a panel drawn here and Perf's own cannot be told apart.
-- Three columns: status dot, step, slash command. The command column is the point — it teaches the
-- typed form while you click, so the panel is a crutch you can stop needing.
local ROW_W, ROW_H, GAP = 360, 22, 4
local DOT_X, DOT = 8, 8        -- column 1: status dot
local LABEL_X   = 26           -- column 2: step name
local CMD_PAD   = 10           -- column 3: slash command, right-aligned
local TITLE_H = 24
local PAD = 8

-- Per-state color, used for both the row's text and its status dot. `busy` deliberately shares the
-- gold of an interactive control: the step IS happening, and graying it out would read as "nothing
-- is going on" during the one phase where the user most needs to know the addon is recording.
local COLORS = {
    done   = { 0.30, 0.85, 0.30 },
    -- Same green as `done`: it has been run. Still clickable, because re-reading a report costs
    -- nothing and is regularly wanted twice.
    used   = { 0.30, 0.85, 0.30 },
    ready  = { 0.90, 0.90, 0.92 },
    busy   = { 1.00, 0.82, 0.00 },
    locked = { 0.40, 0.40, 0.42 },
    -- Muted red rather than a warning red: cancel is always available, so a shade that shouts would
    -- shout on every frame of every run.
    cancel = { 0.80, 0.32, 0.32 },
}

-- Command column, dimmer than its row so it reads as reference rather than as another control.
local CMD_COLOR = { 0.45, 0.45, 0.48 }

local LOCKED_DOT_ALPHA = 0.35
local CHECK = 12                                   -- the done mark, centered over the dot
local HOVER_GOLD   = { 1, 0.82, 0 }
local HOVER_CANCEL = { 1.00, 0.45, 0.45 }
local CENTER_X = -320                              -- Perf's spot, set once at build

local function setColor(fs, c) fs:SetTextColor(c[1], c[2], c[3]) end
local function colorOf(state) return COLORS[state] or COLORS.locked end

local function required(d, field, kind)
  if type(d[field]) ~= kind then
    error(("LibKa0s-Widgets-1.0: StepPanel requires d.%s (a %s)"):format(field, kind), 3)
  end
end

local function checkDescriptor(d)
  if type(d) ~= "table" then
    error("LibKa0s-Widgets-1.0: StepPanel requires a descriptor table", 3)
  end
  required(d, "name", "string")
  required(d, "addonName", "string")
  required(d, "rows", "function")
  required(d, "onClick", "function")
end

local function readRows(d)
  local list = d.rows()
  if type(list) ~= "table" then return {} end
  return list
end

local function readTitle(d)
  local t = d.title
  if type(t) == "function" then t = t() end
  return t ~= nil and tostring(t) or ""
end

--- The footer, when the descriptor carries a usable one: a number height and two functions.
local function footerOf(d)
  local f = d.footer
  if type(f) ~= "table" or type(f.build) ~= "function" or type(f.paint) ~= "function" then return nil end
  if type(f.height) ~= "number" or f.height < 0 then return nil end
  return f
end

--- Re-pin the height bounds to `h`, keeping the width bounds MakeResizable set. Guarded like
--- Core's setBounds, because SetResizeBounds replaced the SetMinResize / SetMaxResize pair in 10.0.
local function pinHeight(frame, minW, h)
  if type(frame.SetResizeBounds) == "function" then
    local curMinW, _, curMaxW
    if type(frame.GetResizeBounds) == "function" then curMinW, _, curMaxW = frame:GetResizeBounds() end
    local loW = (type(curMinW) == "number" and curMinW > 0) and curMinW or minW
    local hiW = (type(curMaxW) == "number" and curMaxW >= loW) and curMaxW or loW
    frame:SetResizeBounds(loW, h, hiW, h)
    return
  end
  if type(frame.SetMinResize) == "function" then frame:SetMinResize(minW, h) end
  if type(frame.SetMaxResize) == "function" then
    local sw = type(UIParent) == "table" and type(UIParent.GetWidth) == "function" and UIParent:GetWidth()
    frame:SetMaxResize((type(sw) == "number" and sw > minW) and sw or minW, h)
  end
end

--- Build one step panel. See the API document for the descriptor and the handle.
function lib.StepPanel(d)
  checkDescriptor(d)
  local footer = footerOf(d)
  local showClose = d.close ~= false
  local panel = {}
  local frame
  local buttons, shown, pinnedCount = {}, 0, nil
  local minW = ROW_W + PAD * 2

  local function heightFor(n)
    local h = TITLE_H + PAD * 2 + n * (ROW_H + GAP)
    if footer then h = h + footer.height + PAD end
    return h
  end

  local function rowWidth()
    local w = frame:GetWidth()
    if type(w) == "number" and w > PAD * 2 then return w - PAD * 2 end
    return ROW_W
  end

  local function stretchRows(w)
    if type(w) ~= "number" or w <= 0 then w = frame:GetWidth() end
    if type(w) ~= "number" or w <= 0 then return end
    for _, b in ipairs(buttons) do b:SetWidth(w - PAD * 2) end
  end

  local function onEnter(b)
    local row = b.__row
    if not row then return end
    -- Hover marks what a click would do, so only an actionable row lights up; a tip is for any row
    -- (a done step's tip says what it did).
    if row.actionable then setColor(b.text, row.state == "cancel" and HOVER_CANCEL or HOVER_GOLD) end
    if row.tip ~= nil and type(d.tooltip) == "function" then
      b.__tipShown = true
      d.tooltip(b, row)
    end
  end

  local function onLeave(b)
    if b.__row then setColor(b.text, colorOf(b.__row.state)) end
    if b.__tipShown then
      b.__tipShown = nil
      if type(GameTooltip) == "table" and GameTooltip.Hide then GameTooltip:Hide() end
    end
  end

  local function onClick(b)
    local index = b.__index
    local row = readRows(d)[index]
    if row and row.actionable then d.onClick(row, index) end
    panel.Refresh()
  end

  local function makeRow(index)
    local b = CreateFrame("Button", nil, frame)
    b:SetSize(rowWidth(), ROW_H)
    b:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -(TITLE_H + PAD + (index - 1) * (ROW_H + GAP)))
    -- A solid color texture, not a glyph or an art path: PerfPanel.lua's note on the dot.
    b.dot = b:CreateTexture(nil, "ARTWORK")
    b.dot:SetSize(DOT, DOT)
    b.dot:SetPoint("LEFT", b, "LEFT", DOT_X, 0)
    if type(d.check) == "string" or type(d.check) == "number" then
      b.check = b:CreateTexture(nil, "OVERLAY")
      b.check:SetSize(CHECK, CHECK)
      b.check:SetPoint("CENTER", b.dot, "CENTER", 0, 0)
      b.check:SetTexture(d.check)
      b.check:Hide()
    end
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.text:SetPoint("LEFT", b, "LEFT", LABEL_X, 0)
    b.text:SetJustifyH("LEFT")
    b.cmd = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.cmd:SetPoint("RIGHT", b, "RIGHT", -CMD_PAD, 0)
    b.cmd:SetJustifyH("RIGHT")
    setColor(b.cmd, CMD_COLOR)
    b.__index = index
    b:SetScript("OnEnter", onEnter)
    b:SetScript("OnLeave", onLeave)
    b:SetScript("OnClick", onClick)
    return b
  end

  local function paintRow(b, row)
    b.__row = row
    local c = colorOf(row.state)
    b.text:SetText(row.label)
    b.cmd:SetText(row.command)
    setColor(b.text, c)
    if b.dot.SetColorTexture then
      b.dot:SetColorTexture(c[1], c[2], c[3], row.state == "locked" and LOCKED_DOT_ALPHA or 1)
    end
    local done = b.check ~= nil and row.state == "done"
    if b.check then
      b.check:SetVertexColor(c[1], c[2], c[3])
      b.check:SetShown(done)
    end
    b.dot:SetShown(not done)
    if row.actionable then b:Enable() else b:Disable() end
    -- What was rendered, for the headless suites (PerfPanel.lua records the same three).
    b.__label, b.__state, b.__command = row.label, row.state, row.command
    b:Show()
  end

  local function build()
    local n = #readRows(d)
    frame = CreateFrame("Frame", d.name, UIParent, "BackdropTemplate")
    frame:SetSize(minW, heightFor(n))
    frame:SetPoint("CENTER", CENTER_X, 0)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -6)
    frame.title:SetText(readTitle(d))
    if showClose then
      -- The third argument is the addon FOLDER the close icon's path is built from; without it
      -- MakeCloseButton falls back to the multiplication sign (Perf panel minor 3's bug).
      local close = core.MakeCloseButton(frame, panel.Hide, d.addonName)
      if close then
        close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -(TITLE_H - 18) / 2)
        frame.closeButton = close
      end
    end
    if footer then
      footer.build(frame, {
        Show = panel.Show, Hide = panel.Hide, Toggle = panel.Toggle, IsShown = panel.IsShown,
        Refresh = panel.Refresh, Buttons = panel.Buttons,
        TITLE_H = TITLE_H, PAD = PAD, ROW_W = ROW_W,
      })
    end
    core.ApplySkin(frame)
    frame:Hide()
    if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, d.name) end
    core.MakeResizable(frame, {
      minWidth = minW, minHeight = heightFor(n), widthOnly = true, onResize = stretchRows,
    })
    pinnedCount = n
  end

  function panel.Frame()
    if frame then return frame end
    if type(CreateFrame) ~= "function" then return nil end
    build()
    return frame
  end

  --- Repaint from `rows()` and the title. Cheap and idempotent: safe on every host transition.
  function panel.Refresh()
    if not frame then return end
    frame.title:SetText(readTitle(d))
    local list = readRows(d)
    for i, row in ipairs(list) do
      buttons[i] = buttons[i] or makeRow(i)
      paintRow(buttons[i], row)
    end
    shown = #list
    for i = shown + 1, #buttons do
      buttons[i].__row = nil
      buttons[i]:Hide()
    end
    local h = heightFor(shown)
    frame:SetHeight(h)
    if shown ~= pinnedCount then
      pinHeight(frame, minW, h)
      pinnedCount = shown
    end
    if footer then footer.paint(frame) end
  end

  function panel.Show()
    local f = panel.Frame()
    if not f then return end
    panel.Refresh()
    f:Show()
  end

  function panel.Hide() if frame then frame:Hide() end end
  function panel.IsShown() return (frame and frame:IsShown()) and true or false end
  function panel.Toggle()
    if panel.IsShown() then panel.Hide() else panel.Show() end
  end

  --- The row buttons of the last paint, by index. A fresh table: writing to it moves nothing.
  function panel.Buttons()
    local out = {}
    for i = 1, shown do out[i] = buttons[i] end
    return out
  end

  return panel
end
