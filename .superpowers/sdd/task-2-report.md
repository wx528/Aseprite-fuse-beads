# Task 2 Report: MARD 色板数据

## What I implemented

- `tests/test_palette.lua`: structural test for the palette module, exactly as the brief specifies (ASCII-only code, written directly).
- `tests/run.lua`: added `"test_palette.lua"` to the `files` list, exactly as the brief specifies.
- `src/palette_mard.lua`: the 18-entry starter palette. Because the brief file contains UTF-8-encoded Chinese names that my read tooling could not reliably transcribe, I extracted the ```lua `return { ... }` ``` block from the brief **byte-exactly** (regex-extract the block, normalize CRLF->LF, write as UTF-8 without BOM). Verified byte-identical to the brief: the bytes following `"H1", name = "` are `E9 90 A7 E5 80 9F E5 A3 8A` in both files. No BOM (file starts with `72 65 74` = `ret`). No comments, module returns a table, per global constraints.

## TDD Evidence

### RED

Command: `powershell -ExecutionPolicy Bypass -File run-tests.ps1`

Output:
```
passed=1 failed=1
ERROR in test_palette.lua: cannot open D:\Work\Aseprite\fuse-beads\tests/../src/palette_mard.lua: No such file or directory
TESTS FAILED
exit=1
```

Expected and correct: `src/palette_mard.lua` did not exist yet, so `dofile` inside `test_palette.lua` raised, which the harness reports as `ERROR in test_palette.lua` (brief Step 2 expectation).

### GREEN

Command: `powershell -ExecutionPolicy Bypass -File run-tests.ps1`

Output:
```
passed=128 failed=0
ALL TESTS PASSED
exit=0
```

128 = 1 smoke assertion + 1 palette-count assertion + 18 entries x 7 per-entry assertions. Matches the brief Step 4 expectation (`ALL TESTS PASSED`).

## Files changed

- `src/palette_mard.lua` (new, 19 lines, 18 entries H1-H4/A1-A3/B1/C1-C2/D1-D2/E1/F1-F2/G1-G3)
- `tests/test_palette.lua` (new, 18 lines)
- `tests/run.lua` (1 line added to `files`)

Commit: `24066a6 Add MARD palette starter data` (exact message from brief, exactly the 3 files staged).

## Self-review findings

1. **Test count sanity**: 128 assertions all passing; per-entry checks cover code presence/uniqueness, name type, rgb table, and r/g/b numeric range 0-255. Matches brief interface: array of `{ code=string, name=string, rgb={r,g,b} }`, codes globally unique.
2. **Global constraints**: no comments in any file; test loads module via `debug.getinfo(1,"S").source:sub(2):match(...)` + `dofile` (no `require`); module returns a table. Color values are plain 0-255 numbers here (the `app.pixelColor.rgba` constraint applies when constructing Aseprite colors in later tasks, not to this data file).
3. **Verbatim fidelity**: palette block is a byte-exact copy of the brief (hex-verified), so any later correction only needs to happen in one place.
4. **CONCERN - encoding defect in the brief**: the brief's palette section is double-encoded. The names on disk are the GBK-mojibake renderings of the intended Chinese names, themselves encoded as UTF-8 (e.g. H1's name bytes `E9 90 A7 E5 80 9F E5 A3 8A` decode to the 3 mojibake characters that result from reading UTF-8 `E7 99 BD E8 89 B2` ("white") as GBK). I copied verbatim per instructions; the names will display as garbage in the plugin UI until fixed. Recovery is mechanical (encode current string as GBK, decode as UTF-8) and Task 7 already plans color-card proofreading - recommend fixing names there or in a small follow-up.
5. No other repo files touched; `.superpowers/` remains untracked as before.
