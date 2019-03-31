package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('pluginList')
local rea = require 'rea'
local PluginListApp = require 'PluginListApp'

-- rea.log(package)

local Mem = require 'Mem'
local Watcher = require 'Watcher'
local Window = require 'Window'
local PluginGrid = require 'PluginGrid'
local paths = require 'paths'



PluginListApp:create():start({
  profile = false
})
