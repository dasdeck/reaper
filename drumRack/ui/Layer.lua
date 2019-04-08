local Component = require 'Component'
local TextButton = require 'TextButton'
local IconButton = require 'IconButton'
local Image = require 'Image'
local TrackStateButton = require 'TrackStateButton'
local Track = require 'Track'
local Menu = require 'Menu'
local _ = require '_'
local colors = require 'colors'
local icons = require 'icons'

local rea = require 'rea'

local Layer = class(Component)

function Layer:create(track, pad)

    -- rea.log('Layer:create')
    local self = Component:create()
    setmetatable(self, Layer)

    self.pad = pad
    self.rack = pad.rack
    self.track = track

    self.icon = self:addChildComponent(Image:create(track:getIcon(), 'fit'))

    self.mute = self:addChildComponent(TrackStateButton:create(self.track, 'mute', 'M'))
    self.mute.color = colors.mute

    self.lock = self:addChildComponent(IconButton:create(icons.lock))
    self.lock.onButtonClick = function()
        track:setLocked(not track:isLocked())
    end
    self.lock.getToggleState = function()
        return track:isLocked()
    end

    self.solo = self:addChildComponent(TrackStateButton:create(self.track, 'solo', 'S'))
    self.solo.color = colors.solo

    self.name = self:addChildComponent(TextButton:create('layer'))

    self.name.getText = function()
        return self.track:getInstrument() and self.track:getInstrument():getName() or self.track:getName()
    end

    self.name.getToggleState = function()
        return self:isSelected()
    end

    self.name.onClick = function(s, mouse)
        if mouse:wasRightButtonDown() then
            local menu = Menu:create()
            menu:addItem('layer -> track', function()
                track:setVisibility(true, true)
                local recs = self.track:getReceives()
                local con = _.find(recs, function(rec)
                    local src = rec:getSourceTrack()
                    return src == self.rack:getTrack()
                end)
                assert(con, 'layer should have a rack connection')
                con:remove()
            end, 'layer -> track')

            menu:show()
        elseif mouse:isAltKeyDown() then
            rea.transaction('delete layer', function()
                self.track:remove()
            end)
        else
            rea.transaction('focus layer', function()
                self.track:focus()
                self:setSelected(not self:isSelected())
            end)
        end
    end

    self.icon.onDblClick = function()
        self.track:getInstrument():open()
    end

    self.name.onDrag = function()
        Component.dragging = self
    end

    self.watchers:watch(Track.watch.focusedTrack, function()
        self:update()
    end)

    self:update()

    return self
end

function Layer:isSelected()
    return self.track:getMeta('layer:selected', true)
end

function Layer:setSelected(selected)
    if selected == 1 then
    end

    selected = selected == nil and true or selected
    self.track:setMeta('layer:selected', selected and true or false)
end

function Layer:update()
    if self:isSelected() then
        local InstrumentUI = require 'InstrumentUI'
        if self.instrument then self.instrument:delete() end
        self.instrument = self:addChildComponent(InstrumentUI:create(self.track))

        -- if self.pad:getOutput() and self.track:getOutput() == self.pad:getOutput() then
        --     self.instrument.audioTrack.next:delete()
        --     self.instrument.audioTrack.next = nil
        -- end

        self:resized()
        rea.log('expanded')
    end
    if self.parent then self.parent:resized() end
end


function Layer:isSampler()
    return self.track:getInstrument():isSampler()
end

function Layer:paint(g)
    self.name.drawBackground(self, g, self.name:getColor())
end

function Layer:resized()

    local h = 20
    -- local w = self.
    self.icon:setSize(h,h)

    -- self.mute:setBounds(self.icon:getRight(), 0, h, h)
    -- self.solo:setBounds(self.mute:getRight(), 0, h, h)
    -- self.lock:setBounds(self.solo:getRight(), 0, h, h)

    self.name:setBounds(h, self.lock:getBottom(), self.w-h, h)

    self.h = h
    if self.instrument then
        self.instrument:setBounds(0,self.name:getBottom(), self.w)
        self.h = self.instrument:getBottom()
    end

    -- rea.log(self.h)

end

return Layer