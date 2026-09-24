# 全局约束

## Global Constraints

- Aseprite 路径：`D:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe`（测试用它无头运行）
- 拿不到进程退出码：测试运行器必须打印 `ALL TESTS PASSED` �?`TESTS FAILED`，以输出文本为准
- 模块加载一律用 `debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")` 取自身目�?+ `dofile`，不�?`require`
- 颜色值一律用 `app.pixelColor.rgba(r,g,b,a)` 构造，分量�?`app.pixelColor.rgbaR/G/B/A` 读取
- 每个模块文件 `return` 一个表作为公开接口
- 代码不写注释



---

### Task 6: 入口脚本（对话框 + 接线�?
**Files:**
- Create: `fuse-beads-export.lua`（仓库根目录�?
**Interfaces:**
- Consumes: `Color.nearest`、`Render.render`、Task 2 色板�?- Produces: 用户可运行的脚本。无代码接口被后续任务依赖�?
说明：对话框无法在无头模式测试，本任务的验证是代码审�?+ Task 7 的手动验收�?
- [ ] **Step 1: 写入口脚�?*

`fuse-beads-export.lua`�?
```lua
local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local Color = dofile(here .. "/src/color.lua")
local Render = dofile(here .. "/src/render.lua")
local palette = dofile(here .. "/src/palette_mard.lua")

local sprite = app.sprite
if not sprite then
  app.alert("没有打开�?sprite，请先打开一张图")
  return
end

local defaultName = "pattern.png"
if sprite.filename and sprite.filename ~= "" then
  defaultName = app.fs.joinPath(app.fs.filePath(sprite.filename), app.fs.fileTitle(sprite.filename) .. "_pattern.png")
end

local dlg = Dialog("导出拼豆图纸")
dlg:file{ id = "output", label = "输出文件", save = true, filename = defaultName, filetypes = { "png" } }
dlg:combobox{ id = "brand", label = "色板", options = { "MARD/漫漫" }, option = "MARD/漫漫" }
dlg:number{ id = "cell", label = "格子大小(px)", text = "32", decimals = 0 }
dlg:slider{ id = "bead", label = "豆子直径(%)", min = 50, max = 100, value = 90 }
dlg:check{ id = "stats", label = "包含用量统计", selected = true }
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

local okSave, err = pcall(function()
  local out = Render.render(flat, matches, {
    cell = math.max(8, math.floor(data.cell)),
    beadRatio = data.bead / 100,
    showStats = data.stats,
  })
  out:saveAs(data.output)
end)

if okSave then
  app.alert("导出完成�? .. data.output)
else
  app.alert("导出失败�? .. tostring(err))
end
```

- [ ] **Step 2: 语法检查（无头加载，不进对话框�?*

临时验证脚本 `tests/check_syntax.lua`�?
```lua
local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
dofile(here .. "/../src/color.lua")
dofile(here .. "/../src/font.lua")
dofile(here .. "/../src/render.lua")
dofile(here .. "/../src/palette_mard.lua")
print("SYNTAX OK")
```

Run: `& "D:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe" -b --script tests\check_syntax.lua`
Expected: 输出 `SYNTAX OK`（入口脚本本身依�?app.sprite �?Dialog，无法无头加载，仅检查模块）

另跑一遍全量测试确认无回归�?Run: `powershell -ExecutionPolicy Bypass -File run-tests.ps1`
Expected: `ALL TESTS PASSED`

- [ ] **Step 3: Commit**

```bash
git add fuse-beads-export.lua tests/check_syntax.lua
git commit -m "Add export script entry point with dialog"
```

---

