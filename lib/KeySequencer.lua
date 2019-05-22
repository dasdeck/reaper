local Component = require 'Component'
local Keyboard = require 'Keyboard'
local Sequencer = require 'Sequencer'

local KeySequencer = class(Component)

function KeySequencer:create()

    local self = Component:create()
    setmetatable(self, KeySequencer)

    self.keyboard = self:addChildComponent(Keyboard.create(36, 48, true))
    self.sequencer = self:addChildComponent(Sequencer:create())

    return self

end

function KeySequencer:resized()
    self.keyboard:setBounds(0, 0, 300, self.h)
    self.sequencer:setBounds(300, 0, self.w - 300, self.h)
end

return KeySequencer