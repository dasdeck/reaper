package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('tools')
addScope('drumRack')
addScope('drumRack/ui')

local Tools = require 'Tools'
local ButtonList = require 'ButtonList'
local WindowApp = require 'WindowApp'

WindowApp:create('tools', ButtonList:create(Tools, nil, nil, 0,0, 200, 600)):start()
