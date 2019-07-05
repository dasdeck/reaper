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

    self.track = data.track
    -- rea.log(data)
    self.header = self:addChildComponent(Label:create(tostring(data.key)))
    self.header.onDblClick = function()
        if self.track and self.track:getInstrument() then
            self.track:getInstrument():open(true)
        end
    end

    local msg1 = '0x9'..string.format("%x", 0)

    self.header.onMouseDown = function(self, mouse)

        reaper.StuffMIDIMessage(0, msg1, data.key, math.floor(mouse.x / self.w * 127))
    end

    self.header.onMouseUp = function()
        reaper.StuffMIDIMessage(0, msg1, data.key, 0)
    end

    self.editor = self:addChildComponent(SequencerLaneEditor:create(data))

    return self
end

function SequencerLane:resized()

    self.header:setBounds(0,0,self.h,self.h)
    self.editor:setBounds(self.h, 0, self.w - self.h, self.h)

end

return SequencerLane