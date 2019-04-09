

local Component = require 'Component'
local DelaySlider = require 'DelaySlider'
local TextButton = require 'TextButton'
local Track = require 'Track'
local Menu = require 'Menu'
local Mem = require 'Mem'
local TransposeControll = require 'TransposeControll'
local DirFlipper = require 'DirFlipper'
local rea = require 'rea'


local _ = require '_'

local TrackToolControlls = class(Component)

function TrackToolControlls:create(track)
    local self = Component:create()
    setmetatable(self, TrackToolControlls)

    self.track = track

    self.transpose = self:addChildComponent(TransposeControll:create(track), 'transpose')

    self.delay = self:addChildComponent(DelaySlider:create(track), 'delay')

    self.globalTranspose = self:addChildComponent(TextButton:create(''))
    self.globalTranspose.getText = function()
        return tostring(math.floor(Mem.read('tracktool', 0)))
    end
    self.globalTranspose.onClick = function()
        local state = track:getTrackTool():getParam(3) == 0
        track:getTrackTool():setParam(3, state and 1 or 0)
    end
    self.globalTranspose.getToggleState = function()
        return track:getTrackTool():getParam(3) > 0
    end

    return self
end

function TrackToolControlls:getTrack()
    return self.track
end

function TrackToolControlls:resized()

    local h  = 20

    self.delay:setBounds(0, 0, self.w, h)

    local w = self.w / 2
    local y = self.delay:getBottom()

    self.transpose:setBounds(0, y, self.w - h, h)

    self.globalTranspose:setBounds(self.w - h, y, h, h)


    -- self.fx:setBounds(0, self.globalTranspose:getBottom(), self.w, 200)

end

return TrackToolControlls

