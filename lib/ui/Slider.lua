local Component = require 'Component'
local Label = require 'Label'
local color = require 'color'
local colors = require 'colors'

local rea = require 'rea'
local Slider = class(Label)

function Slider:create(...)

    local self = Label:create('', ...)
    setmetatable(self, Slider)
    self.pixelsPerValue = 100
    self.colorValue = color.rgb(1,0,0)
    self.wheelscale = 1
    return self

end

function Slider:canClickThrough()
    return false
end

function Slider:onMouseDown()

    reaper.Undo_BeginBlock()

    self.valueDown = self:getValue()
    self.yDown = gfx.mouse_y
end

function Slider:onMouseUp()
    if self.valueDown and self.valueDown ~= self:getValue() then
        reaper.Undo_EndBlock('slider change', -1)
    end
end

function Slider:onDrag()
    self:setValue(self.valueDown + (self.yDown - gfx.mouse_y) / self.pixelsPerValue)
    self:repaint(true)
end

function Slider:onMouseWheel(mouse)
    rea.transaction('slider change', function()
        if mouse.mouse_wheel > 0 then
            self:setValue(self:getValue() + 1 * self.wheelscale)
        else
            self:setValue(self:getValue() - 1 * self.wheelscale)
        end
        self:repaint(true)
    end)
end

function Slider:onClick(mouse)
    if mouse:wasRightButtonDown() then
        self:promptValue()
    end
    -- if mouse:isCommandKeyDown() then

    -- end
end

function Slider:getColor(full)
    local c = Label.getColor(self)
    if not full then c = c:fade_by(0.8) end
    return c
end

function Slider:resetValue()
    rea.transaction('reset slider', function()
        self:setValue(self:getDefaultValue())
        self:repaint(true)
    end)
end

function Slider:paint(g)

    Label.paint(self, g)
    g:setColor(self:getColor(true))
    local padding = 0
    g:roundrect(padding ,padding , self.w - 2 * padding, self.h - 2*padding, 5, false)
    self:paintBar(g)
end

function Slider:paintBar(g)

    local min = self:getMin()
    local max = self:getMax()
    if min and max then
        g:setColor((self.colorValue):with_alpha(0.5))

        local range = max - min

        local center = (self.bipolar and ((self.bipolar - min) / range) or 0) * self.w

        local valueRelative = (self:getValue() - min) / range

        if self.h > self.w then
            local h = self.h * valueRelative
            g:rect(0, self.h - h, self.w, h, true)
        else
            local x = math.floor(self.w * valueRelative)
            local w = math.abs(x - center)
            x = math.min(center, x)
            g:rect(x, 0, w, self.h, true)
        end
    end

end

function Slider:promptValue()
    local value = rea.prompt("value", self:getValue())
    if value and value:trim():isNumeric() then

        local newval = tonumber(value)
        if self:getValue() ~= newval then
            rea.transaction('slider change', function()
                self:setValue(newval)
                self:repaint(true)
            end)
        end
    end
end

function Slider:onDblClick()
    self:resetValue()
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

function Slider:getMax()
end

function Slider:getMin()
end

return Slider