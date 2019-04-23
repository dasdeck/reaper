local Track = require 'Track'
local Mem = require 'Mem'
local TrackState = require 'TrackState'
local Bus = require 'Bus'
local colors = require 'colors'
local _ = require '_'
local rea = require 'rea'

local Pad = class()

function Pad:create(rack)

    local self = {}
    setmetatable(self, Pad)

    self.rack = rack

    return self
end

function Pad:setKeyRange(low, hi)
    self.rack:getMapper():setParamForPad(self, 1, low)
    self.rack:getMapper():setParamForPad(self, 2, hi)
    return self
end

function Pad:getAllTracks(tracks)
    tracks = tracks or {}

    local fx = pad:getFx()
    if fx then tracks[fx.guid] = fx end

    _.forEach(pad:getLayers(), function(track)
        tracks[track.guid] = track
    end)

    return tracks
end

function Pad:savePad()
    local tracks = self:getAllTracks()

    local data = TrackState.fromTracks(tracks)
    return _.join(data, '\n')
end

function Pad:loadPad(file)
    local selection = Track.getSelectedTracks()

    Track.setSelectedTracks({})

    reaper.Main_openProject(file)

    Track.deferAll()

    local loadedTracks = Track.getSelectedTracks()

    fx = _.find(loadedTracks, function(track)
        return _.size(track:getReceives()) > 0
    end)

    if not self:getFx() or not self:getFx():isLocked() then
        self:setFx(fx)
    end

    self:removeLayers()

    _.forEach(loadedTracks, function(layerToLoad)
        if layerToLoad ~= fx then
            self:addTrack(layerToLoad)
        end
    end)

    Track.setSelectedTracks(selection)
    return self
end

function Pad:getNext()
    return self.rack.pads[self:getIndex() + 1]
end

function Pad:getPrev()
    return self.rack.pads[self:getIndex() - 1]
end

function Pad:getAllTracks(res)
    res = res or {}
    local fx = self:getFx()
    if fx then res[fx.guid] = fx end
    _.forEach(self:getLayers(), function(layer)
        res[layer.guid] = layer
    end)
    return res
end

function Pad:setLocked(lock)
    _.forEach(self:getAllTracks(), function(track)
        track:setLocked(lock)
    end)
end

function Pad:getLocked()
    local tracks = self:getAllTracks()
    if _.size(tracks) > 0 then
        local hasLocked = false
        local hasUnlocked = false

        _.forEach(tracks, function(track)
            local locked = track:isLocked()
            hasUnlocked = hasUnlocked or not locked
            hasLocked = hasLocked or locked
        end)

        local state = (hasLocked and 1 or 0) + (hasLocked and hasUnlocked and 1 or 0)
        return state, hasLocked, hasUnlocked
    end
    return 0

end

function Pad:setSelected()
    return self.rack:setSelectedPad(self:getIndex())
end

function Pad:learn()
    self:learnLow()
    self:learnHi()
end

function Pad:learnLow()
    self.rack:getMapper():setParam(3, 1)
end

function Pad:addSelectedTracks()
    _.forEach(Track.getSelectedTracks(), function(track)
        self:addTrack(track)
    end)
end

function Pad:learnHi()
    self.rack:getMapper():setParam(4, 1)
end

function Pad:isSelected()
    return self.rack:getSelectedPad() == self
end

function Pad:hasContent()
    local layers = self:getLayers()
    return layers and _.size(layers) > 0
end

function Pad:removeFx()
    local fx = self:getFx()
    local rackFx = self.rack:getFx()

    if fx then
        self:setOutput(rackFx, fx)

        if fx:isManagedBy(self.rack:getTrack()) then
            fx:remove()
        end
    end

end

function Pad:getUniqueName()
    return self.rack:getTrack().guid .. 'pad' .. tostring(self:getIndex())
end

function Pad:getOutput()
    return self:getFx() or self.rack:getFx() or nil
end

function Pad:setOutput(track, filter)
    if self:getFx() and self:getFx():getOutput() == filter then
        self:getFx():setOutput(track)
    end

    _.forEach(self:getLayers(), function(layer)
        if layer:getOutput() == filter then
            layer:setOutput(track)
        end
    end)

end

function Pad:getFx(create)

    local track = _.some(self.rack:getTrack():getSends(), function(send)
        return send:getMidiSourceBus() == self:getIndex() and send:getType() == 'bus' and send:getTargetTrack()
    end)

    if create and not track and (_.size(self:getLayers()) > 0) then
        self:setFx(self:createFx())
    end

    return track
