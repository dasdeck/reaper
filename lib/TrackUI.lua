local Track = require 'Track'
local Menu = require 'Menu'
local TrackStateButton = require 'TrackStateButton'

local _ = require '_'
local rea = require 'rea'
local TrackUI = class()

function TrackUI.click(track, mouse)

    if mouse:wasRightButtonDown() then
        local menu = Menu:create()
        menu:addItem(TrackStateButton:create(track, 'tcp', 'T'):getMenuEntry())
        menu:addItem(TrackStateButton:create(track, 'mcp', 'M'):getMenuEntry())
        menu:addItem('rename', function()
            local name = rea.prompt('name', track:getName())
            if name then
                rea.transaction('rename track', function()
                    track:setName(name)
                end)
            end
        end)
        menu:show()

    else

        track:focus()

        if mouse:isAltKeyDown() then
            local tracks = Track.getSelectedTracks(true)
            rea.transaction('remove track', function()
                if mouse:isShiftKeyDown() and _.size(tracks) > 0 then
                    _.forEach(tracks, function(track) track:remove() end)
                else
                    track:remove(true)
                end
            end)
        elseif mouse:isShiftKeyDown() then
            track:setMuted(not track:isMuted())
        elseif mouse:isCommandKeyDown() and mouse:isShiftKeyDown() and _.size(Track.getSelectedTracks()) > 0 then

            local firstSelected = _.first(Track.getSelectedTracks()):getIndex()
            local lastSelected = _.last(Track.getSelectedTracks()):getIndex()
            local minIndex = math.min(track:getIndex(), firstSelected)
            local maxIndex = math.max(track:getIndex(), lastSelected)
            local tracks = Track.getAllTracks()
            for i = minIndex, maxIndex do
                tracks[i]:setSelected(true)
            end

        else
            local wasSelected = track:isSelected()
            local sbSelected = 1
            if mouse:isCommandKeyDown() then sbSelected = not wasSelected end
            track:setSelected(sbSelected)
        end

    end

end

return TrackUI