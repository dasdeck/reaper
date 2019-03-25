package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('monitor')

local WindowApp = require 'WindowApp'
local MonitorPresets = require 'MonitorPresets'

WindowApp:create('monitor', MonitorPresets:create(0,0,170, 100)):start()




