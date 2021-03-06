local Label = require 'Label'
local Mouse = require 'Mouse'
local Component = require 'Component'
local color = require 'color'
local rea = require 'rea'

local TextButton = class(Label)

function TextButton:create(content, ...)
    local self = Label:create(content, ...)
    setmetatable(self, TextButton)
    return self
end

function TextButton:getToggleStateInt()
    local state = self:getToggleState()
    if type(state) ~= 'number' then
       state = state and 1 or 0
    end
    return state
end

function TextButton:repaintOnMouse()
    return not Component.dragging
end


function TextButton:getColor()
    local state = self:getToggleStateInt()
    local c = ((self:isMouseDown() or state > 0) and self.color)
                or (self:isMouseOver() and self.color:fade(0.8))
                or self.color:fade(0.5)

    if self:isDisabled() then c = c:fade(0.2) end
    return c
end

function TextButton:onClick(mouse)
    if self.onButtonClick and self:isVisible() and not self:isDisabled() then
        self:onButtonClick(mouse)
    end
    self:repaint(true)
end

function TextButton:canClickThrough()
    return false
end

function TextButton:getToggleState()
    return false
end

function TextButton:getMenuEntry(tansaction)
    assert(self.getText)
    return {
        name = self:getText(),
        callback = function()
            self:onClick(Mouse.capture())
        end,
        checked = self:getToggleState(),
        disabled = self:isDisabled(),
        tansaction = tansaction
    }
end


return TextButton