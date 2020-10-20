local rea = require 'rea'
local Send = require 'Send'
local Plugin = require 'Plugin'
local Watcher = require 'Watcher'
local Collection = require 'Collection'
local TrackState = require 'TrackState'
local Mem = require 'Mem'
local color = require 'color'
local colors = require 'colors'
local _ = require '_'
local paths = require 'paths'

local Track = class()

-- static --

Track.mem = Mem:create('track')

Track.typeMap = {
    aux = 'aux',
    bus = 'bus',
    instrument = 'instrument',
    midi = 'midi',
    audio = 'audio',
    la = 'la',
    output = 'output'
}

Track.types = _.map(Track.typeMap, function(type) return type end)
table.sort(Track.types)

Track.metaMatch = 'TRACK:({.*}):META'

function Track.getSelectedTrack()
    if nil == Track.selectedTrack then
        local track = reaper.GetSelectedTrack(0,0)
        Track.selectedTrack = track and Track:create(track) or nil
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

function Track.getFocusedTrack(live)
    return Track.get(Track.mem:get(0) - 1)
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

function Track.setSelectedTracks(tracks, add)
    if not add then
        _.forEach(Track.getAllTracks(), function(track) track:setSelected(false) end)
    end

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
    local track = Track.getAllTracks()[index+1]
    return track and track:exists() and track
end

function Track.insert(index)

    -- reaper.OnStopButton()

    index = index == nil and reaper.CountTracks(0) or index
    reaper.InsertTrackAtIndex(index, true)
    Track.deferAll()
    return Track.get(index)
end

function Track.disarmAll()
    _.forEach(Track.getAllTracks(), function(track)
        track:setArmed(false)
    end)
end

Track.watch = {
    selectedTrack = Watcher:create(Track.getSelectedTrack),
    selectedTracks = Watcher:create(Track.getSelectedTracks),
    tracks = Watcher:create(Track.getAllTracks),
    focusedTrack = Watcher:create(Track.getFocusedTrack)
}

-- obj --

function Track:create(track)

    assert(track, 'cant create empty track wrapper')

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

function Track:iconize()
    self:setIcon(self:getImage())

end

function Track:createSlave(name, indexOffset)
    local t = Track.insert(self:getIndex() + indexOffset)
    self:setName(self:getName() or self:getDefaultName())

    return t:setName(self:getName() .. ':' .. name)
end

function Track:onChange(listener)
    table.insert(self.listeners, listener)
end

function Track:isArmed()
    return self:getValue('arm') ~= 0
end

function Track:getAllSourceTracks(res)
    res = res or {}
    table.insert(res, self)
    _.forEach(self:getReceives(), function(rec)
        rec:getSourceTrack():getAllSourceTracks(res)
    end)

    return res
end

function Track:setArmed(arm)
    if arm == 1 then
        _.forEach(Track.getAllTracks(), function(track)
            track:setArmed(track == self)
        end)
    else
        self:setValue('arm', arm)
    end
    return self
end

function Track:setAutoRecArm(enabled)
    self:setState(self:getState():withAutoRecArm(enabled))
end

function Track:triggerChange(message)
    _.forEach(self.listeners, function(listener)
        listener(message)
    end)
    return self
end


function Track:defer()
    self.state = nil
end

function Track:isAux()
    return self:getType() == Track.typeMap.aux
end

function Track:exists()
    return reaper.ValidatePtr2(0, self.track, 'MediaTrack*')
end

function Track:wantsAudioControlls()
    return self:getType() == Track.typeMap.output or self:getType() == Track.typeMap.aux or self:getType() == Track.typeMap.bus
end

function Track:isLA()
    return self:getName() and self:getName():endsWith(':la')
end

function Track:isAudioTrack()
    local instrument = self:getInstrument()
    if instrument and (not instrument:canDoMultiOut() or not instrument:isMultiOut()) then
        return true
    end
end

function Track:isInstrument()
    return self:getType() == Track.typeMap.instrument
end

function Track:isMidiTrack()
    return self:getType() == Track.typeMap.midi
end

function Track:getMidiMaster()
    return _.some(self:getSends(), function(send) return send:getTargetTrack():isInstrument() and send:getTargetTrack() end)
end

function Track:getMetaKey()
    return 'TRACK:'..self.guid..':META'
