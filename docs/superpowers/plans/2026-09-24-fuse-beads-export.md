# 拼豆图纸导出插件 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aseprite Lua 脚本，把当前 sprite 导出为拼豆图�?PNG（圆�?+ MARD 色号标注 + 用量统计）�?
**Architecture:** �?Lua 模块按职责拆分（色板数据 / 颜色匹配 / 位图字体 / 渲染），入口脚本�?`dofile` 按自身路径加载同级模块。测试通过 `Aseprite.exe -b --script tests/run.lua` 无头运行，运行器输出 `ALL TESTS PASSED` 判定成功�?
**Tech Stack:** Aseprite 1.3.18.6 内嵌 Lua 5.4，无外部依赖�?
## Global Constraints

- Aseprite 路径：`D:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe`（测试用它无头运行）
- 拿不到进程退出码：测试运行器必须打印 `ALL TESTS PASSED` �?`TESTS FAILED`，以输出文本为准
- 模块加载一律用 `debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")` 取自身目�?+ `dofile`，不�?`require`
- 颜色值一律用 `app.pixelColor.rgba(r,g,b,a)` 构造，分量�?`app.pixelColor.rgbaR/G/B/A` 读取
- 每个模块文件 `return` 一个表作为公开接口
- 代码不写注释

## 文件结构

- `src/palette_mard.lua` �?MARD 色号表，return 数组，元�?`{ code="A1", name="...", rgb={r=,g=,b=} }`
- `src/color.lua` �?`Color.rgbToLab(r,g,b)->l,a,b`、`Color.nearest(palette,r,g,b)->entry,isExact`
- `src/font.lua` �?`Font.GLYPHS`、`Font.measure(text,scale)->w,h`、`Font.draw(img,x,y,text,scale,color)`
- `src/render.lua` �?`Render.countUsage(matches)->list`、`Render.render(srcImg,matches,opts)->outImg`，opts = `{ cell=32, beadRatio=0.9, showStats=true }`
- `fuse-beads-export.lua` �?入口：对话框 + �?sprite + 调用渲染 + 保存（放仓库根目录，方便拷进 Aseprite 脚本目录�?- `tests/run.lua` �?测试运行器，dofile 各测试文�?- `tests/gen_fixtures.lua` �?生成手动验收用的测试�?PNG
- `run-tests.ps1` �?�?Aseprite 无头�?tests/run.lua，按输出判成�?
matches 约定：`matches[y][x]`�? 起）= 色板条目�?�?`nil`（透明留空）�?
---

### Task 1: 项目骨架 + 测试运行�?
**Files:**
- Create: `tests/run.lua`
- Create: `tests/test_smoke.lua`
- Create: `run-tests.ps1`

**Interfaces:**
- Produces: 全局函数 `ok(cond, msg)`、`eq(got, want, msg)` 供所有后续测试文件使用；`run-tests.ps1` 是后续所有任务的测试命令�?
- [ ] **Step 1: 写测试运行器和冒烟测�?*

`tests/run.lua`�?
```lua
local src = debug.getinfo(1, "S").source:sub(2)
local dir = src:match("^(.*)[/\\]")

local passed, failed = 0, 0
local failures = {}

function ok(cond, msg)
  if cond then
    passed = passed + 1
  else
    failed = failed + 1
    failures[#failures + 1] = "FAIL: " .. (msg or "assertion")
  end
end

function eq(got, want, msg)
  ok(got == want, (msg or "") .. " [want=" .. tostring(want) .. " got=" .. tostring(got) .. "]")
end

local files = {
  "test_smoke.lua",
}

for _, f in ipairs(files) do
  local chunk, err = pcall(dofile, dir .. "/" .. f)
  if not chunk then
    failed = failed + 1
    failures[#failures + 1] = "ERROR in " .. f .. ": " .. tostring(err)
  end
end

print(string.format("passed=%d failed=%d", passed, failed))
for _, msg in ipairs(failures) do print(msg) end
if failed == 0 then
  print("ALL TESTS PASSED")
else
  print("TESTS FAILED")
end
```

`tests/test_smoke.lua`�?
```lua
eq(1 + 1, 2, "smoke")
```

