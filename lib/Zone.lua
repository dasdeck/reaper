local Component = require 'Component'
local rea = require 'rea'
local _ = require '_'

local Zone = class(Component)

function Zone.create(track)
    local self = Component:create()
    setmetatable(self, Zone)
    self.track = track
    self.range = track:getFx('midi_note_filter', false, true)

    return self.range and self or nil
end

function Zone:canClickThrough()
    return false
end

function Zone:onClick(mouse)
    if mouse:isAltKeyDown() then
        rea.transaction('remove zone',function()
            self.track:remove()
        end)
    else
        rea.transaction('select zone', function()
            self.track:setSelected(1)
        end)
    end
end

function Zone:getKey()
    return self.range:getParam(0)
end

function Zone:setKey(key)
    local from = self.range:getParam(0)
    self.range:setParam(0, key)
    self.range:setParam(1, key)

    _.forEach(self.track:getContent(), function(item)
        _.forEach(item:getTakes(), function(take)
            take:flipNotes(from, key)
        end)
    end)

end

function Zone:paint(g)
    g:setColor(1,0,0,1)
    g:rect(0,0,self.w,self.h, self.track:isSelected())
end

function Zone:onDrag()
    Component.dragging = self
end


return Zone