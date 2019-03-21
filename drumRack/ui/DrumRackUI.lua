local PadGrid = require 'PadGrid'
local Component = require 'Component'
local PadEditor = require 'PadEditor'
local ButtonList = require 'ButtonList'
local Split = require 'Split'
local DrumRackOptions = require 'DrumRackOptions'

local colors = require 'colors'
local _ = require '_'


local rea = require 'Reaper'

local DrumRackUI = class(Component)


-- methods

function DrumRackUI:create(rack)

    local self = Component:create()

    setmetatable(self, DrumRackUI)

    self.rack = rack

    self.opts = self:addChildComponent(ButtonList:create(DrumRackOptions(rack), true))
    self.padgrid = self:addChildComponent(PadGrid:create({rack = rack}))

    local splits = _.map(rack.pads, function(pad) return {args = pad} end)
    self.layers = self:addChildComponent(ButtonList:create(splits, false, Split))
    self.layers.isVisible = function()
        return rack:isSplitMode()
    end
    self.padgrid.isVisible = function()
        return not rack:isSplitMode()
    end
--
    return self

end

function DrumRackUI:isVisible()
    return self.rack:getTrack():exists()
end

function DrumRackUI:update()
    local currentPad = self.padEditor and self.padEditor.pad

    if self.rack:getSelectedPad() and self.rack:getSelectedPad() ~= currentPad then
        if self.padEditor then self.padEditor:delete() end
        self.padEditor = self:addChildComponent(PadEditor:create(self.rack:getSelectedPad()))
    end
end

function DrumRackUI:resized()

    self:update()

    self.opts:setBounds(0, 0, self.w, 20)

    local padgrid = self.w
    self.padgrid:setBounds(0, self.opts:getBottom(), padgrid, padgrid)
    self.layers:setBounds(0, self.opts:getBottom(), padgrid, padgrid)

    local y = self.padgrid:getBottom()
    if self.padEditor then
        self.padEditor:setBounds(0, y, self.w)
    end

end

return DrumRackUI