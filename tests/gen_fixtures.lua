local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local outDir = here .. "/../fixtures"
app.fs.makeAllDirectories(outDir)

local rgba = app.pixelColor.rgba

local solid = Image(8, 8, ColorMode.RGB)
for px in solid:pixels() do px(rgba(220, 40, 40, 255)) end
solid:saveAs(outDir .. "/solid_red.png")

local grad = Image(16, 16, ColorMode.RGB)
for y = 0, 15 do
  for x = 0, 15 do
    grad:drawPixel(x, y, rgba(x * 16, y * 16, 128, 255))
  end
end
grad:saveAs(outDir .. "/gradient.png")

local trans = Image(8, 8, ColorMode.RGB)
for y = 0, 7 do
  for x = 0, 7 do
    if (x + y) % 2 == 0 then
      trans:drawPixel(x, y, rgba(50, 90, 220, 255))
    end
  end
end
trans:saveAs(outDir .. "/transparent.png")

local off = Image(8, 8, ColorMode.RGB)
for px in off:pixels() do px(rgba(123, 77, 200, 255)) end
off:saveAs(outDir .. "/off_palette.png")

print("FIXTURES DONE")
