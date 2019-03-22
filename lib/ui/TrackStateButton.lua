local TextButton = require 'TextButton'
local Component = require 'Component'
local Track = require 'Track'
local rea = require 'Reaper'

local TrackStateButton = class(TextButton)

function TrackStateButton:create(track, key, content)
    local self = TextButton:create(content or key)
    self.track = track
    self.key = Track.valMap[key] or Track.stringMap[key] or key
    setmetatable(self, TrackStateButton)
    return self
end

function TrackStateButton:getToggleState()
    return self.track and reaper.GetMediaTrackInfo_Value(self.track.track, self.key) > 0
end

function TrackStateButton:onClick()
    rea.transaction('toggle: ' .. (self:getText()), function()
        local state = (not self:getToggleState()) and 1 or 0
        reaper.SetMediaTrackInfo_Value(self.track.track, self.key, state)
    end)
end


return TrackStateButton
