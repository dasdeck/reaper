local Track = require 'Track'
local Menu = require 'Menu'

local colors = require 'colors'
local _ = require '_'

local Aux = class(Track)


function Aux.getCreateMenu(callback, menu)

    callback = callback or function()end
    menu = menu or Menu:create()

    menu:addItem('new aux', function()
        callback(Aux.createAux():focus())
    end, 'new aux')

    return menu
end

function Aux.getMenu(callback, menu, checked)

    checked = checked or function() return false end

    if instanceOf(Track, checked) then
        checked = function(bus)
            return bus == checked
        end
    end

    callback = callback or function()end
    menu = menu or Menu:create()

    _.forEach(Aux.getAuxTracks(), function(aux)
        menu:addItem(aux:getName(), {
            checked = checked(aux),
            function()
                callback(aux)
            end
        })
    end)

    menu:addSeperator()
    Aux.getCreateMenu(callback, menu)
    return menu
end


function Aux.createAux(name)
    local track = Track.insert()
    track:setColor(colors.aux)
    -- track:addFx(name)
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