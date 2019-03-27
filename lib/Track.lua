local rea = require 'rea'
local Send = require 'Send'
local Plugin = require 'Plugin'
local Watcher = require 'Watcher'
local Collection = require 'Collection'
local TrackState = require 'TrackState'

local _ = require '_'

local Track = class()

-- static --

Track.metaMatch = 'TRACK:({.*})'

function Track.getSelectedTrack()
    if nil == Track.selectedTrack then
        local track = reaper.GetSelectedTrack(0,0)
        Track.selectedTrack = track and Track:create(track)
    end

    return Track.selectedTrack
end

function Track.onStateChange()
    _.forEach(Track.getAllTracks(), function(track)
        track:defer()
    end)
end

function Track.deferAll()

    Track.selectedTrack = nil
    Track.selectedTracks = nil
    Track.focusedTrack = nil
    local current = Track.getAllTracks(true)
    if Track.tracks ~= current then
        Track.tracks = current
    end

end

Track.trackMap = {}

function Track.getTrackMap()
    Track.getAllTracks()
    return Track.trackMap
end

function Track.getFocusedTrack()
    if nil == Track.focusedTrack then
        local track = reaper.GetMixerScroll()
        Track.focusedTrack = track and Track:create(track)
    end

    return Track.focusedTrack
end

function Track.getSelectedTracks(live)
    if nil == Track.selectedTracks or live then
        Track.selectedTracks = {}
        for i=0, reaper.CountSelectedTracks(0)-1 do
            local track = Track:create(reaper.GetSelectedTrack(0,i))
            table.insert(Track.selectedTracks, track)
        end
        Track.selectedTracks = Collection:create(Track.selectedTracks)
    end

    return Track.selectedTracks
end

function Track.setSelectedTracks(tracks)
    _.forEach(Track.getAllTracks(), function(track) track:setSelected(false) end)
    _.forEach(tracks, function(track)
        if track:exists() then
            track:setSelected(true)
        end
    end)

    Track.deferAll()
end

function Track.getAllTracks(live)
    if live then
        local tracks = _.map(rea.getAllTracks(), function(t) return Track:create(t) end)
        return Collection:create(tracks)
    elseif nil == Track.tracks then
        Track.tracks = Track.getAllTracks(true)
    end
    return Track.tracks
end

function Track.get(index)
    local track = (index >= 0) and reaper.GetTrack(0, index);
    return track and Track:create(track)
end

function Track.insert(index)
    index = index == nil and reaper.CountTracks(0) or index
    reaper.InsertTrackAtIndex(index, true)
    return Track.get(index)
end

Track.watch = {
    selectedTrack = Watcher:create(Track.getSelectedTrack),
    selectedTracks = Watcher:create(Track.getSelectedTracks),
    tracks = Watcher:create(Track.getAllTracks),
    focusedTrack = Watcher:create(Track.getFocusedTrack)
}

-- obj --

function Track:create(track)

    assertDebug(not track, 'cant create empty track wrapper')

    local wrapper = _.find(Track.tracks, function(t) return t.track == track end)

    if not wrapper then
        local guid = reaper.GetTrackGUID(track)
        local self = {}
        setmetatable(self, Track)
        self.track = track
        self.guid = guid

        Track.trackMap[guid] = self

        self.listeners = {}
        wrapper = self

    end

    return wrapper
end

function Track:onChange(listener)
    table.insert(self.listeners, listener)
end

function Track:triggerChange(message)
    _.forEach(self.listeners, function(listener)
        listener(message)
    end)
    return self
end

-- get

function Track:defer()
    self.state = nil
end

function Track:exists()

    return _.find(Track.getAllTracks(true), self)
    -- body
end

function Track:isMidiTrack()
    local instrument = self:getInstrument()
    return not instrument
end

function Track:getMetaKey(extra)
    return 'TRACK:'..self.guid..':META:' .. extra
end

function Track:setMeta(name, value)
    reaper.SetProjExtState(0, 'D3CK', self:getMetaKey(name), value)
    return self
end

function Track:getMeta(name, value)
    local suc, res = reaper.GetProjExtState(0, 'D3CK', self:getMetaKey(name))
    return suc > 0 and res or nil
end

function Track:isAudioTrack()
    local instrument = self:getInstrument()
    return instrument
end

function Track:focus()
    reaper.SetMixerScroll(self.track)
    rea.refreshUI()

    return self
end

function Track:isFocused()
    return reaper.GetMixerScroll() == self.track
end

function Track:isSelected()
    return _.some(Track.getSelectedTracks(), function(track)
        return track == self and true or false
    end)
end

function Track:choose()
    self:focus()
    self:setSelected(1)
    return self
end

function Track:setSelected(select)
    if select == 1 then
        reaper.SetOnlyTrackSelected(self.track)
    else
        reaper.SetTrackSelected(self.track, select == nil and true or select)
    end
    return self
end

function Track:getPrev()
    return Track.get(self:getIndex()-2)
end

Track.stringMap = {
    name = 'P_NAME',
    icon = 'P_ICON'
}