end

function Pad:createFx()
    track = Bus.createBus(_.first(self:getLayers()):getIndex())
    track:setIcon('pads.png')
    track:setManaged(self.rack:getTrack())
    track:setVisibility(false, true)
    return track
end

function Pad:setFx(track)
    self:removeFx()
    if track then

        local currentOutPut = self:getOutput()
        if track:isManagedBy(self.rack:getTrack()) then
            track:setOutput(currentOutPut)
            track:setName('pad' .. self:getName())
        end
        self:setOutput(track, currentOutPut)

        local send = self.rack:getTrack():createSend(track)
        send:setType('bus')
        send:setMidiBusIO(self:getIndex(), 0)
    end
    return pad
end

function Pad:hasPadFx()
    return self:getFx(false)
end

function Pad:addTrack(newTrack)
    if newTrack then
        local send = self.rack:getTrack():createSend(newTrack)
        send:setMidiBusIO(self:getIndex(), 1)
        send:setAudioIO(-1, -1)
        -- newTrack:setParent(self:getFx() or self.rack:getTrack():getParent())
        newTrack:setIcon(newTrack:getIcon() or 'fx.png')
        newTrack:setVisibility(false, false)
        newTrack:focus()
        -- newTrack:setType(Track.typeMap.layer)
        newTrack:autoName()
        newTrack:getTrackTool(true)
        newTrack:setOutput(self:getOutput())
        newTrack:setManaged(self.rack:getTrack())
    end
end

function Pad:addLayer(path, name)

    local track = self.rack:getTrack()

    local layers = self:getLayers()
    local rackChildren = track:getChildren()

    local index =
        _.size(layers) > 0 and _.last(layers):getIndex()
        or _.size(rackChildren) > 0 and _.last(rackChildren):getIndex()
        or track:getIndex()

    local newTrack
    if path and type(path) == 'string' then

        if path:endsWith('.RTrackTemplate') then
            reaper.Main_openProject(path)
            newTrack = Track.getSelectedTrack()
        else

            local Instrument = require 'Instrument'

            if reaper.file_exists(path) then
                newTrack = Instrument.createInstrument('ReaSamplomatic5000')
                if newTrack then
                    local fx = newTrack:getInstrument()
                    fx:setParam('FILE0', path)
                    fx:setParam('DONE', '')
                    newTrack:setIcon(rea.findIcon('wave decrease'))
                end
            else
                newTrack = Instrument.createInstrument(path)
            end

            if name then
                newTrack:setName(name)
            end

        end
    else
        reaper.InsertTrackAtIndex(index, true)
        newTrack = Track:create(reaper.GetTrack(0, index))
    end

    self:addTrack(newTrack)
    return newTrack

end

function Pad:removeLayers(keepLocked)
    while _.size(self:getLayers()) > 0 do
        _.first(self:getLayers()):remove()
    end
end

function Pad:clear()

    self:removeLayers()
    self:removeFx()

end

function Pad:getLayers()
    return _.map(self:getLayerConnections(), function(send) return send:getTargetTrack() end)
end

function Pad:getLayerConnections()

    local layers = {}

    _.forEach(self.rack:getTrack():getSends(), function(send)
        if send:getMidiSourceBus() == self:getIndex() and send:getTargetTrack():isManagedBy(self.rack:getTrack()) and send:getTargetTrack():isInstrument() then
            table.insert(layers, send)
        end
    end)

    return layers
end

function Pad:getName()
    return tostring(self:getIndex())
end

function Pad:getIndex()
    return _.indexOf(self.rack.pads, self)
end

function Pad:flipPad(otherPad)
    local layersA = otherPad:getLayerConnections()
    local layersB = self:getLayerConnections()

    for k,v in pairs(layersA) do
        v:setMidiBusIO(self:getIndex(), 1)
    end

    for k,v in pairs(layersB) do
        v:setMidiBusIO(otherPad:getIndex(), 1)
    end

    local fxA = otherPad:getFx()
    local fxB = self:getFx()
    self:setFx(fxA)
    otherPad:setFx(fxB)
end

function Pad:copyPad(otherPad)
    _.forEach(otherPad:getLayers(), function(layer)
        self:addTrack(layer:clone())
    end)
end

function Pad:noteOff()
    if self:getVelocity() > 0 then
       self.rack.mem:set(self.rack.maxNumPads + self:getIndex() - 1, -1)
    end
end

function Pad:getVelocity()
    return self.rack.mem:get(self:getIndex() - 1)
end

return Pad