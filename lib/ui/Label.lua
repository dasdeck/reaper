local Component = require 'Component'
local Text = require 'Text'
local color = require 'color'

local rea = require 'rea'
local Label = class(Component)

function Label:create(content, ...)

    local self = Component:create(...)

    self.r = 6
    if content then
        if type(content) == 'string' then
            self.content = self:addChildComponent(Text:create(content))
            self.content.getText = function()
                return self.getText and self:getText() or self.content.text
            end
        else
            self.content = self:addChildComponent(content)
        end

        -- self.content.isVisible = function() return false end--(false)
    end

    self.color = color.rgb(1,1,1)
    setmetatable(self, Label)
    return self

end

function Label:getColor()
    local c = self.color
    if self:isDisabled() then c = c:fade(0.2) end
    return c
end

function Label:drawBackground(g, c)
    c = c or self:getColor()
    local padding = 1

    g:setColor(c);
    g:rect(padding ,padding , self.w - 2 * padding, self.h - 2*padding, true)
    -- g:roundrect(padding ,padding , self.w - 2 * padding, self.h - 2*padding, self.r or 5, true)

end

function Label:paint(g)

    local c = self:getColor()
    self:drawBackground(g, c)
    -- self.content:paintInline(g)

end

return Label