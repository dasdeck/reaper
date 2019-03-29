local Track = require 'Track'
local _ = require '_'
local colors = require 'colors'
local Bus = class()

function Bus.getAllBusses()
    return _.filter(Track.getAllTracks(), function(track)
        return track:isBus()
    end)
end

function Bus.createBus(index)
    local track = Track.insert(index)
    track:setType(Track.typeMap.bus)
    track:setColor(colors.fx)
    return track
end

return Bus