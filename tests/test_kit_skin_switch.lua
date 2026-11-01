-- tests/test_kit_skin_switch.lua — the skin-switch check (testkit/skin_switch.lua) and the kit suite
-- that runs it (testkit/test_skin_switch.lua). This repo also wires the suite live, over
-- tests/fixture_skin_switch.lua's painted surfaces; this file drives what that run cannot show: a
-- surface that does not change, a surface that draws nothing, and what is excluded.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local F = dofile("tests/fixture_skin_paint.lua")
local W = dofile("tests/_kit/skin_switch.lua")

local OWNER = "SwitchHost"

local function env()
  local m, Skin = F.env()
  local S = F.owner(Skin, OWNER)
  return m, Skin, S
end

--- A plain object with one drawing setter, standing in for a region.
local function region()
  return { SetVertexColor = function() end, SetTextColor = function() end }
end

--- A surface that repaints from token `name` through the host's own paint.
local function tinted(Skin, name, extra)
  local r = region()
  local s = {
    name = "tinted " .. name,
    build = function() return r end,
    paint = function(o) o:SetVertexColor(Skin:Color(OWNER, name)) end,
  }
  for k, v in pairs(extra or {}) do s[k] = v end
  return s
end

local function facts(Skin, surfaces) return { owner = OWNER, skin = Skin, surfaces = surfaces } end

-- ── the probe ────────────────────────────────────────────────────────────────────────────────

local function colorText(c) return ("%.3f %.3f %.3f %.3f"):format(c[1], c[2], c[3], c[4] or 1) end

test("skin switch: the probe gives every token a value of its kind", function()
  local _, Skin = env()
  local tokens = W.probeTokens(Skin)
  for _, e in ipairs(Skin.SCHEMA) do
    assertTrue(tokens[e.name] ~= nil, e.name .. " has no probe value")
  end
end)

test("skin switch: every probe color is its own, and none is Ka0s Default's", function()
  local _, Skin = env()
  local tokens, base, seen = W.probeTokens(Skin), Skin:ResolveSkin("ka0s"), {}
  for _, e in ipairs(Skin.SCHEMA) do
    if e.kind == "color" then
      local text = colorText(tokens[e.name])
      assertEqual(seen[text], nil, e.name .. " repeats a value")
      seen[text] = e.name
      local was = base[e.name]
      if type(was) == "table" then assertTrue(colorText(was) ~= text, e.name .. " equals Ka0s Default") end
    end
  end
end)

test("skin switch: the tokens a real skin shares are apart under the probe", function()
  local _, Skin = env()
  local tokens = W.probeTokens(Skin)
  assertTrue(colorText(tokens["icon.arrow"]) ~= colorText(tokens["hud.label"]))
  assertTrue(colorText(tokens["menu.text"]) ~= colorText(tokens["text.body"]))
end)

