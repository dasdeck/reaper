require 'Util'
local Plugin = require 'Plugin'

local PartialPresets = class()

function PartialPresets:create(config)
    local preset = {}
    setmetatable(preset, PartialPresets)
    preset.config = config
    return preset
end

function PartialPresets:store()
end

function PartialPresets:getCurrentSettings()
    local preset = {}
    for i, value in ipairs(self.config.params) do
        preset[value] = self.config.plugin:getParam(value)
    end
    return preset;
end

function PartialPresets:load(preset)
    for i, value in ipairs(self.config.params) do
        self.config.plugin:setParam(value, preset[value])
    end
end

function PartialPresets:matches(preset)
    for i, value in ipairs(self.config.params) do
        if not fequal(preset[value], self.config.plugin:getParam(value), 2) then
            return false
        end
    end
    return true
end

return PartialPresets