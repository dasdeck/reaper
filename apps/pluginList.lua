package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('pluginList')

local Window = require 'Window'
local PluginList = require 'PluginList'

Window.openComponent(PluginList:create(), {
  name = 'pluginlist',
  w = 170,
  h = 100,
  dock = 769
})



