# 全局约束

## Global Constraints

- Aseprite 路径：`D:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe`（测试用它无头运行）
- 拿不到进程退出码：测试运行器必须打印 `ALL TESTS PASSED` �?`TESTS FAILED`，以输出文本为准
- 模块加载一律用 `debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")` 取自身目�?+ `dofile`，不�?`require`
- 颜色值一律用 `app.pixelColor.rgba(r,g,b,a)` 构造，分量�?`app.pixelColor.rgbaR/G/B/A` 读取
- 每个模块文件 `return` 一个表作为公开接口
- 代码不写注释



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

