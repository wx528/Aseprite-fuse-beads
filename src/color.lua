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

function Color.nearest(palette, r, g, b)
  local cache = exactCache[palette]
  if not cache then
    cache = {}
    for _, e in ipairs(palette) do
      cache[e.rgb.r .. "," .. e.rgb.g .. "," .. e.rgb.b] = e
    end
    exactCache[palette] = cache
  end
  local exact = cache[r .. "," .. g .. "," .. b]
  if exact then
    return exact, true
  end
  local l1, a1, b1 = Color.rgbToLab(r, g, b)
  local best, bestD = nil, nil
  for _, e in ipairs(palette) do
    if not e.labL then
      e.labL, e.labA, e.labB = Color.rgbToLab(e.rgb.r, e.rgb.g, e.rgb.b)
    end
    local d = (l1 - e.labL) ^ 2 + (a1 - e.labA) ^ 2 + (b1 - e.labB) ^ 2
    if not bestD or d < bestD then
      best, bestD = e, d
    end
  end
  return best, false
end

return Color