Track.valMap = {
    arm = 'I_RECARM',
    toParent = 'B_MAINSEND',
    lock = 'C_LOCK',
    tcp = 'B_SHOWINTCP',
    mcp = 'B_SHOWINMIXER',
    mute = 'B_MUTE',
    solo = 'I_SOLO'
}

function Track:getDefaultName()
    return 'Track ' .. tostring(self:getIndex())
end

function Track:getName()
    local res, name = reaper.GetTrackName(self.track, '')
    return res and name ~= self:getDefaultName() and name or nil
end

function Track:setLocked(locked)

    self:setState(self:getState():withLocking(locked))

    return self
end

function Track:isLocked()
    return self:getState():isLocked()
end

function Track:getValue(key)
    if Track.stringMap[key] then
        local res, val = reaper.GetSetMediaTrackInfo_String(self.track, Track.stringMap[key], '', false)
        return res and val or nil
    elseif Track.valMap[key] then
        return reaper.GetMediaTrackInfo_Value(self.track, Track.valMap[key])
    end
end

function Track:setValue(key, value)
    self:setValues({[key] = value})
    return self
end

function Track:setValues(vals)

    for k, v in pairs(vals or {}) do
        if Track.stringMap[k] then
            reaper.GetSetMediaTrackInfo_String(self.track, Track.stringMap[k], v, true)
        elseif Track.valMap[k] then
            reaper.SetMediaTrackInfo_Value(self.track, Track.valMap[k], v == true and 1 or (v == false and 0) or v)
        end
    end

    return self

end

function Track:getInstrument()
    local inst = reaper.TrackFX_GetInstrument(self.track)
    return inst >= 0 and Plugin:create(self, inst) or nil
end

function Track:remove()
    reaper.DeleteTrack(self.track)
    Track.trackMap[self.guid] = nil
    Track.deferAll()
end

function Track:getFxList()

    local ignored = {
        'DrumRack',
        'TrackTool'
    }
    local inst = self:getInstrument()
    local res = {}
    for i = inst and inst:getIndex() or 0, reaper.TrackFX_GetCount(self.track) - 1 do
        table.insert(res, Plugin:create(self, i))
    end
    return res
end

function Track:getState(live)
    if live or not self.state then
        local success, state = reaper.GetTrackStateChunk(self.track, '', false)
        self.state = TrackState:create(state)
    end
    return self.state
end

function Track:__tostring()
    return self:getName() .. ' :: ' .. tostring(self.track)
end

function Track:setState(state)
    self.state = state
    reaper.SetTrackStateChunk(self.track, state:__tostring(), false)
    return self
end

function Track:removeReceives()
    for i=0,reaper.GetTrackNumSends(self.track, -1) do
        reaper.RemoveTrackSend(self.track, -1, i)
    end
    return self
end

function Track:clone()
    local index = self:getIndex()
    reaper.InsertTrackAtIndex(index, false)
    local track = Track:create(reaper.GetTrack(0, index))
    track:setState(self:getState())
    return track
end

function Track:hasMedia()
    return reaper.CountTrackMediaItems(self.track) > 0
end

function Track:isBusTrack()

    local isDrumRack = self:getFx('DrumRack')
    local isContentTrack = self:getInstrument() or self:hasMedia()
    local recs = self:getReceives()
    local hasBusRecs = (_.size(recs) == 0 or _.some(recs, function(rec)
        return rec:isBusSend()
    end))
    local sends = self:getSends()
    local hasMidiSends = _.some(sends, function(send)
        return send:isMidi() and not send:isAudio()
    end)
    return hasBusRecs and not isContentTrack and not isDrumRack

end

function Track:createLATrack()
    local la = Track.insert(self:getIndex())

    la:setVisibility(false, true)
            :setIcon(self:getIcon() or 'fx.png')
            :setName(self:getName() .. ':la')
            :createSend(self)
                :setMidiIO(-1, -1)
                :setSendMode(3)

    return la
end

function Track:createMidiSlave()

    local slave = Track.insert(self:getIndex())

        slave:setVisibility(true, false)
            :setIcon(self:getIcon() or 'midi.png')
            :setName(self:getName() .. ':midi')
            :createSend(self, true)
                :setAudioIO(-1, -1)

    return slave
end

function Track:getMidiSlaves()
    return _.map(self:getReceives(), function(rec)
        if rec:isMidi() then
            return rec:getSourceTrack()
        end
    end)
end

function Track:isRoutedTo(target)

end

function Track:routeTo(target)
    if not target then
        self:setValue('toParent', true)
    else
        if not self:sendsTo(target) then
            self:createSend(target, true)
        end
    end
    return self
end

function Track:removeSend(target)
    _.forEach(self:getSends(), function(send)
        if send:getTargetTrack() == target then
            send:remove()
        end
    end)
    return self
end

function Track:sendsTo(track)
    return _.some(self:getSends(), function(send)
        return send:getTargetTrack() == track
    end)
end


