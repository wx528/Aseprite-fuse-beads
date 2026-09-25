local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local Color = dofile(here .. "/../src/color.lua")
local Render = dofile(here .. "/../src/render.lua")
local palette = dofile(here .. "/../src/palette_perler.lua")
local src = Image(4, 2, ColorMode.RGB)
local matches = {}
for y = 1, 2 do
  matches[y] = {}
  for x = 1, 4 do
    matches[y][x] = Color.nearest(palette, (x * 60) % 255, (y * 120 + x * 30) % 255, (x * y * 70) % 255)
  end
end
local out = Render.render(src, matches, { cell = 32, showStats = true, showCoords = true, brand = "PERLER" })
out:saveAs(here .. "/../fixtures/perler_test.png")
print("PERLER OK " .. out.width .. "x" .. out.height)