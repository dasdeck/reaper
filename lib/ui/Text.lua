local Component = require 'Component'
local color = require 'color'

local rea = require 'Reaper'
local Text = class(Component)

function Text:create(text, ...)

    local self = Component:create(...)
    self.text = text or ''
    self.color = color.rgb(1,1,1)
    setmetatable(self, Text)
    return self

end

function Text:getColor()
    local c = self.color
    if self:isDisabled() then c = c:fade(0.2) end
    return c
end

function Text:paint()

    local c = self:getColor()
    local text = self:getText()
    if text and text:len() then
        local padding = 5
        self:setColor(c:lighten_to(1-round(c.L)):desaturate_to(0))
        self:drawFittedText(text, padding ,0 , self.w - padding * 2, self.h)
    end

end

function Text:getText()
    return self.text
end

return Text