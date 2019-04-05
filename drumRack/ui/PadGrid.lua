


local Component = require 'Component'
local PadUI = require 'PadUI'
local _ = require '_'
local PadGrid = class(Component)
local rea = require 'rea'

local defaults = {
    cols = 4,
    rows = 4
}

function PadGrid:create(rack, ...)

    local self = Component:create(...)
    self.rack = rack
    _.assign(self, defaults)

    setmetatable(self, PadGrid)
    self:createPads()
    return self

end

function PadGrid:createPads()

    local i = 1
    for row = 1, self.rows do
        for col = 1, self.cols do
            self:addChildComponent(PadUI:create(self.rack.pads[i]))
            i = i + 1
        end
    end

end

function PadGrid:resized()

    local i = 1
    local w = self.w / self.cols
    local h = self.h / self.rows
    for row = 1, self.rows do
        for col = 1, self.cols do
            local pad = self.children[i]
            i = i + 1
            pad:setBounds((col-1) * w, (self.rows - row) * h, w, h)
        end
    end

end

return PadGrid