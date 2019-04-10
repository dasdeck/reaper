local Component = require 'Component'

local MixerChannel = class(Component)

function MixerChannel:create()
    local self = Component:create()
    setmetatable(self, MixerChannel)
    return self
end

return MixerChannel