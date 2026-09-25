local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local Color = dofile(here .. "/color.lua")
local Render = dofile(here .. "/render.lua")

local BRANDS = {
  { label = "MARD", file = "palette_mard", ascii = "MARD" },
  { label = "Perler", file = "palette_perler", ascii = "PERLER" },
  { label = "Hama", file = "palette_hama", ascii = "HAMA" },
  { label = "Artkal", file = "palette_artkal", ascii = "ARTKAL" },
}

return function()
  local sprite = app.sprite
  if not sprite then
    app.alert("No sprite open. Open a sprite first.")
    return
  end

  if sprite.width > 128 or sprite.height > 128 then
    local warn = Dialog("Size Warning")
    warn:label{ text = "Image is " .. sprite.width .. "x" .. sprite.height .. " - quite large." }
    warn:label{ text = "Exporting may freeze Aseprite; bead patterns are rarely this big." }
    warn:label{ text = "Consider Sprite > Sprite Size first (e.g. 64x64)." }
    warn:button{ id = "ok", text = "Export Anyway" }
    warn:button{ id = "cancel", text = "Cancel" }
    warn:show()
    if not warn.data.ok then
      return
    end
  end

  local defaultName = "pattern.png"
  if sprite.filename and sprite.filename ~= "" then
    defaultName = app.fs.joinPath(app.fs.filePath(sprite.filename), app.fs.fileTitle(sprite.filename) .. "_pattern.png")
  end

  local brandLabels = {}
  for i, b in ipairs(BRANDS) do
    brandLabels[i] = b.label
  end

  local dlg = Dialog("Export Fuse Beads Pattern")
  dlg:file{ id = "output", label = "Output File", save = true, filename = defaultName, filetypes = { "png" } }
  dlg:combobox{ id = "brand", label = "Palette", options = brandLabels, option = brandLabels[1] }
  dlg:combobox{ id = "shape", label = "Bead Shape", options = { "Square", "Circle" }, option = "Square" }
  dlg:number{ id = "cell", label = "Cell Size (px)", text = "32", decimals = 0 }
  dlg:slider{ id = "bead", label = "Bead Diameter (%)", min = 50, max = 100, value = 90 }
  dlg:number{ id = "gridEvery", label = "Divider Every (cells)", text = "5", decimals = 0 }
  dlg:slider{ id = "textSize", label = "Code Font Size (%)", min = 50, max = 150, value = 100 }
  dlg:check{ id = "coords", label = "Edge Coordinates", text = "", selected = true }
  dlg:check{ id = "stats", label = "Usage Stats", text = "", selected = true }
  dlg:button{ id = "ok", text = "Export", focus = true }
  dlg:button{ id = "cancel", text = "Cancel" }
  dlg:show()

  local data = dlg.data
  if not data.ok then
    return
  end

  local brand = BRANDS[1]
  for _, b in ipairs(BRANDS) do
    if b.label == data.brand then
      brand = b
    end
  end
  local palette = dofile(here .. "/" .. brand.file .. ".lua")

  local frame = app.frame and app.frame.frameNumber or 1
  local flat = Image(sprite.width, sprite.height, ColorMode.RGB)
  flat:drawSprite(sprite, frame)

  local matches = {}
  for y = 0, sprite.height - 1 do
    matches[y + 1] = {}
    for x = 0, sprite.width - 1 do
      local px = flat:getPixel(x, y)
      if app.pixelColor.rgbaA(px) >= 128 then
        local e = Color.nearest(palette, app.pixelColor.rgbaR(px), app.pixelColor.rgbaG(px), app.pixelColor.rgbaB(px))
        matches[y + 1][x + 1] = e
      end
    end
  end

  local showStats = data.stats ~= false

  local okSave, err = pcall(function()
    local out = Render.render(flat, matches, {
      cell = math.max(8, math.floor(tonumber(data.cell) or 32)),
      beadRatio = (tonumber(data.bead) or 90) / 100,
      beadShape = data.shape == "Circle" and "circle" or "square",
      gridEvery = tonumber(data.gridEvery) or 5,
      textScale = tonumber(data.textSize) or 100,
      brand = brand.ascii,
      showCoords = data.coords ~= false,
      showStats = showStats,
    })
    out:saveAs(data.output)
  end)

  if okSave then
    app.alert("Exported: " .. data.output .. " (stats: " .. (showStats and "on" or "off") .. ")")
  else
    app.alert("Export failed: " .. tostring(err))
  end
end
