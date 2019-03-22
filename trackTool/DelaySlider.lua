local Component = require 'Component'
local Slider = require 'Slider'

local DelaySlider = class(Slider)

function DelaySlider:create(trackSource)
    local self = Slider:create()
    self.trackSource = trackSource
    setmetatable(self, DelaySlider)
    return self
end

function DelaySlider:getPlugin(create)
    local track = self.trackSource:getTrack()
    return track and track:getTrackTool(create)

end

function DelaySlider:getText()
    return self:getPlugin() and tostring(self:getValue()) or '--'
end

function DelaySlider:getValue()
    local plugin = self:getPlugin()
    return plugin and plugin:getParam(0) or 0
end

function DelaySlider:isDisabled()
    return self:getPlugin() == nil
end

function DelaySlider:isActive()
    local track = self.trackSource:getTrack()
    -- return not track or not track:isMidiTrack()
    return track
end

function DelaySlider:setValue(val)
    local plugin = self:getPlugin(true)
    if plugin then plugin:setIndex(0):setParam(0, val) end
    self:repaint()
end

return DelaySlider