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
  "test_palette.lua",
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