`run-tests.ps1`�?
```powershell
$out = & "D:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe" -b --script "$PSScriptRoot\tests\run.lua" 2>&1 | Out-String
$out
if ($out -match "ALL TESTS PASSED") { exit 0 } else { exit 1 }
```

- [ ] **Step 2: 跑测试确认通过**

Run: `powershell -ExecutionPolicy Bypass -File run-tests.ps1`
Expected: 输出�?`passed=1 failed=0` �?`ALL TESTS PASSED`，退出码 0

- [ ] **Step 3: Commit**

```bash
git add tests/run.lua tests/test_smoke.lua run-tests.ps1
git commit -m "Add headless test harness"
```

---

### Task 2: MARD 色板数据

**Files:**
- Create: `src/palette_mard.lua`
- Modify: `tests/run.lua`（把 `"test_palette.lua"` 加进 files 列表�?- Create: `tests/test_palette.lua`

**Interfaces:**
- Produces: `palette_mard.lua` return 数组；元�?`{ code=string, name=string, rgb={r=0..255, g=0..255, b=0..255} }`，code 全局唯一�?
- [ ] **Step 1: 写失败测�?*

`tests/test_palette.lua`�?
```lua
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
```

`tests/run.lua` �?files 改为�?
```lua
local files = {
  "test_smoke.lua",
  "test_palette.lua",
}
```

- [ ] **Step 2: 跑测试确认失�?*

Run: `powershell -ExecutionPolicy Bypass -File run-tests.ps1`
Expected: `TESTS FAILED`，含 `ERROR in test_palette.lua`（文件不存在�?
- [ ] **Step 3: 写色板起始数�?*

`src/palette_mard.lua`（起�?16 色，RGB 为近似值，正式使用前按实体色卡核对，见 Task 7）：

```lua
return {
  { code = "H1", name = "白色", rgb = { r = 245, g = 245, b = 245 } },
  { code = "H2", name = "黑色", rgb = { r = 30, g = 30, b = 30 } },
  { code = "H3", name = "浅灰", rgb = { r = 180, g = 180, b = 180 } },
  { code = "H4", name = "深灰", rgb = { r = 100, g = 100, b = 100 } },
  { code = "A1", name = "大红", rgb = { r = 220, g = 40, b = 40 } },
  { code = "A2", name = "深红", rgb = { r = 150, g = 25, b = 35 } },
  { code = "A3", name = "粉红", rgb = { r = 245, g = 160, b = 175 } },
  { code = "B1", name = "橙色", rgb = { r = 240, g = 130, b = 35 } },
  { code = "C1", name = "黄色", rgb = { r = 245, g = 220, b = 50 } },
  { code = "C2", name = "奶油", rgb = { r = 250, g = 240, b = 180 } },
  { code = "D1", name = "绿色", rgb = { r = 60, g = 170, b = 70 } },
  { code = "D2", name = "深绿", rgb = { r = 30, g = 100, b = 50 } },
  { code = "E1", name = "青色", rgb = { r = 70, g = 200, b = 200 } },
  { code = "F1", name = "蓝色", rgb = { r = 50, g = 90, b = 220 } },
  { code = "F2", name = "深蓝", rgb = { r = 30, g = 45, b = 120 } },
  { code = "G1", name = "紫色", rgb = { r = 140, g = 70, b = 170 } },
  { code = "G2", name = "棕色", rgb = { r = 130, g = 85, b = 50 } },
  { code = "G3", name = "肤色", rgb = { r = 245, g = 205, b = 170 } },
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `powershell -ExecutionPolicy Bypass -File run-tests.ps1`
Expected: `ALL TESTS PASSED`

- [ ] **Step 5: Commit**

```bash
git add src/palette_mard.lua tests/run.lua tests/test_palette.lua
git commit -m "Add MARD palette starter data"
```

---

### Task 3: 颜色匹配（RGB→Lab 最近邻�?
**Files:**
- Create: `src/color.lua`
- Modify: `tests/run.lua`（files �?`"test_color.lua"`�?- Create: `tests/test_color.lua`

**Interfaces:**
- Consumes: Task 2 的色板条目格式�?- Produces: `Color.rgbToLab(r,g,b)->l,a,b`；`Color.nearest(palette,r,g,b)->entry,isExact`。Task 5�? 依赖这两个签名�?
- [ ] **Step 1: 写失败测�?*

`tests/test_color.lua`�?
```lua
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
```

- [ ] **Step 2: 跑测试确认失�?*

Run: `powershell -ExecutionPolicy Bypass -File run-tests.ps1`
Expected: `TESTS FAILED`，`ERROR in test_color.lua`

- [ ] **Step 3: 实现 color.lua**

`src/color.lua`�?
```lua
local Color = {}

