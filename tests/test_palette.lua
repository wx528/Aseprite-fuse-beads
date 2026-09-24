local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local palette = dofile(here .. "/../src/palette_mard.lua")

ok(type(palette) == "table" and #palette >= 16, "palette has at least 16 colors")

local seen = {}
for _, e in ipairs(palette) do
  ok(type(e.code) == "string" and #e.code > 0, "entry has code")
  ok(not seen[e.code], "unique code " .. tostring(e.code))
  seen[e.code] = true
  ok(type(e.name) == "string", "entry " .. tostring(e.code) .. " has name")
  ok(type(e.rgb) == "table", "entry " .. tostring(e.code) .. " has rgb")
  for _, ch in ipairs({ "r", "g", "b" }) do
    local v = e.rgb[ch]
    ok(type(v) == "number" and v >= 0 and v <= 255, "entry " .. tostring(e.code) .. " rgb." .. ch .. " in range")
  end
end
