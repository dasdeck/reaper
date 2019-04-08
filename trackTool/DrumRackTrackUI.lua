local Component = require 'Component'
local Track = require 'Track'
local TrackToolControlls = require 'TrackToolControlls'
local TrackStateButton = require 'TrackStateButton'
local TextButton = require 'TextButton'
local ButtonList = require 'ButtonList'
local Project = require 'Project'
local FXList = require 'FXList'
local AudioTrackUI = require 'AudioTrackUI'
local PadGrid = require 'PadGrid'
local Output = require 'Output'
local Outputs = require 'Outputs'
local Type = require 'Type'
local Slider = require 'Slider'
local DrumRack = require 'DrumRack'

local colors = require 'colors'
local rea = require 'rea'
local _ = require '_'

local DrumRackTrackUI = class(Component)

function DrumRackTrackUI:create(track)

    local self = Component:create()
    setmetatable(self, DrumRackTrackUI)

    self.track = track
    self.drumRack = track:getFx(DrumRack.fxName)

    self:update()

    return self
end

function DrumRackTrackUI:update()
    self:deleteChildren()

    local track = self.track

    local inlineUI = track:getInlineUI()
    if inlineUI then
        self.inline = self:addChildComponent(inlineUI)
    end

end

function DrumRackTrackUI:resized()

    local h = 20
    local y = 0

    if self.inline then
        self.inline:fitToWidth(self.w)
        y = self.inline:getBottom()
    end

    -- if self.audioTrack then
    --     self.audioTrack:setBounds(0, y, self.w)
    -- else
    --     self.mute:setBounds(0,y, self.w/2, h)
    --     self.solo:setBounds(self.mute:getRight(),y, self.w/2, h)
    --     y = self.solo:getBottom()
    --     self.outputs:setBounds(0,y, self.w)
    --     y = self.outputs:getBottom()
    --     self.output:setBounds(0, y, self.w, h)
    -- end


end

return DrumRackTrackUI

