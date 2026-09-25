function init(plugin)
  plugin:newCommand{
    id = "FuseBeadsExport",
    title = "Export Fuse Beads Pattern",
    group = "file_export",
    onenabled = function()
      return app.sprite ~= nil
    end,
    onclick = function()
      dofile(plugin.path .. "/src/exporter.lua")()
    end
  }
end

function exit(plugin)
end
