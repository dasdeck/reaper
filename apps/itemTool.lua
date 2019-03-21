package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('itemTool')

local ItemTool = require 'ItemTool'
local Window = require 'Window'

Window.openComponent(ItemTool:create(), {
  name = 'itemtool',
  w = 200,
  h = 600,
  dock = 1}
)
