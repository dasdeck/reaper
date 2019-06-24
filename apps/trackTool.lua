package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
local rea = require 'rea'
addScope('trackTool')
addScope('drumRack')
addScope('drumRack' .. rea.seperator ..  'ui')
addScope('pluginList')

local TrackToolSwitcher = require 'TrackToolSwitcher'
local WindowApp = require 'WindowApp'
local Builder = require 'Builder'

local paths = require 'paths'

local TrackToolJSFX = paths.effectsDir:childFile('TrackTool')
local Wrap = paths.effectsDir:childFile('Wrap')

if not TrackToolJSFX:exists() or not Wrap:exists() then
  TrackToolJSFX:setContent(paths.scriptDir:childFile('jsfx/TrackTool'):getContent())
  Wrap:setContent(paths.scriptDir:childFile('jsfx/Wrap'):getContent())
  reaper.MB('plugin installed, restart script', 'restart', 0)
end

TrackToolJSFX:setContent(paths.scriptDir:childFile('jsfx/TrackTool'):getContent())
Wrap:setContent(paths.scriptDir:childFile('jsfx/Wrap'):getContent())

WindowApp:create('tracktool', TrackToolSwitcher:create(0,0,200, 600)):start({
  profile = false
})
