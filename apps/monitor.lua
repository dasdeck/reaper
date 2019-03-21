package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('monitor')

local Window = require 'Window'
local MonitorPresets = require 'MonitorPresets'

Window.openComponent(MonitorPresets:create(), {
  name = 'monitor',
  w = 170,
  h = 100,
  dock = 769
})



