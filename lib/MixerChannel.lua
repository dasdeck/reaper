local Component = require 'Component'
local TextButton = require 'TextButton'
local Label = require 'Label'
local Track = require 'Track'
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

    self.name = self:addChildComponent(TextButton:create(self.track:getName()))

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

function MixerChannel:resized()
    self.w = 60
    local x = self.w
    _.forEach(self.tracks, function(child)
        child:setBounds(x, 20, nil, self.h - 20)
        x = x + child.w
    end)
    self.w = x
    self.name:setBounds(0,0,self.w, 20)
end

return MixerChannel