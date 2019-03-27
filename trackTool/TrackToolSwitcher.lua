local Component = require 'Component'
local Track = require 'Track'
local TrackTool = require 'TrackTool'

local rea = require 'rea'
local _ = require '_'

local TrackToolSwitcher = class(Component)

function TrackToolSwitcher:create(...)
    local self = Component:create(...)
    setmetatable(self, TrackToolSwitcher)

    self.track = Track.getFocusedTrack(true)

    self.watchers:watch(Track.watch.focusedTrack, function()
        self.track = Track.getFocusedTrack(true)
        self:update()
    end
)
    self:update()

    return self
end

function TrackToolSwitcher:update()
    self:deleteChildren()

    if self.track then
        self:addChildComponent(TrackTool:create(self.track))
    end
end


return TrackToolSwitcher

