local Component = require 'Component'
local Meter = class(Component)
local rea = require 'rea'

function Meter:create(track)
    local self = Component:create()
    self.track = track
    setmetatable(self, Meter)

    self.watchers:watch(function()
        return round(self.track:getPeakInfo(), 10)
    end, function(val)
        self.gain = val
        self:repaint()
    end)
    self.overlayPaint = true
    return self
end

function Meter:onClick(mouse)
    self.track:getPeakHoldInfo(true)
    self:repaint()
end

function Meter:paint(g)

    local w = self.w / 2
    -- for i = 0, 1 do
    local c = math.min(1, self.gain)

    if c == 1 then
        g:setColor(1,0,0,1)
    else
        g:setColor(0,0,0,1)
    end

    local h = math.floor(c * self.h)

    g:rect(0,self.h - h, self.w, h, true)

    -- endC
    -- local r = math.min(self.w, self.h) / 2



    -- g:circle(r,r,r, true, true)

end

return Meter