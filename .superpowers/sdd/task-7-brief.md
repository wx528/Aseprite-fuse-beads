# 全局约束

## Global Constraints

- Aseprite 路径：`D:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe`（测试用它无头运行）
- 拿不到进程退出码：测试运行器必须打印 `ALL TESTS PASSED` �?`TESTS FAILED`，以输出文本为准
- 模块加载一律用 `debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")` 取自身目�?+ `dofile`，不�?`require`
- 颜色值一律用 `app.pixelColor.rgba(r,g,b,a)` 构造，分量�?`app.pixelColor.rgbaR/G/B/A` 读取
- 每个模块文件 `return` 一个表作为公开接口
- 代码不写注释



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

