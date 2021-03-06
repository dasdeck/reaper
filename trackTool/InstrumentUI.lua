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

function InstrumentUI:create(track)
    local self = Component:create()
    setmetatable(self, InstrumentUI)

    self.instrument = track:getInstrument()
    self.track = self.instrument.track

    self:update()

    return self
end

function InstrumentUI:getFx(create)

end

function InstrumentUI:setFx(track)

end

function InstrumentUI:update()
    self:deleteChildren()

    local track = self.track

    local inlineUI = track:getInlineUI()
    if inlineUI then
        self.inline = self:addChildComponent(inlineUI)
    end

    -- if self.instrument:canDoMultiOut() then
        self.mute = self:addChildComponent(TrackStateButton:create(track, 'mute', 'M'))
        self.solo = self:addChildComponent(TrackStateButton:create(track, 'solo', 'S'))

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
    -- else
    --     self.audioTrack = self:addChildComponent(AudioTrackUI:create(self.track))
    -- end

end

function InstrumentUI:resized()

    local h = 20
    local y = 0

    if self.inline then
        self.inline:fitToWidth(self.w)
        y = self.inline:getBottom()
    end

    if self.controlls then
        -- self.controlls.isVisible = function() return false end
        self.controlls:setBounds(0,y,self.w,self.controlls.h)
        y = self.controlls:getBottom()
    end

    if self.audioTrack then
        self.audioTrack:setBounds(0, y, self.w)
        y = self.audioTrack:getBottom()
    else
        self.mute:setBounds(0,y, self.w/2, h)
        self.solo:setBounds(self.mute:getRight(),y, self.w/2, h)
        y = self.solo:getBottom()
        self.outputs:setBounds(0,y, self.w)
        y = self.outputs:getBottom()
        -- self.output:setBounds(0, y, self.w)
        -- y = self.output:getBottom()
    end

    self.h = y

end

return InstrumentUI