end

function Track:getMetaData(extra)
    if not self.metaData then
        local res = self:getValue('d3ck', {})
        self.metaData = Collection:create(res)
    end

    return self.metaData
end

function Track:setMetaData(coll)
    self:setValue('d3ck', tostring(coll))
    return track
end

function Track:setMeta(name, value)
    local data = self:getMetaData()
    data[name] = value
    self:setMetaData(data)
    return self
end

function Track:getMeta(name, default)
    local data = self:getMetaData()

    if name == nil then
        return data or default or {}
    end

    if data[name] == nil then
        return default
    end

    return data[name]
end

function Track:isAudioTrack()
    local instrument = self:getInstrument()
    return instrument
end

function Track:isSampler()
    return self:getInstrument() and self:getInstrument():isSampler()
end

function Track:touch()

    local selection = Track.getSelectedTracks()
    self:setSelected(1)
    Track.deferAll()
    reaper.Main_OnCommand(40914, 0) -- set as last touch
    Track.setSelectedTracks(selection, true)

end

function Track:getManager()
    local manager = self:getMeta('managed')
    if manager then
        return Track.trackMap[manager]
    end
end

function Track:focus()
    local instrument = self:getInstrument()
    if instrument and not instrument:canDoMultiOut() then
        if instrument.track:getFx('DrumRack') then
            local DrumRack = require 'DrumRack'
            local fx = DrumRack:create(instrument.track):getFx()
            if fx then
                fx:focus()
            end
        else
            Track.mem:set(0, instrument.track:getIndex())
        end
    else
        Track.mem:set(0, self:getIndex())
    end

    return self
end

function Track:isFocused(slaves)
    return self == Track.getFocusedTrack() or
    (slaves and _.some(self:getManagedTracks(), function(track) return track:isFocused(slaves) end))
end

function Track:isSelected(managed)
    return _.some(Track.getSelectedTracks(), function(track)
        return track == self and true or false
    end) or (managed and _.some(self:getManagedTracks(), function(track)
        return track:isSelected(true)
    end))
end

function Track:choose()
    self:focus()
    self:setSelected(1)
    return self
end

function Track:setSelected(select)
    if select == 1 then
        reaper.SetOnlyTrackSelected(self.track)
        return self
    end

    select = select == nil and true or select
    if select ~= self:isSelected() then
        reaper.SetTrackSelected(self.track, select)
    end
    return self
end

function Track:getPrev()
    return Track.get(self:getIndex()-2)
end

Track.stringMap = {
    name = 'P_NAME',
    icon = 'P_ICON',
    d3ck = 'P_EXT:D3CK',
    guid = 'GUID'
}

Track.valMap = {
    input = 'I_RECINPUT',
    monitor = 'I_RECMON',
    fx = 'I_FXEN',
    chans = 'I_NCHAN',
    height = 'I_HEIGHTOVERRIDE',
    hlock = 'B_HEIGHTLOCK',
    vol = 'D_VOL',
    pan = 'D_PAN',
    arm = 'I_RECARM',
    toParent = 'B_MAINSEND',
    lock = 'C_LOCK',
    tcp = 'B_SHOWINTCP',
    mcp = 'B_SHOWINMIXER',
    mute = 'B_MUTE',
    solo = 'I_SOLO'
}

function Track:getPan()
    return self:getValue('pan')
end

function Track:createUI()
    local type = self:getType()
    if type == Track.typeMap.midi then
        local MidiTrackUI = require 'MidiTrackUI'
        return MidiTrackUI:create(self)
    elseif type == Track.typeMap.instrument or self:getInstrument() then
        if self:getFx((require 'DrumRack').fxName) then
            local DrumRackTrackUI = require 'DrumRackTrackUI'
            return DrumRackTrackUI:create(self)
        else
            local instrument = self:getInstrument()
            return instrument and (require 'InstrumentUI'):create(self)
        end
    elseif self == Track.master then
        return (require 'MasterUI'):create(self)
    else
        return (require 'AudioTrackUI'):create(self)
    end
end

