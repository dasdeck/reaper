local Component = require 'Component'
local TrackToolControlls = require 'TrackToolControlls'
local TrackStateButton = require 'TrackStateButton'
local TextButton = require 'TextButton'
local ButtonList = require 'ButtonList'
local FXList = require 'FXList'
local FXListAddButton = require 'FXListAddButton'
local La = require 'La'
local AuxUI = require 'AuxUI'
local Output = require 'Output'
local Type = require 'Type'
local Slider = require 'Slider'
local Track = require 'Track'

local colors = require 'colors'
local rea = require 'rea'
local _ = require '_'

local AudioTrackUI = class(Component)

function AudioTrackUI:create(track, isOutput)
    local self = Component:create()
    setmetatable(self, AudioTrackUI)

    self.track = track

    local track = self.track

    self.fx = self:addChildComponent(FXList:create(track, '+master-fx'))
    self.fxAdd = self:addChildComponent(FXListAddButton:create(track))
    -- self:update()

    return self
end

function AudioTrackUI:update()
    self:deleteChildren()



end

function AudioTrackUI:resized()

    local h = 20
    local y = 0

    self.fx:setBounds(0,y,self.w)
    y = self.fx:getBottom()

    self.fxAdd:setBounds(0,y, self.w, h)
    y = self.fxAdd:getBottom()
    self.h = y
end

return AudioTrackUI