local function toLinear(c)
  c = c / 255
  if c > 0.04045 then
    return ((c + 0.055) / 1.055) ^ 2.4
  end
  return c / 12.92
end

function Color.rgbToLab(r, g, b)
  local R, G, B = toLinear(r), toLinear(g), toLinear(b)
  local X = (0.4124 * R + 0.3576 * G + 0.1805 * B) / 0.95047
  local Y = (0.2126 * R + 0.7152 * G + 0.0722 * B)
  local Z = (0.0193 * R + 0.1192 * G + 0.9505 * B) / 1.08883
  local function f(t)
    if t > 0.008856 then
      return t ^ (1 / 3)
    end
    return 7.787 * t + 16 / 116
  end
  local fx, fy, fz = f(X), f(Y), f(Z)
  return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)
end

local exactCache = setmetatable({}, { __mode = "k" })

function Color.nearest(palette, r, g, b)
  local cache = exactCache[palette]
  if not cache then
    cache = {}
    for _, e in ipairs(palette) do
      cache[e.rgb.r .. "," .. e.rgb.g .. "," .. e.rgb.b] = e
    end
    exactCache[palette] = cache
  end
  local exact = cache[r .. "," .. g .. "," .. b]
  if exact then
    return exact, true
  end
  local l1, a1, b1 = Color.rgbToLab(r, g, b)
  local best, bestD = nil, nil
  for _, e in ipairs(palette) do
    if not e.labL then
      e.labL, e.labA, e.labB = Color.rgbToLab(e.rgb.r, e.rgb.g, e.rgb.b)
    end
    local d = (l1 - e.labL) ^ 2 + (a1 - e.labA) ^ 2 + (b1 - e.labB) ^ 2
    if not bestD or d < bestD then
      best, bestD = e, d
    end
  end
  return best, false
end

return Color
```

- [ ] **Step 4: 跑测试确认通过**

Run: `powershell -ExecutionPolicy Bypass -File run-tests.ps1`
Expected: `ALL TESTS PASSED`

- [ ] **Step 5: Commit**

```bash
git add src/color.lua tests/run.lua tests/test_color.lua
git commit -m "Add RGB to Lab nearest color matching"
```

---

### Task 4: 3x5 位图字体

**Files:**
- Create: `src/font.lua`
- Modify: `tests/run.lua`（files �?`"test_font.lua"`�?- Create: `tests/test_font.lua`

**Interfaces:**
- Produces: `Font.measure(text, scale)->w,h`；`Font.draw(img, x, y, text, scale, color)`�?x,y) 为左上角；`Font.GLYPHS` 键为单字符字符串，值为 5 �?× 3 列的 "0"/"1" 字符串数组。Task 5 依赖�?
- [ ] **Step 1: 写失败测�?*

`tests/test_font.lua`�?
```lua
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
```

- [ ] **Step 2: 跑测试确认失�?*

Run: `powershell -ExecutionPolicy Bypass -File run-tests.ps1`
Expected: `TESTS FAILED`，`ERROR in test_font.lua`

- [ ] **Step 3: 实现 font.lua**

`src/font.lua`�?
```lua
local Font = {}

