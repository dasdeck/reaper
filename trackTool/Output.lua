local TextButton = require 'TextButton'
local colors = require 'colors'

local Output = class(TextButton)

function Output:create(track)
    local self = TextButton:create('output')

    self.track = track
    self.currentOutput = self.track:getOutput()
    self.color = self.currentOutput and self.currentOutput:getColor() or colors.default
    return self

end

function Output:isDisabled()
    return not self.track:getOutput() and self.track:getValue('toParent') == 0
end

function Output:getText()
    local output = self.track:getOutput()
    if not output then
        if self.track:getValue('toParent') > 0 then
            return 'master'
        else
            return '--'
        end
    else
        return output:getName()
    end
end

function Output:onClick(mouse)

    if mouse:wasRightButtonDown() then
        local menu = Menu:create()
        local busMenu = Menu:create()
        _.forEach(Track.getAllTracks(), function(otherTrack)
            -- local checked = false
            if otherTrack ~= self.track and otherTrack:isBus() then
                busMenu:addItem(otherTrack:getName() or otherTrack:getDefaultName(), {
                    callback = function()
                        self.track:setOutput(otherTrack)
                    end,
                    checked = self.currentOutput == otherTrack,
                    transaction = 'change routing'

                })
            end

        end)
        busMenu:addSeperator()
        busMenu:addItem('new bus', function()
            self.track:setOutput(Bus.createBus(), true)
        end, 'add bus')
        menu:addItem('bus', busMenu)
        menu:addItem('master', {
            checked = not self.currentOutput and self.track:getValue('toParent') > 0,
            callback = function()
                self.track:setOutput(nil)
            end
        }, 'change routing')
        menu:show()
    elseif self.currentOutput then
        self.currentOutput:focus()
    end
end

return Output