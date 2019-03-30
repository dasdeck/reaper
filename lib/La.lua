local Track = require 'Track'
local colors = require 'colors'
local _ = require '_'

local La = class(Track)

function La.createLa(source)
    local track = Track.insert()
    track:setOutput(source:getOutput())
    track:setColor(colors.la)
    track:setName(source:getName())
    track:setType(Track.typeMap.la)
    track:setVisibility(false, true)
    :setIcon(source:getIcon() or 'fx.png')

    source:createSend(track)
    :setMidiBusIO(-1, -1)
    :setMode(3)

    return track
end

function La.getLaTracks()
    return _.filter(Track.getAllTracks(), function(track)
        return track:isLa()
    end)
end

return La