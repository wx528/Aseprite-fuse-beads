local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local Color = dofile(here .. "/../src/color.lua")

local lw = Color.rgbToLab(255, 255, 255)
eq(math.floor(lw + 0.5), 100, "white L=100")
local lb = Color.rgbToLab(0, 0, 0)
eq(math.floor(lb + 0.5), 0, "black L=0")

local pal = {
  { code = "X1", name = "red", rgb = { r = 255, g = 0, b = 0 } },
  { code = "X2", name = "blue", rgb = { r = 0, g = 0, b = 255 } },
}

local e1, exact1 = Color.nearest(pal, 255, 0, 0)
eq(e1.code, "X1", "exact hit returns red")
ok(exact1, "exact flag true on exact hit")

local e2, exact2 = Color.nearest(pal, 250, 10, 10)
eq(e2.code, "X1", "near red maps to red")
ok(not exact2, "exact flag false on fuzzy match")

local e3 = Color.nearest(pal, 20, 20, 240)
eq(e3.code, "X2", "near blue maps to blue")


local browns = {
  { code = "G19", name = "b1", rgb = { r = 189, g = 111, b = 54 } },
  { code = "G7", name = "b2", rgb = { r = 138, g = 94, b = 64 } },
  { code = "F10", name = "b3", rgb = { r = 106, g = 62, b = 37 } },
}
eq(Color.nearest(browns, 0xC3, 0x70, 0x20).code, "G19", "light orange-brown to G19")
eq(Color.nearest(browns, 0x98, 0x4E, 0x16).code, "G7", "dark brown to G7")