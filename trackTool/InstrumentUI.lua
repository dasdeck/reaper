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

local colors = require 'colors'
local rea = require 'rea'
local _ = require '_'

local InstrumentUI = class(Component)

function InstrumentUI:create(instrument)
    local self = Component:create()
    setmetatable(self, InstrumentUI)

    self.track = instrument.track
    self.instrument = instrument

    self:update()

    return self
end

function InstrumentUI:update()
    self:deleteChildren()

    local track = self.track

    local inlineUI = track:getInlineUI()
    if inlineUI then
        self.inline = self:addChildComponent(inlineUI)
    end


    if self.instrument:canDoMultiOut() then

        self.mute = self:addChildComponent(TrackStateButton:create(track, 'mute', 'M'))
        self.solo = self:addChildComponent(TrackStateButton:create(track, 'solo', 'S'))

        self.output = self:addChildComponent(Output:create(track))

        self.outputs = self:addChildComponent(Outputs:create(track))

        if self.track:getTrackTool() then
            self.controlls = self:addChildComponent(TrackToolControlls:create(self.track))
        else
            self.controlls = self:addChildComponent(TextButton:create('+InstrumentUIs'))
            self.controlls.onButtonClick = function()
                rea.transaction('init InstrumentUI', function()
                    self.track:getTrackTool(true)
                end)
            end

        end
    else
        self.audioTrack = self:addChildComponent(AudioTrackUI:create(self.track))
    end

end

function InstrumentUI:resized()

    local h = 20
    local y = 0

    if self.inline then
        self.inline:fitToWidth(self.w)
        y = self.inline:getBottom()
    end

    if self.audioTrack then
        self.audioTrack:setBounds(0, y, self.w)
    else
        self.mute:setBounds(0,y, self.w/2, h)
        self.solo:setBounds(self.mute:getRight(),y, self.w/2, h)
        y = self.solo:getBottom()
        self.outputs:setBounds(0,y, self.w)
        y = self.outputs:getBottom()
        self.output:setBounds(0, y, self.w, h)
    end


end

return InstrumentUI

