local Component = require 'Component'
local Meter = class(Component)
local rea = require 'rea'

function Meter:create(track)
    local self = Component:create()
    self.track = track
    setmetatable(self, Meter)
    self.watchers:watch(function()
        return round(self.track:getPeakInfo()^0.5, 10   )
    end, function(val)
        self.gain = val
        self:repaint()
    end)
    self.overlayPaint = true
    return self
end

function Meter:paint(g)
    local r = math.min(self.w, self.h) / 2
    local c = math.min(1, self.gain)
    g:setColor(1,0,0, c)
    g:circle(r,r,r, true, true)
end

return Meter