function Track:getSends()
    local sends = {}

    for i = 0, reaper.GetTrackNumSends(self.track, 0)-1 do
        table.insert(sends, Send:create(self.track, i))
    end

    return sends
end

function Track:getReceives()
    local recs = {}
    for i = 0, reaper.GetTrackNumSends(self.track, -1)-1 do
        table.insert(recs, Send:create(self.track, i, -1))
    end
    return recs
end

function Track:receivesFrom(otherTrack)
    return _.some(self:getReceives(), function(rec)
        return rec:getSourceTrack().track == otherTrack.track
    end)
end

function Track:isParentOf(track)
    return track:getParent() and track:getParent().track == self.track
end

function Track:getParent()
    local parent = reaper.GetParentTrack(self.track)
    return parent and Track:create(parent)
end

function Track:getChildren()
    return _.map(rea.getChildTracks(self.track), function(track) return Track:create(track) end)
end

function Track:getIcon(name)
    local p = self:getValue('icon')
    return p and p:len() > 0 and p or nil
end

function Track:setIcon(name)
    self:setValue('icon', name)
    return self
end

function Track:setType(type)
    return self:setMeta('type', type)
end

function Track:getType()
    return self:getMeta('type')
end

function Track:autoName()
    if not self:getName() then
        local inst = self:getInstrument()
        if inst then
            self:setName(inst:getName())
        end
    end
    return self
end

function Track:setName(name)
    self:setValue('name', name)
    return self
end

function Track:validatePlugins()

    local current = self:getPlugins(true)
    if not _.equal(current, self.pluginCache) then
        self.pluginCache = current
        _.forEach(current, function(plugin)
            plugin:reconnect()
        end)
    end
    return self
end

function Track:getPlugins(live)

    if live then
        local res = {}

        for i = 0, reaper.TrackFX_GetCount()-1 do
            table.insert(res, Plugin:create(self, i))
        end

        return res
    else
        return self.pluginCache or {}
    end
end

function Track:getFx(name, force, rec)
    if name == false then
        local success, input = reaper.GetUserInputs("name", 1, "name", "")
        if success then
            name = input
        end
    end
    if not name then return nil end

    local index = reaper.TrackFX_AddByName(self.track, name, rec or false, force and 1 or 0)

    return index >= 0 and Plugin:create(self, index + (rec and 0x1000000 or 0)) or nil
end

function Track:addFx(name, input)
    return reaper.TrackFX_AddByName(self.track, name, input or false, 1)
end

function Track:createSend(target, sendOnly)
    local cindex = reaper.CreateTrackSend(self.track, target.track or target)
    if sendOnly then self:setValue('toParent', false) end
    return Send:create(self.track, cindex)
end

function Track:getFirstChild()
    return _.first(self:getChildren())
end

function Track:getIndex()
    local tracks = rea.getAllTracks()
    for k, v in pairs(tracks) do
        if v == self.track then return k end
    end
end

function Track:setVisibility(tcp, mcp)
    reaper.SetMediaTrackInfo_Value(self.track, 'B_SHOWINTCP', tcp and 1 or 0)
    reaper.SetMediaTrackInfo_Value(self.track, 'B_SHOWINMIXER', mcp and 1 or 0)
    rea.refreshUI()
    return self
end

function Track:findChild(needle)
    return rea.findTrack(needle, _.map(self:getChildren(), function(track) return track.track end))
end

function Track:setFolderState(val)
    reaper.SetMediaTrackInfo_Value(self.track, 'I_FOLDERDEPTH', val or 0)
    return self
end

function Track:getFolderState()
    return reaper.GetMediaTrackInfo_Value(self.track, 'I_FOLDERDEPTH')
end

function Track:isFolder()
    return self:getFolderState() == 1
end

function Track:setParent(newParent)

    if not newParent then return end

    local prevSelection = Track.getSelectedTracks()

    local lastChild = newParent:isFolder() and _.last(newParent:getChildren())
    Track.setSelectedTracks({self})
    if lastChild then
        reaper.ReorderSelectedTracks(lastChild:getIndex(), 2)
    else
        reaper.ReorderSelectedTracks(newParent:getIndex(), 1)
    end

    Track.setSelectedTracks(prevSelection)

    return self

end

function Track:addChild(options)
    self:setFolderState(1)

    local lastChild = _.last(self:getChildren())
    lastChild = lastChild and Track:create(lastChild)
    local index = (lastChild or self):getIndex()

    reaper.InsertTrackAtIndex(index, true)
    local track = reaper.GetTrack(0, index)
    track = Track:create(track)

    track:setValues(options)
    return track
end

function Track:getTrackTool(force)
    -- local plugin = self:getFx('../Scripts/D3CK/test.jsfx', force or false)
    local plugin = self:getFx('TrackTool', force or false)
    if plugin then plugin:setIndex(0) end
    return plugin
end

function Track:__lt(other)
    return self.getIndex() > other.getIndex()
end

function Track:__eq(other)
    return (other and self.track == other.track)
end

Track.master = Track:create(reaper.GetMasterTrack())

return Track
