local PadGrid = require 'PadGrid'
local Component = require 'Component'
local PadEditor = require 'PadEditor'
local ButtonList = require 'ButtonList'
local Split = require 'Split'
local DrumRackOptions = require 'DrumRackOptions'
local DrumRack = require 'DrumRack'
local Menu = require 'Menu'
local Track = require 'Track'

local colors = require 'colors'
local _ = require '_'


local rea = require 'Reaper'

local DrumRackUI = class(Component)

function DrumRackUI.drumRackButton(mouse)
    local addRack = function()
        local name = rea.prompt('name')
        if name then
            local track = Track.insert()
            track:setName(name:len() and name or 'drumrack'):choose()
            return DrumRack.init(track)
        end
    end
    local addSplit = function()
        return addRack():setSplitMode()
    end

    if mouse:wasRightButtonDown() then

        local tracks = Track.getSelectedTracks()

        local menu = Menu:create()
        menu:addItem('new drumrack', addRack, 'add empty drumrack')
        menu:addItem('new splitrack', addRack, 'add empty splitrack')

        if _.size(tracks) > 0 then
            menu:addSeperator()
            menu:addItem('pad-layers from selected tracks', function()

                local rack = addRack()
                if rack then
                    _.forEach(tracks, function(track)
                        rack.pads[1]:addTrack(track)
                    end)
                end
            end, 'add drum rack')
            menu:addItem('pads from selected tracks', function()
                local tracks = Track.getSelectedTracks()
                local rack = addRack()
                if rack then
                    local i = 1
                    _.forEach(tracks, function(track)
                        if rack.pads[i] then
                            rack.pads[i]:addTrack(track)
                        end

                        i = i + 1
                    end)
                end
            end, 'add drum rack')
            menu:addSeperator()

            menu:addItem('split-layers from selected tracks', function()
                local tracks = Track.getSelectedTracks()
                local rack = addSplit()
                rack.pads[1]:setKeyRange(0,127)
                if rack then
                    _.forEach(tracks, function(track)
                        rack.pads[1]:addTrack(track)
                    end)
                end
            end, 'add drum rack')
        end
        menu:show()
    else
        rea.transaction('add drum rack',addRack)
    end
end

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