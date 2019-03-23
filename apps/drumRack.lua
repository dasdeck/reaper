package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('drumRack')
addScope('drumRack/ui')

local Watcher = require 'Watcher'

local DrumRackSelector = require 'DrumRackSelector'
local Window = require 'Window'

local paths = require 'paths'

local DrumRackJSFX = paths.effectsDir:childFile('DrumRack')

if not DrumRackJSFX:exists() then
  DrumRackJSFX:setContent(paths.scriptDir:childFile('jsfx/DrumRack'):getContent())
  reaper.MB('plugin installed, restart script', 'restart', 0)
else

Window.openComponent(DrumRackSelector:create(), {
    name = 'drumrack',
    w = 600,
    h = 300,
    dock = 1,
    profile = false
    }
  )

end
