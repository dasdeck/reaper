local Component = require 'Component'
local Label = require 'Label'
local color = require 'color'

local rea = require 'rea'
local Slider = class(Label)

function Slider:create(...)

    local self = Label:create('', ...)
    self.pixelsPerValue = 100
    setmetatable(self, Slider)
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
    -- rea.logCount('drags')
    self:repaint(true)
end

function Slider:onMouseWheel(mouse)
    rea.transaction('slider change', function()
        if mouse.mouse_wheel > 0 then
            self:setValue(self:getValue() + 1)
        else
            self:setValue(self:getValue() - 1)
        end
        self:repaint(true)
    end)
end

function Slider:onClick(mouse)
    if mouse:isCommandKeyDown() then
        self:setValue(self:getDefaultValue())
        self:repaint(true)
    end
end

function Slider:getColor(full)
    local c = Label.getColor(self)
    if not full then c = c:fade_by(0.8) end
    return c
end

function Slider:paint(g)

    Label.paint(self, g)

    g:setColor(self:getColor(true))

    local padding = 0
    g:roundrect(padding ,padding , self.w - 2 * padding, self.h - 2*padding, 5, false)

end

function Slider:onDblClick()
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