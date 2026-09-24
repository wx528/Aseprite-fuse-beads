local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local Font = dofile(here .. "/../src/font.lua")

local w, h = Font.measure("A1", 2)
eq(w, 14, "measure A1 scale2 width")
eq(h, 10, "measure scale2 height")

local img = Image(20, 10, ColorMode.RGB)
local white = app.pixelColor.rgba(255, 255, 255, 255)
Font.draw(img, 0, 0, "1", 1, white)
eq(app.pixelColor.rgbaR(img:getPixel(1, 0)), 255, "digit 1 top pixel set")
eq(app.pixelColor.rgbaR(img:getPixel(0, 0)), 0, "digit 1 left of top unset")

local img2 = Image(40, 20, ColorMode.RGB)
Font.draw(img2, 0, 0, "A", 2, white)
eq(app.pixelColor.rgbaR(img2:getPixel(2, 0)), 255, "A top center set at scale2")
eq(app.pixelColor.rgbaR(img2:getPixel(3, 0)), 255, "A top center second pixel at scale2")
eq(app.pixelColor.rgbaR(img2:getPixel(0, 0)), 0, "A top left unset")

for ch in ("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"):gmatch(".") do
  ok(Font.GLYPHS[ch] ~= nil, "glyph exists for " .. ch)
end
