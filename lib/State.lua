local _ = require '_'
local rea = require 'rea'

local State = class()

local cat = 'D3CK'

State.global = {

    set = function(key, value)
        if type(value) == 'table' then
            _.forEach(value, function (value, subkey)
                State.global.set(key .. '_' .. subkey, value)
            end)
        else
            reaper.SetExtState(cat, key, tostring(value), true)
        end
    end,

    get = function(key, default, multi)
        local res = {}
        if multi then
            _.forEach(multi, function(subkey)
                local k = key .. '_' .. subkey
                res[subkey] = State.global.get(k, default and default[subkey] or nil)
            end)
            return res
        else
            return reaper.HasExtState(cat, key) and reaper.GetExtState(cat, key) or default
        end
    end
}

function State:create(scope)
    local self = {}
    self.scope = scope
    setmetatable(self, State)
    return self
end

function State:set(key, value)
    State.global.set(self.scope .. '_' .. key, value)
end

function State:get(key, default)
    return State.global.get(self.scope .. '_' .. key, default)
end

return State