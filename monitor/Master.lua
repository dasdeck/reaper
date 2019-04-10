local Component = require 'Component'
local MasterUI = require 'MasterUI'
local Track = require 'Track'
local Project = require 'Project'
local MonitorPresets = require 'MonitorPresets'
local Master = class(Component)

function Master:create()
    local self = Component:create()
    setmetatable(self, Master)
    self.watchers:watch(Project.watch.project, function()
        self:update()
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
    self.monitor:setBounds(0,0,self.w, h * 4)
    self.fx:setBounds(0,self.monitor:getBottom(), self.w)
end

return Master