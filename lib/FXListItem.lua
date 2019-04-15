local Image = require 'Image'
local Label = require 'Label'
local Component = require 'Component'
local TextButton = require 'TextButton'
local PluginListApp = require 'PluginListApp'
local Menu = require 'Menu'
local Mouse = require 'Mouse'
local Aux = require 'Aux'
local Bus = require 'Bus'
local Track = require 'Track'

local paths = require 'paths'
local colors = require 'colors'
local rea = require 'rea'
local _ = require '_'

local FXListItem = class(Component)

function FXListItem.getMenu()
end

function FXListItem:canClickThrough()
    return false
end

function FXListItem.replace(fx)
    PluginListApp.pick(PluginListApp.cats.effects, function(name)
        rea.transaction('replace effect', function()
            local index = fx.index
            fx:remove()
            local plugin = fx.track:addFx(name)
            plugin:setIndex(index)
            plugin:open()
        end)
    end)
end

function FXListItem.getMoveMenu(item)

    local menu = Menu:create(
        _.map(Track.getAllTracks(), function(track)

            local use = track ~= item.fx.track and _.find({
                Track.typeMap.aux,
                Track.typeMap.bus,
                Track.typeMap.output,
                Track.typeMap.audio
            }, track:getType())

            return use and {
                name = track:getName() or track:getDefaultName(),
                callback = function()
                    item:setIndex(99999, track)
                end,
                transaction = 'move fx'
            } or nil
        end))

    if item.fx.track ~= Track.master then
        menu:addSeperator()
        menu:addItem('master', function()
            item:setIndex(99999, Track.master)
        end)
    end

    return menu
end

function FXListItem:create(plugin, plain)

    local file = not plain and plugin:getImage()
    local comp = file and Image:create(file, 'fit', 1) or Label:create(plugin:getCleanName(), 0,0,200,40)

    local self = Component:create(0,0, comp.w, comp.h)
    setmetatable(self, FXListItem)

    self.repaintOnMouseEnterOrLeave = true

    self.fx = plugin

    self.comp = self:addChildComponent(comp)

    return self

end

function FXListItem:onClick(mouse)

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


        menu:addItem('move to track', FXListItem.getMoveMenu(self))

        menu:addItem('remove', function()
            self.fx:remove()
        end, 'remove')
        menu:addItem('replace', function()
            FXListItem.replace(self.fx)
        end)
        menu:addItem('add before', function()
            PluginListApp.pick(PluginListApp.cats.effects, function(name)
                rea.transaction('add before', function()
                    local plugin = self.fx.track:addFx(name)
                    if plugin then
                        plugin:setIndex(self.fx.index)
                        plugin:open()
                    end
                end)
            end)
        end)
        menu:addItem('add after', function()
            PluginListApp.pick(PluginListApp.cats.effects, function(name)
                rea.transaction('add after', function()
                    local plugin = self.fx.track:addFx(name)
                    if plugin then
                        plugin:setIndex(self.fx.index+1)
                        plugin:open()
                    end
                end)
            end)
        end)
        menu:show()
    elseif mouse:isShiftKeyDown() and mouse:isAltKeyDown() then
        FXListItem.replace(self.fx)
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

function FXListItem:setIndex(index, track)
    local e =  Mouse.capture()
    local copy = false
    if self.mouse:wasRightButtonDown() then
        local menu = Menu:create()
        menu:addItem('copy', function()
            copy = true
        end)
        menu:show()
    else
        copy = e:isCommandKeyDown()
    end

    self.fx:setIndex(index, track, copy)
end

function FXListItem:onDrop()
    if instanceOf(Component.dragging, Component) and Component.dragging.setIndex and Component.dragging.fx ~= self.fx and self:isMouseOver() then
        rea.transaction('move fx', function()

            local sametrack = Component.dragging.fx.track == self.fx.track
            local offset = (self.mouse.y > (self.h / 2)) and 1 or 0

            from = Component.dragging.fx.index
            to  = self.fx.index + offset

            to = math.max(0, to)

            if sametrack and to > from then to = to -1 end

            if sametrack and from == to  then return false end

            Component.dragging:setIndex(to, self.fx.track)


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


return FXListItem