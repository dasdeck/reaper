local PCMSource = class()


function PCMSource:create(pcm)
    local self = {
        pcm = pcm
    }
    setmetatable(self, PCMSource)
    return self
end

function PCMSource:getFile()
    return reaper.GetMediaSourceFileName(self.pcm, '')
end

function PCMSource:getLen()
end

return PCMSource