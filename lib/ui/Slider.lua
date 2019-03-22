local Component = require 'Component'
local Label = require 'Label'
local color = require 'color'

local rea = require 'Reaper'
local Slider = class(Label)

function Slider:create(...)

    local self = Label:create('', ...)
    setmetatable(self, Slider)
    return self

end

function Slider:canClickThrough()
    return false
end

function Slider:onMouseDown()
    self.valueDown = self:getValue()
    self.yDown = gfx.mouse_y
end

function Slider:onDrag()
    self:setValue(self.valueDown + (self.yDown - gfx.mouse_y)    / 100)
end

function Slider:onMouseWheel(mouse)
    if mouse.mouse_wheel > 0 then
        self:setValue(self:getValue() + 1)
    else
        self:setValue(self:getValue() - 1)
    end
end

function Slider:onClick(mouse)
    if mouse:isCommandKeyDown() then
        self:setValue(self:getDefaultValue())
    end
end

function Slider:getColor(full)
    local c = Label.getColor(self)
    if not full then c = c:fade_by(0.8) end
    return c
end

function Slider:paint()

    Label.paint(self)

    self:setColor(self:getColor(true))

    local padding = 0
    self:roundrect(padding ,padding , self.w - 2 * padding, self.h - 2*padding, 5, false)

end

function Slider:onDblClick()
    local success, value = reaper.GetUserInputs("value", 1, "value", self:getValue())
    local val = tonumber(value)
    if success and tostring(val) == value then
        self:setValue(val)
    end
end

function Slider:setValue(val)
end

function Slider:getValue()
    return 0
end

function Slider:getText()
    return tostring(self:getValue())
end

function Slider:getDefaultValue()
    return 0
end

return Slider