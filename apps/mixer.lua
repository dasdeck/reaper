package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'

local WindowApp = require 'WindowApp'
local Mixer = require 'Mixer'

WindowApp:create('mixer', Mixer:create()):start(
{
profile = false
})



