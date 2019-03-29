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

function TrackListComp:create(track)

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

    self.h = 20
    if track:isFocused(true) then
        self.slaves = self:addChildComponent(ButtonList:create({}))
        self.slaves.getData = function()
            return _.map(track:getSlaves(), function(slave)
                return {
                    proto = TrackListComp,
                    args = slave,
                    size = 20
                }
            end)
        end
        self.slaves:updateList()
        self.h = self.h + self.slaves.h
    end

    local icon = track:getIcon()
    self.icon = self:addChildComponent(icon and Image:create(icon, 'fit') or Component:create())
    self.icon.onDblClick = function()
        if track:getInstrument() then
            track:getInstrument():open()
        end
    end
    return self

end

function TrackListComp:paint(g)
    Label.drawBackground(self, g, self.name:getColor())
end

function TrackListComp:resized()

    local h = 20

    local buttons = #self.children - 1

    self.icon:setBounds(0,0,h,h)
    self.name:setBounds(self.icon:getRight(), 0, self.w - h, h)

    if self.slaves then
        self.slaves:setBounds(0, self.name:getBottom(), self.w, h)
    end
    -- self.h = self.slaves:getBottom()
end

return TrackListComp