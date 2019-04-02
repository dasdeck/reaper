local Track = require 'Track'
local colors = require 'colors'
local _ = require '_'

local Aux = class(Track)

function Aux.createAux(name)
    local track = Track.insert()
    track:setColor(colors.aux)
    track:addFx(name)
    track:iconize()
    track:setType(Track.typeMap.aux)
    track:setName(name)
    track:setVisibility(false, true)
    return track
end

function Aux.getAuxTracks()
    return _.filter(Track.getAllTracks(), function(track)
        return track:isAux()
    end)
end

return Aux