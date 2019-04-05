local Component = require 'Component'
local TextButton = require 'TextButton'
local rea = require 'rea'

local OutputListComp = class(Component)

function OutputListComp:create(output)
    local self = Component:create()
    setmetatable(self, OutputListComp)
    self.output = output
    self.name = self:addChildComponent(TextButton:create(output.name))


    self.name.getToggleState = function()
        return self.output.getConnection() ~= nil
    end

    self.name.onDblClick = function(s, mouse)
        local con = self.name.onButtonClick(s, mouse)
        if con then
            con:getTargetTrack():focus()
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
            if not con then
                rea.transaction('create output', function()
                    con = self.output.createConnection()
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
    local h = self.h

    self.name:setBounds(0, 0, self.w, h)
    -- self.link:setBounds(self.name:getRight(), 0, h, h)

end


return OutputListComp