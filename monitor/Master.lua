local Component = require 'Component'
local MasterUI = require 'MasterUI'
local Track = require 'Track'
local Project = require 'Project'
local MonitorPresets = require 'MonitorPresets'
local Mouse = require 'Mouse'
local Master = class(Component)

function Master:create()
    local self = Component:create()
    setmetatable(self, Master)
    self.watchers:watch(Project.watch.project, function()
        if not Mouse.capture():isButtonDown() then
            self:update()
        end
    end)

    self:update()

    return self
end

function Master:update()
    self:deleteChildren()

    self.monitor = self:addChildComponent(MonitorPresets:create())
    self.fx = self:addChildComponent(MasterUI:create(Track.master))
    self:resized()
end

function Master:resized()
    local h = 20
    self.monitor:setBounds(0,0,self.w)

    self.fx:setBounds(0,self.monitor:getBottom(), self.w)
end

return Master