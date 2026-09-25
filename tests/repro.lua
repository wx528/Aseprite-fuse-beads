local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local Color = dofile(here .. "/../src/color.lua")
local Render = dofile(here .. "/../src/render.lua")
local palette = dofile(here .. "/../src/palette_mard.lua")

local spr = Sprite(8, 8, ColorMode.RGB)
local cel = spr.cels[1]
local img = cel.image
local rgba = app.pixelColor.rgba
for y = 0, 7 do
  for x = 0, 7 do
    if (x + y) % 3 == 0 then
      img:drawPixel(x, y, rgba(220, 40, 40, 255))
    elseif (x + y) % 3 == 1 then
      img:drawPixel(x, y, rgba(60, 170, 70, 255))
    end
  end
end

local flat = Image(spr.width, spr.height, ColorMode.RGB)
flat:drawSprite(spr, 1)

local matches = {}
for y = 0, spr.height - 1 do
  matches[y + 1] = {}
  for x = 0, spr.width - 1 do
    local px = flat:getPixel(x, y)
    if app.pixelColor.rgbaA(px) >= 128 then
      matches[y + 1][x + 1] = Color.nearest(palette, app.pixelColor.rgbaR(px), app.pixelColor.rgbaG(px), app.pixelColor.rgbaB(px))
    end
  end
end

local out = Render.render(flat, matches, { cell = 32, beadRatio = 0.9, showStats = true })
out:saveAs(here .. "/../fixtures/repro.png")
print("REPRO DONE " .. out.width .. "x" .. out.height)
