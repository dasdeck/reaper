local Image = require 'Image'
local Label = require 'Label'
local Component = require 'Component'
local TextButton = require 'TextButton'
local PluginListApp = require 'PluginListApp'
local Menu = require 'Menu'
local Aux = require 'Aux'
local Bus = require 'Bus'

local paths = require 'paths'
local colors = require 'colors'
local rea = require 'rea'

local FXListItem = class(Component)

function FXListItem:create(plugin)

    local file = plugin:getImage()
    local comp = file and Image:create(file, 'fit', 1) or Label:create(plugin:getCleanName(), 0,0,200,40)

    local self = Component:create(0,0, comp.w, comp.h)
    setmetatable(self, FXListItem)

    self.repaintOnMouseEnterOrLeave = true

    self.fx = plugin

    self.comp = self:addChildComponent(comp)
    self.replace = self:addChildComponent(TextButton:create('R'))
    self.replace.getAlpha = function()
        if self.replace:isMouseOver() then
            return 1
        elseif self:isMouseOver() then
            return 0.5
        else
            return 0
        end
    end

    return self

end

function FXListItem:onClick(mouse)

    local replace = function()
        PluginListApp.pick(PluginListApp.cats.effects, function(name)
            rea.transaction('replace effect', function()
                local index = self.fx.index
                self.fx:remove()
                local plugin = self.fx.track:addFx(name)
                plugin:setIndex(index)
            end)
        end)
    end

    if mouse:wasRightButtonDown() then
        local menu = Menu:create()

        if self.fx:canDoMultiOut() then
            menu:addItem('create multiout', function()
                self.fx:createMultiOut()
            end, 'create multiout')
        end

        local moveMenu = Menu:create()
        moveMenu:addItem('create aux from effect', function()

        end)

        menu:addItem('remove', function()
            self.fx:remove()
        end, 'remove')
        menu:addItem('replace', replace)
        menu:addItem('add before', function()
            PluginListApp.pick(PluginListApp.cats.effects, function(name)
                rea.transaction('add before', function()
                    local plugin = self.fx.track:addFx(name)
                    plugin:setIndex(self.fx.index)
                end)
            end)
        end)
        menu:addItem('add after', function()
            PluginListApp.pick(PluginListApp.cats.effects, function(name)
                rea.transaction('add after', function()
                    local plugin = self.fx.track:addFx(name)
                    plugin:setIndex(self.fx.index+1)
                end)
            end)
        end)
        menu:show()
    elseif mouse:isShiftKeyDown() and mouse:isAltKeyDown() then
        replace()
    elseif mouse:isShiftKeyDown() then
        self.fx:setEnabled(not self.fx:getEnabled())
    elseif mouse:isAltKeyDown() then
        self.fx:remove()
    end

end

function FXListItem:onDblClick(mouse)
    if self.fx:isOpen() then
        self.fx:close()
    else
        self.fx:open()
    end
end

-- function FXListItem:onDragOver()
--     self.parent:repaint(true)
-- end

function FXListItem:onDrag()
    Component.dragging = self
    -- self.parent:repaint(true)
end

function FXListItem:onMouseUp()
    self.parent:repaint(true)
end

function FXListItem:onDrop()
    if Component.dragging and instanceOf(Component.dragging, FXListItem) and Component.dragging.fx ~= self.fx and self:isMouseOver() then
            rea.transaction('move fx', function()

                local offset = (self.mouse.y > (self.h / 2)) and 1 or 0

                local from = Component.dragging.fx.index
                local to  = self.fx.index + offset

                if to -1 == from then return false end

                Component.dragging.fx:setIndex(to, self.fx.track)
            end)
    else
        self:repaint('all')
    end
end

function FXListItem:paintOverChildren(g)

    if Component.dragging and Component.dragging.fx and Component.dragging.fx ~= self.fx and self:isMouseOver() then
        g:setColor(colors.mute:with_alpha(0.5))
        local h = self.h/2
        g:rect(0, (self.mouse.y > h) and h or 0 ,self.w, h, true)
    end
end

function FXListItem:getAlpha()
    return self.fx:getEnabled() and 1 or 0.5
end

function FXListItem:resized()
    self.comp:setSize(self.w, self.h)
end

return FXListItem