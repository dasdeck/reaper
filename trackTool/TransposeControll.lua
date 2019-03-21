local Component = require 'Component'
local TextButton = require 'TextButton'
local Slider = require 'Slider'

local TransposeControll = class(Component)

function TransposeControll:create(trackSource)
    local self = Component:create()
    setmetatable(self, TransposeControll)

    self.children.value = Slider:create()

    function getPlugin()
        local track = trackSource:getTrack()
        return track:getTrackTool(true)
    end

    function self.children.value.getValue()
         return getPlugin():getParam(2)
    end

    function self.children.value:setValue(val)
        getPlugin():setParam(2, val)
    end

    self.children.semDown = TextButton:create('<')
    self.children.semDown.onClick = function(s, mouse)
        self.children.value:setValue(self.children.value:getValue() - (mouse:isAltKeyDown() and 12 or 1))
    end
    self.children.semUp = TextButton:create('>')
    self.children.semUp.onClick = function(s, mouse)
        self.children.value:setValue(self.children.value:getValue() + (mouse:isAltKeyDown() and 12 or 1))
    end

    return self
end

function TransposeControll:resized()
    local size = 20
    local c = self.children

    c.semDown.w = size
    c.semDown.h = size

    c.value.x = c.semDown:getRight()
    c.value.w = self.w - size * 2
    c.value.h = size

    c.semUp.x = c.value:getRight()
    c.semUp.w = size
    c.semUp.h = size

end

return TransposeControll