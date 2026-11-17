-- tests/fixture_de00.lua -- CIEDE2000 and the hover floor the skin suites share:
-- tests/test_skin_defs.lua (a title-bar control's hover, SR2-L1) and
-- tests/test_footer_button_hover.lua (a footer button's hover, SR2-L3). Moved out of the first,
-- unchanged, when the second was written, so the two cannot drift: one copy rather than two, for the
-- reason tests/fixture_widgets.lua gives.
--
-- Loaded as `dofile("tests/fixture_de00.lua")`. Holds no state.

local D = {}

-- The hover floor of SR2-L1 (ruling 1 of Ka0sAddonsCommonTasks
-- docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/SR2_SMOKE_ROUND2.md), ΔE00 from a control's rest to its
-- hover: 20, the lowest pair the owner accepted (Ember's title bar, 20.1). The owner's answer 3 of
-- the same addendum (SR2-L3) holds a footer button's label to it too.
D.HOVER_DE00_MIN = 20

--- One sRGB channel (0..1), linearized as WCAG 2 states it.
local function channel(c)
  if c <= 0.03928 then return c / 12.92 end
  return ((c + 0.055) / 1.055) ^ 2.4
end

--- CIEDE2000 (CIE 142-2001) between two sRGB colors, D65. The formula as Sharma, Wu and Dalal, "The
--- CIEDE2000 Color-Difference Formula: Implementation Notes, Supplementary Test Data, and Mathematical
--- Observations", Color Research & Application 30(1), 2005, state it, the hue rotation term R_T
--- included, kL = kC = kH = 1. L* alone cannot tell a hue change from a shade change; CIE76 cannot
--- either here (it scores WoW Midnight's bad title-bar pair 51 and Obsidian's good one 41).
local atan2 = math.atan2 or math.atan
function D.srgbToLab(c)
  local r, g, b = channel(c[1]), channel(c[2]), channel(c[3])
  local x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047
  local y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
  local z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883
  local function f(v) return v > (6 / 29) ^ 3 and v ^ (1 / 3) or v / (3 * (6 / 29) ^ 2) + 4 / 29 end
  return { 116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z)) }
end

function D.deltaE00(p, q)
  local rad, deg = math.rad, math.deg
  local L1, a1, b1, L2, a2, b2 = p[1], p[2], p[3], q[1], q[2], q[3]
  local Cbar = (math.sqrt(a1 * a1 + b1 * b1) + math.sqrt(a2 * a2 + b2 * b2)) / 2
  local G = 0.5 * (1 - math.sqrt(Cbar ^ 7 / (Cbar ^ 7 + 25 ^ 7)))
  local a1p, a2p = (1 + G) * a1, (1 + G) * a2
  local C1, C2 = math.sqrt(a1p * a1p + b1 * b1), math.sqrt(a2p * a2p + b2 * b2)
  local h1 = C1 == 0 and 0 or deg(atan2(b1, a1p)) % 360
  local h2 = C2 == 0 and 0 or deg(atan2(b2, a2p)) % 360
  local dh = 0
  if C1 * C2 ~= 0 then
    dh = h2 - h1
    if dh > 180 then dh = dh - 360 elseif dh < -180 then dh = dh + 360 end
  end
  local dL, dC, dH = L2 - L1, C2 - C1, 2 * math.sqrt(C1 * C2) * math.sin(rad(dh / 2))
  local Lb, Cb, hb = (L1 + L2) / 2, (C1 + C2) / 2, h1 + h2
  if C1 * C2 ~= 0 then
    if math.abs(h1 - h2) <= 180 then hb = (h1 + h2) / 2
    elseif h1 + h2 < 360 then hb = (h1 + h2 + 360) / 2
    else hb = (h1 + h2 - 360) / 2 end
  end
  local Tt = 1 - 0.17 * math.cos(rad(hb - 30)) + 0.24 * math.cos(rad(2 * hb))
    + 0.32 * math.cos(rad(3 * hb + 6)) - 0.20 * math.cos(rad(4 * hb - 63))
  local dTheta = 30 * math.exp(-((hb - 275) / 25) ^ 2)
  local RC = 2 * math.sqrt(Cb ^ 7 / (Cb ^ 7 + 25 ^ 7))
  local SL = 1 + 0.015 * (Lb - 50) ^ 2 / math.sqrt(20 + (Lb - 50) ^ 2)
  local SC, SH = 1 + 0.045 * Cb, 1 + 0.015 * Cb * Tt
  local RT = -math.sin(rad(2 * dTheta)) * RC
  local l, c, h = dL / SL, dC / SC, dH / SH
  return math.sqrt(l * l + c * c + h * h + RT * c * h)
end

--- ΔE00 between two sRGB colors (alpha ignored).
function D.de00(x, y) return D.deltaE00(D.srgbToLab(x), D.srgbToLab(y)) end

return D
