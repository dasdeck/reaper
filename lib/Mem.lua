
local rea = require 'rea'
local Mem = class()
local Watcher = require 'Watcher'
Mem.current = nil

function Mem.refreshConnection(name)
    assert(name)
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
    return reaper.gmem_read(index or 0)
end

function Mem:create(name)
    assert(name)
    local self = {name = name}
    setmetatable(self, Mem)
    return self
end

function Mem:get(index)
    return Mem.read(self.name, index)
end

function Mem:set(index, value)
    return Mem.write(self.name, index, value)
end

return Mem