local Component = require 'Component'
local TextButton = require 'TextButton'
local Label = require 'Label'
local rea = require 'rea'

local OutputListComp = class(Component)

function OutputListComp:create(output)
    local self = Component:create()
    setmetatable(self, OutputListComp)

    self.output = output
    self.name = self:addChildComponent(TextButton:create(output.name))

    self.paint = function(s, g)
        Label.drawBackground(self, g, self.name:getColor())
    end

    self.expanded = self:addChildComponent(TextButton:create('+'))
    self.expanded.getToggleState = function()
        return output.getConnection() and output.getConnection():getTargetTrack():getMeta().expanded
    end

    if self.expanded.getToggleState() then
        local con = output.getConnection()
        local comp = con and con:getTargetTrack():createUI()
        if comp then
            self.outputTrack = self:addChildComponent(comp)
        end
    end

    self.name.getToggleState = function()
        return self.output.getConnection() ~= nil
    end

    self.name.onDblClick = function(s, mouse)
        local con = self.output.getConnection()
        if con then
            rea.transaction('remove output', function()
                con:getTargetTrack():remove()
            end)
        else
            rea.transaction('create output', function()
                con = self.output.createConnection()
            end)
        end
    end

    self.name.onButtonClick = function(s, mouse)
        local con = self.output.getConnection()
        if mouse:isAltKeyDown() then
            if con then
                rea.transaction('remove output', function()
                    con:getTargetTrack():remove()
                end)
            end
        else
            local con = self.output.getConnection()
            if con then
                rea.transaction('toggle output', function()
                    con:getTargetTrack():setMeta('expanded',not self.expanded.getToggleState())
                    self.parent:updateList()
                    local win = self:getWindow()
                    win.component:resized()
                end)
            end
        end
        return con

    end

    self.link = self:addChildComponent(TextButton:create('>'))
    self.link.onButtonClick = function(s, mouse)
        local con = self.name.onButtonClick(s, mouse)
        if con then
            con:getTargetTrack():focus()
        end
    end

    return self
end

function OutputListComp:resized()
    local h = 20

    self.name:setBounds(0, 0, self.w, h)

    local y = self.name:getBottom()

    if self.outputTrack then
        self.outputTrack:setBounds(0,y, self.w)
        y = self.outputTrack:getBottom()
    end

    self.h = y

end

return OutputListComp