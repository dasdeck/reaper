package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

--dofile('../D3CK/boot.lua')

require 'boot'
addScope('tools')
addScope('drumRack')

local Tools = require 'Tools'
local ButtonList = require 'ButtonList'
local Window = require 'Window'

Window.openComponent(ButtonList:create(Tools), {
  name = 'tools',
  w = 200,
  h = 600,
  dock = 1}
)
