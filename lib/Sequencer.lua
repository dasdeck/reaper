local Component = require 'Component'
local Sequencer = class(Component)

function Sequencer:create()
    local self = Component:create()
    setmetatable(self, Sequencer)
    return self
end

return Sequencer