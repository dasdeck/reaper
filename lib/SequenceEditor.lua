local Component = require 'Component'
local SequencerLane = require 'SequencerLane'
local EmptyLane = require 'EmptyLane'
local rea = require 'rea'
local colors = require 'colors'
local _ = require '_'

local SequenceEditor = class(Component)

function SequenceEditor:create(lanes)
    local self = Component:create()
    setmetatable(self, SequenceEditor)
    -- self.take = take
    self.numSteps = 4
    self.root = 36
    self.ppq = 960
    self.lanes = lanes


    lanes = (_.size(lanes) > 0) and lanes  or _.map({
        36,37,38,39
    }, function(key) return {key = key, track = track} end)

    if lanes then
        _.forEach(lanes, function(data)
            self:addChildComponent(SequencerLane:create(data))
        end)
    end

    self:addChildComponent(EmptyLane:create(self))

    self.watchers:watch(function() return self:getPlayPos() end, function(value)
        self:repaint()
    end)

    return self
end

function SequenceEditor:getPPS()
    return self.ppq / self:getNumSteps()
end

function SequenceEditor:getNumBars()
    if self.take then
        return self.take:getSource():getLength()
    else
        local loopstart, loopend = self:getRange()
        local len = loopend - loopstart
        return len
    end
end

function SequenceEditor:getRange(time)
    local s, e = reaper.GetSet_LoopTimeRange(false, false, 0 , 0, false)
    if not time then
        local res, st = reaper.TimeMap2_timeToBeats(0, s)
        local res, se = reaper.TimeMap2_timeToBeats(0, e)
        return st * 4, se * 4
    else
        return s, e
    end
end

function SequenceEditor:getPlayPos()
    return reaper.GetPlayState() > 0 and reaper.GetPlayPosition2() or reaper.GetCursorPosition()
end

function SequenceEditor:getNumSteps()
    return self.numSteps
end

function SequenceEditor:getOffset()
    return self:getRange() * self.ppq
end


function SequenceEditor:getNumTotalSteps()
    return self:getNumBars() * self.numSteps
end

function SequenceEditor:getTakes()
    local Track = require 'Track'
    local items = {}
    _.forEach(self:getAbsoluteSteps(), function (step)
        local bpos = step / self.ppq
        local time = reaper.TimeMap2_beatsToTime(0, bpos)-- + loopstart
        local item = _.first(_.first(Track.getAllTracks()):getItemsUnderPosition(time))
        if not _.find(items, item) then
            table.insert(items, item)
        end
    end)
    return items
end

function SequenceEditor:getNotes()
    local positions = {}
    _.forEach(self:getTakes(), function (item)
        local offset = reaper.TimeMap2_timeToQN(0, item:getPos() ) * self.ppq
        local take = item:getActiveTake()
        _.forEach(take:getNotes(), function( note )
            table.insert(positions, note.startppqpos + offset)
        end)
    end)
    return positions
end
        -- body
function SequenceEditor:getAbsoluteSteps()
    local positions = {}
    local total = self:getNumTotalSteps()
    for step = 1, total do
        positions[step] = (step-1) * self:getPPS() + self:getOffset()
    end
    return positions
end

function SequenceEditor:resized()
    local h = self.h / _.size(self.children)

    _.forEach(self.children, function(child, i)
        child:setBounds(0, h * (i-1), self.w, h)
    end)
end

function SequenceEditor:paintOverChildren(g)

    local loopstart, loopend = reaper.GetSet_LoopTimeRange(false, false, 0 , 0, false)
    local len = loopend - loopstart
    local pos = (self:getPlayPos() - loopstart) / len * self.w

    local stepSize = self.w / self:getNumTotalSteps()
    g:setColor(1,0,0,1)
    g:rect(pos, 0, stepSize, self.h)

end

return SequenceEditor