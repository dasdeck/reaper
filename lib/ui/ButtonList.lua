local Component = require 'Component'
local TextButton = require 'TextButton'
local _ = require '_'
local Menu = require 'Menu'

local rea = require 'Reaper'

local ButtonList = class(Component)

function ButtonList:create(data, layout, proto, ...)

    local self = Component:create(...)
    self.layout = layout
    self.data = data
    self.proto = proto or TextButton
    setmetatable(self, ButtonList)
    self:createChildren()
    return self

end

function ButtonList:createChildren()

    self.children = {}
    local size = self.layout == true and 'w' or 'h'
    for i, value in pairs(self.data) do

        local proto = value.proto or self.proto

        local args = value.args or tostring(i)
        local comp = type(proto) == 'function' and proto() or proto:create(args)

        comp.color = value.color or comp.color

        assert(not comp.data, 'comps can not have a "data" member')

        comp.data = value

        comp.data.args = args

        comp.onButtonClick = comp.onButtonClick or function(s, mouse)
            if value.onClick then
                value.onClick(value, mouse)
            else
                self:onItemClick(i, value)
            end

        end

        if self.layout == 1 then
            comp.onClick = function() end
            comp.canClickThrough = function() return true end
            comp.isVisible = function() return comp:getToggleState() end
        end

        comp.getToggleState = function()
            if value.getToggleState then
                return value:getToggleState(value)
            else
                return self:isSelected(i, value)
            end
        end

        if value.getText then
            function comp:getText()
                return value:getText()
            end
        end

        if value.isDisabled then
            comp.isDisabled = function()
                return value:isDisabled(value)
            end
        end

        self:addChildComponent(comp)
        self[size] = self[size] + comp[size]
    end

    if self.layout == 1 and _.size(self.children) then
        self[size] = _.first(self.children)[size]
    end
end


function ButtonList:onClick()
    if self.layout == 1 then
        self:showAsMenu()
    end
end

function ButtonList:resized()

    if self.layout == 1 then
        for k, child in pairs(self.children) do
            child.w = self.w
            child.h = self.h
            child.x = 0
            child.y = 0
        end
    else
        local len = _.size(self.data)
        local dim = self.layout == true and 'w' or 'h'
        local p = self.layout == true and 'x' or 'y'
        local size = self[dim] / len

        local i = 0
        for k, child in pairs(self.children) do
            child.w = self.w
            child.h = self.h
            child.x = 0
            child.y = 0

            child[p] = i * size
            child[dim] = size
            i = i + 1
        end
    end

end

function ButtonList:onItemClick(i, entry)
end

function ButtonList:isSelected(i, entry)
end

function ButtonList:showAsMenu()
    local menu = Menu:create()

    for k, child in pairs(self.children) do

        menu:addItem(child.data.args,{
            callback = function() return child:onButtonClick(true) end,
            checked = child:getToggleState()
        })
    end

    menu:show()

end

return ButtonList