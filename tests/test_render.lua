local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local Render = dofile(here .. "/../src/render.lua")

local pal = {
  { code = "A1", name = "red", rgb = { r = 255, g = 0, b = 0 } },
  { code = "B2", name = "blue", rgb = { r = 0, g = 0, b = 255 } },
}

local src = Image(2, 2, ColorMode.RGB)
local matches = {
  { pal[1], pal[2] },
  { nil, pal[1] },
}

local usage = Render.countUsage(matches)
eq(#usage, 2, "usage has 2 entries")
eq(usage[1].entry.code, "A1", "most used first")
eq(usage[1].count, 2, "A1 count is 2")
eq(usage[2].count, 1, "B2 count is 1")

local out = Render.render(src, matches, { cell = 16, beadRatio = 0.9, showStats = false })
eq(out.width, 33, "board width without stats")
eq(out.height, 33, "board height without stats")

local bead = out:getPixel(8, 8)
eq(app.pixelColor.rgbaR(bead), 255, "red bead center red channel")
eq(app.pixelColor.rgbaB(bead), 0, "red bead center blue channel")

local grid = out:getPixel(0, 0)
eq(app.pixelColor.rgbaR(grid), 120, "border line is dark divider")

local emptyCell = out:getPixel(8, 24)
eq(app.pixelColor.rgbaR(emptyCell), 255, "transparent cell stays white")
eq(app.pixelColor.rgbaG(emptyCell), 255, "transparent cell green white")

local out2 = Render.render(src, matches, { cell = 16, beadRatio = 0.9, showStats = true })
eq(out2.height, 33 + 2 * 16, "stats adds one row per used color")
local swatch = out2:getPixel(7, 41)
eq(app.pixelColor.rgbaR(swatch), 255, "first stats swatch is red")

local Font = dofile(here .. "/../src/font.lua")
local out3 = Render.render(src, matches, { cell = 16, beadRatio = 0.9, showStats = true })
local labelW = select(1, Font.measure("A1 X 2", 1))
eq(out3.width, math.max(33, 16 + 2 + labelW), "stats width accommodates label")

local big = Render.render(src, matches, { cell = 32, beadRatio = 0.9, showStats = false })
local aboveText = big:getPixel(4, 19)
ok(not (app.pixelColor.rgbaR(aboveText) == 255 and app.pixelColor.rgbaG(aboveText) == 255 and app.pixelColor.rgbaB(aboveText) == 255), "code text must not fill the bead at cell=32")


local sparse = { {}, { pal[1], pal[2] } }
local sparseUsage = Render.countUsage(sparse)
eq(#sparseUsage, 2, "sparse matches: two colors counted")
if #sparseUsage == 2 then eq(sparseUsage[1].count, 1, "sparse matches: count is 1") end
local outSparse = Render.render(src, sparse, { cell = 16, beadRatio = 0.9, showStats = true })
eq(outSparse.height, 33 + 2 * 16, "sparse matches: stats rows add height")

local sqc = out:getPixel(1, 1)
eq(app.pixelColor.rgbaG(sqc), 0, "square bead fills interior corner by default")

local cir = Render.render(src, matches, { cell = 16, beadRatio = 0.9, showStats = false, beadShape = "circle" })
local cc = cir:getPixel(1, 1)
ok(app.pixelColor.rgbaR(cc) == 255 and app.pixelColor.rgbaG(cc) == 255, "circle bead leaves interior corner empty")

local src10 = Image(10, 1, ColorMode.RGB)
local m10 = { {} }
for x = 1, 10 do m10[1][x] = pal[1] end
local div = Render.render(src10, m10, { cell = 16, beadRatio = 0.9, showStats = false, gridEvery = 5 })
eq(app.pixelColor.rgbaR(div:getPixel(48, 8)), 200, "normal grid line stays light")
eq(app.pixelColor.rgbaR(div:getPixel(80, 8)), 120, "divider dark at multiple of 5")
eq(app.pixelColor.rgbaR(div:getPixel(81, 8)), 120, "divider is 2px wide")
eq(app.pixelColor.rgbaR(div:getPixel(160, 8)), 120, "right border is dark divider")

local nodiv = Render.render(src10, m10, { cell = 16, beadRatio = 0.9, showStats = false, gridEvery = 0 })
eq(app.pixelColor.rgbaR(nodiv:getPixel(80, 8)), 200, "gridEvery 0 disables interior divider")
eq(app.pixelColor.rgbaR(nodiv:getPixel(0, 8)), 120, "borders stay dark when dividers disabled")

local m2 = { { pal[2], pal[2] }, { pal[2], pal[1] } }
local u2 = Render.countUsage(m2)
eq(u2[1].entry.code, "A1", "stats sorted by code, not count")
eq(u2[2].entry.code, "B2", "code order second")

local pal7 = {}
local m7 = { {} }
for i = 1, 7 do
  pal7[i] = { code = "A" .. i, name = "c" .. i, rgb = { r = i * 30, g = 0, b = 0 } }
  m7[1][i] = pal7[i]
end
local src7 = Image(7, 1, ColorMode.RGB)
local out7 = Render.render(src7, m7, { cell = 16, beadRatio = 0.9, showStats = true })
eq(out7.height, 17 + 5 * 16, "stats column capped at 5 rows")
local labelW7 = select(1, Font.measure("A6 X 1", 1))
local colW = 16 + 2 + labelW7
eq(app.pixelColor.rgbaR(out7:getPixel(colW + 4, 17 + 3)), 180, "6th entry starts second column")