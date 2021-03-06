local TextButton = require 'TextButton'
local Component = require 'Component'
local Track = require 'Track'
local Layer = require 'Layer'
local Menu = require 'Menu'
local Pad = require 'Pad'
local Mem = require 'Mem'
local Watcher = require 'Watcher'
local Image = require 'Image'
local DrumRack = require 'DrumRack'
local Collection = require 'Collection'
local PluginListApp = require 'PluginListApp'
local Instrument = require 'Instrument'

local _ = require '_'
local rea = require 'rea'
local icons = require 'icons'
local colors = require 'colors'

local PadUI = class(Component)

function PadUI.getChokeMenu(pad)
    local val = math.floor(pad.rack:getMapper():getParam(10))
    local menu = Menu:create()

    for i=0, 16 do
        menu:addItem(i == 0 and '--' or tostring(i), {
            callback = function()
                pad.rack:getMapper():setParam(10, i)
            end,
            checked = val == i
        })
    end
    return menu
end

function PadUI.getModeMenu(pad)
    local val = pad.rack:getMapper():getParam(8)
    return Menu:create({
        {
            name = 'release',
            callback = function() pad.rack:getMapper():setParam(8, 0) end,
            checked = val == 0
        },
        {
            name = 'hold:time',
            callback = function() pad.rack:getMapper():setParam(8, 1) end,
            checked = val == 1
        },
        {
            name = 'hold:inf',
            callback = function() pad.rack:getMapper():setParam(8, 2) end,
            checked = val == 2
        }
    })
end

function PadUI.showMenu(pad)

    local rack = pad.rack

    local menu = Menu:create()
    menu:addItem('select by midi',{
        callback = function()
            local value = rack:getMapper():getParam(6) == 0 and 1 or 0
            rack:getMapper():setParam(6, value)
        end,
        checked = rack:getMapper():getParam(6) == 1
    })

    menu:addItem('save pad', {
        disabled = not pad:hasContent(),
        callback = function()
            local file = DrumRack.padPresetDir:saveDialog('.RTrackTemplate', pad:getName())
            if file then
                writeFile(file, pad:savePad())
            end
        end,
    })
    menu:addItem('load pad', function()
        local file = DrumRack.padPresetDir:browseForFile('RTrackTemplate')
        if file then
            rea.transaction('load pad', function()
                pad:loadPad(file)
            end)
        end
    end)

    menu:addSeperator()


    menu:addItem('trigger mode', PadUI.getModeMenu(pad))
    menu:addItem('choke group', PadUI.getChokeMenu(pad))

    local low, high = pad.rack:getMapper():getKeyRange(pad)

    local learnMenu = Menu:create()
    learnMenu:addItem(tostring(low) .. '-' .. tostring((high)), {
        disabled = true
    })

    learnMenu:addItem('learn low', function() pad:learnLow() end)
    learnMenu:addItem('learn high', function() pad:learnHi() end)
    learnMenu:addItem('learn both', function() pad:learn() end)

    menu:addItem('key range', learnMenu)

    menu:addSeperator()
    local addMenu = Menu:create()
    if _.size(pad.rack:getSelectedTracks()) > 0 then
        addMenu:addItem('selected tracks as layers', function() pad:addSelectedTracks() end, 'add empty track')
    end
    addMenu:addItem('empty track', function() pad:addLayer() end, 'add empty track')
    addMenu:addItem('instrument', function()

        -- local name = rea.prompt("name")

        PluginListApp.pick(PluginListApp.cats.instruments,function(res)
            rea.transaction('add instrument', function()
                local track = Instrument.createInstrument(res)
                if track then
                    pad:addTrack(track)
                end
            end)
        end)
        -- local PluginListApp = require 'PluginListApp'
        -- PluginListApp.pick(PluginListApp.)
        -- Instrument
        -- if name then
        --     pad:addLayer(name)
        -- end
    end, 'add instrument pad')

    menu:addItem('add', addMenu)
    menu:addSeperator()

    menu:addItem('clear pad', function() pad:clear() end, 'clear pad')
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
            self.pad.rack.mem:set(DrumRack.maxNumPads + self.pad:getIndex() - 1, velo)
            self.pad.rack.mem:set(DrumRack.maxNumPads * 2 + self.pad:getIndex() - 1, key)
        end
    end

    self.padButton.canClickThrough = function()
        return true
    end

    self.padButton.getToggleState = function (s, mouse)
        return self.pad:isSelected()
    end

    self.padButton.onDblClick = function()
        if not self.pad:hasContent() then
            PluginListApp.pick(PluginListApp.cats.instruments,function(res)
                rea.transaction('add instrument', function()
                    local track = Instrument.createInstrument(res)
                    if track then
                        self.pad:addTrack(track)
                    end
                end)
            end)
        end
    end

    self.padButton.onClick = function (s, mouse)

        showMixer()

        if mouse:isAltKeyDown() then
            rea.transaction('clear pad', function()
                self.pad:clear()
            end)
        else

            local wasSelected = pad:setSelected()

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

            pad:noteOff()

            if mouse:wasRightButtonDown() then
                PadUI.showMenu(self.pad)
            end
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
            local layer = self.pad:addLayer(k, _.last(k:split('/')))
            -- if not layer:getName() or layer:getName():len() == 0 or layer:getName() == layer:getDefaultName() then
            --     local fileName = _.last(k:split('/'))
            --     local name = rea.prompt('name', fileName)
            --     layer:setName(name or fileName)
            -- end
        end
        showMixer()
    end)

    self.pad:setSelected()

end

function PadUI:onDrag()
    Component.dragging = self
    self.pad:noteOff()
end

function PadUI:onDrop(mouse)

    if Component.dragging ~= self then

        self.pad:setSelected()

        if instanceOf(Component.dragging, Component) and getmetatable(Component.dragging.pad) == Pad then

            local pad = Component.dragging.pad

            if mouse:wasRightButtonDown() then
                local menu = Menu:create()
                menu:addItem('flip pads', function() self.pad:flipPad(pad) end, 'flip pad')
                menu:addItem('copy pad', function() self.pad:copyPad(pad) end, 'copy pad')

                menu:show()
            elseif mouse:isCommandKeyDown() then
                rea.transaction('copy pad', function()
                    self.pad:copyPad(pad)
                end)
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
        g:setColor(colors.bus:with_alpha((self.pad:getVelocity() / 127)^0.5))
        g:rect(padding, padding, self.w - padding * 2, self.h - padding * 2, true, true)
    end
end


return PadUI