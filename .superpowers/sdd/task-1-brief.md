# 全局约束

## Global Constraints

- Aseprite 路径：`D:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe`（测试用它无头运行）
- 拿不到进程退出码：测试运行器必须打印 `ALL TESTS PASSED` �?`TESTS FAILED`，以输出文本为准
- 模块加载一律用 `debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")` 取自身目�?+ `dofile`，不�?`require`
- 颜色值一律用 `app.pixelColor.rgba(r,g,b,a)` 构造，分量�?`app.pixelColor.rgbaR/G/B/A` 读取
- 每个模块文件 `return` 一个表作为公开接口
- 代码不写注释



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

