local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local Color = dofile(here .. "/../src/color.lua")
local palette = dofile(here .. "/../src/palette_mard.lua")
local function show(r, g, b)
  local e = Color.nearest(palette, r, g, b)
  print(string.format("#%02X%02X%02X -> %s (%d,%d,%d)", r, g, b, e.code, e.rgb.r, e.rgb.g, e.rgb.b))
end
show(0xC3, 0x70, 0x20)
show(0x98, 0x4E, 0x16)
local browns = {}
for _, e in ipairs(palette) do
  if e.rgb.r > 60 and e.rgb.r < 220 and e.rgb.r > e.rgb.g and e.rgb.g >= e.rgb.b and e.rgb.g < 160 then
    browns[#browns + 1] = string.format("%s(%d,%d,%d)", e.code, e.rgb.r, e.rgb.g, e.rgb.b)
  end
end
print("brown-ish entries: " .. table.concat(browns, " "))