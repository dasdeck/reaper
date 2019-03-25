package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('trackTool')
addScope('drumRack')
addScope('pluginList')

local TrackTool = require 'TrackTool'
local WindowApp = require 'WindowApp'
local Builder = require 'Builder'
local rea = require 'rea'
local paths = require 'paths'

local TrackToolJSFX = paths.effectsDir:childFile('TrackTool')
if not TrackToolJSFX:exists() then
  TrackToolJSFX:setContent(paths.scriptDir:childFile('jsfx/TrackTool'):getContent())
  reaper.MB('plugin installed, restart script', 'restart', 0)
else
  WindowApp:create('tracktool', TrackTool:create(0,0,200, 600)):start()
end
