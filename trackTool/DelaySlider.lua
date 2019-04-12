local Component = require 'Component'
local Slider = require 'Slider'

local DelaySlider = class(Slider)

function DelaySlider:create(track)
    local self = Slider:create()
    self.track = track
    self.pixelsPerValue = 5
    setmetatable(self, DelaySlider)
    return self
end

function DelaySlider:getPlugin(create)
    return self.track:getTrackTool(create)

end

function DelaySlider:getText()
    return self:getPlugin() and tostring(math.floor(self:getValue())) or '--'
end

function DelaySlider:getValue()
    local plugin = self:getPlugin()
    return plugin and math.floor(plugin:getParam(0) or 0)
end

function DelaySlider:isDisabled()
    return self:getPlugin() == nil
end

function DelaySlider:setValue(val)
    local plugin = self:getPlugin(true)
    if plugin then plugin:setParam(0, val) end
end

return DelaySlider