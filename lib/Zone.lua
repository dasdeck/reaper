local Component = require 'Component'
local rea = require 'rea'


local Zone = class(Component)

function Zone.create(track)
    local self = Component:create()
    setmetatable(self, Zone)
    self.track = track
    return self
end

function Zone:canClickThrough()
    return false
end

function Zone:onClick(mouse)
    if mouse:isAltKeyDown() then
        rea.transaction('remove zone',function()
            self.track:remove()
        end)
    end
end

function Zone:setKey(key)
    local range = self.track:getFx('midi_note_filter', false, true)

    range:setParam(0, key)
    range:setParam(1, key)
end

function Zone:paint(g)
    g:setColor(1,0,0,1)
    g:rect(0,0,self.w,self.h)
end

function Zone:onDrag()
    Component.dragging = self
end


return Zone