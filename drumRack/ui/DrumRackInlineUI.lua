local PadGrid = require 'PadGrid'
local Component = require 'Component'
local PadEditor = require 'PadEditor'
local ButtonList = require 'ButtonList'
local Split = require 'Split'
local DrumRackOptions = require 'DrumRackOptions'
local Project = require 'Project'
local DrumRack = require 'DrumRack'
local Menu = require 'Menu'
local Track = require 'Track'

local colors = require 'colors'
local _ = require '_'

local rea = require 'rea'

local DrumRackInlineUI = class(Component)

-- methods

function DrumRackInlineUI:create(rack)

    local self = Component:create()

    setmetatable(self, DrumRackInlineUI)

    self.rack = rack

    -- self.opts = self:addChildComponent(ButtonList:create(DrumRackOptions(rack), true))
    self.padgrid = self:addChildComponent(PadGrid:create(rack))

    local splits = _.map(rack.pads, function(pad) return {args = pad} end)
    -- self.layers = self:addChildComponent(ButtonList:create(splits, false, Split))

    local change = function()
        -- self.layers:setVisible(rack:isSplitMode())
        self.padgrid:setVisible(not rack:isSplitMode())
        self:update()
    end
    self.watchers:watch(Project.watch.project, change)
    self.watchers:watch(function()
        return self.rack:getSelectedPad()
    end, change)
    change()

    return self

end

function DrumRackInlineUI:update()
    local currentPad = self.padEditor and self.padEditor.pad

    if self.rack:getSelectedPad() and self.rack:getSelectedPad() ~= currentPad then
        if self.padEditor then self.padEditor:delete() end
        self.padEditor = self:addChildComponent(PadEditor:create(self.rack:getSelectedPad()))
    end

    self:resized()
end

function DrumRackInlineUI:resized()

    -- self.opts:setBounds(0, 0, self.w, 20)
    local y = 0

    local padgrid = self.w
    self.padgrid:setBounds(0, y, padgrid, padgrid)
    -- self.layers:setBounds(0, padgrid, padgrid)

    local y = self.padgrid:getBottom()
    if self.padEditor then
        self.padEditor:setBounds(0, y, self.w)
    end

    self.h = self.padEditor:getBottom()

end

return DrumRackInlineUI