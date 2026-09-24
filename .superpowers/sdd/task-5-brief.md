# 全局约束

## Global Constraints

- Aseprite 路径：`D:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe`（测试用它无头运行）
- 拿不到进程退出码：测试运行器必须打印 `ALL TESTS PASSED` �?`TESTS FAILED`，以输出文本为准
- 模块加载一律用 `debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")` 取自身目�?+ `dofile`，不�?`require`
- 颜色值一律用 `app.pixelColor.rgba(r,g,b,a)` 构造，分量�?`app.pixelColor.rgbaR/G/B/A` 读取
- 每个模块文件 `return` 一个表作为公开接口
- 代码不写注释



---

### Task 5: 图纸渲染（网�?+ 圆豆 + 色号 + 用量统计�?
**Files:**
- Create: `src/render.lua`
- Modify: `tests/run.lua`（files �?`"test_render.lua"`�?- Create: `tests/test_render.lua`

**Interfaces:**
- Consumes: `Font.draw` / `Font.measure`（Task 4）；Task 2 色板条目格式�?- Produces: `Render.countUsage(matches)->list`（元�?`{ entry=条目, count=数字 }`，按 count 降序）；`Render.render(srcImg, matches, opts)->Image`，opts = `{ cell=int, beadRatio=0..1, showStats=bool }`。Task 6 依赖这两个签名�?
- [ ] **Step 1: 写失败测�?*

`tests/test_render.lua`�?
```lua
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
eq(app.pixelColor.rgbaR(grid), 200, "grid line gray")

local emptyCell = out:getPixel(8, 24)
eq(app.pixelColor.rgbaR(emptyCell), 255, "transparent cell stays white")
eq(app.pixelColor.rgbaG(emptyCell), 255, "transparent cell green white")

local out2 = Render.render(src, matches, { cell = 16, beadRatio = 0.9, showStats = true })
eq(out2.height, 33 + 2 * 16, "stats adds one row per used color")
local swatch = out2:getPixel(7, 41)
eq(app.pixelColor.rgbaR(swatch), 255, "first stats swatch is red")
```

- [ ] **Step 2: 跑测试确认失�?*

Run: `powershell -ExecutionPolicy Bypass -File run-tests.ps1`
Expected: `TESTS FAILED`，`ERROR in test_render.lua`

- [ ] **Step 3: 实现 render.lua**

`src/render.lua`�?
```lua
local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local Font = dofile(here .. "/font.lua")

local Render = {}

local GRID = nil
local WHITE = nil
local BLACK = nil

local function gridColor()
  if not GRID then GRID = app.pixelColor.rgba(200, 200, 200, 255) end
  return GRID
end

local function white()
  if not WHITE then WHITE = app.pixelColor.rgba(255, 255, 255, 255) end
  return WHITE
end

local function black()
  if not BLACK then BLACK = app.pixelColor.rgba(0, 0, 0, 255) end
  return BLACK
end

local function textColorFor(rgb)
  local lum = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b
  if lum > 140 then
    return black()
  end
  return white()
end

local function fitScale(text, cell)
  local s = math.max(1, math.floor(cell / 8))
  while s > 1 do
    local w, h = Font.measure(text, s)
    if w <= cell - 4 and h <= cell - 4 then
      return s
    end
    s = s - 1
  end
  return 1
end

local function drawCenteredText(img, text, cellX, cellY, cell, color)
  local s = fitScale(text, cell)
  local w, h = Font.measure(text, s)
  local x = cellX + math.floor((cell - w) / 2)
  local y = cellY + math.floor((cell - h) / 2)
  Font.draw(img, x, y, text, s, color)
end

function Render.countUsage(matches)
  local byCode, order = {}, {}
  for y = 1, #matches do
    for x = 1, #matches[1] do
      local e = matches[y][x]
      if e then
        if not byCode[e.code] then
          byCode[e.code] = { entry = e, count = 0 }
          order[#order + 1] = byCode[e.code]
        end
        byCode[e.code].count = byCode[e.code].count + 1
      end
    end
  end
  table.sort(order, function(a, b) return a.count > b.count end)
  return order
end

function Render.render(srcImg, matches, opts)
  local cols, rows = srcImg.width, srcImg.height
  local cell = opts.cell or 32
  local beadRatio = opts.beadRatio or 0.9
  local usage = Render.countUsage(matches)
  local statsRows = opts.showStats and #usage or 0

  local W = cols * cell + 1
  local H = rows * cell + 1 + statsRows * cell
  local out = Image(W, H, ColorMode.RGB)
  for px in out:pixels() do
    px(white())
  end

  local grid = gridColor()
  for gx = 0, cols do
    for y = 0, rows * cell do
      out:drawPixel(gx * cell, y, grid)
    end
  end
  for gy = 0, rows do
    for x = 0, cols * cell do
      out:drawPixel(x, gy * cell, grid)
    end
  end

  local r = math.floor((cell - 2) * beadRatio / 2)
  local r2 = r * r
  for cy = 1, rows do
    for cx = 1, cols do
      local e = matches[cy][cx]
      if e then
        local centerX = (cx - 1) * cell + math.floor(cell / 2)
        local centerY = (cy - 1) * cell + math.floor(cell / 2)
        local beadColor = app.pixelColor.rgba(e.rgb.r, e.rgb.g, e.rgb.b, 255)
        for dy = -r, r do
          for dx = -r, r do
            if dx * dx + dy * dy <= r2 then
              out:drawPixel(centerX + dx, centerY + dy, beadColor)
            end
          end
        end
        drawCenteredText(out, e.code, (cx - 1) * cell, (cy - 1) * cell, cell, textColorFor(e.rgb))
      end
    end
  end

  if opts.showStats then
    local top = rows * cell + 1
    for i, u in ipairs(usage) do
      local rowTop = top + (i - 1) * cell
      local swColor = app.pixelColor.rgba(u.entry.rgb.r, u.entry.rgb.g, u.entry.rgb.b, 255)
      for sy = 2, cell - 3 do
        for sx = 2, cell - 3 do
          out:drawPixel(sx, rowTop + sy, swColor)
        end
      end
      local label = u.entry.code .. " x " .. u.count
      local s = fitScale(label, cell)
      local tw, th = Font.measure(label, s)
      Font.draw(out, cell + 2, rowTop + math.floor((cell - th) / 2), label, s, black())
    end
  end

  return out
end

return Render
```

- [ ] **Step 4: 跑测试确认通过**

Run: `powershell -ExecutionPolicy Bypass -File run-tests.ps1`
Expected: `ALL TESTS PASSED`

- [ ] **Step 5: Commit**

```bash
git add src/render.lua tests/run.lua tests/test_render.lua
git commit -m "Add pattern board rendering with usage stats"
```

---

