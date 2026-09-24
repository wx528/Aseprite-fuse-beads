$out = & "D:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe" -b --script "$PSScriptRoot\tests\run.lua" 2>&1 | Out-String
$out
if ($out -match "ALL TESTS PASSED") { exit 0 } else { exit 1 }
