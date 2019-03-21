package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('drumRack')
addScope('drumRack/ui')

local Watcher = require 'Watcher'

local DrumRackSelector = require 'DrumRackSelector'
local Window = require 'Window'


local Plugin = require 'Plugin'

if not Plugin.exists('DrumRack') then

  reaper.MB("this script need the drumrack jsfx to be installed", "install plugin", 0)


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
