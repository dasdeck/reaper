local Component = require 'Component'
local TextButton = require 'TextButton'
local Label = require 'Label'
local Track = require 'Track'
local TrackStateButton = require 'TrackStateButton'
local GainSlider = require 'GainSlider'
local PanSlider = require 'PanSlider'
local FXList = require 'FXList'
local FXListAddButton = require 'FXListAddButton'
local Image = require 'Image'
local Meter = require 'Meter'

local rea = require 'rea'
local _ = require '_'
local colors = require 'colors'

local MixerChannel = class(Component)
function MixerChannel:create(track)

    if track:getType() == 'instrument' then return end
    if track:getType() == 'midi' then return end

    local self = Component:create()
    setmetatable(self, MixerChannel)
    self.track = track
    self:update()
    return self
end

function MixerChannel:update()
    self:deleteChildren()
    self.tracks = {}

    self.gain = self:addChildComponent(GainSlider:create(self.track))
    self.pan = self:addChildComponent(PanSlider:create(self.track))
    self.name = self:addChildComponent(Label:create(self.track:getName()))
    self.name:setVisible(false)
    local image = self.track:getImage() and Image:create(self.track:getImage(), 'fit') or ''
    self.image = self:addChildComponent(Label:create(image))
    self.image.canClickThrough = function()
        return false
    end
    self.image.inline = true
    self.image.onDblClick = function()
        if self.track:getManager() and self.track:getManager():getInstrument() then
            self.track:getManager():getInstrument():toggleOpen()
        end
    end

    self.meter = self:addChildComponent(Meter:create(self.track))

    self.mute = self:addChildComponent(TrackStateButton:create(self.track, 'mute', 'M'))
    self.solo = self:addChildComponent(TrackStateButton:create(self.track, 'solo', 'S'))

    self.fxadd = self:addChildComponent(FXListAddButton:create(self.track, 'fx'))

    local fx = self.track:getFxList()
    if _.size(fx) > 0 then
        self.fxlist = self:addChildComponent(FXList:create(fx))
    end

    local tracks = Track.getAllTracks()
    _.forEach(tracks, function(track)
        if track:getOutput() == self.track then
            local track = self:addChildComponent(MixerChannel:create(track))
            if track then
                table.insert(self.tracks, track)
            end
        end
    end)
end

function MixerChannel:onDblClick(m)
    self.fxadd.name:onButtonClick(m)
end

function MixerChannel:paint(g)
    Label.drawBackground(self, g, colors.default)
    self.name:paint(g)
    g.y = self.image.y
    self.image:paint(g)
end

function MixerChannel:paintOverChildren(g)
    g:setColor(0,0,0,1)
    g:roundrect(0,0, self.w, self.h)
    if Track.getSelectedTrack() and not self.track:receivesFrom(Track.getSelectedTrack()) then
        g:setColor(0,0,0,0.5)
        g:roundrect(0,0, self.w, self.h, nil, true)
    end

end

function MixerChannel:onDrag()
    Component.dragging = self
end

function MixerChannel:canClickThrough()
    return false
end

function MixerChannel:onDrop()

    local droppedTrack = instanceOf(Component.dragging, MixerChannel) and Component.dragging.track

    if droppedTrack and droppedTrack ~= self.track then
        local type = self.track:getType()
        if type == 'aux' then

        elseif type == 'bus' then
            if not droppedTrack:receivesFrom(self.track) then
                rea.transaction('change routing', function()
                    droppedTrack:setOutput(self.track)
                end)
            end

        end

    elseif instanceOf(Component.dragging, Component) and Component.dragging.setIndex then
        self.fxadd:onDrop()
    end
end

function MixerChannel:resized()
    local h = 20
    self.w = h * 2

    if self.fxlist then
        self.fxlist:setSize(self.w)
        self.fxlist:setPosition(0, self.h - h*8 - self.fxlist.h, h*2)
    end

    self.meter:setBounds(0,self.h - h*2, h*2, h*2)

    self.fxadd:setBounds(0,self.h - h*8,h*2,h)

    self.pan:setBounds(0,self.h - h*3, h*2, h)
    self.gain:setBounds(0,self.h - h*3 - h*4,h,h*4)

    self.mute:setBounds(h,self.h - h*4,h,h)
    self.solo:setBounds(h,self.h - h*5,h,h)

    self.image:setBounds(0, self.h - h*2, h*2, h*2)
    local x = self.w
    _.forEach(self.tracks, function(child)
        child:setBounds(x, h, nil, self.h - h)
        x = x + child.w
    end)
    self.w = x

    self.name:setBounds(0,0,self.w, h)
end

return MixerChannel