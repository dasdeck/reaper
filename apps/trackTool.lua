package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('trackTool')
addScope('drumRack')

local TrackTool = require 'TrackTool'
local Window = require 'Window'

local paths = require 'paths'

local TrackToolJSFX = paths.effectsDir:file('TrackTool')

if not TrackToolJSFX:exists() then
  TrackToolJSFX:setContent(paths.scriptDir:file('jsfx/TrackTool'):getContent())
  reaper.MB('plugin installed, restart script', 'restart', 0)
else
  Window.openComponent(TrackTool:create(), {
    name = 'tracktool',
    w = 200,
    h = 600,
    dock = 1}
  )
end