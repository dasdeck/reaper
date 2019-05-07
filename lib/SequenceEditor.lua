    local Component = require 'Component'
local ButtonList = require 'ButtonList'

local rea = require 'rea'
local colors = require 'colors'
local _ = require '_'

local SequenceEditor = class(Component)

function SequenceEditor:create(take)
    local self = Component:create()
    setmetatable(self, SequenceEditor)
    self.take = take
    self.numSteps = 4
    self.root = 36
    self.ppq = 960

    self.lanes = {
        36,37,38,39
    }

    return self
end

function SequenceEditor:getNumBars()
    return self.take:getSource():getLength()
end

function SequenceEditor:getNumLanes()
    return _.size(self:getLanes())
end

function SequenceEditor:getLanes()
    if self.lanes then
        return self.lanes
    end
end

function SequenceEditor:getNumSteps()
    return self.take:getSource():getLength() * self.numSteps
end

function SequenceEditor:getPPS()
    return self.ppq / self.numSteps
end

function SequenceEditor:getNote(pos, lane)
    local pitch = self:getLanes()[lane]
    return _.find(self.take:getNotes(), function(note)
        return note.startppqpos == pos and note.pitch == pitch
    end)
end

function SequenceEditor:getNotes()
    local notes = self.take:getNotes()
    local notesCache = {}
    for lane=1, self:getNumLanes() do
        local pitch = self:getLanes()[lane]
        for step=1, self:getNumSteps() do
            local ppqpos = (step-1) * self:getPPS()
            notesCache[lane] = notesCache[lane] or {}
            notesCache[lane][step] = _.find(notes, function(note)
                return note.startppqpos == ppqpos and note.pitch == pitch
            end)
        end
    end
    return notesCache
end

function SequenceEditor:getPos(x)
    local relx = x / self.w
    local step = math.floor(self:getNumSteps() * relx)
    local ppqpos = step * self:getPPS()

    return ppqpos

end

function SequenceEditor:changeStep(pos, velo, note)
    note = note or self:getNote(pos, self.lane)
    velo = velo or self:getVelo()
    local pitch = self:getLanes()[self.lane]
    if self.add then
        if not note then
            self.changed = true
            reaper.MIDI_InsertNote(self.take.take, false,false, pos, pos + 1, 1, pitch, velo, false)
        elseif note.vel ~= velo then
            self.changed = true
            reaper.MIDI_SetNote(self.take.take, note.index, false, false, pos, pos+1, 1, pitch, velo, false)
        end
        self:repaint()
    elseif note then
        self.changed = true
        reaper.MIDI_DeleteNote(self.take.take, note.index)
        self:repaint()
    end
end

function SequenceEditor:getVelo()
    if not self.mouse:isShiftKeyDown() then
        local numLanes = self:getNumLanes()
        local laneY = self.h - self.lane / numLanes * self.h
        local laneH = self.h / numLanes
        local vel = math.max(0, math.min(1, (self.mouse.y - laneY) / laneH))
        return math.floor(127 * (1-vel))
    else
        return 127
    end
end

function SequenceEditor:onDrag(mouse)
    self:changeStep(self:getPos(mouse.x))
end

function SequenceEditor:mouseUp()
    if self.changed then
        reaper.Undo_EndBlock('change sequence', -1)
    end
end

function SequenceEditor:onMouseDown(mouse)
    local pos = self:getPos(self.mouse.x)
    local numLanes = self:getNumLanes()
    self.lane = math.floor((self.h - self.mouse.y) / self.h * numLanes) + 1

    local note = self:getNote(pos, self.lane)

    reaper.Undo_BeginBlock()
    self.changed = false

    self.add = mouse:isLeftButtonDown()
    self:changeStep(pos, nil, note)

end

function SequenceEditor:paint(g)
    local num = self:getNumBars()
    local w = self.w / num
    local numLanes = self:getNumLanes()

    if numLanes > 0 then
        g:setColor(colors.default:with_alpha(0.4))

        for i = 0 , num -1 do
            if i % 2 == 0 then
                g:rect(i * w, 0, w, self.h, true)
            end
        end

        local h = self.h / numLanes

        local laneDiv = math.floor(numLanes ^ 0.5)

        if laneDiv > 1 then
            local divH = h  * laneDiv
            g:setColor(colors.default:with_alpha(0.2))
            for i = 0 , numLanes -1 do
                if i % laneDiv == 0 then
                    g:rect(0, i*divH, self.w, divH , true)
                end
            end
        end

        g:setColor(colors.default:with_alpha(0.1))
        num = self:getNumSteps()
        w = self.w / num
        for i = 0, num -1 do
            if i % 2 == 0 then
                g:rect(w * i, 0, w, self.h, false)
            end
        end

        h = self.h / numLanes

        for i = 0 , numLanes do
            g:rect(0,i*h, self.w, h)
        end

        local notes = self:getNotes()
        g:setColor(colors.mute:with_alpha(0.5))
        for l = 1 , numLanes do

            for i = 0, num -1 do
                local pos = i * self:getPPS()
                -- local note = self:getNote(pos, l)
                local note = notes[l][i+1] --{vel = math.random(127)}
                if note then
                    local h2 = math.floor(note.vel / 127 * h)
                    g:rect(w*i, self.h - l*h + (h-h2) , w,h2, true)
                end
            end
        end
    end
end

return SequenceEditor