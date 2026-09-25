local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local Color = dofile(here .. "/src/color.lua")
local Render = dofile(here .. "/src/render.lua")
local palette = dofile(here .. "/src/palette_mard.lua")

local sprite = app.sprite
if not sprite then
  app.alert("没有打开的 sprite，请先打开一张图")
  return
end

if sprite.width > 128 or sprite.height > 128 then
  local warn = Dialog("尺寸警告")
  warn:label{ text = "当前图像 " .. sprite.width .. "x" .. sprite.height .. "，尺寸过大" }
  warn:label{ text = "导出可能导致软件卡死；拼豆图纸一般不会用这么大尺寸" }
  warn:label{ text = "建议先用 精灵 > 精灵大小 缩小（如 64x64）再导出" }
  warn:button{ id = "ok", text = "执意导出" }
  warn:button{ id = "cancel", text = "取消" }
  warn:show()
  if not warn.data.ok then
    return
  end
end

local defaultName = "pattern.png"
if sprite.filename and sprite.filename ~= "" then
  defaultName = app.fs.joinPath(app.fs.filePath(sprite.filename), app.fs.fileTitle(sprite.filename) .. "_pattern.png")
end

local dlg = Dialog("导出拼豆图纸")
dlg:file{ id = "output", label = "输出文件", save = true, filename = defaultName, filetypes = { "png" } }
dlg:combobox{ id = "brand", label = "色板", options = { "MARD/漫漫" }, option = "MARD/漫漫" }
dlg:combobox{ id = "shape", label = "豆子形状", options = { "方形", "圆形" }, option = "方形" }
dlg:number{ id = "cell", label = "格子大小(px)", text = "32", decimals = 0 }
dlg:slider{ id = "bead", label = "豆子直径(%)", min = 50, max = 100, value = 90 }
dlg:number{ id = "gridEvery", label = "分格线间隔(格)", text = "5", decimals = 0 }
dlg:check{ id = "stats", label = "包含用量统计", text = "", selected = true }
dlg:button{ id = "ok", text = "导出", focus = true }
dlg:button{ id = "cancel", text = "取消" }
dlg:show()

local data = dlg.data
if not data.ok then
  return
end

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
    beadShape = data.shape == "圆形" and "circle" or "square",
    gridEvery = tonumber(data.gridEvery) or 5,
    showStats = showStats,
  })
  out:saveAs(data.output)
end)

if okSave then
  app.alert("导出完成：" .. data.output .. "（统计：" .. (showStats and "开" or "关") .. "）")
else
  app.alert("导出失败：" .. tostring(err))
end
