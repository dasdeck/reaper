local Component = require 'Component'
local Track = require 'Track'
local TrackToolControlls = require 'TrackToolControlls'
local TextButton = require 'TextButton'
local Project = require 'Project'

local rea = require 'rea'
local _ = require '_'

local TrackTool = class(Component)

function TrackTool:create(...)
    local self = Component:create(...)
    setmetatable(self, TrackTool)

    self.track = Track.getFocusedTrack(true)

    local change = function()
        -- rea.log('change')
        self.track = Track.getFocusedTrack(true)
        self:update()
        self:repaint()
    end

    Track.watch.focusedTrack:onChange(change)
    Track.watch.tracks:onChange(change)
    Project.watch.project:onChange(change)

    self:update()

    return self
end

function TrackTool:update()
    self:deleteChildren()

    if self.track then
        if self.track:getTrackTool() then
            self.controlls = self:addChildComponent(TrackToolControlls:create(self.track))
        else
            self.activator = self:addChildComponent(TextButton:create('+tracktools'))
            self.activator.onButtonClick = function()
                rea.transaction('init tracktool', function()
                    self.track:getTrackTool(true)
                end)
            end
        end

    end
end

return TrackTool

