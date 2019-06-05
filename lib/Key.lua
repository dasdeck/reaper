local Component = require 'Component'
local _ = require '_'
local rea = require 'rea'
local paths = require 'paths'

local Key = class(Component)

function Key.create(key)

    local self = Component:create()

    self.key = key
    setmetatable(self, Key)
    self:createZones()

    return self
end

local blackKeys = {
    1, 3, 6, 8, 10
 }

function Key:onDrag()
    Component.dragging = self
end

function Key:createZones()
    local Zone = require 'Zone'
    self.zones = {}
    _.forEach(self:getZones(), function(track)
        -- rea.log(self.key)
        table.insert(self.zones, self:addChildComponent(Zone.create(track)))
    end)
end

function Key:getZones()
    local Track = require 'Track'
    return _.filter(Track.getAllTracks(), function(track)
        if track:isArmed() then
            local keyRange = track:getFx('midi_note_filter', false, true)

            return keyRange and keyRange:getParam(0) <= self.key and keyRange:getParam(1) >= self.key
        end
    end)
end

function Key:onDrop()
    local Zone = require 'Zone'
    if instanceOf(Component.dragging, Zone) then
        rea.transaction('change key', function()
            Component.dragging:setKey(self.key)
        end)
    elseif instanceOf(Component.dragging, Key) then
        rea.transaction('flip keys', function()
            local zones = self.zones
            local others = Component.dragging.zones
            _.forEach(zones, function(zone)
                zone:setKey(Component.dragging.key)
            end)
            _.forEach(others, function(zone)
                zone:setKey(self.key)
            end)
        end)
    end
end

function Key:onFilesDrop(files)

    local Track = require 'Track'
    local TrackState = require 'TrackState'

    rea.transaction('add sampler', function()
        _.forEach(files, function(file)

            local template = paths.reaDir:childDir('TrackTemplates'):childFile('sampler.RTrackTemplate')
            local track = _.first(TrackState.fromTemplate(template:getContent())) --Track.insert()
            track = track or Track.insert()

            track:setName(_.last(file:split(package.config:sub(1,1))))
            track:setArmed(true)
            local sampler = track:getFx('ReaSamplomatic5000')
            sampler:setParam('FILE0', file)
            sampler:setParam('DONE', '')
            track:setIcon(rea.findIcon('wave decrease'))
            track:setSelected(1)
            local range = track:getFx('midi_note_filter', false, true)

            range:setParam(0, self.key)
            range:setParam(1, self.key)

        end)
    end)
end

function Key:paint(g)
    local c = _.find(blackKeys, self.key % 12) and 0 or 1
    g:setColor(c,c,c, 1)
    g:rect(0,0,self.w, self.h, true, true)
end

function Key:resized()
    local horz = self.w > self.h
    local s = horz and self.h or self.w
    _.forEach(self.zones, function(zone, i)
        if horz then
            zone:setBounds(s * (i-1), 0, s, self.h)
        else
            zone:setBounds(0, s * (i-1), self.w, s)
        end
    end)
end

return Key