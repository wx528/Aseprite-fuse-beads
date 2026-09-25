function init(plugin)
  plugin:newCommand{
    id = "FuseBeadsExport",
    title = "导出拼豆图纸",
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
