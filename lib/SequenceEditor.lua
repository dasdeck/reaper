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
    self.numLanes = 16
    self.laneDiv = 4
    self.root = 36
    self.ppq = 960
    return self
end

function SequenceEditor:getNumBars()
    return self.take:getSource():getLength()
end

function SequenceEditor:getLanes()
    if self.lanes then
        return self.lanes
    else
    end
        -- local lanes =
end

function SequenceEditor:getNumSteps()
    return self.take:getSource():getLength() * self.numSteps
end

function SequenceEditor:getPPS()
    return self.ppq / self.numSteps
end

function SequenceEditor:getNote(pos, lane)
    return _.find(self.take:getNotes(), function(note)
        return note.startppqpos == pos and note.pitch == lane
    end)
end

function SequenceEditor:getPos(x)
    local relx = x / self.w
    local step = math.floor(self:getNumSteps() * relx)
    local ppqpos = step * self:getPPS()

    return ppqpos

end

function SequenceEditor:changeStep(pos, note)
    note = note or self:getNote(pos, self.lane)
    if self.add then
        if not note then

            reaper.MIDI_InsertNote(self.take.take, false,false, pos, pos + 1, 1, self.lane, 127, false)
            self:repaint()
        end
    elseif note then
        reaper.MIDI_DeleteNote(self.take.take, note.index)
        self:repaint()
    end
end

function SequenceEditor:onDrag(mouse)
    self:changeStep(self:getPos(mouse.x))
end

function SequenceEditor:onMouseDown(mouse)
    local pos = self:getPos(self.mouse.x)
    self.lane = math.floor((self.h - self.mouse.y) / self.h * self.numLanes) + self.root
    -- rea.log(self.lane)
    local note = self:getNote(pos, self.lane)

    self.add = not note
    self:changeStep(pos, note)

end

function SequenceEditor:paint(g)
    local num = self:getNumBars()
    local w = self.w / num
    local h = self.h / self.laneDiv

    g:setColor(colors.default:with_alpha(0.4))

    for i = 0 , num -1 do
        if i % 2 == 0 then
            g:rect(i * w, 0, w, self.h, true)
        end
    end

    g:setColor(colors.default:with_alpha(0.2))
    for i = 0 , self.laneDiv -1 do
        if i % 2 == 0 then
            g:rect(0, i*h, self.w, h , true)
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

    h = self.h / self.numLanes

    for i = 0 , self.numLanes do
        g:rect(0,i*h, self.w, h)
    end

    g:setColor(colors.mute:with_alpha(0.5))
    for l = 1 , self.numLanes do
        for i = 0, num -1 do
            local pos = i * self:getPPS()
            if self:getNote(pos, l - 1 + self.root) then
                g:rect(w*i, self.h - l*h , w,h, true)
            end
        end
    end
end

return SequenceEditor