
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('drumRack')

local Track = require 'Track'

function test()
  local context = {reaper.get_action_context()}
  local track = Track.getFocusedTrack(true)
  track:setPan(track:getPan() + context[7] * 0.01)
  reaper.defer(test)
end
reaper.defer(test)
