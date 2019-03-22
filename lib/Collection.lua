local _ = require '_'
local Collection = class()

function Collection:create(data)
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

function Collection:__index(key)
    return self.data[key]
end


return Collection