
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('drumRack')

local Track = require 'Track'
local _ = require '_'

local tracks = Track.getSelectedTracks(true)
local num = #tracks
if num > 0 then

  local someArmed = _.some(tracks, function(track) return track:isArmed() end)

  Track.disarmAll()
  if not someArmed then
    _.forEach(tracks, function(track)
      track:setArmed(true)
    end)
  end

end
