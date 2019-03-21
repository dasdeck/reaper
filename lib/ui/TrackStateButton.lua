local TextButton = require 'TextButton'
local Component = require 'Component'

local TrackStateButton = class(TextButton)

function TrackStateButton:create(track, key, name)
    local self = TextButton:create(name or key)
    self.track = track
    self.key = key
    setmetatable(self, TrackStateButton)
    return self
end

function TrackStateButton:getToggleState()
    return self.track and reaper.GetMediaTrackInfo_Value(self.track.track, self.key) > 0
end

function TrackStateButton:onClick()
    local state = (not self:getToggleState()) and 1 or 0
    reaper.SetMediaTrackInfo_Value(self.track.track, self.key, state)
end


return TrackStateButton
