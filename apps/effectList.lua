package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('pluginList')
local rea = require 'rea'
local PluginListApp = require 'PluginListApp'

local res, err = xpcall(function()

  PluginListApp:create('effects'):start({
    profile = false
  })

end, debug.traceback)

if not res then
    local context = {reaper.get_action_context()}
    --rea.logPin('context', context)
    rea.logPin('error', err)
end
