
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('drumRack')

local Track = require 'Track'

function test()
  local context = {reaper.get_action_context()}
  local track = Track.getFocusedTrack(true)
  track:setVolume(track:getVolume() + context[7] * 0.1)
  reaper.defer(test)
end
reaper.defer(test)
