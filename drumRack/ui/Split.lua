local PadUI = require 'PadUI'
local colors = require 'colors'
local Mouse = require 'Mouse'
local rea = 'Reaper'

local Split = class(PadUI)

function Split:create(pad)
    local self = PadUI:create(pad)

    setmetatable(self, Split)

    return self
end

function Split:paintOverChildren(g)

    if self.pad:hasContent() then
        local low, high = self.rack:getMapper():getKeyRange(self.pad)

        local x1 = low / 127 * self.w
        local x2 = (high+1) / 127 * self.w

        g:setColor(colors.fx:with_alpha(0.5))
        g:rect(x1, 0, x2 - x1, self.h, true)
    end

end

return Split