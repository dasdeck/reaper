local Collection = require 'Collection'

local Send = class()

function Send:create(track, index, cat)
    local self = {
        track = track,
        index = index,
        cat = cat == nil and 0 or cat
    }
    setmetatable(self, Send)
    return self
end

function Send:remove()
    reaper.RemoveTrackSend(self.track, self.cat, self.index)
end

function Send:getMedaData()
    local suc, res = reaper.GetSetTrackSendInfo_String(self.track, self.cat, self.index, 'P_EXT:D3CK','', false)
    res = suc and res or {}
    return Collection:create(res)
end
function Send:setMedaData(coll)
    reaper.GetSetTrackSendInfo_String(self.track, self.cat, self.index, 'P_EXT:D3CK', tostring(coll), true)
end

function Send:setType(type)
    local coll = self:getMedaData()
    coll.type = type
    self:setMedaData(coll)
    return self
end

function Send:getType()
    return self:getMedaData().type
end

function Send:isOutput()
    local Track = require 'Track'
    return self:getType() == Track.typeMap.output
end

function Send:getSourceTrack()
    local Track = require 'Track'
    local source = reaper.BR_GetMediaTrackSendInfo_Track(self.track, self.cat, self.index, 0)
    return Track:create(source)
end

function Send:getMidiSourceChannel()
    return reaper.GetTrackSendInfo_Value(self.track, self.cat, self.index, 'I_MIDIFLAGS') & 0xff;
end

function Send:getMidiSourceBus()
    return reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'I_MIDI_SRCBUS', false, 0)
end

function Send:getMidiTargetBus()
    return reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'I_MIDI_DSTBUS', false, 0)
end

function Send:getMidiBusses()
    return self:getMidiSourceBus(), self:getMidiTargetBus()
end

function Send:setAudioIO(i, o)

    reaper.SetTrackSendInfo_Value(self.track, self.cat, self.index, "I_SRCCHAN", i or -1)
    reaper.SetTrackSendInfo_Value(self.track, self.cat, self.index, "I_DSTCHAN", o or -1)
    return self
end

function Send:getAudioIO()

    local src = reaper.GetTrackSendInfo_Value(self.track, self.cat, self.index, "I_SRCCHAN", i or -1)
    local dest = reaper.GetTrackSendInfo_Value(self.track, self.cat, self.index, "I_DSTCHAN", o or -1)
    return src, dest
end

function Send:setMuted(muted)
    reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'B_MUTE', true, (muted == nil and 1) or (muted and 1 or 0))
    return self
end

function Send:isMuted()
    return reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'B_MUTE', false, 0) > 0
end

function Send:getVolume()
    return reaper.GetTrackSendInfo_Value(self.track, self.cat, self.index, 'D_VOL')
end

function Send:setVolume(gain)
    reaper.SetTrackSendInfo_Value(self.track, self.cat, self.index, 'D_VOL', gain)
end

function Send:isAudio()
    return self:getAudioIO() ~= -1
end

function Send:setMode(mode)
    reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'I_SENDMODE', true, mode)
    return self
end

function Send:getMode()
    return reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'I_SENDMODE', false, 0)
end

function Send:isBusSend()
    local i , o = self:getAudioIO()
    return i == 0 and o == 0 and self:getMode() == 0
end

function Send:isPreFaderSend()
    return reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'I_SENDMODE', false, 0) == 3
end

function Send:isMidi()
    return self:getMidiBusses() ~= -1
end

function Send:setMidiBusIO(i, o)

    reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'I_MIDI_SRCBUS', true, i)
    reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'I_MIDI_DSTBUS', true, o)
    return self
end

function Send:setSourceMidiChannel(channel)

    local MIDIflags = reaper.GetTrackSendInfo_Value(self.track, self.cat, self.index, 'I_MIDIFLAGS') & 0xFFFFFF00 | channel
    reaper.SetTrackSendInfo_Value(self.track, self.cat, self.index, "I_MIDIFLAGS", MIDIflags)
    return self
end

function Send:getTargetTrack()
    local Track = require 'Track'
    local target = reaper.BR_GetMediaTrackSendInfo_Track(self.track, self.cat, self.index, 1)
    return Track:create(target)
end

return Send