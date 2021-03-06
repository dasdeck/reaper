local Component = require 'Component'
local TextButton = require 'TextButton'
local Slider = require 'Slider'
local rea = require 'rea'

local TransposeControll = class(Component)

function TransposeControll:create(track)
    local self = Component:create()
    setmetatable(self, TransposeControll)

    self.track = track

    self.value = self:addChildComponent(Slider:create())

    self.value.getValue = function()
        return self:getValue()
    end

    self.value.setValue = function(s, val)
        self:setValue(val)
    end

    self.semDown = self:addChildComponent(TextButton:create('<'))
    self.semDown.onButtonClick = function(s, mouse)
        rea.transaction('change transpose', function()
            self.value:setValue(self.value:getValue() - (mouse:isAltKeyDown() and 12 or 1))
        end)
    end
    self.semUp = self:addChildComponent(TextButton:create('>'))
    self.semUp.onButtonClick = function(s, mouse)
        rea.transaction('change transpose', function()
            self.value:setValue(self.value:getValue() + (mouse:isAltKeyDown() and 12 or 1))
        end)
    end

    return self
end

function TransposeControll:getValue()
    return math.floor(self.track:getTrackTool(true):getParam(2))
end

function TransposeControll:setValue(val)
    self.track:getTrackTool(true):setParam(2, val)
end

function TransposeControll:resized()
    local size = 20

    self.semDown:setSize(size, size)
    self.value:setBounds(self.semDown:getRight(), 0, self.w - size * 2, size)
    self.semUp:setBounds(self.value:getRight(), 0, size, size)

end

return TransposeControll