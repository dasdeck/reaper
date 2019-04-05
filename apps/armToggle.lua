
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('drumRack')

local Track = require 'Track'
local _ = require '_'

local track = Track.getSelectedTrack(true)
if track then
  local wereArmed = _.filter(Track.getAllTracks(), function(track) return track:isArmed() end)
  if track:isArmed() and _.size(wereArmed) == 1 then
    Track.disarmAll()
  else
    track:setArmed(1)
  end

end
