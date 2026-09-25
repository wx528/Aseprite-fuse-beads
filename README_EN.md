# Aseprite Fuse Beads Pattern Exporter

[中文](README.md)

![Crocodile](assets/sprite001.gif)

Export the sprite open in Aseprite as a fuse beads (Perler/MARD) pattern PNG with one click: every bead labeled with its MARD color code, coordinate numbers on all four edges, a summary header and bead usage statistics.

![Example](fixtures/gradient_pattern.png)

## Installation

**Recommended**: download `fuse-beads.aseprite-extension` from [Releases](../../releases) and double-click it (or Edit > Preferences > Extensions > Add Extension). Then use **File > Export > 导出拼豆图纸 (Fuse Beads Export)**.

**Alternative**: copy `fuse-beads-export.lua` and the whole `src/` folder into your Aseprite scripts folder (File > Scripts > Open Scripts Folder), rescan scripts, and run it from File > Scripts.

## Usage

1. Open your pixel art in Aseprite (resize to bead dimensions first, e.g. 64×64, via Sprite > Sprite Size)
2. Run the export command
3. Dialog options:
   - Output file: defaults to `<name>_pattern.png`
   - Palette: MARD (221 solid colors)
   - Bead shape: square (default, fills the cell) / circle (adjustable diameter)
   - Cell size: 32px default
   - Divider interval: a bold line every N cells (default 5, 0/1 disables)
   - Coordinate labels on four edges: on by default
   - Usage statistics: on by default (includes the summary header)
4. Click Export

## Features

- Exports the flattened current frame, 1 pixel = 1 bead
- 221 solid MARD colors (A–H + M series, RGB sampled from the official color card), CIEDE2000 color matching
- Transparent pixels are left empty
- A warning dialog appears when either side exceeds 128px (exporting huge images can freeze the app)

## Palette Data

`src/palette_mard.lua` has one entry per color: `{ code = "A1", name = "A1", rgb = { r = R, g = G, b = B } }` — edit freely. Note: values are sampled from a photo of the official color card and may differ slightly from physical beads.

## Development

Tests: `powershell -ExecutionPolicy Bypass -File run-tests.ps1` (runs all assertions headlessly inside Aseprite).

Build extension: bump `version` in `package.json`, then `powershell -ExecutionPolicy Bypass -File build-extension.ps1`.

## License

MIT
