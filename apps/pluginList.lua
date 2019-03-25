package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('pluginList')

local App = require 'App'
local Mem = require 'Mem'
local Watcher = require 'Watcher'
local Window = require 'Window'
local PluginList = require 'PluginList'
local rea = require 'rea'

local name = 'pluginlist'

local app = App:create('pluginlist')

local pluginListMem = Mem:create(app.name)

local window = Window:create(app.name, PluginList:create(0, 0, 170, 100))

Watcher:create(function() return pluginListMem:get() end):onChange(function(state)

  if state == 1 then
    window:show()
  else
    window:close()

  end
end)

pluginListMem:set(0, 1)

app:start()
