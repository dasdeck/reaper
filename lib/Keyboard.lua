local Component = require 'Component'
local _ = require '_'

local Keyboard = class(Component)

function Keyboard.create(lo, hi)

    local self = Component:create()
    setmetatable(self, Keyboard)
    self.lo = lo or 0
    self.hi = hi or 127
    return self
end

function Keyboard:paint(g)

    local num = (self.hi - self.lo) + 1
    local w  = math.floor(self.w / num)

    local blackKeys = {
       1, 3, 6, 8, 10
    }
    for i = 0, num do

        local c = _.find(blackKeys, (i + self.lo) % 12) and 0 or 1
        g:setColor(c,c,c, 1)
        g:rect(i * w , 0, w - 1 , self.h, true, true)
    end
end

return Keyboard