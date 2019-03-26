local Component = require 'Component'
local LayerList = require 'LayerList'
local ButtonList = require 'ButtonList'
local PadOptions = require 'PadOptions'
local Split = require 'Split'
local rea = require 'rea'

local PadEditor = class(Component)

function PadEditor:create(pad)
    self = Component:create()
    self.pad = pad
    self.options =  self:addChildComponent(ButtonList:create(PadOptions(pad), true))

    self.options.isVisible = function( )
        return pad:hasContent()
    end

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

    self.layers = self:addChildComponent(LayerList:create(pad))
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

    self.range:setBounds(0,0,self.w, h)

    local y = self.range:isVisible() and self.range:getBottom() or 0


    self.options:setBounds(0, y, self.w, h)


    self.layers:setBounds(0, self.options:getBottom(), self.w, self.h - self.options:getBottom())

end

return PadEditor