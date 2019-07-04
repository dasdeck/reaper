local Component = require 'Component'

local rea = require 'rea'
local colors = require 'colors'
local _ = require '_'

local EmptyLane = class(Component)

function EmptyLane:create(sequencer)

    local self = Component:create()
    setmetatable(self, EmptyLane)

    self.sequencer = sequencer

    return self
end

function EmptyLane:onFilesDrop(files)

end

function EmptyLane:paint(g)
    local s = 0.2
    g:setColor(s,s,s,1)
    g:rect(0,0,self.w,self.h,true)
end

return EmptyLane