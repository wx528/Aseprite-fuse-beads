local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)[/\\]")

app.alert = function(msg) print("ALERT: " .. tostring(msg)) end

_G.Dialog = function(title)
  local data = {}
  local w = {}
  local function reg(opts)
    if opts and opts.id then
      if opts.selected ~= nil then
        data[opts.id] = opts.selected
      elseif opts.text ~= nil then
        data[opts.id] = tonumber(opts.text)
      elseif opts.value ~= nil then
        data[opts.id] = opts.value
      elseif opts.option ~= nil then
        data[opts.id] = opts.option
      elseif opts.filename ~= nil then
        data[opts.id] = opts.filename
      end
    end
    return w
  end
  for _, m in ipairs({ "file", "number", "slider", "check", "combobox", "button", "label" }) do
    w[m] = function(self, opts)
      if m == "button" then
        if opts and opts.id == "ok" then
          data.ok = true
        end
        return w
      end
      return reg(opts)
    end
  end
  w.show = function(self) end
  w.data = data
  return w
end

dofile(here .. "/../fuse-beads-export.lua")

print("sprite: " .. tostring(app.sprite and app.sprite.width .. "x" .. app.sprite.height))
