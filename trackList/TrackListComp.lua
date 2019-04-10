local Component = require 'Component'
local Image = require 'Image'
local TextButton = require 'TextButton'
local ButtonList = require 'ButtonList'
local TrackStateButton = require 'TrackStateButton'
local Label = require 'Label'
local Track = require 'Track'
local Menu = require 'Menu'
local TrackUI = require 'TrackUI'
local rea = require 'rea'
local _ = require '_'

local TrackListComp = class(Component)

function TrackListComp:create(track, hideChildren)

    local self = Component:create()
    setmetatable(self, TrackListComp)

    self.track = track

    self.name = self:addChildComponent(TextButton:create(track:getName() or track:getDefaultName()))
    self.name.color = track:getColor() or self.name.color

    self.name.getToggleState = function()
        return track:isSelected()
    end
    self.name.content.just = 0
    self.name.onButtonClick = function(s, mouse)
        TrackUI.click(track, mouse)
    end

    if track:isSelected(true) and not hideChildren then
        self.slaves = self:addChildComponent(ButtonList:create(_.map(track:getManagedTracks(), function(slave)
            return {
                proto = TrackListComp,
                args = slave,
                size = 20
            }
        end)))
    end

    local icon = track:getImage()
    self.icon = self:addChildComponent(icon and Image:create(icon, 'fit') or Component:create())
    self.icon.onDblClick = function()
        if track:getInstrument() then
            track:getInstrument():toggleOpen()
        elseif _.size(track:getFxList()) then
            track:getFxList()[1]:toggleOpen()
        end
    end

    self.solo = self:addChildComponent(TrackStateButton:create(track, 'solo', 'S'))

    return self

end

function TrackListComp:paint(g)
    Label.drawBackground(self, g, self.name:getColor())
end

function TrackListComp:getAlpha()
    return self.track:exists() and self.track:isMuted() and 0.5 or 1
end

function TrackListComp:resized()

    local h = 20

    local buttons = #self.children - 1

    self.icon:setBounds(0,0,h,h)
    self.name:setBounds(self.icon:getRight(), 0, self.w - 2*h, h)
    self.solo:setBounds(self.w - h,0,h,h)
    local y = self.solo:getBottom()

    if self.slaves then
        self.slaves:setBounds(h/2, self.name:getBottom(), self.w-h/2)
        y = self.slaves:getBottom()
    end

    self.h = y
    -- self.h = self.slaves:getBottom()
end

return TrackListComp