function Track:getInlineUI()
    if self:getType() == Track.typeMap.instrument then
        if self:getInstrument() then
            local DrumRack = require 'DrumRack'
            local drumRack = self:getFx((require 'DrumRack').fxName)
            if drumRack then
                local DrumRackInlineUI = require 'DrumRackInlineUI'
                return DrumRackInlineUI:create(DrumRack:create(self))
            else
                local FXListItem = require 'FXListItem'
                return FXListItem:create(self:getInstrument())
            end
        end
    end
end

function Track:setPan(volume)
    self:setValue('pan', round(math.max(-1, math.min(1,volume)), 100))
end

function Track:isMuted()
    return self:getValue('mute') == 1
end

function Track:setMuted(mute)
    self:setValue('mute', (mute == true or mute == nil) and 1 or 0)
end

function Track:getDefaultName()
    return 'Track ' .. tostring(self:getIndex())
end

function Track:getSafeName()
    return self:getName() or self:getDefaultName()
end

function Track:getName()
    local res, name = reaper.GetTrackName(self.track, '')
    return res and name or nil
end

function Track:setLocked(locked)
    self:setState(self:getState():withLocking(locked))
    return self
end

function Track:getVolume()
    return linToDB(self:getValue('vol'))
end

function Track:setVolume(volume)
    self:setValue('vol', dbToLin(round(volume, 100)))
end

function Track:isLocked()
    return self:getState():isLocked()
end

function Track:getValue(key, default)
    if Track.stringMap[key] then
        local res, val = reaper.GetSetMediaTrackInfo_String(self.track, Track.stringMap[key], '', false)
        return res and val or default
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
    if self:isMidiTrack() then
        return _.some(self:getSends(), function(send) return send:getTargetTrack():getInstrument() end)
    elseif self:getFx('DrumRack') then
        return self:getFx('DrumRack')
    else
        local inst = reaper.TrackFX_GetInstrument(self.track)
        return inst >= 0 and Plugin:create(self, inst) or nil
    end
end

function Track:setManaged(track)
    self:setMeta('managed', track and track.guid)
    return self
end

function Track:isManagedBy(track)
    return track.guid == self:getMeta('managed')
end

function Track:remove(slaves)

    if self:isBus() then
        _.forEach(Track.getAllTracks(), function(track)
            if track:getOutput() == self then
                track:setOutput(self:getOutput())
            end
        end)
    end

    _.forEach(self:getManagedTracks(), function(slave)
        slave:remove(slaves)
    end)

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
    for i = inst and inst:getIndex() + 1 or 0, reaper.TrackFX_GetCount(self.track) - 1 do
        table.insert(res, Plugin:create(self, i))
    end
    return res
end

function Track:getState(live)
    if live or not self.state then
        local success, state = reaper.GetTrackStateChunk(self.track, '', false)
        self.state = TrackState.create(state)
    end
    return self.state
end

function Track:getMidiIn()
    local state = self:getState():__tostring()
    local pattern = 'REC (.-)\n'
    local values = state:match(pattern)

    return values:split(' ')[2]
end

function Track:setMidiIn(value)
    local state = self:getState():__tostring()
    local pattern = 'REC (.-)\n'
    local values = state:match(pattern)

    local valuesArr = values:split(' ')
    valuesArr[2] = value
    local newState = state:gsub(values, _.join(valuesArr, ' '))
    -- rea.log(newState)
    self:setState(newState)

end

function Track:__tostring()
    return self:getSafeName() .. ' :: ' .. tostring(self.track) .. '::' .. (self:getType() or '')
end

function Track:setState(state)
    if type(state) == 'string' then state = TrackState.create(state) end
    self.state = state
    reaper.SetTrackStateChunk(self.track, tostring(state), false)
    return self
end

function Track:removeReceives()
    for i=0,reaper.GetTrackNumSends(self.track, -1) do
        reaper.RemoveTrackSend(self.track, -1, i)
    end
    return self
end

function Track:getNoteNames()
    local all = {}
    for i = 0 , 127 do
        table.insert(all, self:getNoteName(i))
    end
    return all
end

function Track:getNoteName(note)
    local current = reaper.GetTrackMIDINoteNameEx(0,self.track, note, 0)
    return current
end

function Track:setNoteName(note, name)
    local current = self:getNoteName(note)
    if current ~= name then
        reaper.SetTrackMIDINoteNameEx(0,self.track, note, 0, name)

        _.forEach(self:getMidiSlaves(), function(midi)
            midi:setNoteName(note, name)
        end)
    end
