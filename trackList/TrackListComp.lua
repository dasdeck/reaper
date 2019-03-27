local Component = require 'Component'
local Image = require 'Image'
local TextButton = require 'TextButton'
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

    self.name.onButtonClick = function(s, mouse)
        TrackUI.click(track, mouse)
    end

    local icon = track:getIcon()
    self.icon = self:addChildComponent(icon and Image:create(icon, 'fit') or Component:create())

    -- self.tcp = self:addChildComponent(TrackStateButton:create(track, 'tcp', 'T'))
    -- self.tcp.r = 0
    -- self.mcp = self:addChildComponent(TrackStateButton:create(track, 'mcp', 'M'))
    -- self.mcp.r = 0


    return self

end

function TrackListComp:paint(g)
    Label.drawBackground(self, g, self.name:getColor())
end

function TrackListComp:resized()

    local h = self.h

    local buttons = #self.children - 1

    self.icon:setBounds(0,0,h,h)
    -- self.tcp:setBounds(self.icon:getRight(),0,h,h)
    -- self.mcp:setBounds(self.tcp:getRight(),0,h,h)
    self.name:setBounds(self.icon:getRight(), 0, self.w - h*buttons, h)
end

return TrackListComp