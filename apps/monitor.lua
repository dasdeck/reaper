package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('monitor')
addScope('trackTool')
addScope('pluginList')

local WindowApp = require 'WindowApp'
local Master = require 'Master'

WindowApp:create('monitor', Master:create()):start()




