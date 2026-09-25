local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local Render = dofile(here .. "/../src/render.lua")
local pal7 = {}
local m7 = { {} }
for i = 1, 7 do
  pal7[i] = { code = "A" .. i, name = "c" .. i, rgb = { r = i * 30, g = 0, b = 0 } }
  m7[1][i] = pal7[i]
end
pal7[7].code = "A10"
local src7 = Image(7, 1, ColorMode.RGB)
local out = Render.render(src7, m7, { cell = 16, beadRatio = 0.9, showStats = true })
print("size " .. out.width .. "x" .. out.height)
for y = 36, 44 do
  local line = ""
  for x = 50, 82 do
    local p = out:getPixel(x, y)
    local r, g, b = app.pixelColor.rgbaR(p), app.pixelColor.rgbaG(p), app.pixelColor.rgbaB(p)
    if r == 255 and g == 255 then
      line = line .. "."
    elseif r == 210 then
      line = line .. "7"
    elseif r == 180 then
      line = line .. "6"
    elseif r == 0 and g == 0 and b == 0 then
      line = line .. "#"
    else
      line = line .. "?"
    end
  end
  print(line)
end