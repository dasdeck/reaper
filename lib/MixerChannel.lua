local Component = require 'Component'
local TextButton = require 'TextButton'
local Label = require 'Label'
local Track = require 'Track'
local GainSlider = require 'GainSlider'
local PanSlider = require 'PanSlider'
local FXList = require 'FXList'

local rea = require 'rea'
local _ = require '_'
local colors = require 'colors'

local MixerChannel = class(Component)
function MixerChannel:create(track)
    if track:getType() == 'midi' then return nil end
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
    self.name = self:addChildComponent(TextButton:create(self.track:getName()))

    local fx = self.track:getFxList()
    if _.size(fx) > 0 then
        self.fxlist = self:addChildComponent(FXList:create(fx))
    end

    local tracks = Track.getAllTracks()
    _.forEach(tracks, function(track)
        if track:getOutput() == self.track then
            table.insert(self.tracks, self:addChildComponent(MixerChannel:create(track)))
        end
    end)
end

function MixerChannel:paint(g)
    Label.drawBackground(self, g, self.track:getColor() or colors.default)
end

function MixerChannel:onDrag()
    Component.dragging = self
end

function MixerChannel:canClickThrough()
    return false
end

function MixerChannel:onDrop()

    rea.log('drop')
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
    end
end

function MixerChannel:resized()
    local h = 20

    if self.fxlist then
        self.w = h * 5
        self.fxlist:setBounds(h*2, h*2, h*3, self.h-h*2)
    else
        self.w = h * 2
    end
    self.pan:setBounds(0,h,self.w, h)
    self.gain:setBounds(0,h*2,h,self.h-h*2)

    local x = self.w
    _.forEach(self.tracks, function(child)
        child:setBounds(x, h, nil, self.h - h)
        x = x + child.w
    end)
    self.w = x
    self.name:setBounds(0,0,self.w, h)
end

return MixerChannel