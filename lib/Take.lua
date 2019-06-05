local PCMSource = require 'PCMSource'
local rea = require 'rea'
local Take = class()
local _ = require '_'

function Take:create(take, item)

    local self = {
        item = item,
        take = take
    }
    setmetatable(self, Take)
    return self
end

function Take:getSource()
    return PCMSource:create(reaper.GetMediaItemTake_Source(self.take))
end

function Take:isActive()
    return reaper.GetActiveTake(self.item.item) == self.take
end

function Take:setActive()
    reaper.SetActiveTake(self.take)
    rea.refreshUI()
end

function Take:setPlayRate(strech)
    reaper.SetMediaItemTakeInfo_Value(self.take,"D_PLAYRATE",strech)
end

function Take:remove()
    local tmp = not self:isActive() and reaper.GetActiveTake(self.item.item)
    self:setActive()
    reaper.Main_OnCommand(40129, 0)
    if tmp then
        -- rea.log(tmp)
        Take:create(tmp, self.item):setActive()
    end
end

function Take:flipNotes(from, to)
    local a = _.filter(self:getNotes(), function(note)
        return note.pitch == from
    end)
    local b = _.filter(self:getNotes(), function(note)
        return note.pitch == to
    end)

    _.forEach(a, function(note)
        note.pitch = to
        self:writeNote(note)
    end)
    _.forEach(b, function(note)
        note.pitch = from
        self:writeNote(note)
    end)
end

function Take:writeNote(note)
    reaper.MIDI_SetNote(self.take, note.index, false, false, note.startppqpos, note.endppqpos, 1, note.pitch, note.vel, false)
end

function Take:getNotes()

    local notes = {}
    local i = 0
    while true do
        local suc, sel, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(self.take, i)
        if not suc then return notes end
        table.insert(notes, {
            index = i,
            pitch = pitch,
            vel = vel,
            startppqpos = startppqpos,
            endppqpos = endppqpos
        })
        i = i + 1
    end

end

function Take:__eq(other)
    return self.take == other.take
end

function Take:getFile()
    return self:getSource():getFile()
end


return Take