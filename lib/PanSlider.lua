local Slider = require 'Slider'

local PanSlider = class(Slider)

function PanSlider:create(panSource)
    local self = Slider:create()
    self.panSource = panSource
    setmetatable(self,PanSlider)

    self.watchers:watch(function()
        return self.panSource:getPan()
    end, function()
        self:repaint(true)
    end)

    self.pixelsPerValue = 100
    self.bipolar = 0
    self.wheelscale = 0.01
    return self
end

function PanSlider:getText()
    return tostring(round(self:getValue() * 100)) .. ' %'
end

function PanSlider:getValue()
    return self.panSource:getPan()
end

function PanSlider:setValue(volume)
    self.panSource:setPan(volume)
end

function PanSlider:getMin()
    return -1
end

function PanSlider:getMax()
    return 1
end

return PanSlider