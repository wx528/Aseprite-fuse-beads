local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
dofile(here .. "/src/exporter.lua")()