end

function Track:clone()

    local tracks = _.concat({self}, self:getManagedTracks())
    local state = _.join(TrackState.fromTracks(tracks), '\n')
    -- rea.log(state)
    return table.unpack(TrackState.fromTemplate(state))

end

function Track:hasMedia()
    return reaper.CountTrackMediaItems(self.track) > 0
end

function Track:updateFxRouting()
    local track = 0
    _.forEach(self:getFxList(), function(fx)
        if fx:getCleanName() == 'Wrap' then
            if track == 0 then track  = track + 1
                fx:setParam(3, 0)
                self:setValue('chans', 4)
            else
                fx:setParam(3, 1)
                track = track -1
            end
        else
            fx:setIO(track, track)
        end

    end)
end

function Track:isBus()
    return self:getType() == Track.typeMap.bus
end

function Track:getLATracks()
    return _.map(self:getSends(), function(send)
        local track = send:getTargetTrack()
        return send:getMode() == 3 and track:getType() == Track.typeMap.la and track or nil
    end)
end

function Track:getMidiSlaves()
    return _.map(self:getReceives(), function(rec)
        if rec:isMidi() and rec:getSourceTrack():getType() == Track.typeMap.midi then
            return rec:getSourceTrack()
        end
    end)
end

function Track:getManagedTracks()
    return _.filter(Track.getAllTracks(), function(track)
        return track:isManagedBy(self)
    end)
end

function Track:canSendTo(otherTrack)
    return not self:receivesFrom(otherTrack) --:receivesFrom()
end

function Track:canDoSideChain()
    return _.some(self:getFxList(), function(fx)
        -- return fx:
    end)
end

function Track:createMidiSlave()

    local slave = Track.insert(self:getIndex())

    slave:setValue('height', 40)
    slave:setValue('hlock', 1)
    slave:addFx('TrackTool')
    slave:setManaged(self)
    slave:setValue('input', 6112)
    slave:setState(slave:getState():withValue('REC', function(values)
        values[7] = 1
    end))
    slave:setType(Track.typeMap.midi)
    slave:setVisibility(true, false)
        :setIcon(self:getIcon() or 'midi.png')
        :setName(self:getName())
        :setColor(colors.midi)
        :createSend(self, true)
            :setAudioIO(-1, -1)

    return slave
end

function Track:getColor()
    local c = reaper.GetTrackColor(self.track)

    local r, g, b = reaper.ColorFromNative(c)

    return c > 0 and color.rgb(r / 255, g / 255, b / 255) or nil
end

function Track:setColor(c)
    reaper.SetTrackColor(self.track, c:native())
    return self
end

function Track:getOutputConnection()
    return _.some(self:getSends(), function(send)
        return send:getType() == 'output' and send
    end)
end

function Track.getMenu(callback, menu, checked)

    assert(type(callback) == 'function')

    if checked and not type(checked) == 'function' then
        checked = function(track)
            return track == checked
        end
    end
    menu = menu or (require 'Menu'):create()

    local Bus = require 'Bus'
    local Aux = require 'AuxTrack'
    local Instrument = require 'Instrument'
    menu:addItem('Bus', Bus.getMenu(callback, nil, checked))
    menu:addItem('Aux', Aux.getMenu(callback, nil, checked))
    menu:addItem('Instrument', Instrument.getMenu(callback, nil, checked))

    -- if checked ~= Track.master then
        menu:addSeperator()
        menu:addItem('master', {
            checked = checked and checked(Track.master),
            callback = function()
                callback(Track.master)
            end
        })
    -- end

    return menu

end

function Track:setOpen(open)
    open = open == nil and true
    reaper.TrackFX_SetOpen(self.track, -1, open)
end

function Track:getOutput()
    local toParent = self:getValue('toParent') > 0
    local output = not toParent and _.some(self:getSends(), function(send)
        return send:getType() == 'output' and send:getTargetTrack()
    end) or nil

    return output
end

function Track:isMultioutRouting()
    return self:getInstrument() and (self:getValue('toParent') == 0) and (not self:getOutputConnection() or self:getOutputConnection():isMuted()) and true or false
end

