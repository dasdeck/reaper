 local Component = require 'Component'

local rea = require 'rea'
local colors = require 'colors'
local _ = require '_'

local SequencerLane = class(Component)

function SequencerLane:create(data)

    assert(data.key and (data.take or data.track))

    local self = Component:create()
    setmetatable(self, SequencerLane)

    self.take = data.take
    self.note = data.key
    self.track = data.track

    self.ppq = 960

    return self
end

function SequencerLane:getNumBars()
    return self.parent:getNumBars()
end

function SequencerLane:getRange(time)
    return self.parent:getRange(time)
end


function SequencerLane:getNumTotalSteps()
    return self.parent:getNumTotalSteps()
end

function SequencerLane:getPPS()
    return self.ppq / self.parent:getNumSteps()
end

function SequencerLane:getNote(pos)
    local take = self:getTake(pos)
    if take then
        return _.find(take:getNotes(), function(note)
            return note.startppqpos == pos and note.pitch == self.note
        end)
    end
end

function SequencerLane:getNotes(offsetIn)
    local notesCache = {}
    offsetIn = offsetIn or 0

    for step = 1, self:getNumTotalSteps() do
        local ppqpos = (step-1) * self:getPPS()
        local take = self:getTake(ppqpos)
        if take then
            local offset = offsetIn + reaper.TimeMap2_timeToQN(0, take.item:getPos() ) * self.ppq
            ppqpos = ppqpos - offset
            local note = _.find(take:getNotes(), function(note)
                return note.startppqpos == ppqpos and note.pitch == self.note
            end)
            if note then
                note.startppqpos = note.startppqpos + offset
                notesCache[step] = note
            end
        end
    end
    return notesCache
end

function SequencerLane:getPos(x)
    local relx = x / self.w
    local step = math.floor(self:getNumTotalSteps() * relx)
    local ppqpos = step * self:getPPS()
    local off = self.parent:getRange() * self.ppq
    return ppqpos + off
end

function SequencerLane:getTake(pos, create)

    local loopstart, loopend = self:getRange(true)
    local time = reaper.TimeMap2_beatsToTime(0, pos / self.ppq) + loopstart
    if not self.take then
        local items = self.track:getItemsUnderPosition(time)
        local item = _.first(self.track:getItemsUnderPosition(time))
        if item then
            return item:getActiveTake()
        elseif create then

            _.forEach(self.track:getContent(), function(item)
                local e = item:getEnd()
                local p = item:getPos()

                if e > loopstart and e <= time then
                    loopstart = e
                elseif p > time and p < loopend then
                    loopend = p
                end

            end)
            local item = self.track:createContent(loopstart, loopend)
            return item:getActiveTake()
        end

    else
        return self.take
    end

end

function SequencerLane:changeStep(pos)
    local note = self:getNote(pos)

    if self.add then
        local velo = self:getVelo()
        if not note then
            local take = self:getTake(pos, true)
            local offset = reaper.TimeMap2_timeToQN(0, take.item:getPos() ) * self.ppq
            pos = pos - offset
            reaper.MIDI_InsertNote(take.take, false,false, pos, pos + 1, 1, self.note, velo, false)
            self.changed = true
        elseif note.vel ~= velo then
            reaper.MIDI_SetNote(note.take.take, note.index, false, false, note.startppqpos, note.endppqpos, 1, note.pitch, velo, false)
            self.changed = true
        end
        self:repaint()
    elseif note then
        -- rea.log('remove')
        reaper.MIDI_DeleteNote(note.take.take, note.index)
        self:repaint()
        self.changed = true
    end
end

function SequencerLane:getVelo()
    if self.mouse:isShiftKeyDown() then
        local laneH = self.h
        local vel = math.max(0, math.min(1, (self.mouse.y) / laneH))
        return math.floor(127 * (1-vel))
    else
        return 127
    end
end

function SequencerLane:onDrag(mouse)
    self:changeStep(self:getPos(self.mouse.x))
end

function SequencerLane:mouseUp()
    if self.changed then
        reaper.Undo_EndBlock('change sequence', -1)
    end
end

function SequencerLane:onMouseDown(mouse)
    local pos = self:getPos(self.mouse.x)

    reaper.Undo_BeginBlock()
    self.changed = false

    self.add = mouse:isLeftButtonDown() and not mouse:isAltKeyDown()
    self:changeStep(pos)

end

function SequencerLane:paint(g)
    local num = self:getNumBars()
    local w = self.w / num
    local numLanes = 1

    if numLanes > 0 then
        g:setColor(colors.default:with_alpha(0.4))

        for i = 0 , num -1 do
            if i % 2 == 0 then
                g:rect(i * w, 0, w, self.h, true)
            end
        end

        local h = self.h

        local laneDiv = math.floor(numLanes ^ 0.5)

        if laneDiv > 1 then
            local divH = h  * laneDiv
            g:setColor(colors.default:with_alpha(0.2))
            if self.note % laneDiv == 0 then
                g:rect(0, i*divH, self.w, divH , true)
            end
        end

        g:setColor(colors.default:with_alpha(0.1))
        num = self:getNumTotalSteps()
        w = self.w / num
        for i = 0, num -1 do
            if i % 2 == 0 then
                g:rect(w * i, 0, w, self.h, false)
            end
        end

        h = self.h

        g:rect(0,0, self.w, self.h)

        local notes = self:getNotes(- self.parent:getRange() * self.ppq)
        -- rea.log(notes)
        g:setColor(colors.mute:with_alpha(0.5))
        for i = 0, num -1 do

            local note = notes[i+1]
            if note then
                local h2 = math.floor(note.vel / 127 * h)
                g:rect(w*i, self.h - h + (h-h2) , w,h2, true)
            end
        end
    end
end

return SequencerLane