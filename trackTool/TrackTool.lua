

local Component = require 'Component'
local Track = require 'Track'
local ButtonList = require 'ButtonList'
local DelaySlider = require 'DelaySlider'
local TextButton = require 'TextButton'
local Slider = require 'Slider'
local DrumRack = require 'DrumRack'
local Menu = require 'Menu'
local TransposeControll = require "TransposeControll"
local DirFlipper = require "DirFlipper"
local rea = require "Reaper"

local _ = require "_"

local TrackTool = class(Component)

function TrackTool:create()
    local self = Component:create()

    self.transpose = self:addChildComponent(TransposeControll:create(self), 'transpose')

    self.delay = self:addChildComponent(DelaySlider:create(self), 'delay')
    function self.delay:isVisible()
        return self:isActive()
    end

    self.type = self:addChildComponent(TextButton:create('type'), 'type')
    function self.type.getText()
        return self:getTrack():getType() or '--'
    end

    function self.type.onClick(s, mouse)

        if mouse:wasRightButtonDown() then
            local menu = Menu:create()
            _.forEach({
                'instrument',
                'drumrack',
                'pad',
                'layer'
            }, function(value)
                menu:addItem(value, function()
                    self:getTrack():setType(value)
                end)
            end)

            menu:show()
        end
    end

    self.preset = self:addChildComponent(DirFlipper:create(reaper.GetResourcePath()))

    -- Track.watch.selectedTrack:onChange(function(track)
    --     self.track = track
    -- end)
    self.track = Track.getFocusedTrack()
    Track.watch.focusedTrack:onChange(function(track)
        self.track = track
        self:repaint()
    end)

    setmetatable(self, TrackTool)
    return self
end

function TrackTool:getTrack()
    return self.track
end

function TrackTool:isDisabled()
    return self:getTrack() == nil
end

function TrackTool:isVisible()
    return self:getTrack()
end

function TrackTool:wantsMouse()
    return self:getTrack()
end

function TrackTool:resized()

    local h  = 20

    self.type:setBounds(0, 0, self.w, h)

    self.delay:setBounds(0, self.type:getBottom(), self.w, h)

    self.transpose:setBounds(0, self.delay:getBottom(), self.w, h)

    self.preset:setBounds(0, self.transpose:getBottom(), self.w, h)

end

return TrackTool

