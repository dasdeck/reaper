local PCMSource = require 'PCMSource'
local rea = require 'rea'
local Take = class()


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

function Take:remove()
    local tmp = not self:isActive() and reaper.GetActiveTake(self.item.item)
    self:setActive()
    reaper.Main_OnCommand(40129, 0)
    if tmp then
        -- rea.log(tmp)
        Take:create(tmp, self.item):setActive()
    end
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