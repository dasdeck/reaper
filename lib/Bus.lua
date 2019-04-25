local Track = require 'Track'
local Menu = require 'Menu'

local _ = require '_'
local colors = require 'colors'
local Bus = class()

function Bus.getCreateMenu(callback, menu)

    callback = callback or function()end
    menu = menu or Menu:create()

    local allTracks = Track.getAllTracks()
    if Bus.hasTopLevelTracks(allTracks) then
        menu:addItem('create bus from all', function()
            local bus = Bus.fromTracks(allTracks, true)
            if bus then
                bus:focus()
                callback(bus)
            end
        end, 'bus all')
    end

    local selectedTracks = Track.getSelectedTracks()
    if Bus.hasTopLevelTracks(selectedTracks) then
        menu:addItem('create bus from selection', function()
            local bus = Bus.fromTracks(selectedTracks, true)
            if bus then
                bus:focus()
                callback(bus)
            end
        end, 'bus selection')
    end
    menu:addItem('create empty bus', function()
        callback(Bus.createBus():focus())
    end, 'create empty bus')

    return menu
end

function Bus.getMenu(callback, menu, checked)

    checked = checked or function() return false end

    if type(checked) ~= 'function' then
        checked = function(bus)
            return bus == checked
        end
    end

    callback = callback or function()end
    menu = menu or Menu:create()

    _.forEach(Bus.getAllBusses(), function(bus)
        menu:addItem(bus:getName(), {
            checked = checked(bus),
            function()
                callback(bus)
            end
        })
    end)

    menu:addSeperator()
    Bus.getCreateMenu(callback, menu)
    return menu
end

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