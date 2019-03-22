

local Component = require 'Component'
local DelaySlider = require 'DelaySlider'
local TextButton = require 'TextButton'
local Track = require 'Track'
local Menu = require 'Menu'
local TransposeControll = require "TransposeControll"
local DirFlipper = require "DirFlipper"
local rea = require "Reaper"

local _ = require "_"

local TrackToolControlls = class(Component)

function TrackToolControlls:create()
    local self = Component:create()

    self.transpose = self:addChildComponent(TransposeControll:create(self), 'transpose')

    self.delay = self:addChildComponent(DelaySlider:create(self), 'delay')

    self.globalTranspose = self:addChildComponent(TextButton:create(''))
    self.globalTranspose.getText = function()
        reaper.gmem_attach('tracktool')
        return tostring(reaper.gmem_read(0))
    end
    self.globalTranspose.onClick = function()
        local state = Track.getFocusedTrack():getTrackTool():getParam(3) == 0
        Track.getFocusedTrack():getTrackTool():setParam(3, state and 1 or 0)
    end
    self.globalTranspose.getToggleState = function()
        return Track.getFocusedTrack():getTrackTool():getParam(3) > 0
    end

    setmetatable(self, TrackToolControlls)
    return self
end

function TrackToolControlls:getTrack()
    return self.parent.track
end

function TrackToolControlls:resized()

    local h  = 20

    self.delay:setBounds(0, 0, self.w, h)

    self.transpose:setBounds(0, self.delay:getBottom(), self.w, h)

    self.globalTranspose:setBounds(0, self.transpose:getBottom(), self.w, h)

end

return TrackToolControlls

