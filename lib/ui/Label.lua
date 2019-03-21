local Component = require 'Component'
local color = require 'color'

local rea = require 'Reaper'
local Label = class(Component)

function Label:create(text, ...)

    local self = Component:create(...)
    self.h = 30
    self.w = 30
    self.text = (text and text.label) or text or ''
    self.color = color.rgb(1,1,1)
    setmetatable(self, Label)
    return self

end

function Label:getColor()
    local c = self.color
    if self:isDisabled() then c = c:fade(0.2) end
    return c
end

function Label:drawBackground(c)
    c = c or self:getColor()
    local padding = 0

    self:setColor(c);
    self:roundrect(padding ,padding , self.w - 2 * padding, self.h - 2*padding, 5, true)

end

function Label:drawLabelText(c)

    c = c or self:getColor()

    local text = self:getText()
    if text and text:len() then
        local padding = 5
        self:setColor(c:lighten_to(1-round(c.L)):desaturate_to(0))
        self:drawFittedText(text, padding ,0 , self.w - padding * 2, self.h)
    end
end

function Label:paint()

    local c = self:getColor()
    self:drawBackground(c)
    self:drawLabelText(c)

end


function Label:isDisabled()
    return self.disabled or (self.parent and self.parent:isDisabled())
end

function Label:getText()
    return self.text
end

return Label