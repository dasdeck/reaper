local Component = require 'Component'
local SequencerLane = require 'SequencerLane'

local rea = require 'rea'
local colors = require 'colors'
local _ = require '_'

local SequenceEditor = class(Component)

function SequenceEditor:create(take, lanes)
    local self = Component:create()
    setmetatable(self, SequenceEditor)
    self.take = take
    self.numSteps = 4
    self.root = 36
    self.ppq = 960
    self.lanes = lanes

    lanes = lanes or _.map({
        36,37,38,39
    }, function(key) return {key = key, take = take} end)

    _.forEach(lanes, function(data)
        self:addChildComponent(SequencerLane:create(data))
    end)

    self.watchers:watch(function() return self:getPlayPos() end, function(value)
        self:repaint()
    end)

    return self
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

function SequenceEditor:getNumTotalSteps()
    return self:getNumBars() * self.numSteps
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