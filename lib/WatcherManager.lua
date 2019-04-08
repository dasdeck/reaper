local Watcher = require 'Watcher'
local _ = require '_'

local WatcherManager = class()

function WatcherManager:create()
    local self = {
        offs = {},
        watchers = {}
    }
    setmetatable(self, WatcherManager)
    return self
end

function WatcherManager:watch(watcher, callback, onstart)

    if getmetatable(watcher) ~= Watcher then
        watcher = Watcher:create(watcher, onstart)
        table.insert(self.watchers, watcher)
    elseif onstart == false then
        local use = false
        local origCallback = callback
        callback = function(...)
            if use then return origCallback(...) end
            use = true
        end
    end



    table.insert(self.offs, watcher:onChange(callback))
end

function WatcherManager:clear()
    _.forEach(self.offs, function(off) off() end)
    _.forEach(self.watchers, function(watcher) watcher:close() end)
end


function WatcherManager:__gc()
    self:clear()
end

return WatcherManager