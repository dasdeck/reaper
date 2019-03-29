local _ = require '_'
local json = require 'json'
local rea = require 'rea'

local Collection = class()

function Collection:create(data)
    if type(data) == 'string' then
        data = json.decode(data) or {}
    end

    local self = {
        data = data
    }
    setmetatable(self, Collection)
    return self
end

function Collection:__eq(other)
    return _.equal(self.data, other.data)
end

function Collection:__len()
    return #self.data
end

function Collection:__pairs()
    return pairs(self.data)
end

function Collection:__ipairs()
    return ipairs(self.data)
end

function Collection:map(call)
    return Collection:create(_.map(self.data, call))
end

function Collection:__newindex(key, value)
    self.data[key] = value
end

function Collection:__index(key)
    return Collection[key] and Collection[key] or key == 'data' and self.data or self.data[key]
end

function Collection:get(key)
    return self.data[key]
end

function Collection:set(key, value)
    self.data[key] = value
    return self
end

function Collection:__tostring()
    return json.encode(self.data)
end

return Collection