local PCMSource = require 'PCMSource'
local Take = class()


function Take:create(take)
    local self = {
        take = take
    }
    setmetatable(self, Take)
    return self
end

function Take:getPCMSource()
    return PCMSource:create(reaper.GetMediaItemTake_Source(self.take))
end

function Take:getFile()
    return self:getPCMSource():getFile()
end

return Take