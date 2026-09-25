local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local Render = dofile(here .. "/../src/render.lua")
local e = { code = "G20", name = "G20", rgb = { r = 122, g = 53, b = 37 } }
local src = Image(1, 1, ColorMode.RGB)
local out = Render.render(src, { { e } }, { cell = 32, showStats = false })
local minY, maxY = 99, -1
for y = 0, 31 do
  for x = 0, 31 do
    local px = out:getPixel(x, y)
    if app.pixelColor.rgbaR(px) == 255 and app.pixelColor.rgbaG(px) == 255 and app.pixelColor.rgbaB(px) == 255 then
      if y < minY then minY = y end
      if y > maxY then maxY = y end
    end
  end
end
print("G20 white text rows: " .. minY .. ".." .. maxY .. " height=" .. (maxY - minY + 1))