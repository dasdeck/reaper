local Component = require 'Component'
local TextButton = require 'TextButton'
local DrumRack = require 'DrumRack'
local DrumRackUI = require 'DrumRackUI'
local Track = require 'Track'
local Project = require 'Project'

local rea = require 'rea'
local _ = require '_'

local DrumRackSelector = class(Component)

function DrumRackSelector:create(...)

    local self = Component:create(...)
    self.followSelection = true

    self.button = self:addChildComponent(TextButton:create('+DrumRack'))

    self.button.onButtonClick = function(s, mouse)
        DrumRackUI.drumRackButton(mouse)
    end

    self.watchers:watch(Track.watch.tracks, function()
        if self.drumrack then
            if not self.drumrack.rack.track:exists() then
                self.drumrack:remove()
                self.drumrack = nil
            end
        end
    end)

    self.watchers:watch(Track.watch.selectedTracks, function(tracks)
        if self.followSelection then

            local selectedDrumRack = _.some(tracks, function(track)
                return DrumRack.getAssociatedDrumRack(track)
            end)
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

    self.button:setVisible(not self.drumrack)
    self:repaint()

end

function DrumRackSelector:resized()

    if self.drumrack then
        self.drumrack:setSize(self.w, self.h)
    end
    self.button:setSize(self.w, self.h)



end


return DrumRackSelector