local Track = require 'Track'
local Mem = require 'Mem'
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

function Pad:refreshConnections()
    local fxBus = self.rack:getFx()
    local fx = self:getFx()
    local layers = self:getLayers()

    if fx then fx:routeTo(fxBus) end

    _.forEach(layers, function(layer)
        if fx and fxBus then
            layer:removeSend(fxBus)
        end
        layer:routeTo(fx or fxBus)
    end)
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
    local layers = self:getLayers()

    if fx then
        while _.size(fx:getReceives()) > 0 do
            local rec = _.first(fx:getReceives())
            local source = rec:getSourceTrack()
            rec:remove()
            if rackFx then source:createSend(rackFx)
            else source:setValue('toParent', true)
            end
        end
    end

    fx:remove()

end

function Pad:getFx(create)

    local track = _.some(self.rack:getTrack():getSends(), function(send)
        return send:getMidiSourceBus() == self:getIndex() and send:isMuted() and send:getTargetTrack()
    end)

    if create and not track and (_.size(self:getLayers()) > 0) then

        track = Track.insert(_.first(self:getLayers()):getIndex())
        track:setIcon('pads.png')
        track:setName(self:getName())
        track:setVisibility(false, true)
        track:setType('pad')
        self:setFx(track)

    end
    return track
end

function Pad:setFx(track)
    if track then
        local send = self.rack:getTrack():createSend(track)
        send:setMuted()
        send:setMidiBusIO(self:getIndex(), 0)
        self:refreshConnections()
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
        newTrack:setParent(self:getFx() or self.rack:getTrack():getParent())
        newTrack:setIcon(newTrack:getIcon() or 'fx.png')
        newTrack:setVisibility(false, true)
        newTrack:focus()
        newTrack:setType('layer')
        newTrack:autoName()

        self:refreshConnections()
    end
end

function Pad:addLayer(path)

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
            reaper.InsertTrackAtIndex(index, true)
            newTrack = Track:create(reaper.GetTrack(0, index))

            local fx
            if reaper.file_exists(path) then
                fx = newTrack:getFx('ReaSamplomatic5000', true)
                fx:setParam('FILE0', path)
                fx:setParam('DONE', '')
                newTrack:setIcon(rea.findIcon('wave decrease'))
            else
                fx = newTrack:getFx(path, true)
            end

        end
    else
        reaper.InsertTrackAtIndex(index, true)
        newTrack = Track:create(reaper.GetTrack(0, index))
    end

    track:setSelected(1)

    self:addTrack(newTrack)

end

function Pad:clear()

    while _.size(self:getLayers()) > 0 do
        _.first(self:getLayers()):remove()
    end

end

function Pad:getLayers()
    return _.map(self:getLayerConnections(), function(send) return send:getTargetTrack() end)
end

function Pad:getLayerConnections()

    local layers = {}

    _.forEach(self.rack:getTrack():getSends(), function(send)
        if send:getMidiSourceBus() == self:getIndex() and not send:isMuted() then
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
end

function Pad:copyPad(otherPad)
    _.forEach(otherPad:getLayers(), function(layer)
        self:addTrack(layer:clone():removeReceives())
    end)
end

function Pad:noteOff()
    if self:getVelocity() > 0 then
        Mem.write('drumrack', self.rack.maxNumPads + self:getIndex() - 1, -1)
    end
end

function Pad:getVelocity()
    return Mem.read('drumrack', self:getIndex() - 1)
end

return Pad