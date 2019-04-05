package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
local ChangeStacker = require 'ChangeStacker'
local Track = require 'Track'

local rea = require 'rea'

local track

local stacker = ChangeStacker:create('change pan')
stacker.getValue = function()
  return track and track:exists() and track:getPan()
end
stacker.setValue = function(s,value)
  if track and track:exists() then track:setPan(value) end
end

function test()
  track = Track.getFocusedTrack(true)
  if track then
    local context = {reaper.get_action_context()}
    local newValue = context[7]

    stacker:apply(newValue * 0.01)

  end
  reaper.defer(test)
end
test()
