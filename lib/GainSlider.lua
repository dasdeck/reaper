
local Slider = require 'Slider'

local GainSlider = class(Slider)

function GainSlider:create(gainSource)
    local self = Slider:create()
    self.gainSource = gainSource
    setmetatable(self, GainSlider)
    self.pixelsPerValue = 10

    self.watchers:watch(function()
        return self.gainSource:getVolume()
    end, function()
        self:repaint(true)
    end)
    return self
end

function GainSlider:getValue()
    return round(self.gainSource:getVolume(),10)
end

function GainSlider:setValue(volume)
    self.gainSource:setVolume(volume)
end

function GainSlider:getMin()
    return -60
end

function GainSlider:getMax()
    return 10
end

return GainSlider