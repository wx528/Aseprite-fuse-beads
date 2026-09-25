local Color = {}

local function toLinear(c)
  c = c / 255
  if c > 0.04045 then
    return ((c + 0.055) / 1.055) ^ 2.4
  end
  return c / 12.92
end

function Color.rgbToLab(r, g, b)
  local R, G, B = toLinear(r), toLinear(g), toLinear(b)
  local X = (0.4124 * R + 0.3576 * G + 0.1805 * B) / 0.95047
  local Y = (0.2126 * R + 0.7152 * G + 0.0722 * B)
  local Z = (0.0193 * R + 0.1192 * G + 0.9505 * B) / 1.08883
  local function f(t)
    if t > 0.008856 then
      return t ^ (1 / 3)
    end
    return 7.787 * t + 16 / 116
  end
  local fx, fy, fz = f(X), f(Y), f(Z)
  return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)
end

local exactCache = setmetatable({}, { __mode = "k" })

local rad = math.rad
local deg = math.deg
local atan2 = math.atan

local function deltaE00(l1, a1, b1, l2, a2, b2)
  local avgL = (l1 + l2) / 2
  local C1 = math.sqrt(a1 * a1 + b1 * b1)
  local C2 = math.sqrt(a2 * a2 + b2 * b2)
  local avgC = (C1 + C2) / 2
  local avgC7 = avgC ^ 7
  local G = 0.5 * (1 - math.sqrt(avgC7 / (avgC7 + 6103515625)))
  local a1p, a2p = a1 * (1 + G), a2 * (1 + G)
  local C1p = math.sqrt(a1p * a1p + b1 * b1)
  local C2p = math.sqrt(a2p * a2p + b2 * b2)
  local function hp(a, b)
    if a == 0 and b == 0 then
      return 0
    end
    local h = deg(atan2(b, a))
    return h < 0 and h + 360 or h
  end
  local h1p, h2p = hp(a1p, b1), hp(a2p, b2)
  local dLp = l2 - l1
  local dCp = C2p - C1p
  local dhp
  if C1p * C2p == 0 then
    dhp = 0
  else
    dhp = h2p - h1p
    if dhp > 180 then
      dhp = dhp - 360
    elseif dhp < -180 then
      dhp = dhp + 360
    end
  end
  local dHp = 2 * math.sqrt(C1p * C2p) * math.sin(rad(dhp / 2))
  local avghp
  if C1p * C2p == 0 then
    avghp = h1p + h2p
  elseif math.abs(h1p - h2p) > 180 then
    if h1p + h2p < 360 then
      avghp = (h1p + h2p + 360) / 2
    else
      avghp = (h1p + h2p - 360) / 2
    end
  else
    avghp = (h1p + h2p) / 2
  end
  local T = 1 - 0.17 * math.cos(rad(avghp - 30)) + 0.24 * math.cos(rad(2 * avghp))
    + 0.32 * math.cos(rad(3 * avghp + 6)) - 0.20 * math.cos(rad(4 * avghp - 63))
  local dtheta = 30 * math.exp(-((avghp - 275) / 25) ^ 2)
  local avgCp = (C1p + C2p) / 2
  local avgCp7 = avgCp ^ 7
  local Rc = 2 * math.sqrt(avgCp7 / (avgCp7 + 6103515625))
  local Sl = 1 + 0.015 * (avgL - 50) ^ 2 / math.sqrt(20 + (avgL - 50) ^ 2)
  local Sc = 1 + 0.045 * avgCp
  local Sh = 1 + 0.015 * avgCp * T
  local Rt = -math.sin(rad(2 * dtheta)) * Rc
  local dL2 = (dLp / Sl) ^ 2
  local dC2 = (dCp / Sc) ^ 2
  local dH2 = (dHp / Sh) ^ 2
  return dL2 + dC2 + dH2 + Rt * (dCp / Sc) * (dHp / Sh)
end

function Color.nearest(palette, r, g, b)
  local cache = exactCache[palette]
  if not cache then
    cache = { results = {} }
    for _, e in ipairs(palette) do
      cache[e.rgb.r .. "," .. e.rgb.g .. "," .. e.rgb.b] = e
    end
    exactCache[palette] = cache
  end
  local key = r .. "," .. g .. "," .. b
  local exact = cache[key]
  if exact then
    return exact, true
  end
  local cached = cache.results[key]
  if cached then
    return cached, false
  end
  local l1, a1, b1 = Color.rgbToLab(r, g, b)
  local best, bestD = nil, nil
  for _, e in ipairs(palette) do
    if not e.labL then
      e.labL, e.labA, e.labB = Color.rgbToLab(e.rgb.r, e.rgb.g, e.rgb.b)
    end
    local d = deltaE00(l1, a1, b1, e.labL, e.labA, e.labB)
    if not bestD or d < bestD then
      best, bestD = e, d
    end
  end
  cache.results[key] = best
  return best, false
end

return Color
