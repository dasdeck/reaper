
local Mem = class()
local Watcher = require 'Watcher'
Mem.current = nil

function Mem.refreshConnection(name)

    if Mem.current ~= name then
        reaper.gmem_attach(name)
        Mem.current = name
    end
end

function Mem.write(name, index, value)
    Mem.refreshConnection(name)
    reaper.gmem_write(index, value)
end

function Mem.read(name, index)
    Mem.refreshConnection(name)
    return reaper.gmem_read(index)
end

return Mem