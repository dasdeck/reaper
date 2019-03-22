local Component = require 'Component'
local Image = require 'Image'
local TextButton = require 'TextButton'
local Label = require 'Label'
local Track = require 'Track'
local _ = require '_'

local TrackListComp = class(Component)

function TrackListComp:create(track)

    local self = Component:create()
    setmetatable(self, TrackListComp)

    self.track = track
    self.name = self:addChildComponent(TextButton:create(track:getName() or track:getDefaultName()))

    self.name.getToggleState = function()
        return track:isSelected()
    end

    self.name.onButtonClick = function(s, mouse)
        local wasSelected = track:isSelected()
        local sbSelected = 1
        if mouse:isCommandKeyDown() then sbSelected = not wasSelected end
        if mouse:isShiftKeyDown() then
            local firstSelected = _.first(Track.getSelectedTracks()):getIndex()
            local lastSelected = _.last(Track.getSelectedTracks()):getIndex()
            local minIndex = math.min(track:getIndex(), firstSelected)
            local maxIndex = math.max(track:getIndex(), lastSelected)
            local tracks = Track.getAllTracks()
            for i=minIndex,maxIndex do
                tracks[i]:setSelected(true)
            end
        else
            track:setSelected(sbSelected)
        end
    end

    local icon = track:getIcon()
    self.icon = self:addChildComponent(icon and Image:create(icon, 'fit') or Component:create())

    return self

end

function TrackListComp:paint()
    Label.drawBackground(self, self.name:getColor())
end

function TrackListComp:resized()

    local h = self.h

    self.icon:setBounds(0,0,h,h)
    -- n = self.name.text
    self.name:setBounds(self.icon:getRight(), 0, self.w - h, h)
end

return TrackListComp