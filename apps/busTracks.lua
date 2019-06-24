package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'

local Track = require 'Track'
local _ = require '_'
local selectedTracks = Track.getSelectedTracks()
local index = _.reduce(selectedTracks, function(carry, track)
    return math.min(carry, track:getIndex())
end, 9999999)

local track = Track.insert(index-1)
track:setFolderState(1)

_.forEach(selectedTracks, function(child)
    child:setParent(track)
end)