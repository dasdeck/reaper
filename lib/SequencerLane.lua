local Component = require 'Component'
local SequencerLaneEditor = require 'SequencerLaneEditor'
local Label = require 'Label'

local rea = require 'rea'
local colors = require 'colors'
local _ = require '_'

local SequencerLane = class(Component)

function SequencerLane:create(data)

    local self = Component:create()
    setmetatable(self, SequencerLane)

    -- rea.log(data)
    self.header = self:addChildComponent(Label:create(tostring(data.key)))
    self.editor = self:addChildComponent(SequencerLaneEditor:create(data))

    return self
end

function SequencerLane:resized()

    self.header:setBounds(0,0,self.h,self.h)
    self.editor:setBounds(self.h, 0, self.w - self.h, self.h)

end

return SequencerLane