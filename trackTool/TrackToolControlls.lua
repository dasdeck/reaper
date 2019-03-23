

local Component = require 'Component'
local DelaySlider = require 'DelaySlider'
local TextButton = require 'TextButton'
local Track = require 'Track'
local Menu = require 'Menu'
local TransposeControll = require "TransposeControll"
local DirFlipper = require "DirFlipper"
local rea = require "Reaper"

local FXList = require 'FXList'

local _ = require "_"

local TrackToolControlls = class(Component)

function TrackToolControlls:create(track)
    local self = Component:create()
    setmetatable(self, TrackToolControlls)

    self.track = track

    self.transpose = self:addChildComponent(TransposeControll:create(track), 'transpose')

    self.delay = self:addChildComponent(DelaySlider:create(track), 'delay')

    self.globalTranspose = self:addChildComponent(TextButton:create(''))
    self.globalTranspose.getText = function()
        reaper.gmem_attach('tracktool')
        return tostring(reaper.gmem_read(0))
    end
    self.globalTranspose.onClick = function()
        local state = track:getTrackTool():getParam(3) == 0
        track:getTrackTool():setParam(3, state and 1 or 0)
    end
    self.globalTranspose.getToggleState = function()
        return track:getTrackTool():getParam(3) > 0
    end

    self.fx = self:addChildComponent(FXList:create(track))

    return self
end

function TrackToolControlls:getTrack()
    return self.track
end

function TrackToolControlls:resized()

    local h  = 20

    self.delay:setBounds(0, 0, self.w, h)

    self.transpose:setBounds(0, self.delay:getBottom(), self.w, h)

    self.globalTranspose:setBounds(0, self.transpose:getBottom(), self.w, h)

    self.fx:setBounds(0, self.globalTranspose:getBottom(), self.w, 200)

end

return TrackToolControlls

