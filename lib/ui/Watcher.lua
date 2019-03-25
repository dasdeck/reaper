local _ = require '_'

local Watcher = class()
local rea = require 'rea'

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
    rea.logCount('watcher')
    setmetatable(self, Watcher)
    table.insert(Watcher.watchers, self)

    return self
end

function Watcher:close()
    rea.logCount('watcher', -1)
    rea.logCount('watch', -#self.listeners)

    _.removeValue(Watcher.watchers, self)
    self.listeners = {}
end

function Watcher:onChange(listener)
    rea.logCount('watch')
    table.insert(self.listeners, listener)
    return function()
        self:removeListener(listener)
    end
end

function Watcher:removeListener(listener)
    -- rea.logCount('watch', -1)

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