Font.GLYPHS = {
  ["0"] = { "111", "101", "101", "101", "111" },
  ["1"] = { "010", "110", "010", "010", "111" },
  ["2"] = { "111", "001", "111", "100", "111" },
  ["3"] = { "111", "001", "111", "001", "111" },
  ["4"] = { "101", "101", "111", "001", "001" },
  ["5"] = { "111", "100", "111", "001", "111" },
  ["6"] = { "111", "100", "111", "101", "111" },
  ["7"] = { "111", "001", "001", "010", "010" },
  ["8"] = { "111", "101", "111", "101", "111" },
  ["9"] = { "111", "101", "111", "001", "111" },
  A = { "010", "101", "111", "101", "101" },
  B = { "110", "101", "110", "101", "110" },
  C = { "011", "100", "100", "100", "011" },
  D = { "110", "101", "101", "101", "110" },
  E = { "111", "100", "110", "100", "111" },
  F = { "111", "100", "110", "100", "100" },
  G = { "011", "100", "101", "101", "011" },
  H = { "101", "101", "111", "101", "101" },
  I = { "111", "010", "010", "010", "111" },
  J = { "001", "001", "001", "101", "010" },
  K = { "101", "101", "110", "101", "101" },
  L = { "100", "100", "100", "100", "111" },
  M = { "101", "111", "111", "101", "101" },
  N = { "101", "111", "111", "111", "101" },
  O = { "010", "101", "101", "101", "010" },
  P = { "110", "101", "110", "100", "100" },
  Q = { "010", "101", "101", "110", "011" },
  R = { "110", "101", "110", "101", "101" },
  S = { "011", "100", "010", "001", "110" },
  T = { "111", "010", "010", "010", "010" },
  U = { "101", "101", "101", "101", "111" },
  V = { "101", "101", "101", "101", "010" },
  W = { "101", "101", "111", "111", "101" },
  X = { "101", "101", "010", "101", "101" },
  Y = { "101", "101", "010", "010", "010" },
  Z = { "111", "001", "010", "100", "111" },
}

function Font.measure(text, scale)
  if #text == 0 then
    return 0, 0
  end
  return (#text * 4 - 1) * scale, 5 * scale
end

function Font.draw(img, x, y, text, scale, color)
  local cx = x
  for i = 1, #text do
    local g = Font.GLYPHS[text:sub(i, i)]
    if g then
      for row = 1, 5 do
        local line = g[row]
        for col = 1, 3 do
          if line:sub(col, col) == "1" then
            for sy = 0, scale - 1 do
              for sx = 0, scale - 1 do
                img:drawPixel(cx + (col - 1) * scale + sx, y + (row - 1) * scale + sy, color)
              end
            end
          end
        end
      end
    end
    cx = cx + 4 * scale
  end
end

return Font
```

- [ ] **Step 4: 跑测试确认通过**

Run: `powershell -ExecutionPolicy Bypass -File run-tests.ps1`
Expected: `ALL TESTS PASSED`

- [ ] **Step 5: Commit**

```bash
git add src/font.lua tests/run.lua tests/test_font.lua
git commit -m "Add 3x5 bitmap font"
```

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

### Task 7: 手动验收 + 色卡核对

**Files:**
- Create: `tests/gen_fixtures.lua`

- [ ] **Step 1: 写测试图生成脚本**

`tests/gen_fixtures.lua`�?
```lua
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
```

Run: `& "D:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe" -b --script tests\gen_fixtures.lua`
Expected: 输出 `FIXTURES DONE`，`fixtures/` 下生�?4 �?PNG

- [ ] **Step 2: 手动验收（用户在 Aseprite UI 中操作）**

1. 把仓库里 `fuse-beads-export.lua` �?`src/` 整个拷到 Aseprite 脚本目录（文�?> 脚本 > 打开脚本文件夹），然后在 文件 > 脚本 里运�?`fuse-beads-export`
2. 依次打开 `fixtures/` 四张图运行导出，核对�?   - solid_red：全�?A1 圆豆，统计区只有一�?"A1 x 64"
   - gradient：每格有圆豆和色号，无报�?   - transparent：棋盘格，透明格留白无豆无色号，统�?"F1 x 32"
   - off_palette：全部映射到同一色号（肉眼判断接近紫�?G1�?   - �?sprite 时运�?�?�?没有打开�?sprite"
3. 有问题回报修�?
- [ ] **Step 3: 色卡数据核对（用户）**

用户对照自己�?MARD/漫漫实体色卡，编�?`src/palette_mard.lua`：每行格�?`{ code = "色号", name = "名称", rgb = { r = R, g = G, b = B } }`，可增删行。改完跑 `run-tests.ps1` 确认数据格式合法�?
- [ ] **Step 4: Commit**

```bash
git add tests/gen_fixtures.lua fixtures
git commit -m "Add manual acceptance fixtures"
```

---

## 备注

- 第二阶段（打�?`.aseprite-extension`）不在本计划内，脚本验收通过后另立计划�?- `fixtures/*.png` 是生成物，也可以选择加进 `.gitignore` 而不提交�?