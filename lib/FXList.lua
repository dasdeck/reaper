
local Component = require 'Component'
local ButtonList = require 'ButtonList'
local FXListItem = require 'FXListItem'

local TextButton = require 'TextButton'
local PluginListApp = require 'PluginListApp'

local colors = require 'colors'
local rea = require 'rea'
local _ = require '_'

local FXList = class(ButtonList)

function FXList:create(fx)
    local self = ButtonList:create()
    -- self.track = track
    self.fx = fx

    setmetatable(self, FXList)

    self:updateList()

    return self
end

function FXList:getData()

    local res = {

    }
    local group

    _.forEach(self.fx, function(fx)
        if fx:getCleanName() == 'LA' then
            local LAItem = require 'LAItem'
            if group then
                group.last = fx
                group = nil
            else
                group = {
                    proto = LAItem,
                    first = fx,
                    fx = {},
                    size = true
                }
                group.args = group
                table.insert(res, group)
            end
        elseif group then
            table.insert(group.fx, fx)
        else
            table.insert(res, {
                proto = FXListItem,
                args = fx,
                size = true
            })
        end

    end)

    return res
end

function FXList.addByClick(track, mouse, index)
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
                if plug then
                    if index then
                        plug:setIndex(index)
                    end
                    plug:open()
                end
            end)
        end)
    end
end

function FXList:resized()
    if self.w > 0 then

        _.forEach(self.children, function(child, i)
            child:fitToWidth(self.w)
        end)

        ButtonList.resized(self)
    end
end

return FXList