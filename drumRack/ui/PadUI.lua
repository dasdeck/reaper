local TextButton = require 'TextButton'
local Component = require 'Component'
local Track = require 'Track'
local Layer = require 'Layer'
local Menu = require 'Menu'
local Pad = require 'Pad'
local _ = require '_'
local colors = require 'colors'
local rea = require 'Reaper'
local Watcher = require 'Watcher'
local Image = require 'Image'
local icons = require 'icons'
local PadUI = class(Component)
local DrumRack = require 'DrumRack'

function PadUI.showMenu(pad)

    local menu = Menu:create()

    local low, high = pad.rack:getMapper():getKeyRange(pad)

    local learnMenu = Menu:create()
    learnMenu:addItem(tostring(low) .. '-' .. tostring((high)), {
        disabled = true
    })

    learnMenu:addItem('low', function() pad:learnLow() end)
    learnMenu:addItem('high', function() pad:learnHi() end)
    learnMenu:addItem('both', function() pad:learn() end)

    menu:addItem('learn', learnMenu)

    local addMenu = Menu:create()
    addMenu:addItem('selected tracks as layers', function() pad:addSelectedTracks() end, 'add empty track')
    addMenu:addItem('empty track', function() pad:addLayer() end, 'add empty track')
    addMenu:addItem('instrument', function()
        local success, name = reaper.GetUserInputs("name", 1, "name", "")
        if success then
            pad:addLayer(name)
        end
    end, 'add instrument pad')

    menu:addItem('add', addMenu)
    menu:addSeperator()
    menu:addItem('clear', function() pad:clear() end, 'clear pad')
    menu:show()

end

function PadUI:onDelete( )
    self.watcher:close()
end

function PadUI:create(pad)

    local self = Component:create()
    setmetatable(self, PadUI)
    self.pad = pad
    self.rack = pad.rack

    self.watcher = Watcher:create(function() return self.pad:getVelocity() end)
    self.watcher:onChange(function() self:repaint() end)

    self.padButton = self:addChildComponent(TextButton:create())

    self.lock = self:addChildComponent(Image:create(icons.lock))
    self.lock.getAlpha = function()
        local states = {
            1,
            0.5,
        }
        return states[pad:getLocked()] or 0
    end

    self.padButton.getText = function()
        return self.pad:getName()
    end

    self.padButton.onMouseDown = function(s, mouse)
        if not s:isVisible() then return end

        if mouse:isRightButtonDown() then
        else
            local key = self.mouse.x / self.w * 127
            local velo = 127 - self.mouse.y / self.h * 127
            reaper.gmem_write(DrumRack.maxNumPads + self.pad:getIndex() - 1, velo)
            reaper.gmem_write(DrumRack.maxNumPads * 2 + self.pad:getIndex() - 1, key)
        end
    end

    self.padButton.canClickThrough = function()
        return true
    end

    self.padButton.getToggleState = function (s, mouse)
        return self.pad:isSelected()
    end

    self.padButton.onClick = function (s, mouse)
        local wasSelected = pad:setSelected()

        if wasSelected then
            if pad:getFx() then
                pad:getFx():focus()
            elseif _.first(pad:getLayers()) then
                _.first(pad:getLayers()):focus()
            end
        end

        pad:noteOff()

        if mouse:wasRightButtonDown() then
            PadUI.showMenu(self.pad)
        end
    end

    self.padButton.isDisabled = function()
        return not self.pad:hasContent()
    end

    return self
end


function PadUI:onFilesDrop(files)

    rea.transaction('add layer', function()
        for v, k in pairs(files) do
            self.pad:addLayer(k)
        end
    end)

end

function PadUI:onDrag()
    Component.dragging = self.pad
    self.pad:noteOff()
end

function PadUI:onDrop(mouse)

    if Component.dragging ~= self.pad then

        self.pad:setSelected()

        if getmetatable(Component.dragging) == Pad then


            if mouse:wasRightButtonDown() then
                local menu = Menu:create()
                menu:addItem('flip pads', function() self.pad:flipPad(Component.dragging) end, 'flip pad')
                menu:addItem('copy pad', function() self.pad:copyPad(Component.dragging) end, 'copy pad')
                menu:show()
            else
                rea.transaction('flip pads', function()
                    self.pad:flipPad(Component.dragging)
                end)
            end

        elseif getmetatable(Component.dragging) == Layer then
            rea.transaction('move layer', function()
                Component.dragging.send:setMidiBusIO(self.pad:getIndex(), 1)
            end)
        end
    end
end

function PadUI:paintOverChildren()
    local padding = 5

    if self.pad:getVelocity() > 0 then
        self:setColor(colors.fx:with_alpha(self.pad:getVelocity() / 127))
        self:rect(padding, padding, self.w - padding * 2, self.h - padding * 2, true, true)
    end
end

function PadUI:resized()

    local padding = 2
    self.padButton:setBounds(padding, padding, self.w - 2 * padding, self.h - 2 * padding)

end

return PadUI