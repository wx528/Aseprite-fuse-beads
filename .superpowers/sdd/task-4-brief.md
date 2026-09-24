# 全局约束

## Global Constraints

- Aseprite 路径：`D:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe`（测试用它无头运行）
- 拿不到进程退出码：测试运行器必须打印 `ALL TESTS PASSED` �?`TESTS FAILED`，以输出文本为准
- 模块加载一律用 `debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")` 取自身目�?+ `dofile`，不�?`require`
- 颜色值一律用 `app.pixelColor.rgba(r,g,b,a)` 构造，分量�?`app.pixelColor.rgbaR/G/B/A` 读取
- 每个模块文件 `return` 一个表作为公开接口
- 代码不写注释



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

