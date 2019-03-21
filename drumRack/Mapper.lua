local Plugin = require 'Plugin'
local Pad = require 'Pad'

local Mapper = class(Plugin)

function Mapper:create(plugin)
    local self = Plugin:create(plugin.track, plugin.index)
    setmetatable(self, Mapper)
    return self
end

function Mapper:getKeyRange(index)

    if getmetatable(index) == Pad then
        return self:getKeyRange(index:getIndex())
    end

    local pad = self:getParam(0)
    self:setParam(0, index)
    local low = self:getParam(1)
    local high = self:getParam(2)

    self:setParam(0, pad)

    return math.floor(low), math.floor(high)
end

function Mapper:setParamForPad(index, param, value)

    assert(param > 0, 'can not set param 0 (selected pad)')

    if getmetatable(index) == Pad then
        return self:setParamForPad(index:getIndex(), param, value)
    end

    local pad = self:getParam(0)
    self:setParam(0, index)

    self:setParam(param, value)

    self:setParam(0, pad)

end


return Mapper