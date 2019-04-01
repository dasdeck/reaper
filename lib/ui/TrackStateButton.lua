local TextButton = require 'TextButton'
local Track = require 'Track'
local Component = require 'Component'
local Project = require 'Project'
local colors = require 'colors'
local rea = require 'rea'

local TrackStateButton = class(TextButton)

local transitions = {
    solo = {
        [0] = 2,
        [2] = 0
    }
}

function TrackStateButton:create(track, key, content, values)
    local self = TextButton:create(content or key)
    self.values = values or transitions[key]
    self.track = track
    self.key = key
    self.color = colors[key]

    setmetatable(self, TrackStateButton)
    return self
end

function TrackStateButton:getToggleState()
    return self.track and self.track:getValue(self.key) > 0
end

function TrackStateButton:onClick()
    rea.transaction('toggle: ' .. (self:getText()), function()

        local state = self.track:getValue(self.key)

        state = (self.values and self.values[state]) or (state  == 0 and 1 or 0)

        self.track:setValue(self.key, state)
        rea.refreshUI()
    end)
end

function TrackStateButton:getText()
    return self.content.text or self.key
end

return TrackStateButton
