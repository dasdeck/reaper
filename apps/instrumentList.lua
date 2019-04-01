package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('pluginList')
local rea = require 'rea'
local PluginListApp = require 'PluginListApp'

PluginListApp:create('instruments'):start({
  profile = false
})
