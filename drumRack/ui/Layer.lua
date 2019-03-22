local Component = require 'Component'
local TextButton = require 'TextButton'
local IconButton = require 'IconButton'
local Image = require 'Image'
local TrackStateButton = require 'TrackStateButton'
local Menu = require 'Menu'
local _ = require '_'
local colors = require 'colors'
local icons = require 'icons'

local rea = require 'Reaper'

local Layer = class(Component)

function Layer:create(track, pad)
    local self = Component:create()
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
        return self.track:isFocused()
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
            self.track:focus()
        end
    end

    self.name.onDblClick = function()
        self.track:getInstrument():open()
    end

    self.name.onDrag = function()
        Component.dragging = self
    end

    setmetatable(self, Layer)
    return self
end

function Layer:isSampler()
    return self.track:getInstrument():getParam('FILE0') ~= nil
end

function Layer:paint()
    self.name.drawBackground(self, self.name:getColor())
end

function Layer:resized()

    local h = self.h
    self.icon:setSize(h,h)

    self.mute:setBounds(self.icon:getRight(), 0, h, h)

    self.solo:setBounds(self.mute:getRight(), 0, h, h)

    self.lock:setBounds(self.solo:getRight(), 0, h, h)

    self.name:setBounds(self.lock:getRight(), 0, self.w - self.lock:getRight(), h)

end

return Layer