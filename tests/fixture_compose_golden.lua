-- tests/fixture_compose_golden.lua — what every PATH-KEYED composer call emitted before compose
-- minor 4 added the record-backed arm, frozen as text.
--
-- The arm's contract with the collection is that a caller who never passes `bind` gets exactly the
-- rows it got at compose minor 3. "Exactly" is checkable only against a record taken BEFORE the
-- change, so these strings were generated from OptionsCompose.lua minor 3 (v1.30.0) and are never
-- regenerated from the current file: a golden rewritten from the code under test proves nothing.
-- If a later minor changes path-keyed output ON PURPOSE, the case that reads this file goes red,
-- and the new strings are written in the same commit as the change that explains them.
--
-- `serialize` is deterministic: keys sorted, functions written as `fn`, nested tables inline. It
-- records every field of every row -- not just the leaf list the shape cases already pin -- because
-- a composer that kept its paths and changed a label, a default or an order would pass those.

local G = {}

local function keyOf(k) return type(k) == "string" and k or ("[" .. tostring(k) .. "]") end

function G.serialize(v)
  local t = type(v)
  if t == "function" then return "fn" end
  if t == "string" then return string.format("%q", v) end
  if t ~= "table" then return tostring(v) end
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return keyOf(a) < keyOf(b) end)
  local parts = {}
  for _, k in ipairs(keys) do parts[#parts + 1] = keyOf(k) .. "=" .. G.serialize(v[k]) end
  return "{" .. table.concat(parts, ",") .. "}"
end

--- The calls, by name. Chosen to reach every spec field the common spec documents and every
--- composer-specific one, so an arm that leaked into the path-keyed branch shows up somewhere.
function G.calls(O)
  local block = { page = "general", group = "Appearance", subgroup = "Bar" }
  local function spec(extra)
    local s = {}
    for k, v in pairs(block) do s[k] = v end
    for k, v in pairs(extra or {}) do s[k] = v end
    return s
  end
  return {
    { "ColorPair/plain", function() return O.ColorPair(spec()) end },
    { "ColorPair/full", function()
      return O.ColorPair(spec{ key = "bgColor", label = "Background color", hasAlpha = false,
        prefix = "frame.", order = 40, classColor = { source = "unit", unit = "target", default = true },
        extra = { { path = "frame.bgInset", type = "number", label = "Inset", min = 0, max = 8 } } })
    end },
    { "FontGroup/plain", function() return O.FontGroup(spec()) end },
    { "FontGroup/full", function()
      return O.FontGroup(spec{ prefix = "units.target.", order = 100, hasAlpha = false,
        keys = { font = "face", useClassColorFont = "classFont" },
        labels = { fontSize = "Size" }, defaults = { fontSize = 14, fontFlags = "" },
        omit = { fontShadow = true },
        extra = { { path = "units.target.justify", type = "string", label = "Justify" } } })
    end },
    { "BorderGroup/plain", function() return O.BorderGroup(spec()) end },
    { "BorderGroup/show", function()
      return O.BorderGroup(spec{ show = true, prefix = "p.", keys = { borderStyle = "borderTexture" },
        classColor = { source = "player" },
        extra = { { path = "p.borderOffset", type = "number", label = "Border offset" } } })
    end },
    { "BarGroup/plain", function() return O.BarGroup(spec()) end },
    { "BarGroup/full", function()
      return O.BarGroup(spec{ prefix = "bars.", order = 7, labels = { barAlpha = "Fill opacity" },
        defaults = { barTexture = "Smooth" }, omit = { useClassColorBar = true } })
    end },
    { "MasterControls/framed", function()
      local rows, tail = O.MasterControls{ addonName = "Test Host", page = "general",
        onResetAll = function() end, onResetPosition = function() end }
      return { rows = rows, tail = tail }
    end },
    { "MasterControls/frameless", function()
      local rows, tail = O.MasterControls{ addonName = "Test Host", page = "general", frameless = true,
        debugConsolePath = "session.console", prefix = "general.", group = "Master",
        leadButton = { text = "Go", onClick = function() end },
        extra = { { path = "general.extraRow", type = "bool", label = "Extra" } } }
      return { rows = rows, tail = tail }
    end },
  }
end

-- Generated from OptionsCompose.lua minor 3 (LibKa0s v1.30.0). Do not regenerate from a later file.
G.GOLDEN = {
  ["ColorPair/plain"] = "{[1]={classColorSource=\"player\",group=\"Appearance\",hasAlpha=true,label=\"Color\",order=0,page=\"general\",path=\"color\",startsLine=true,subgroup=\"Bar\",tooltip=\"The color. Not read while Use class color is on, except for its opacity, which always applies.\",type=\"color\"},[2]={classColorSource=\"player\",default=false,group=\"Appearance\",label=\"Use class color\",order=10,page=\"general\",path=\"useClassColorColor\",subgroup=\"Bar\",tooltip=\"Take this color from the class color instead of the swatch beside it.\",type=\"bool\"}}",
  ["ColorPair/full"] = "{[1]={classColorSource=\"unit\",classColorUnit=\"target\",group=\"Appearance\",hasAlpha=false,label=\"Background color\",order=40,page=\"general\",path=\"frame.bgColor\",startsLine=true,subgroup=\"Bar\",tooltip=\"The background color. Not read while Use class color is on, except for its opacity, which always applies.\",type=\"color\"},[2]={classColorSource=\"unit\",classColorUnit=\"target\",default=true,group=\"Appearance\",label=\"Use class color\",order=50,page=\"general\",path=\"frame.useClassColorBgColor\",subgroup=\"Bar\",tooltip=\"Take this color from the class color instead of the swatch beside it.\",type=\"bool\"},[3]={group=\"Appearance\",label=\"Inset\",max=8,min=0,order=60,page=\"general\",path=\"frame.bgInset\",subgroup=\"Bar\",type=\"number\"}}",
  ["FontGroup/plain"] = "{[1]={default=\"Friz Quadrata TT\",dialogControl=\"LSM30_Font\",group=\"Appearance\",label=\"Font\",order=0,page=\"general\",path=\"font\",startsLine=true,subgroup=\"Bar\",tooltip=\"The face this text is drawn in.\",type=\"string\",values=fn},[2]={default=12,group=\"Appearance\",label=\"Font size\",max=32,min=6,order=10,page=\"general\",path=\"fontSize\",step=1,subgroup=\"Bar\",tooltip=\"Height of the text, in points.\",type=\"number\"},[3]={classColorSource=\"player\",group=\"Appearance\",hasAlpha=true,label=\"Font color\",order=20,page=\"general\",path=\"fontColor\",startsLine=true,subgroup=\"Bar\",tooltip=\"The color the text is drawn in. Not read while Use class color is on, except for its opacity, which always applies.\",type=\"color\"},[4]={classColorSource=\"player\",default=false,group=\"Appearance\",label=\"Use class color\",order=30,page=\"general\",path=\"useClassColorFont\",subgroup=\"Bar\",tooltip=\"Draw this text in the class color instead of the swatch beside it.\",type=\"bool\"},[5]={default=\"OUTLINE\",group=\"Appearance\",label=\"Font flags\",order=40,page=\"general\",path=\"fontFlags\",sorting={[1]=\"\",[2]=\"OUTLINE\",[3]=\"THICKOUTLINE\",[4]=\"MONOCHROME\",[5]=\"OUTLINE, MONOCHROME\"},subgroup=\"Bar\",tooltip=\"Outline and monochrome rendering.\",type=\"string\",values={=\"None\",MONOCHROME=\"Monochrome\",OUTLINE=\"Outline\",OUTLINE, MONOCHROME=\"Monochrome outline\",THICKOUTLINE=\"Thick outline\"}},[6]={default=false,group=\"Appearance\",label=\"Font shadow\",order=50,page=\"general\",path=\"fontShadow\",subgroup=\"Bar\",tooltip=\"Draw a soft shadow behind the text, for legibility over bright art.\",type=\"bool\"}}",
  ["FontGroup/full"] = "{[1]={default=\"Friz Quadrata TT\",dialogControl=\"LSM30_Font\",group=\"Appearance\",label=\"Font\",order=100,page=\"general\",path=\"units.target.face\",startsLine=true,subgroup=\"Bar\",tooltip=\"The face this text is drawn in.\",type=\"string\",values=fn},[2]={default=14,group=\"Appearance\",label=\"Size\",max=32,min=6,order=110,page=\"general\",path=\"units.target.fontSize\",step=1,subgroup=\"Bar\",tooltip=\"Height of the text, in points.\",type=\"number\"},[3]={classColorSource=\"player\",group=\"Appearance\",hasAlpha=false,label=\"Font color\",order=120,page=\"general\",path=\"units.target.fontColor\",startsLine=true,subgroup=\"Bar\",tooltip=\"The color the text is drawn in. Not read while Use class color is on, except for its opacity, which always applies.\",type=\"color\"},[4]={classColorSource=\"player\",default=false,group=\"Appearance\",label=\"Use class color\",order=130,page=\"general\",path=\"units.target.classFont\",subgroup=\"Bar\",tooltip=\"Draw this text in the class color instead of the swatch beside it.\",type=\"bool\"},[5]={default=\"\",group=\"Appearance\",label=\"Font flags\",order=140,page=\"general\",path=\"units.target.fontFlags\",sorting={[1]=\"\",[2]=\"OUTLINE\",[3]=\"THICKOUTLINE\",[4]=\"MONOCHROME\",[5]=\"OUTLINE, MONOCHROME\"},subgroup=\"Bar\",tooltip=\"Outline and monochrome rendering.\",type=\"string\",values={=\"None\",MONOCHROME=\"Monochrome\",OUTLINE=\"Outline\",OUTLINE, MONOCHROME=\"Monochrome outline\",THICKOUTLINE=\"Thick outline\"}},[6]={group=\"Appearance\",label=\"Justify\",order=150,page=\"general\",path=\"units.target.justify\",subgroup=\"Bar\",type=\"string\"}}",
  ["BorderGroup/plain"] = "{[1]={default=\"None\",dialogControl=\"LSM30_Border\",group=\"Appearance\",label=\"Border style\",order=0,page=\"general\",path=\"borderStyle\",startsLine=true,subgroup=\"Bar\",tooltip=\"The border texture.\",type=\"string\",values=fn},[2]={default=1,group=\"Appearance\",label=\"Border thickness (px)\",max=16,min=0,order=10,page=\"general\",path=\"borderSize\",step=1,subgroup=\"Bar\",tooltip=\"Border edge width, in pixels.\",type=\"number\"},[3]={classColorSource=\"player\",group=\"Appearance\",hasAlpha=true,label=\"Border color\",order=20,page=\"general\",path=\"borderColor\",startsLine=true,subgroup=\"Bar\",tooltip=\"The color the border is drawn in. Not read while Use class color is on, except for its opacity, which always applies.\",type=\"color\"},[4]={classColorSource=\"player\",default=false,group=\"Appearance\",label=\"Use class color\",order=30,page=\"general\",path=\"useClassColorBorder\",subgroup=\"Bar\",tooltip=\"Draw this border in the class color instead of the swatch beside it.\",type=\"bool\"}}",
  ["BorderGroup/show"] = "{[1]={default=true,group=\"Appearance\",label=\"Show border\",order=0,page=\"general\",path=\"p.borderShow\",startsLine=true,subgroup=\"Bar\",tooltip=\"Draw a border around this element.\",type=\"bool\"},[2]={default=\"None\",dialogControl=\"LSM30_Border\",group=\"Appearance\",label=\"Border style\",order=10,page=\"general\",path=\"p.borderTexture\",startsLine=true,subgroup=\"Bar\",tooltip=\"The border texture.\",type=\"string\",values=fn},[3]={default=1,group=\"Appearance\",label=\"Border thickness (px)\",max=16,min=0,order=20,page=\"general\",path=\"p.borderSize\",step=1,subgroup=\"Bar\",tooltip=\"Border edge width, in pixels.\",type=\"number\"},[4]={classColorSource=\"player\",group=\"Appearance\",hasAlpha=true,label=\"Border color\",order=30,page=\"general\",path=\"p.borderColor\",startsLine=true,subgroup=\"Bar\",tooltip=\"The color the border is drawn in. Not read while Use class color is on, except for its opacity, which always applies.\",type=\"color\"},[5]={classColorSource=\"player\",default=false,group=\"Appearance\",label=\"Use class color\",order=40,page=\"general\",path=\"p.useClassColorBorder\",subgroup=\"Bar\",tooltip=\"Draw this border in the class color instead of the swatch beside it.\",type=\"bool\"},[6]={group=\"Appearance\",label=\"Border offset\",order=50,page=\"general\",path=\"p.borderOffset\",subgroup=\"Bar\",type=\"number\"}}",
  ["BarGroup/plain"] = "{[1]={default=\"Blizzard\",dialogControl=\"LSM30_Statusbar\",group=\"Appearance\",label=\"Bar texture\",order=0,page=\"general\",path=\"barTexture\",startsLine=true,subgroup=\"Bar\",tooltip=\"The bar's fill texture.\",type=\"string\",values=fn},[2]={default=1,group=\"Appearance\",isPercent=true,label=\"Bar opacity\",max=1,min=0,order=10,page=\"general\",path=\"barAlpha\",step=0.05,subgroup=\"Bar\",tooltip=\"How opaque the bar's fill is.\",type=\"number\"},[3]={classColorSource=\"player\",group=\"Appearance\",hasAlpha=true,label=\"Bar color\",order=20,page=\"general\",path=\"barColor\",startsLine=true,subgroup=\"Bar\",tooltip=\"The color the bar's fill is drawn in. Not read while Use class color is on, except for its opacity, which always applies.\",type=\"color\"},[4]={classColorSource=\"player\",default=false,group=\"Appearance\",label=\"Use class color\",order=30,page=\"general\",path=\"useClassColorBar\",subgroup=\"Bar\",tooltip=\"Draw this bar in the class color instead of the swatch beside it.\",type=\"bool\"}}",
  ["BarGroup/full"] = "{[1]={default=\"Smooth\",dialogControl=\"LSM30_Statusbar\",group=\"Appearance\",label=\"Bar texture\",order=7,page=\"general\",path=\"bars.barTexture\",startsLine=true,subgroup=\"Bar\",tooltip=\"The bar's fill texture.\",type=\"string\",values=fn},[2]={default=1,group=\"Appearance\",isPercent=true,label=\"Fill opacity\",max=1,min=0,order=17,page=\"general\",path=\"bars.barAlpha\",step=0.05,subgroup=\"Bar\",tooltip=\"How opaque the bar's fill is.\",type=\"number\"},[3]={classColorSource=\"player\",group=\"Appearance\",hasAlpha=true,label=\"Bar color\",order=27,page=\"general\",path=\"bars.barColor\",startsLine=true,subgroup=\"Bar\",tooltip=\"The color the bar's fill is drawn in. Not read while Use class color is on, except for its opacity, which always applies.\",type=\"color\"}}",
  ["MasterControls/framed"] = "{rows={[1]={default=true,group=\"Master controls\",label=\"Enable Test Host\",order=0,page=\"general\",path=\"enabled\",startsLine=true,tooltip=\"Turn the addon off without unloading it.\",type=\"bool\"},[2]={default=\"always\",group=\"Master controls\",label=\"General visibility\",order=10,page=\"general\",path=\"visibility\",sorting={[1]=\"always\",[2]=\"inCombat\",[3]=\"outOfCombat\",[4]=\"never\"},tooltip=\"When this addon's display is shown at all.\",type=\"string\",values={always=\"Always\",inCombat=\"Only in combat\",never=\"Never\",outOfCombat=\"Only out of combat\"}},[3]={default=1,group=\"Master controls\",label=\"Master scale\",max=2,min=0.5,order=20,page=\"general\",path=\"scale\",startsLine=true,step=0.05,tooltip=\"Scales the whole addon's display.\",type=\"number\"},[4]={default=1,group=\"Master controls\",isPercent=true,label=\"Master alpha\",max=1,min=0,order=30,page=\"general\",path=\"alpha\",step=0.05,tooltip=\"Opacity of the whole addon's display.\",type=\"number\"},[5]={default=false,group=\"Master controls\",label=\"Lock frame\",order=40,page=\"general\",path=\"locked\",startsLine=true,tooltip=\"Stop the frame being dragged.\",type=\"bool\"},[6]={group=\"Master controls\",label=\"Debug console\",order=50,page=\"general\",path=\"state.debugConsole\",sessionOnly=true,tooltip=\"Show this session's developer log window.\",type=\"bool\"}},tail=fn}",
  ["MasterControls/frameless"] = "{rows={[1]={default=true,group=\"Master\",label=\"Enable Test Host\",order=0,page=\"general\",path=\"general.enabled\",startsLine=true,tooltip=\"Turn the addon off without unloading it.\",type=\"bool\"},[2]={default=\"always\",group=\"Master\",label=\"General visibility\",order=10,page=\"general\",path=\"general.visibility\",sorting={[1]=\"always\",[2]=\"inCombat\",[3]=\"outOfCombat\",[4]=\"never\"},tooltip=\"When this addon's display is shown at all.\",type=\"string\",values={always=\"Always\",inCombat=\"Only in combat\",never=\"Never\",outOfCombat=\"Only out of combat\"}},[3]={group=\"Master\",label=\"Debug console\",order=20,page=\"general\",path=\"session.console\",sessionOnly=true,tooltip=\"Show this session's developer log window.\",type=\"bool\"},[4]={group=\"Master\",label=\"Extra\",order=30,page=\"general\",path=\"general.extraRow\",type=\"bool\"}},tail=fn}",
}

return G
