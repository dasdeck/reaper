package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('drumRack')
addScope('drumRack/ui')


local DrumRackSelector = require 'DrumRackSelector'
local WindowApp = require 'WindowApp'

local paths = require 'paths'

local DrumRackJSFX = paths.effectsDir:childFile('DrumRack')

if not DrumRackJSFX:exists() then
  DrumRackJSFX:setContent(paths.scriptDir:childFile('jsfx/DrumRack'):getContent())
  reaper.MB('plugin installed, restart sscript', 'restart', 0)
else

  WindowApp:create('drumrack', DrumRackSelector:create(0,0, 600, 300)):start({
    profile = true
  })

end
