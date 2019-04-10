package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'

local WindowApp = require 'WindowApp'
local Mixer = require 'Mixer'

-- WindowApp:create('monitor', MonitorPresets:create(0,0,170, 100)):start()
WindowApp:create('monitor', Mixer:create()):start()




