local Component = require 'Component'
local TextButton = require 'TextButton'
local DrumRack = require 'DrumRack'
local DrumRackUI = require 'DrumRackUI'
local Track = require 'Track'
local rea = require 'Reaper'

local DrumRackSelector = class(Component)

function DrumRackSelector:create()
    local self = Component:create()
    self.followSelection = true

    self.button = self:addChildComponent(TextButton:create('+DrumRack'))
    self.button.isVisible = function()
        return not self.drumrack
    end

    self.button.onButtonClick = function(s, mouse)
        DrumRackUI.drumRackButton(mouse)
    end

    Track.watch.tracks:onChange(function()
        if self.drumrack then
            if not self.drumrack.rack.track:exists() then
                self.drumrack:remove()
                self.drumrack = nil
            end
        end
    end)

    Track.watch.selectedTrack:onChange(function(track)
        if self.followSelection then
            local selectedDrumRack = DrumRack.getAssociatedDrumRack(track)
            if selectedDrumRack then
                if not self.drumrack or self.drumrack.rack ~= selectedDrumRack then
                    self:setDrumRack(selectedDrumRack)
                end
            else
                self:setDrumRack(nil)
            end

        end
    end)

    setmetatable(self, DrumRackSelector)

    return self
end

function DrumRackSelector:setDrumRack(rack)
    if self.drumrack then self.drumrack:delete() end
    self.drumrack = rack and self:addChildComponent(DrumRackUI:create(rack)) or nil
end

function DrumRackSelector:resized()

    if self.drumrack then
        self.drumrack:setSize(self.w, self.h)
    else
        self.button:setSize(self.w, self.h)
    end



end


return DrumRackSelector