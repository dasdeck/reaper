
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('drumRack')

local Track = require 'Track'
local rea = require 'rea'

local track = Track.getFocusedTrack()
if track then 
  rea.logPin(track.guid, track:getState()) 
  rea.logPin('type', track:getType())
end
