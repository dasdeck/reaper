local Component = require 'Component'
local Track = require 'Track'
local TrackToolControlls = require 'TrackToolControlls'
local TextButton = require 'TextButton'

local rea = require "Reaper"
local _ = require "_"

local TrackTool = class(Component)

function TrackTool:create()
    local self = Component:create()

    self.track = Track.getFocusedTrack()
    Track.watch.focusedTrack:onChange(function(track)
        self.track = track
        self:repaint()
    end)

    self.controlls = self:addChildComponent(TrackToolControlls:create())
    self.controlls.isVisible = function()
        return self.track and self.track:getTrackTool()
    end

    self.activator = self:addChildComponent(TextButton:create('+tracktools'))
    self.activator.isVisible = function()
        return self.track and not self.track:getTrackTool()
    end
    self.activator.onButtonClick = function()
        self.track:getTrackTool(true)
    end

    setmetatable(self, TrackTool)
    return self
end

return TrackTool

