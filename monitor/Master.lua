local Component = require 'Component'
local MasterUI = require 'MasterUI'
local Track = require 'Track'
local Project = require 'Project'
local MonitorPresets = require 'MonitorPresets'
local Mouse = require 'Mouse'
local TransposeControll = require 'TransposeControll'
local TextButton = require 'TextButton'
local ButtonList = require 'ButtonList'
local Scales = require 'Scales'

local Mem = require 'Mem'
local rea = require 'rea'
local _ = require '_'


local Master = class(Component)
function Master:create()
    local self = Component:create()
    setmetatable(self, Master)
    self.watchers:watch(Project.watch.project, function()
        if not Mouse.capture():isButtonDown() then
            self:update()
        end
    end)

    self.watchers:watch(function()
        local suc, val = reaper.GetProjExtState(0, 'D3CK', 'transpose')
        return tonumber(suc > 0 and val or '0')
    end, function(val)
        Mem.write('tracktooljsfx', 10, val)
    end, false)

    self:update()

    return self
end

function Master:update()

    self:deleteChildren()

    if not Track.master:exists() then return end

    self.transpose = self:addChildComponent(TransposeControll:create())
    self.transpose.getValue = function()
        return Mem.read('tracktooljsfx', 10) or 0
    end
    self.transpose.setValue = function(s, value)
        value = math.floor(value or 0)
        Mem.write('tracktooljsfx', 10, value)
        reaper.SetProjExtState(0, 'D3CK', 'transpose', tostring(value))
    end

    -- rea.log(Scales)

    local default = Scales[1].default
    local buttons = _.map(Scales, function(data)
        return {
            args = data.name,
            onClick = function()
                rea.transaction('set scale', function()
                    _.forEach(data.scale, function(offset, index)
                        Mem.write('tracktooljsfx', 11 + default[index], offset)
                    end)
                end)
            end,
            getToggleState = function()
                return not _.some(data.scale, function(offset, index)
                    return Mem.read('tracktooljsfx', 11 + default[index]) ~= offset
                end)
            end
        }
    end)

    self.scale = self:addChildComponent(ButtonList:create(buttons, 1))

    self.monitor = self:addChildComponent(MonitorPresets:create())

    -- self.fx = self:addChildComponent(MasterUI:create(Track.master))
    self:resized()
end

function Master:resized()
    local h = 20

    self.transpose:setBounds(0,0,self.w / 2, h)
    self.scale:setBounds(self.transpose:getRight(),0,self.transpose.w, h)

    self.monitor:setBounds(0,self.transpose:getBottom(),self.w)

    -- self.fx:setBounds(0,self.monitor:getBottom(), self.w)
end

return Master