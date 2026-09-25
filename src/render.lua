local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")
local Font = dofile(here .. "/font.lua")

local Render = {}

local GRID = nil
local WHITE = nil
local BLACK = nil

local function gridColor()
  if not GRID then GRID = app.pixelColor.rgba(200, 200, 200, 255) end
  return GRID
end

local DIVIDER = nil

local function dividerColor()
  if not DIVIDER then DIVIDER = app.pixelColor.rgba(120, 120, 120, 255) end
  return DIVIDER
end

local function white()
  if not WHITE then WHITE = app.pixelColor.rgba(255, 255, 255, 255) end
  return WHITE
end

local function black()
  if not BLACK then BLACK = app.pixelColor.rgba(0, 0, 0, 255) end
  return BLACK
end

local function textColorFor(rgb)
  local lum = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b
  if lum > 140 then
    return black()
  end
  return white()
end

local function fitScale(text, cell)
  local maxW = math.floor(cell * 0.8)
  local maxH = math.floor(cell * 0.4)
  local s = math.max(1, math.floor(cell / 8))
  while s > 1 do
    local w, h = Font.measure(text, s)
    if w <= maxW and h <= maxH then
      return s
    end
    s = s - 1
  end
  return 1
end

local function drawCenteredText(img, text, cellX, cellY, cell, color)
  local s = fitScale(text, cell)
  local w, h = Font.measure(text, s)
  local x = cellX + math.floor((cell - w) / 2)
  local y = cellY + math.floor((cell - h) / 2)
  Font.draw(img, x, y, text, s, color)
end

function Render.countUsage(matches)
  local byCode, order = {}, {}
  for _, row in pairs(matches) do
    for _, e in pairs(row) do
      if e then
        if not byCode[e.code] then
          byCode[e.code] = { entry = e, count = 0 }
          order[#order + 1] = byCode[e.code]
        end
        byCode[e.code].count = byCode[e.code].count + 1
      end
    end
  end
  table.sort(order, function(a, b)
    local la, na = a.entry.code:match("^(%a+)(%d+)$")
    local lb, nb = b.entry.code:match("^(%a+)(%d+)$")
    la, lb = la or a.entry.code, lb or b.entry.code
    na, nb = tonumber(na) or 0, tonumber(nb) or 0
    if la ~= lb then
      return la < lb
    end
    return na < nb
  end)
  return order
end

function Render.render(srcImg, matches, opts)
  local cols, rows = srcImg.width, srcImg.height
  local cell = opts.cell or 32
  local beadRatio = opts.beadRatio or 0.9
  local usage = Render.countUsage(matches)
  local PER_COL = 5
  local statCols = opts.showStats and math.ceil(#usage / PER_COL) or 0
  local statsRows = opts.showStats and math.min(#usage, PER_COL) or 0

  local maxLabelW = 0
  if opts.showStats then
    for _, u in ipairs(usage) do
      local label = u.entry.code .. " X " .. u.count
      local tw = Font.measure(label, fitScale(label, cell))
      if tw > maxLabelW then maxLabelW = tw end
    end
  end

  local W = cols * cell + 1
  if statCols > 0 then
    W = math.max(W, statCols * (cell + 2 + maxLabelW))
  end
  local H = rows * cell + 1 + statsRows * cell
  local out = Image(W, H, ColorMode.RGB)
  for px in out:pixels() do
    px(white())
  end

  local gridEvery = opts.gridEvery
  if gridEvery == nil then gridEvery = 5 end
  local function isDivider(i, n)
    return i == 0 or i == n or (gridEvery >= 2 and i % gridEvery == 0)
  end

  local grid = gridColor()
  for gx = 0, cols do
    for y = 0, rows * cell do
      out:drawPixel(gx * cell, y, grid)
    end
  end
  for gy = 0, rows do
    for x = 0, cols * cell do
      out:drawPixel(x, gy * cell, grid)
    end
  end

  local r = math.floor((cell - 2) * beadRatio / 2)
  local r2 = r * r
  for cy = 1, rows do
    for cx = 1, cols do
      local e = matches[cy][cx]
      if e then
        local centerX = (cx - 1) * cell + math.floor(cell / 2)
        local centerY = (cy - 1) * cell + math.floor(cell / 2)
        local beadColor = app.pixelColor.rgba(e.rgb.r, e.rgb.g, e.rgb.b, 255)
        if opts.beadShape == "circle" then
          for dy = -r, r do
            for dx = -r, r do
              if dx * dx + dy * dy <= r2 then
                out:drawPixel(centerX + dx, centerY + dy, beadColor)
              end
            end
          end
        else
          local x0 = (cx - 1) * cell + 1
          local y0 = (cy - 1) * cell + 1
          for py = y0, y0 + cell - 2 do
            for px = x0, x0 + cell - 2 do
              out:drawPixel(px, py, beadColor)
            end
          end
        end
        drawCenteredText(out, e.code, (cx - 1) * cell, (cy - 1) * cell, cell, textColorFor(e.rgb))
      end
    end
  end

  local divider = dividerColor()
  for gx = 0, cols do
    if isDivider(gx, cols) then
      for y = 0, rows * cell do
        out:drawPixel(gx * cell, y, divider)
      end
      if gx > 0 and gx < cols then
        for y = 0, rows * cell do
          out:drawPixel(gx * cell + 1, y, divider)
        end
      end
    end
  end
  for gy = 0, rows do
    if isDivider(gy, rows) then
      for x = 0, cols * cell do
        out:drawPixel(x, gy * cell, divider)
      end
      if gy > 0 and gy < rows then
        for x = 0, cols * cell do
          out:drawPixel(x, gy * cell + 1, divider)
        end
      end
    end
  end

  if opts.showStats then
    local top = rows * cell + 1
    local colWidth = cell + 2 + maxLabelW
    for i, u in ipairs(usage) do
      local col = math.floor((i - 1) / PER_COL)
      local row = (i - 1) % PER_COL
      local x0 = col * colWidth
      local rowTop = top + row * cell
      local swColor = app.pixelColor.rgba(u.entry.rgb.r, u.entry.rgb.g, u.entry.rgb.b, 255)
      for sy = 2, cell - 3 do
        for sx = 2, cell - 3 do
          out:drawPixel(x0 + sx, rowTop + sy, swColor)
        end
      end
      local label = u.entry.code .. " X " .. u.count
      local s = fitScale(label, cell)
      local tw, th = Font.measure(label, s)
      Font.draw(out, x0 + cell + 2, rowTop + math.floor((cell - th) / 2), label, s, black())
    end
  end

  return out
end

return Render
