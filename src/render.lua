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

local function fitScale(text, cell, wf, hf)
  local maxW = math.floor(cell * (wf or 0.8))
  local maxH = math.floor(cell * (hf or 0.4))
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
  local margin = opts.showCoords and cell or 0
  local W = margin * 2 + cols * cell + 1

  local chip = math.floor(cell / 2)
  local rowH = chip + 2
  local statsScale = math.max(1, math.floor(cell / 16))
  local entryW = 1
  local perRow = 1
  if opts.showStats then
    local maxTextW = 0
    for _, u in ipairs(usage) do
      local tw = Font.measure(u.entry.code .. " " .. u.count, statsScale)
      if tw > maxTextW then maxTextW = tw end
    end
    entryW = chip + 2 + maxTextW + 4
    perRow = math.max(1, math.floor((W - margin * 2) / entryW))
  end
  local statsRows = opts.showStats and math.ceil(#usage / perRow) or 0
  local H = margin * 2 + rows * cell + 1 + statsRows * rowH
  local out = Image(W, H, ColorMode.RGB)
  for px in out:pixels() do
    px(white())
  end

  local ox, oy = margin, margin

  local gridEvery = opts.gridEvery
  if gridEvery == nil then gridEvery = 5 end
  local function isDivider(i, n)
    return i == 0 or i == n or (gridEvery >= 2 and i % gridEvery == 0)
  end

  local grid = gridColor()
  for gx = 0, cols do
    for y = 0, rows * cell do
      out:drawPixel(ox + gx * cell, oy + y, grid)
    end
  end
  for gy = 0, rows do
    for x = 0, cols * cell do
      out:drawPixel(ox + x, oy + gy * cell, grid)
    end
  end

  local r = math.floor((cell - 2) * beadRatio / 2)
  local r2 = r * r
  for cy = 1, rows do
    for cx = 1, cols do
      local e = matches[cy][cx]
      if e then
        local centerX = ox + (cx - 1) * cell + math.floor(cell / 2)
        local centerY = oy + (cy - 1) * cell + math.floor(cell / 2)
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
          local x0 = ox + (cx - 1) * cell + 1
          local y0 = oy + (cy - 1) * cell + 1
          for py = y0, y0 + cell - 2 do
            for px = x0, x0 + cell - 2 do
              out:drawPixel(px, py, beadColor)
            end
          end
        end
        drawCenteredText(out, e.code, ox + (cx - 1) * cell, oy + (cy - 1) * cell, cell, textColorFor(e.rgb))
      end
    end
  end

  local divider = dividerColor()
  for gx = 0, cols do
    if isDivider(gx, cols) then
      for y = 0, rows * cell do
        out:drawPixel(ox + gx * cell, oy + y, divider)
      end
      if gx > 0 and gx < cols then
        for y = 0, rows * cell do
          out:drawPixel(ox + gx * cell + 1, oy + y, divider)
        end
      end
    end
  end
  for gy = 0, rows do
    if isDivider(gy, rows) then
      for x = 0, cols * cell do
        out:drawPixel(ox + x, oy + gy * cell, divider)
      end
      if gy > 0 and gy < rows then
        for x = 0, cols * cell do
          out:drawPixel(ox + x, oy + gy * cell + 1, divider)
        end
      end
    end
  end

  if opts.showCoords then
    for i = 1, cols do
      local x0 = ox + (i - 1) * cell
      drawCenteredText(out, tostring(i), x0, 0, cell, black())
      drawCenteredText(out, tostring(cols - i + 1), x0, oy + rows * cell + 1, cell, black())
    end
    for i = 1, rows do
      local y0 = oy + (i - 1) * cell
      drawCenteredText(out, tostring(i), 0, y0, cell, black())
      drawCenteredText(out, tostring(rows - i + 1), ox + cols * cell + 1, y0, cell, black())
    end
  end

  if opts.showStats then
    local top = oy + rows * cell + 1 + margin
    local cr = math.max(2, math.floor(rowH * 0.3))
    for i, u in ipairs(usage) do
      local col = (i - 1) % perRow
      local row = math.floor((i - 1) / perRow)
      local x0 = margin + col * entryW
      local y0 = top + row * rowH
      local swColor = app.pixelColor.rgba(u.entry.rgb.r, u.entry.rgb.g, u.entry.rgb.b, 255)
      local bw, bh = entryW - 2, rowH
      for bx = cr, bw - 1 - cr do
        out:drawPixel(x0 + bx, y0, swColor)
        out:drawPixel(x0 + bx, y0 + bh - 1, swColor)
      end
      for by = cr, bh - 1 - cr do
        out:drawPixel(x0, y0 + by, swColor)
        out:drawPixel(x0 + bw - 1, y0 + by, swColor)
      end
      for dy = 0, cr do
        for dx = 0, cr do
          local d = math.sqrt(dx * dx + dy * dy)
          if math.abs(d - cr) < 0.8 then
            out:drawPixel(x0 + cr - dx, y0 + cr - dy, swColor)
            out:drawPixel(x0 + bw - 1 - cr + dx, y0 + cr - dy, swColor)
            out:drawPixel(x0 + cr - dx, y0 + bh - 1 - cr + dy, swColor)
            out:drawPixel(x0 + bw - 1 - cr + dx, y0 + bh - 1 - cr + dy, swColor)
          end
        end
      end
      local cy0 = y0 + math.floor((rowH - chip) / 2)
      for sy = 0, chip - 1 do
        for sx = 0, chip - 1 do
          out:drawPixel(x0 + 1 + sx, cy0 + sy, swColor)
        end
      end
      local label = u.entry.code .. " " .. u.count
      local tw, th = Font.measure(label, statsScale)
      Font.draw(out, x0 + 1 + chip + 2, y0 + math.floor((rowH - th) / 2), label, statsScale, black())
    end
  end

  return out
end

return Render