test("skin switch: a number, a bool and a list move off Ka0s Default", function()
  local _, Skin = env()
  local tokens, base = W.probeTokens(Skin), Skin:ResolveSkin("ka0s")
  for _, e in ipairs(Skin.SCHEMA) do
    if e.kind == "number" or e.kind == "bool" then
      assertTrue(tokens[e.name] ~= base[e.name], e.name)
    elseif e.kind == "colors" and base[e.name] then
      assertEqual(#tokens[e.name], #base[e.name], e.name)
      assertTrue(colorText(tokens[e.name][1]) ~= colorText(base[e.name][1]), e.name)
    end
  end
end)

test("skin switch: a string takes another skin's value where one exists", function()
  local _, Skin = env()
  local tokens, base = W.probeTokens(Skin), Skin:ResolveSkin("ka0s")
  assertTrue(tokens["font.body"] ~= base["font.body"], "a real face, so a font pick resolves")
  local found = false
  for _, def in ipairs(Skin:Skins()) do
    if Skin:ResolveSkin(def.key)["font.body"] == tokens["font.body"] then found = true end
  end
  assertTrue(found, "the probe's face is one a skin ships")
end)

test("skin switch: the probe leaves no skin behind, and the owner keeps its choice", function()
  local _, Skin = env()
  local count = #Skin:Skins()
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(W.runSurface(facts(Skin), tinted(Skin, "text.body"), "clear"), nil)
  assertEqual(#Skin:Skins(), count)
  assertEqual(Skin:GetSkin(W.PROBE_KEY), nil)
  assertEqual(#Skin.__order, count)
  local _, skin = Skin:GetChoice(OWNER)
  assertEqual(skin, "obsidian")
end)

-- ── the spies ────────────────────────────────────────────────────────────────────────────────

test("skin switch: a spy sees a frame's regions and children, and comes off again", function()
  local m = env()
  local frame = m.CreateFrame("Frame")
  local tex = frame:CreateTexture()
  local child = m.CreateFrame("Frame", nil, frame)
  local fs = child:CreateFontString()
  local real = rawget(tex, "SetVertexColor")
  local rec = W.spy({ frame })
  tex:SetVertexColor(0.1, 0.2, 0.3)
  fs:SetTextColor(0.4, 0.5, 0.6)
  frame:SetBackdrop({ bgFile = "x" })
  local n = 0
  for _ in pairs(rec.log) do n = n + 1 end
  assertEqual(n, 3)
  rec.undo()
  assertEqual(rawget(tex, "SetVertexColor"), real)
  assertEqual(tex.__paintVertex and nil, nil)
end)

test("skin switch: a spied setter still draws", function()
  local m = env()
  local frame = m.CreateFrame("Frame")
  local tex = frame:CreateTexture()
  local rec = W.spy({ frame })
  tex:SetVertexColor(0.1, 0.2, 0.3)
  rec.undo()
  local r = tex:GetVertexColor()
  assertEqual(r, 0.1)
end)

test("skin switch: a run takes its spies off the surface", function()
  local _, Skin = env()
  local s = tinted(Skin, "text.body")
  local r = s.build()
  local real = r.SetVertexColor
  assertEqual(W.runSurface(facts(Skin), s, "clear"), nil)
  assertEqual(r.SetVertexColor, real)
end)

-- ── one surface ──────────────────────────────────────────────────────────────────────────────

test("skin switch: a surface that follows a token passes", function()
  local _, Skin = env()
  assertEqual(W.runSurface(facts(Skin), tinted(Skin, "text.body"), "clear"), nil)
end)

test("skin switch: a surface that redraws its literal fails, naming the setter", function()
  local _, Skin = env()
  local r = region()
  local problem = W.runSurface(facts(Skin), {
    name = "typed", build = function() return r end,
    paint = function(o) o:SetVertexColor(0.5, 0.5, 0.5) end,
  }, "clear")
  assertTrue(problem ~= nil and problem:find("typed", 1, true) ~= nil, tostring(problem))
  assertTrue(problem:find("SetVertexColor", 1, true) ~= nil, problem)
  assertTrue(problem:find("did not change", 1, true) ~= nil, problem)
end)

test("skin switch: a surface that draws nothing on a switch fails", function()
  local _, Skin = env()
  local r = region()
  local problem = W.runSurface(facts(Skin), { name = "idle", build = function() return r end }, "clear")
  assertTrue(problem ~= nil and problem:find("drew nothing", 1, true) ~= nil, tostring(problem))
end)

test("skin switch: a surface built before the switch repaints with no host call", function()
  local m, Skin, S = env()
  local frame = m.CreateFrame("Frame")
  local problem = W.runSurface(facts(Skin), {
    name = "panel", build = function() S.Panel(frame); return frame end,
  }, "clear")
  assertEqual(problem, nil)
end)

test("skin switch: a region made on the first repaint is compared on the later two", function()
  local m, Skin = env()
  local frame = m.CreateFrame("Frame")
  local tex
  local problem = W.runSurface(facts(Skin), {
    name = "lazy", build = function() return frame end,
    paint = function(o)
      tex = tex or o:CreateTexture()
      tex:SetVertexColor(0.5, 0.5, 0.5)
    end,
  }, "clear")
  assertTrue(problem ~= nil and problem:find("did not change", 1, true) ~= nil, tostring(problem))
end)

test("skin switch: only one surface's own draws count", function()
  local _, Skin = env()
  local changing, still = tinted(Skin, "text.body"), region()
  local problem = W.runSurface(facts(Skin), {
    name = "still", build = function() return still end,
    paint = function(o)
      changing.paint(changing.build())
      o:SetVertexColor(0.5, 0.5, 0.5)
    end,
  }, "clear")
  assertTrue(problem ~= nil, "another surface's change hid this one")
end)

test("skin switch: a table argument is compared by contents", function()
  local _, Skin = env()
  local r = { SetBackdrop = function() end }
  local problem = W.runSurface(facts(Skin), {
    name = "same backdrop", build = function() return r end,
    paint = function(o) o:SetBackdrop({ bgFile = "x", edgeSize = 1 }) end,
  }, "clear")
  assertTrue(problem ~= nil, "two equal fresh tables read as a change")
end)

-- ── noise ────────────────────────────────────────────────────────────────────────────────────

--- A surface that redraws a literal, and `noise(region, paint number)` beside it.
local function noisy(name, noise)
  local r = { SetVertexColor = function() end, SetText = function() end, SetAlpha = function() end,
              SetFontObject = function() end, SetTexture = function() end }
  local paints = 0
  return {
    name = name, build = function() return r end,
    paint = function(o)
      paints = paints + 1
      o:SetVertexColor(0.5, 0.5, 0.5)
      noise(o, paints)
    end,
  }
end

local NOISE = {
  { "a counter", function(o, n) o:SetText(tostring(n)) end },
  { "a formatted counter", function(o, n) o:SetFontObject({ tick = n }) end },
  { "a toggling alpha", function(o, n) o:SetAlpha(n % 2) end },
  { "a setter on even paints", function(o, n) if n % 2 == 0 then o:SetAlpha(1) end end },
  { "a setter on odd paints", function(o, n) if n % 2 == 1 then o:SetAlpha(1) end end },
}

test("skin switch: a change the skin did not cause does not pass a literal surface", function()
  -- red under: three flips compared once, where any setter that moved between them read as the skin.
  local _, Skin = env()
  for _, row in ipairs(NOISE) do
    local problem = W.runSurface(facts(Skin), noisy(row[1], row[2]), "clear")
    assertTrue(problem ~= nil, row[1] .. " read as the skin")
    assertTrue(problem:find("did not change", 1, true) ~= nil, problem)
  end
end)

test("skin switch: noise leaves a surface that does follow the skin passing", function()
  local _, Skin = env()
  for _, row in ipairs(NOISE) do
    local s = noisy(row[1], row[2])
    local paint = s.paint
    s.paint = function(o)
      paint(o)
      o:SetVertexColor(Skin:Color(OWNER, "text.body"))
    end
    assertEqual(W.runSurface(facts(Skin), s, "clear"), nil, row[1])
  end
end)

test("skin switch: a surface that only draws noise is told so", function()
  local _, Skin = env()
  local r = { SetText = function() end }
  local n = 0
  local problem = W.runSurface(facts(Skin), {
    name = "ticker", build = function() return r end,
    paint = function(o) n = n + 1; o:SetText(tostring(n)) end,
  }, "clear")
  assertTrue(problem ~= nil and problem:find("moved between two draws", 1, true) ~= nil, tostring(problem))
  assertTrue(problem:find("SetText", 1, true) ~= nil, problem)
end)

test("skin switch: a setter only one skin draws is a change", function()
  -- a skin-driven `if`: the key exists under the probe alone, in both home flips alike.
  local _, Skin = env()
  local r = region()
  local problem = W.runSurface(facts(Skin), {
    name = "conditional", build = function() return r end,
    paint = function(o)
      o:SetTextColor(0.5, 0.5, 0.5)
      if Skin:GetChoice(OWNER) and select(2, Skin:GetChoice(OWNER)) == W.PROBE_KEY then
        o:SetVertexColor(0.1, 0.2, 0.3)
      end
    end,
  }, "clear")
  assertEqual(problem, nil)
end)

test("skin switch: a host that skips an unchanged repaint still reads as changing", function()
  -- the extra repaint under the probe draws nothing here, which must count for nothing.
  local _, Skin = env()
  local r = region()
  local last
  local problem = W.runSurface(facts(Skin), {
    name = "cached", build = function() return r end,
    paint = function(o)
      local c = Skin:Color(OWNER, "text.body")
      local key = table.concat({ c, select(2, Skin:Color(OWNER, "text.body")) }, ",")
      if key ~= last then last = key; o:SetVertexColor(Skin:Color(OWNER, "text.body")) end
    end,
  }, "clear")
  assertEqual(problem, nil)
end)

-- ── the exclusions ───────────────────────────────────────────────────────────────────────────

test("skin switch: the first pass clears the Scope", function()
  local _, Skin = env()
  Skin:SetIgnore(OWNER, true, true)
  local panelOn
  local s = tinted(Skin, "text.body", { scope = "panel" })
  local paint = s.paint
  s.paint = function(o) panelOn = Skin:__PanelSkinned(OWNER); paint(o) end
  assertEqual(W.runSurface(facts(Skin), s, "clear"), nil)
  assertEqual(panelOn, true)
  local panel, fonts = Skin:GetIgnore(OWNER)
  assertEqual(panel, true, "and puts it back")
  assertEqual(fonts, true)
end)

test("skin switch: the first pass turns a companion on", function()
  local _, Skin = env()
  local on, seen = false, nil
  local s = tinted(Skin, "text.body", { companion = function(v) on = v end })
  local paint = s.paint
  s.paint = function(o) seen = on; paint(o) end
  assertEqual(W.runSurface(facts(Skin), s, "clear"), nil)
  assertEqual(seen, true)
end)

test("skin switch: a Scope-ignored surface is excluded from the second pass", function()
  local _, Skin = env()
  local r = region()
  local problem, excluded = W.runSurface(facts(Skin), {
    name = "stock", scope = "panel", build = function() return r end,
    paint = function(o) o:SetVertexColor(0.5, 0.5, 0.5) end,
  }, "ignored")
  assertEqual(problem, nil)
  assertEqual(excluded, true)
end)

test("skin switch: a companion surface is excluded from the second pass", function()
  local _, Skin = env()
  local _, excluded = W.runSurface(facts(Skin),
    tinted(Skin, "text.body", { companion = function() end }), "ignored")
  assertEqual(excluded, true)
end)

test("skin switch: a surface with neither still has to change in the second pass", function()
  local _, Skin = env()
  local r = region()
  local problem, excluded = W.runSurface(facts(Skin), {
    name = "hud", build = function() return r end,
    paint = function(o) o:SetVertexColor(0.5, 0.5, 0.5) end,
  }, "ignored")
  assertTrue(problem ~= nil, "it hid behind the Scope")
  assertEqual(excluded, nil)
end)

test("skin switch: the second pass holds the Scope ignored while it switches", function()
  local _, Skin = env()
  local seen
  local s = tinted(Skin, "text.body")
  local paint = s.paint
  s.paint = function(o) seen = Skin:__PanelSkinned(OWNER); paint(o) end
  assertEqual(W.runSurface(facts(Skin), s, "ignored"), nil)
  assertEqual(seen, false)
end)

test("skin switch: a surface that raises is reported, and state comes back", function()
  local _, Skin = env()
  Skin:SetChoice(OWNER, "ka0s", "glass")
  local problem = W.runSurface(facts(Skin), {
    name = "boom", build = function() error("no frame") end,
  }, "clear")
  assertTrue(problem ~= nil and problem:find("no frame", 1, true) ~= nil, tostring(problem))
  assertEqual(Skin:GetSkin(W.PROBE_KEY), nil)
  local _, skin = Skin:GetChoice(OWNER)
  assertEqual(skin, "glass")
end)

-- ── the facts ────────────────────────────────────────────────────────────────────────────────

test("skin switch: facts name a registered owner and at least one surface", function()
  local _, Skin = env()
  local function problem(f) return W.factsProblems(f)[1] end
  assertEqual(problem(facts(Skin, { tinted(Skin, "text.body") })), nil)
  assertTrue(problem({ skin = Skin, surfaces = {} }):find("owner", 1, true) ~= nil)
  assertTrue(problem({ owner = "Nobody", skin = Skin, surfaces = { tinted(Skin, "text.body") } })
    :find("not registered", 1, true) ~= nil)
  assertTrue(problem(facts(Skin, {})):find("no painted surface", 1, true) ~= nil)
  assertTrue(problem({ owner = OWNER, surfaces = {} }):find("skin", 1, true) ~= nil)
end)

test("skin switch: a surface needs a name, a build and a Scope it can mean", function()
  local _, Skin = env()
  local function problem(s) return W.factsProblems(facts(Skin, { s }))[1] end
  assertTrue(problem({ build = function() end }):find("no name", 1, true) ~= nil)
  assertTrue(problem({ name = "x" }):find("no build", 1, true) ~= nil)
  assertTrue(problem({ name = "x", build = function() end, scope = "hud" }):find("scope", 1, true) ~= nil)
  assertTrue(problem({ name = "x", build = function() end, companion = true }):find("companion", 1, true) ~= nil)
end)

test("skin switch: two surfaces may not share a name", function()
  local _, Skin = env()
  local a = tinted(Skin, "text.body")
  assertTrue(W.factsProblems(facts(Skin, { a, a }))[1]:find("twice", 1, true) ~= nil)
end)

-- ── the kit suite, driven by a stand-in ──────────────────────────────────────────────────────

local function suite(f)
  local cases = {}
  local kit = {
    skinSwitch = f,
    test = function(name, fn, skip) cases[#cases + 1] = { name = name, fn = fn, skip = skip } end,
    fail = function(msg) error(msg, 0) end,
  }
  assert(loadfile("tests/_kit/test_skin_switch.lua"))(kit)
  return cases
end

test("skin switch suite: unset facts are one declared skip that names the rule", function()
  local cases = suite(nil)
  assertEqual(#cases, 1)
  assertEqual(cases[1].fn, nil)
  assertTrue(cases[1].skip:find("skinning-§1", 1, true) ~= nil, cases[1].skip)
end)

test("skin switch suite: bad facts fail at load", function()
  assertTrue(not pcall(suite, "x"))
  local _, Skin = env()
  assertTrue(not pcall(suite, facts(Skin, {})))
end)

test("skin switch suite: a surface gets a case per pass, and an excluded one its first only", function()
  local _, Skin = env()
  local cases = suite(facts(Skin, {
    tinted(Skin, "text.body"), tinted(Skin, "text.value", { scope = "panel" }),
  }))
  local names = {}
  for _, c in ipairs(cases) do names[#names + 1] = c.name end
  local text = table.concat(names, "\n")
  assertTrue(text:find("tinted text.body changes", 1, true) ~= nil, text)
  assertTrue(text:find("tinted text.body changes with the Scope ignored", 1, true) ~= nil, text)
  assertTrue(text:find("tinted text.value changes with the Scope ignored", 1, true) == nil, text)
  for _, c in ipairs(cases) do c.fn() end
end)

test("skin switch suite: a surface that does not change fails its case", function()
  local _, Skin = env()
  local r = region()
  local cases = suite(facts(Skin, { {
    name = "typed", build = function() return r end,
    paint = function(o) o:SetVertexColor(0.5, 0.5, 0.5) end,
  } }))
  local failed = 0
  for _, c in ipairs(cases) do
    if c.name:find("typed", 1, true) and not pcall(c.fn) then failed = failed + 1 end
  end
  assertEqual(failed, 2, "both passes")
end)
