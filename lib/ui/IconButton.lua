local Component = require 'Component'
local Label = require 'Label'
local TextButton = require 'TextButton'
local Image = require 'Image'
local color = require 'color'
local rea = require 'Reaper'

local IconButton = class(TextButton)

function IconButton:create(icon)

    local self = TextButton:create()

    self.icon = self:addChildComponent(Image:create(icon, 'fit'))
    self.icon.getAlpha = function()
        return self:getToggleStateInt() == 2 and 0.5 or 1
    end

    setmetatable(self, IconButton)
    return self

end

function IconButton:paint(g)
    self:drawBackground(g)
end

function IconButton:resized()
    self.icon:setSize(self.w - 2, self.h - 4)
end




return IconButton