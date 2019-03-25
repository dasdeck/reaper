
local Component = require 'Component'
local PluginList = require 'PluginList'
local FXListItem = require 'FXListItem'
local TextButton = require 'TextButton'

local colors = require 'colors'
local rea = require 'rea'
local _ = require '_'

local FXList = class(Component)

function FXList:create(track)
    local self = Component:create()
    setmetatable(self, FXList)
    _.forEach(track:getFxList(), function(fx)
        self:addChildComponent(FXListItem:create(fx))
    end)

    self.add = self:addChildComponent(TextButton:create('+fx',0,0,100,25))
    self.add.onButtonClick = function()
        local name = rea.prompt('name')
        if name then
            rea.transaction('add fx', function()
                local index = reaper.TrackFX_AddByName(track.track, name, false, -1)
                if index >= 0 then

                end
            end)
        end
    end

    return self
end

function FXList:resized()
    PluginList.resized(self)
end

return FXList