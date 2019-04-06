local Track = require 'Track'
local _ = require '_'
local colors = require 'colors'
local Bus = class()

function Bus.getAllBusses()
    return _.filter(Track.getAllTracks(), function(track)
        return track:isBus()
    end)
end

function Bus.filterTopLevelTracks(tracks)
    return _.filter(tracks, function(track)
        return not track:getOutput()
    end)
end

function Bus.hasTopLevelTracks(tracks)
    return _.size(Bus.filterTopLevelTracks(tracks)) > 0
end

function Bus.fromTracks(tracks, topLevelOnly)

    tracks = topLevelOnly and Bus.filterTopLevelTracks(tracks) or tracks

    if _.size(tracks) > 0 then
        local bus = Bus.createBus()
        _.forEach(tracks,
        function(track)
            track:setOutput(bus)
        end)
        return bus
    end
end

function Bus.createBus(index, name)

    local track = Track.insert(index)
    track:addFx(name)
    track:iconize()
    track:setType(Track.typeMap.bus)
    track:setName(name or ('Bus ' .. tostring(_.size(Bus.getAllBusses()))))
    track:setColor(colors.bus)
    track:setVisibility(false, true)
    return track
end

return Bus