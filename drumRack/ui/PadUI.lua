local TextButton = require 'TextButton'
local Component = require 'Component'
local Track = require 'Track'
local Layer = require 'Layer'
local Menu = require 'Menu'
local Pad = require 'Pad'
local Mem = require 'Mem'
local Watcher = require 'Watcher'
local Image = require 'Image'
local PadUI = class(Component)
local DrumRack = require 'DrumRack'
local Collection = require 'Collection'

local _ = require '_'
local rea = require 'rea'
local icons = require 'icons'
local colors = require 'colors'

function PadUI.showMenu(pad)

    local menu = Menu:create()

    menu:addItem('save', {
        disabled = not pad:hasContent(),
        callback = function()
            local file = DrumRack.padPresetDir:saveDialog('.RTrackTemplate', pad:getName())
            if file then
                writeFile(file, pad:savePad())
            end
        end,
    })
    menu:addItem('load', function()
        local file = DrumRack.padPresetDir:browseForFile('RTrackTemplate')
        if file then
            rea.transaction('load pad', function()
                pad:loadPad(file)
            end)
        end
    end)

    menu:addSeperator()

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
    if _.size(pad.rack:getSelectedTracks()) > 0 then
        addMenu:addItem('selected tracks as layers', function() pad:addSelectedTracks() end, 'add empty track')
    end
    addMenu:addItem('empty track', function() pad:addLayer() end, 'add empty track')
    addMenu:addItem('instrument', function()
        local name = rea.prompt("name")
        if name then
            pad:addLayer(name)
        end
    end, 'add instrument pad')

    menu:addItem('add', addMenu)
    menu:addSeperator()
    menu:addItem('clear', function() pad:clear() end, 'clear pad')
    menu:show()

end

function PadUI:create(pad)

    local self = Component:create()
    setmetatable(self, PadUI)
    self.pad = pad
    self.rack = pad.rack

    self.watchers:watch(function() return self.pad:getVelocity() end, function() self:repaint() end)

    self.padButton = self:addChildComponent(TextButton:create(''))

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
            Mem.write('drumrack', DrumRack.maxNumPads + self.pad:getIndex() - 1, velo)
            Mem.write('drumrack', DrumRack.maxNumPads * 2 + self.pad:getIndex() - 1, key)
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
            rea.transaction('select pad', function()

                if pad:getFx() then
                    pad:getFx():focus()
                else
                    local firstLayer = _.first(pad:getLayers())
                    if firstLayer then
                        firstLayer:focus()
                        if firstLayer:isSampler() and pad.rack.samplerIsOpen() then
                            pad.rack.closeSampler()
                            firstLayer:getInstrument():open()
                        end
                    end

                end
            end)
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
            local layer = self.pad:addLayer(k)
            if not layer:getName() then
                local fileName = _.last(k:split('/'))
                local name = rea.prompt('name', fileName)
                layer:setName(name or fileName)
            end
        end
    end)

end

function PadUI:onDrag()
    Component.dragging = self
    self.pad:noteOff()
end

function PadUI:onDrop(mouse)

    if Component.dragging ~= self then

        self.pad:setSelected()

        if Component.dragging.pad and getmetatable(Component.dragging.pad) == Pad then

            local pad = Component.dragging.pad

            if mouse:wasRightButtonDown() then
                local menu = Menu:create()
                menu:addItem('flip pads', function() self.pad:flipPad(pad) end, 'flip pad')
                menu:addItem('copy pad', function() self.pad:copyPad(pad) end, 'copy pad')

                menu:show()
            else
                rea.transaction('flip pads', function()
                    self.pad:flipPad(pad)
                end)
            end

        elseif getmetatable(Component.dragging) == Layer then
            rea.transaction('move layer', function()
                Component.dragging.send:setMidiBusIO(self.pad:getIndex(), 1)
            end)
        end
    end
end

function PadUI:paintOverChildren(g)
    local padding = 5

    if self.pad:getVelocity() > 0 then
        g:setColor(colors.bus:with_alpha(self.pad:getVelocity() / 127))
        g:rect(padding, padding, self.w - padding * 2, self.h - padding * 2, true, true)
    end
end

function PadUI:resized()

    local padding = 0
    self.padButton:setBounds(padding, padding, self.w - 2 * padding, self.h - 2 * padding)

end

return PadUI