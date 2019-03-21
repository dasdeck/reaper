local _ = require '_'

local Watcher = class()
local rea = require 'Reaper'

Watcher.watchers = {}

function Watcher.deferAll()
    _.forEach(Watcher.watchers, function(watcher)
        watcher:defer()
    end)
end

function Watcher:create(callback)
    local self = {
        listeners = {},
        lastValue = nil,
        callback = callback
    }

    -- rea.log('create')
    setmetatable(self, Watcher)
    table.insert(Watcher.watchers, self)

    return self
end

function Watcher:close()
    _.removeValue(Watcher.watchers, self)
end

function Watcher:onChange(listener)
    table.insert(self.listeners, listener)
end

function Watcher:removeListener(listener)
    _.removeValue(self.listeners, listener)
end

function Watcher:defer()
    local newValue = self.callback()
    if #self.listeners > 0 and self.lastValue ~= newValue then
        self.lastValue = newValue
        _.forEach(self.listeners, function(listener)
            listener(newValue)
        end)
    end
end





return Watcher