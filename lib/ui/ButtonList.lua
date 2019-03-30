local Component = require 'Component'
local TextButton = require 'TextButton'
local _ = require '_'
local Menu = require 'Menu'

local rea = require 'rea'

local ButtonList = class(Component)

function ButtonList:create(data, layout, proto, ...)

    local self = Component:create(...)
    self.layout = layout
    self.data = data or {}
    self.proto = proto or TextButton
    setmetatable(self, ButtonList)
    self:updateList()
    return self

end

function ButtonList:updateList()

    self:deleteChildren()
    -- _.forEach(self.children, function(child) child:delete() end)
    -- self.children = {}
    local size = self.layout == true and 'w' or 'h'
    self[size] = 0
    for i, value in pairs(self:getData()) do

        local proto = value.proto or self.proto

        local args = value.args or tostring(i)
        local comp = type(proto) == 'function' and proto() or proto:create(args)

        comp.color = value.color or comp.color

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

        comp.getToggleState = comp.getToggleState ~= TextButton.getToggleState and comp.getToggleState or function()
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

        local CompSize = value.size or (comp[size] > 0 and comp[size]) or self.getDefaultCompSize()
        self:addChildComponent(comp)
        self[size] = self[size] + CompSize
    end

    if self.layout == 1 and _.size(self.children) then
        self[size] = _.first(self.children)[size]
    end

    self:repaint()
end

function ButtonList:getDefaultCompSize()
    return 20
end

function ButtonList:onClick()
    if self.layout == 1 then
        self:showAsMenu()
    end
end

function ButtonList:getData()
    return self.data
end

function ButtonList:resized()

    if self.layout == 1 then
        for k, child in pairs(self.children) do

            child:setBounds(0,0,self.w, self.h)
        end
    else
        local dataList = self:getData()
        local dim = self.layout == true and 'w' or 'h'
        local dimI = self.layout ~= true and 'w' or 'h'
        local p = self.layout == true and 'x' or 'y'
        local pI = self.layout ~= true and 'x' or 'y'

        local size = self[dim] / _.size(dataList)

        local i = 1
        local off = 0
        _.forEach(self.children, function(child)
            local data = dataList[i]

            child[dimI] = self[dimI]
            child[pI] = self[pI]
            child[p] = off
            child[dim] = data and data.size or child[dim] > 0 and child[dim] or size
            off = off + child[dim]
            i = i + 1
            child:relayout()
        end)
    end

end

function ButtonList:onItemClick(i, entry)
end

function ButtonList:isSelected(i, entry)
end

function ButtonList:showAsMenu()
    local menu = Menu:create()

    _.forEach(self:getData(), function(opt, i)
        local child = self.children[i]
        menu:addItem(opt.args, {
            callback = function() return child:onButtonClick(true) end,
            checked = child:getToggleState()
        })
    end)


    menu:show()

end

return ButtonList