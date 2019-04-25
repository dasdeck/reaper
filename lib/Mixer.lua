local Component = require 'Component'
local MixerChannel = require 'MixerChannel'
local Track = require 'Track'
local Project = require 'Project'
local Mouse = require 'Mouse'
local _ = require '_'
local rea = require 'rea'

local Mixer = class(Component)

function Mixer:create()
    local self = Component:create()
    setmetatable(self, Mixer)

    self.watchers:watch(Project.watch.project, function()
        if not Mouse.capture():isButtonDown() then
            self:update()
        end
    end)
    return self
end

function Mixer:update()
    self:deleteChildren()
    self.tracks = {}
    self.aux = {}
    _.forEach(Track.getAllTracks(), function(track)
        if track:getValue('toParent') == 1 then
            local comp = self:addChildComponent(MixerChannel:create(track))
            if comp then
                if track:getType() == 'aux' then
                    table.insert(self.aux, comp)
                else
                    table.insert(self.tracks, comp)
                end
            end
        end
    end)

    self:resized()
    self:repaint(true)
end

function Mixer:onDrop()
    local droppedTrack = instanceOf(Component.dragging, MixerChannel) and Component.dragging.track
    if droppedTrack then
        rea.transaction('change routing', function()
            droppedTrack:setOutput(nil)
        end)
    end
end

function Mixer:onClick()
    rea.transaction('clear selection', function()
        Track.setSelectedTracks({})
    end)
end

function Mixer:resized()
    local x = 0
    _.forEach(self.tracks, function(child)
        child:setBounds(x, 0, nil, self.h)
        x = x + child.w
    end)
    x = self.w
    _.forEach(self.aux, function(child)
        child:setSize(nil, self.h)
        x = x - child.w
        child:setPosition(x, 0)
    end)
end

return Mixer