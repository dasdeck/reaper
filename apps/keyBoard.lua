package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'

local WindowApp = require 'WindowApp'
local Keyboard = require 'Keyboard'

WindowApp:create('keyboard', Keyboard.create(36,47)):start(
{
profile = false
})

