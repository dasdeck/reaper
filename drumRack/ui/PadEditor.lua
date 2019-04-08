local Component = require 'Component'
local ButtonList = require 'ButtonList'
local PadOptions = require 'PadOptions'
local FXButton = require 'FXButton'
-- local AudioTrackUI = require 'AudioTrackUI'
local Layer = require 'Layer'
local Split = require 'Split'
local rea = require 'rea'
local _ = require '_'

local PadEditor = class(Component)

function PadEditor:create(pad)
    self = Component:create()
    self.pad = pad

    self.options =  self:addChildComponent(ButtonList:create(PadOptions(pad), true))

    self.range = self:addChildComponent(Split:create(pad))
    self.range.padButton:setVisible(false)

    self.range.isVisible = function()
        return self.pad.rack:isSplitMode()
    end
    self.range.onDrag = function(mouse)
        local key = self.mouse.x / self.w * 127
        local index = pad:getIndex()
        if not pad:getPrev() then
            pad.rack:getMapper():setParamForPad(pad, 1, 0)
        end

        local nextPad = pad:getNext()
        if nextPad and nextPad:hasContent() then
            pad.rack:getMapper():setParamForPad(pad, 2, key)
            pad.rack:getMapper():setParamForPad(nextPad, 1, key + 1)

            local nextNextPad = nextPad:getNext()
            if not nextNextPad or not nextNextPad:hasContent() then
                pad.rack:getMapper():setParamForPad(nextPad, 2, 127)
            end

        else

            local prevPad = pad:getPrev()
            if prevPad and prevPad:hasContent() then
                pad.rack:getMapper():setParamForPad(pad, 1, key)
                pad.rack:getMapper():setParamForPad(prevPad, 2, key)
            else
                pad.rack:getMapper():setParamForPad(pad, 2, 127)
            end

        end

    end

    self.layers = self:addChildComponent(ButtonList:create())
    self.layers.getData = function()
        return _.map(self.pad:getLayers(), function(layer)
            return {
                size = true,
                proto = function()
                    return Layer:create(layer, self.pad)
                end
            }
        end)
    end
    self.layers:updateList()


    self.fx = self:addChildComponent(FXButton:create(pad, 'pad:fx'))

    setmetatable(self, PadEditor)
    return self
end

function PadEditor:isVisible()
    return self.pad:isSelected()
end

function PadEditor:onFilesDrop(files)
    self.pad:onFilesDrop(files)
end

function PadEditor:resized()
    local h = 20
    local y = 0

    self.options:setBounds(0, y, self.w, h)
    y = self.options:getBottom()

    self.layers:setBounds(0, y, self.w)
    y = self.layers:getBottom()

    self.fx:setBounds(0, y, self.w, h)
    y = self.fx:getBottom()

    self.h = y

end

return PadEditor