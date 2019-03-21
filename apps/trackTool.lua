package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('trackTool')
addScope('drumRack')

local TrackTool = require 'TrackTool'
local Window = require 'Window'

Window.openComponent(TrackTool:create(), {
  name = 'tracktool',
  w = 200,
  h = 600,
  dock = 1}
)
