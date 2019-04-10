local Component = require 'Component'
local MixerChannel = require 'MixerChannel'

local Mixer = class(Component)

function Mixer:create()
    local self = Component:create()
    setmetatable(self, Mixer)
    return self
end


return Mixer