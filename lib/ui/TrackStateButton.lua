local TextButton = require 'TextButton'
local Track = require 'Track'
local Component = require 'Component'
local Project = require 'Project'
local rea = require 'rea'

local TrackStateButton = class(TextButton)

function TrackStateButton:create(track, key, content)
    local self = TextButton:create(content or key)
    self.track = track
    self.key = key
    -- self.watchers:watch(Project.watch.project, function() self:repaint() end)
    setmetatable(self, TrackStateButton)
    return self
end

function TrackStateButton:getToggleState()
    return self.track and self.track:getValue(self.key) > 0
end

function TrackStateButton:onClick()
    rea.transaction('toggle: ' .. (self:getText()), function()
        local state = self.track:getValue(self.key) == 0 and 1 or 0
        --== 0 and 1 or 0
        self.track:setValue(self.key, state)
        rea.refreshUI()
    end)
end

function TrackStateButton:getText()
    return self.content.text or self.key
end



return TrackStateButton
