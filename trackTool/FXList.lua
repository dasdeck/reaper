
local Component = require 'Component'
local PluginList = require 'PluginList'
local FXListItem = require 'FXListItem'
local TextButton = require 'TextButton'
local PluginListApp = require 'PluginListApp'

local colors = require 'colors'
local rea = require 'rea'
local _ = require '_'

local FXList = class(Component)

function FXList:create(track, name)
    local self = Component:create()
    setmetatable(self, FXList)
    _.forEach(track:getFxList(), function(fx)
        self:addChildComponent(FXListItem:create(fx))
    end)

    self.add = self:addChildComponent(TextButton:create(name or '+fx',0,0,100,25))
    self.add.onButtonClick = function(s, mouse)

        if mouse:isAltKeyDown() then
            local name = rea.prompt('name')
            if name then
                rea.transaction('add fx', function()
                    local plug = track:addFx(name)
                    if plug then plug:open() end
                end)
            end
        else
            PluginListApp.pick(PluginListApp.cats.effects, function(name)
                rea.transaction('add fx', function()
                    local plug = track:addFx(name)
                    if plug then plug:open() end
                end)
            end)
        end
    end

    return self
end

function FXList:resized()
    PluginList.resized(self)
end

return FXList