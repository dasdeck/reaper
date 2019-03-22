local Pad = require 'Pad'
local Mapper = require 'Mapper'
local _ = require '_'
local Directory = require 'Directory'

local Track = require 'Track'

local rea = require 'Reaper'

local DrumRack = class()

DrumRack.presetDir = Directory:create(reaper.GetResourcePath() .. '/TrackTemplates/DrumRack')
DrumRack.presetDir:mkdir()
DrumRack.fxName = 'DrumRack'
DrumRack.maxNumPads = 16

function DrumRack.launch()

    local id = reaper.NamedCommandLookup('drumRack.lua')
    if not id then
        id = reaper.AddRemoveReaScript(true, 0, 'path', true)
    end
    if id then reaper.Main_OnCommand(id, 0) end

end

function DrumRack.getAllRacks()
    local tracks = Track.getAllTracks()
    return _.filter(tracks, function(track) return track:getFx(DrumRack.fxName) end)
end

function DrumRack.getAssociatedDrumRack(selected)
    return _.some(DrumRack.getAllRacks(), function(track)
        local rack = DrumRack:create(track)
        return _.find(rack:getAllTracks(true), selected) and rack
    end)
end

function DrumRack.init(track)

    if not track then track = Track.insert()end

    track:setType('drumrack')
        :setIcon(track:getIcon() or 'drumbox.png')
        :setVisibility(true, false)
        :setName(track:getName() or 'drumrack')
        :setValue('toParent', false)
        :getFx(DrumRack.fxName, true)
        local rack = DrumRack:create(track)
        rack:setSelectedPad(1)
    return rack

end

-- methods

function DrumRack:create(track)

    reaper.gmem_attach('drumrack')

    local self = {}

    setmetatable(self, DrumRack)

    self.track = track

    self.pads = {}
    for i=1, DrumRack.maxNumPads do
        table.insert(self.pads, Pad:create(self))
    end

    return self

end

function DrumRack:getLocked()
    local pads = _.filter(self.pads, function(pad) return pad:hasContent() end)

    locks = _.reduce(pads, function(carry, pad)
        local lock = pad:getLocked()
        return math.max(carry, lock)
    end, 0)

    if self:getFx()then
        local l = self:getFx():isLocked()
        if _.size(pads) == 0 then return l
        elseif locks == 1 then
            locks = l and 1 or 2
        elseif locks == 0 then
            locks = l and 2 or locks
        end
    end

    return locks
end

function DrumRack:setLocked(locked)
    if self:getFx() then self:getFx():setLocked(locked) end
    _.forEach(self.pads, function(pad)
        pad:setLocked(locked)
    end)
end

function DrumRack:__eq(o)
    return self.track == o.track
end

function DrumRack:clear()
    _.forEach(self.pads, function(pad)
        pad:clear()
    end)
    return self
end

function DrumRack:getTrack()
    return self.track
end

function DrumRack:getAllTracks(includeMidi)

    local tracks = {
        [self.track.guid] = self.track
    }

    local fx = self:getFx()
    if fx then tracks[fx.guid] = fx end

    _.forEach(self.pads, function(pad, i)
        local fx = pad:getFx()

        if fx then tracks[fx.guid] = fx end

        _.forEach(pad:getLayers(), function(track)
            tracks[track.guid] = track
        end)
    end)

    if includeMidi then
        _.forEach(self.track:getMidiSlaves(), function(track)
            tracks[track.guid] = track
        end)
    end

    return tracks
end

function DrumRack:setSelectedPad(index)
    if self:getMapper() then
        local current = self:getMapper():getParam(0)
        if index == current then return false end
        self:getMapper():setParam(0, index)
        return true
    end
    return self
end

function DrumRack:hasContent()
    return _.some(self.pads, function(pad)
        return pad:hasContent()
    end)
end

function DrumRack:getSelectedPad()
    return self.pads[self:getMapper() and self:getMapper():getParam(0)]
end

function DrumRack:saveKit()
    local tracks = self:getAllTracks()
    table.sort(tracks)
    local data = _.map(tracks, function(track)
        return track:getState()
    end)
    return _.join(data, '\n')
end

function DrumRack:loadKit(file)
    local selection = Track.getSelectedTracks()

    reaper.Main_openProject(file)

    Track.deferAll()

    loadedTracks = Track.getSelectedTracks()
    -- Track.setSelectedTracks({})

    drumRackToLoad = _.some(loadedTracks, function(track)
        return DrumRack.getAssociatedDrumRack(track)
    end)

    if drumRackToLoad then
        self:clear()

        self:setFx(drumRackToLoad:getFx())

        _.forEach(drumRackToLoad.pads, function(padToLoad)
            local pad = self.pads[padToLoad:getIndex()]
            pad:setFx(padToLoad:getFx())
            _.forEach(padToLoad:getLayers(), function(layer)
                pad:addTrack(layer)
            end)
        end)

        drumRackToLoad:getTrack():remove()
    end

    Track.setSelectedTracks(selection)
    return self
end

function DrumRack:refreshConnections()
    _.forEach(self.pads, function(pad)
        pad:refreshConnections()
    end)
    return self
end

function DrumRack:isSplitMode()
    return self:getMapper():getParam(11) > 0
end

local icons = {
    'drumbox.png',
    'fx.png'
}

function DrumRack:setSplitMode(enable)

    local val = enable == nil and 1 or (enable and 1 or 0)
    icon = self:getTrack():getIcon()

    defIcon = _.some(icons, function(i) return icon:includes(i) end)
    if defIcon then
        self:getTrack():setIcon(icons[val + 1])
    end

    self:getMapper():setParam(11, val)
    return self
end

function DrumRack:removeFx()
    if self:getFx() then
        self:getFx():remove()
        self:refreshConnections()
    end
    return self
end

function DrumRack:setFx(track)
    if track then
        self:removeFx()

        local send = self:getTrack():createSend(track)
        send:setMidiBusIO(-1, -1):setMuted()

        self:refreshConnections()

    end
    return self
end

function DrumRack:createFx()
    local fxTrack = Track.insert(self:getTrack():getIndex() - 1)
    fxTrack:setIcon(fxTrack:getIcon() or 'beats.png')
    :setVisibility(false, true)
    if self:getLocked() == 1 then fxTrack:setLocked(true) end
    return fxTrack
end

function DrumRack:getFx(create)

    local fxTrack = _.some(self:getTrack():getSends(), function(send)
        if send:isMuted() and send:getMidiSourceBus() == -1 then
            return send:getTargetTrack()
        end
    end)

    if create and not fxTrack then
        fxTrack = self:createFx()
        self:setFx(fxTrack)
    end

    return fxTrack

end

function DrumRack:isActive()
    return self:getMapper()
end

function DrumRack:getMapper()
    if not self.mapper then
        local fx = self:getTrack():getFx(DrumRack.fxName)
        local mapper = Mapper:create(fx)
        self.mapper = fx and mapper or nil
    end
    return self.mapper
end

return DrumRack