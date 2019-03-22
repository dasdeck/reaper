local _ = require '_'
local rea = require 'Reaper'

local State = {}
local cat = 'D3CK'


State.global = {

    set = function(key, value)
        if type(value) == 'table' then
            _.forEach(value, function (value, subkey)
                reaper.SetExtState(cat, key .. '_' .. subkey, value, true)
            end)
        else
            reaper.SetExtState(cat, key, value, true)
        end
    end,

    get = function(key, default, multi)
        default = default or {}
        if multi then
            _.forEach(multi, function(subkey)
                local k = key .. '_' .. subkey
                default[subkey] = State.global.get(k, default[subkey])
            end)
            return default
        else
            return reaper.HasExtState(cat, key) and reaper.GetExtState(cat, key) or default
        end
    end
}

return State