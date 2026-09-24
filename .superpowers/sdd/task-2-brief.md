# 全局约束

## Global Constraints

- Aseprite 路径：`D:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe`（测试用它无头运行）
- 拿不到进程退出码：测试运行器必须打印 `ALL TESTS PASSED` �?`TESTS FAILED`，以输出文本为准
- 模块加载一律用 `debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")` 取自身目�?+ `dofile`，不�?`require`
- 颜色值一律用 `app.pixelColor.rgba(r,g,b,a)` 构造，分量�?`app.pixelColor.rgbaR/G/B/A` 读取
- 每个模块文件 `return` 一个表作为公开接口
- 代码不写注释



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

