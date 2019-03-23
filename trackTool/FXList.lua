
local Component = require 'Component'
local _ = require "_"
local FXList = class(Component)
local PluginList = require 'PluginList'
local FXListItem = require 'FXListItem'
local colors = require 'colors'

function FXList:create(track)
    local self = Component:create()
    setmetatable(self, FXList)
    _.forEach(track:getFxList(), function(fx)
        self:addChildComponent(FXListItem:create(fx))
    end)

    return self
end

-- function FXList:paint()
--     self:setColor(colors.fx)
--     self:rect(0,0,self.w, self.h, true)
-- end

function FXList:resized()
    PluginList.resized(self)
end

return FXList