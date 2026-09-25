$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$stage = Join-Path $env:TEMP "fuse-beads-ext-stage"
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "$stage\src" -Force | Out-Null
Copy-Item "$root\package.json" $stage
Copy-Item "$root\main.lua" $stage
Copy-Item "$root\src\*.lua" "$stage\src"
$zip = Join-Path $env:TEMP "fuse-beads.zip"
$out = "$root\fuse-beads.aseprite-extension"
Remove-Item $zip -Force -ErrorAction SilentlyContinue
Remove-Item $out -Force -ErrorAction SilentlyContinue
Compress-Archive -Path "$stage\*" -DestinationPath $zip
Move-Item $zip $out
Write-Output "built: $out"
