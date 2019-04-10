local Image = require 'Image'
local Label = require 'Label'
local Component = require 'Component'
local TextButton = require 'TextButton'
local PluginListApp = require 'PluginListApp'
local Menu = require 'Menu'
local Aux = require 'Aux'
local Bus = require 'Bus'
local Track = require 'Track'

local paths = require 'paths'
local colors = require 'colors'
local rea = require 'rea'
local _ = require '_'

local FXListItem = class(Component)

function FXListItem:create(plugin, plain)

    local file = not plain and plugin:getImage()
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
                plugin:open()
            end)
        end)
    end

    if mouse:wasRightButtonDown() then
        local menu = Menu:create()

        menu:addItem('wrap in la', function()
            local pre = self.fx.track:addFx('LA', false, true)
            local post = self.fx.track:addFx('LA', false, true)

            post:setIndex(self.fx.index+1)
            pre:setIndex(self.fx.index)
        end, 'wrap in la')

        menu:addItem('panic', function()
            self.fx:setOffline(true)
            self.fx:setOffline(false)
        end)

        local moveMenu = Menu:create(
            _.map(Track.getAllTracks(), function(track)
                local use = track ~= self.fx.track and not track:isMidiTrack()
                return use and {
                    name = track:getName() or track:getDefaultName(),
                    callback = function()
                        self.fx:setIndex(-1, track)
                    end,
                    transaction = 'move fx'
                } or nil
            end))
        if self.fx.track ~= Track.master then
            moveMenu:addSeperator()
            moveMenu:addItem('master', function()
                self.fx:setIndex(-1, Track.master)
            end)
        end

        menu:addItem('move to track', moveMenu)
        -- local moveMenu = Menu:create()
        -- moveMenu:addItem('create aux from effect', function()

        -- end)

        menu:addItem('remove', function()
            self.fx:remove()
        end, 'remove')
        menu:addItem('replace', replace)
        menu:addItem('add before', function()
            PluginListApp.pick(PluginListApp.cats.effects, function(name)
                rea.transaction('add before', function()
                    local plugin = self.fx.track:addFx(name)
                    plugin:setIndex(self.fx.index)
                    plugin:open()
                end)
            end)
        end)
        menu:addItem('add after', function()
            PluginListApp.pick(PluginListApp.cats.effects, function(name)
                rea.transaction('add after', function()
                    local plugin = self.fx.track:addFx(name)
                    plugin:setIndex(self.fx.index+1)
                    plugin:open()
                end)
            end)
        end)
        menu:show()
    elseif mouse:isShiftKeyDown() and mouse:isAltKeyDown() then
        replace()
    elseif mouse:isShiftKeyDown() then

        if mouse:isCommandKeyDown() then
            -- self.fx:setOffline(not self.fx:getOffline())
        else
            rea.transaction('toggle fx bypass', function()
                self.fx:setEnabled(not self.fx:getEnabled())
            end)
        end
    elseif mouse:isAltKeyDown() then
        rea.transaction('remove fx', function()
            self.fx:remove()
        end)
    end
end

function FXListItem:onDblClick(mouse)
    if self.fx:isOpen() then
        self.fx:close()
    else
        self.fx:open()
    end
end

function FXListItem:onDrag()
    Component.dragging = self
end

function FXListItem:onMouseUp()
    self.parent:repaint(true)
end

function FXListItem:onDrop()
    if Component.dragging and instanceOf(Component.dragging, FXListItem) and Component.dragging.fx ~= self.fx and self:isMouseOver() then
        rea.transaction('move fx', function()

            local sametrack = Component.dragging.fx.track == self.fx.track
            local offset = (self.mouse.y > (self.h / 2)) and 1 or 0

            from = Component.dragging.fx.index
            to  = self.fx.index + offset

            to = math.max(0, to)

            if sametrack and to > from then to = to -1 end

            if sametrack and from == to  then return false end

            Component.dragging.fx:setIndex(to, self.fx.track)
        end)
    else
        self:repaint('all')
    end
end

function FXListItem:paintOverChildren(g)

    if not self.fx:getEnabled() or self.fx.track:getValue('fx') == 0 then
        g:setColor(colors.mute:with_alpha(0.5))
        g:rect(0,0,self.w, self.h, true)
    end
    if instanceOf(Component.dragging, Component) and Component.dragging.fx and Component.dragging.fx ~= self.fx and self:isMouseOver() then
        g:setColor(colors.mute:with_alpha(0.5))
        local h = self.h/2
        g:rect(0, (self.mouse.y > h) and h or 0 ,self.w, h, true)
    end
end

function FXListItem:getAlpha()
    return self.fx:getOffline() and 0.5 or 1
end

function FXListItem:resized()
    self.comp:setSize(self.w, self.h)
end

return FXListItem