function Track:setOutput(target, la)

    if la then
        _.forEach(self:getLATracks(), function(la)
            if la:getOutput() == la then
                la:setOutput(target, true)
            end
        end)
    end

    local multiOut = self:isInstrument()--self:isMultioutRouting()
    local current = self:getOutput()
    _.forEach(self:getSends(), function(send)
        local track = send:getTargetTrack()
        if track:getType() == Track.typeMap.output then
            if track:getOutput() == current then
                track:setOutput(target)
            end
        end
    end)

    self:removeSends(Send.isOutput)
    if not target then
        self:setValue('toParent', not multiOut)
    else
        local send = self:createSend(target, true):setType('output')
        send:setMuted(multiOut)
    end

    return self
end

function Track:removeSends(target)
    target = type(target) == 'function' and target or function(send) return send:getTargetTrack() == target end

    _.forEach(self:getSends(), function(send)
        if target(send) then
            send:remove()
            self:removeSends(target)
            return false
        end
    end)
    return self
end

function Track:sendsTo(track)
    return _.some(self:getSends(), function(send)
        return send:getTargetTrack() == track
    end)
end

function Track:createContent(loopstart, loopend)
    local MediaItem = require 'MediaItem'
    -- rea.log({loopstart, loopend})
    local item = reaper.CreateNewMIDIItemInProj(self.track, loopstart, loopend, false)
    return MediaItem:create(item)
end

function Track:getContent()
    local numItems = reaper.CountTrackMediaItems(self.track)
    local MediaItem = require 'MediaItem'
    local res = {}
    for i = 0, numItems -1 do
        table.insert(res, MediaItem:create(reaper.GetTrackMediaItem(self.track, i)))
    end
    return res
end

function Track:getItemsUnderPosition(pos)
    return _.filter(self:getContent(), function(item)
        return item:getPos() <= pos and item:getEnd() > pos
    end, true)
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
    assert(otherTrack)
    return _.some(self:getReceives(), function(rec)
        return rec:getSourceTrack().track == otherTrack.track or
        rec:getSourceTrack():receivesFrom(otherTrack)
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

function Track:getPeakInfo()
    return reaper.Track_GetPeakInfo(self.track, 0),
    reaper.Track_GetPeakInfo(self.track, 1)
end

function Track:getPeakHoldInfo(clear)
    clear = clear and true or false
    return math.max(reaper.Track_GetPeakHoldDB(self.track, 0, clear),
    reaper.Track_GetPeakHoldDB(self.track, 1, clear))
end

function Track:setIcon(name)
    _.forEach(self:getManagedTracks(), function(track)
        if track:getIcon() == self:getIcon() then
            track:setIcon(name)
        end
    end)

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
    _.forEach(self:getManagedTracks(), function(track)
        if track:getName() == self:getName() then
            track:setName(name)
        end
    end)
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
        local input = rea.prompt("name")
        if input then
            name = input
        end
    end
    if not name then return nil end

    local index = reaper.TrackFX_AddByName(self.track, name, rec or false, 0)
    if index >= 0 then
        return Plugin:create(self, index + (rec and 0x1000000 or 0)) or nil
    elseif force then
        return self:addFx(name, rec)
    end
end

function Track:addFx(name, input, force)
    force = force == nil and -1 or force
    if not name then return end
    local res = reaper.TrackFX_AddByName(self.track, name, input or false, force and -1 or 1)
    if res >= 0 then
        if input then
            res = res + 0x1000000
        end
        -- rea.log(res)
        self:updateFxRouting()
        return Plugin:create(self, res, input)
    end
end

function Track:getImage()
    return self:getIcon() or (
        self:getInstrument() and self:getInstrument():getImage()
    ) or _.some(self:getFxList(), function(fx) return fx:getImage()end)
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

function Track:getVisibility()
    return self:getValue('tcp') == 1, self:getValue('mcp') == 1
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
function Track:setIndex(index, mode)

    local tracks = Track.getSelectedTracks()
    Track.setSelectedTracks({self})
    reaper.ReorderSelectedTracks(index, mode or 0)
    Track.setSelectedTracks(tracks)
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
    local plugin = self:getFx('TrackTool')
    if not plugin and force then
        plugin = self:addFx('TrackTool')
        plugin:setIndex(0)
    end
    -- if plugin then plugin:setIndex(0) end
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
