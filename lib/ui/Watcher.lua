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
    setmetatable(self, Watcher)
    table.insert(Watcher.watchers, self)

    return self
end

function Watcher:close()

    _.removeValue(Watcher.watchers, self)
    self.listeners = {}
end

function Watcher:onChange(listener)
    table.insert(self.listeners, listener)
    return function()
        self:removeListener(listener)
    end
end

function Watcher:removeListener(listener)
    _.removeValue(self.listeners, listener)
end

function Watcher:defer()
    if #self.listeners > 0 then
        local newValue = self.callback()

        if self.lastValue ~= newValue then
            self.lastValue = newValue
            _.forEach(self.listeners, function(listener)
                listener(newValue)
            end)
        end
    end
end





return Watcher