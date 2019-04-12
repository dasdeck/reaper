local Component = require 'Component'
local MixerChannel = require 'MixerChannel'
local Track = require 'Track'
local Project = require 'Project'
local _ = require '_'
local rea = require 'rea'

local Mixer = class(Component)

function Mixer:create()
    local self = Component:create()
    setmetatable(self, Mixer)
    self.watchers:watch(Project.watch.project, function()
        self:update()
    end)
    return self
end

function Mixer:update()
    self:deleteChildren()
    local tracks = Track.getAllTracks()
    _.forEach(tracks, function(track)
        if track:getValue('toParent') == 1 then
            self:addChildComponent(MixerChannel:create(track))
        end
    end)
    self:resized()
end

function Mixer:resized()
    local x = 0
    _.forEach(self.children, function(child)
        child:setBounds(x, 0, nil, self.h)
        x = x + child.w
    end)
    self.w = x
end

return Mixer