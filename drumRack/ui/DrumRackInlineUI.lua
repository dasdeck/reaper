local PadGrid = require 'PadGrid'
local Component = require 'Component'
local PadEditor = require 'PadEditor'
local ButtonList = require 'ButtonList'
local Split = require 'Split'
local DrumRackOptions = require 'DrumRackOptions'
local Project = require 'Project'
local DrumRack = require 'DrumRack'
local Menu = require 'Menu'
local Track = require 'Track'
local FXButton = require 'FXButton'

local colors = require 'colors'
local _ = require '_'

local rea = require 'rea'

local DrumRackInlineUI = class(Component)

-- methods

function DrumRackInlineUI:create(rack)

    local self = Component:create()

    setmetatable(self, DrumRackInlineUI)

    self.rack = rack

    self.padgrid = self:addChildComponent(PadGrid:create(rack))

    local change = function()
        self.padgrid:repaint(true)
        self:update()
    end

    self.watchers:watch(function()
        return self.rack:getSelectedPad()
    end, change, true)

    self.rackFx = self:addChildComponent(FXButton:create(rack, 'rack:fx'))

    if rack:getFx() then
        local AudioTrackUI = require 'AudioTrackUI'
        self.rackFxTrack = self:addChildComponent(AudioTrackUI:create(rack:getFx()))
    end

    change()

    return self

end

function DrumRackInlineUI:update()
    local currentPad = self.padEditor and self.padEditor.pad

    if self.padEditor then
        self.padEditor:delete()
        self.padEditor = nil
    end
    if self.rack:getSelectedPad() then
        self.padEditor = self:addChildComponent(PadEditor:create(self.rack:getSelectedPad()))
    end

    self:resized()
end

function DrumRackInlineUI:resized()

    local y = 0
    local h = 20

    local padgrid = self.w
    self.padgrid:setBounds(0, y, padgrid, padgrid)
    local y = self.padgrid:getBottom()

    if self.padEditor then
        self.padEditor:setBounds(0, y, self.w)
        y = self.padEditor:getBottom()
    end

    self.rackFx:setBounds(0,y,self.w, h)
    y = self.rackFx:getBottom()

    if self.rackFxTrack then
        self.rackFxTrack:setBounds(0, y, self.w)
        y = self.rackFxTrack:getBottom()
    end

    self.h = y

end

return DrumRackInlineUI