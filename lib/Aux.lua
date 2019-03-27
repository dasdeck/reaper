local Track = require 'Track'
local colors = require 'colors'
local _ = require '_'

local Aux = class(Track)

function Aux.createAux(name)
    local track = Track.insert()
    track:setColor(colors.aux)
    track:setName('aux:' .. name)
    track:setVisibility(false, true)
    return track
end

function Aux.getAuxTracks()
    return _.filter(Track.getAllTracks(), function(track)
        return track:isAux()
    end)
end

return Aux