local Component = require 'Component'
local FXList = require 'FXList'
local FXListItem = require 'FXListItem'
local FXListAddButton = require 'FXListAddButton'
local TextButton = require 'TextButton'
local Slider = require 'Slider'
local Label = require 'Label'
local Menu = require 'Menu'
local LAItem = class(Component)

local rea = require 'rea'
local _ = require '_'
local colors = require 'colors'

function LAItem:create(group)
    local self = Component:create()

    setmetatable(self, LAItem)

    self.repaintOnMouseEnterOrLeave = true

    local names = {'C', 'M', 'S'}

    self.fxs = group.fx
    self.fx = group.first
    self.name = self:addChildComponent(Label:create(''))
    self.name.getText = function()
        local mode = self.fx:getParam(4)
        return names[mode + 1]
    end

    self.name.onClick = function(s,mouse)
        if mouse:wasRightButtonDown() then
            local menu = Menu:create()--FXListItem.getMoveMenu(self)
            local mode = self.fx:getParam(4)

            _.forEach(names, function(name, i)
                menu:addItem({
                    name = name,
                    checked = mode == (i-1),
                    callback = function()
                        rea.transaction('set mode', function()
                            self.fx:setParam(4, i-1)
                            self.last:setParam(4, i-1)
                        end)
                    end
                })
            end)
            menu:show()
        elseif mouse:isShiftKeyDown() then
            self.mute:onButtonClick()
        elseif mouse:isAltKeyDown() then
            rea.transaction('remove fx', function()
                self.last:remove()
                self.fx:remove()
            end)
        end
    end

    self.addFx = self:addChildComponent(FXListAddButton:create(group.first.track,'+fx', group.last.index))

    self.mute = self:addChildComponent(TextButton:create('M'))
    self.mute.color = colors.mute
    self.mute.getToggleState = function()
        return group.last:getParam(0) == 1
    end
    self.mute.onButtonClick = function()
        rea.transaction('toggle LA listen', function()
            group.last:setParam(0, not self.mute.getToggleState() and 1 or 0)
        end)
    end

    self.solo = self:addChildComponent(TextButton:create('S'))
    self.solo.color = colors.solo

    self.solo.getToggleState = function()
        return group.last:getParam(0) == 2
    end
    self.solo.onButtonClick = function()
        rea.transaction('toggle LA listen', function()
            group.last:setParam(0, not self.solo.getToggleState() and 2 or 0)
        end)
    end

    self.gain = self:addChildComponent(Slider:create())
    self.gain.pixelsPerValue = 10
    self.gain.min = 0
    self.gain.max = 100
    self.gain.wheelscale = 10
    self.gain.isDisabled = function()
        return self.fx:getParam(4) ~= 0
    end

    self.gain.getValue = function()
        return group.last:getParam(1)
    end
    self.gain.setValue = function(s, value)
        group.last:setParam(1, value)
    end

    self.last = group.last or group.fx


    self.items = self:addChildComponent(FXList:create(group.fx))

    return self
end

function LAItem:setIndex(index, track)

    local fxs = _.concat({self.fx}, self.fxs, {self.last})

    if track == self.fx.track and index <= self.fx.index then
        fxs = reversed(fxs)
        -- rea.log('rev')
    end
    -- rea.log(_.size(self.fxs))
    -- rea.log(self.fxs)
    -- rea.log(fxs)
    _.forEach(fxs, function(fx)
        -- rea.log(index)
        fx:setIndex(index, track)
    end)
end

function LAItem:onDrag()
    Component.dragging = self
end

function LAItem:paint(g)
    Label.drawBackground(self, g, colors.default)
end

function LAItem:onDrop()
    if instanceOf(Component.dragging, FXListItem) and Component.dragging.fx ~= self.fx and self:isMouseOver() then

        local h = self.name.h
        local before = self.mouse.y < h
        local after = self.mouse.y > (self.h - h)

        if before or after then
            rea.transaction('move fx', function()

                local sametrack = Component.dragging.fx.track == self.fx.track

                local offset = after and 1 or 0

                from = Component.dragging.fx.index
                to  = (after and self.last.index or self.fx.index) + offset

                to = math.max(0, to)

                if sametrack and to > from then to = to -1 end

                if sametrack and from == to  then return false end

                Component.dragging.fx:setIndex(to, self.fx.track)
            end)
        end
    else
        self:repaint('all')
    end
end

function LAItem:paintOverChildren(g)

    local h = self.name.h
    local before = self.mouse.y < h
    local after = self.mouse.y > (self.h - h)
    if (before or after) and instanceOf(Component.dragging, Component) and Component.dragging.fx and Component.dragging.fx ~= self.fx and self:isMouseOver() then
        g:setColor(colors.mute:with_alpha(0.5))
        local y = self.mouse.y > (self.h - h) and self.h - h or 0
        g:rect(0, y ,self.w, h, true)
    end

    if not self.fx:getEnabled() or self.fx.track:getValue('fx') == 0 then
        g:setColor(colors.mute:with_alpha(0.5))
        g:rect(0,0,self.w, self.h, true)
    end
end

function LAItem:resized()

    local h = 20
    local y = 0
    local x = 0
    if self.w <= h*2 then
        self.name:setBounds(0,0,self.w, h)
        y = h
    else
        self.name:setBounds(0,0,self.w - h*2, h)
        x = self.name:getRight()
    end
    self.mute:setBounds(x,y,h, h)
    self.solo:setBounds(self.mute:getRight(),y,h, h)
    y = self.solo:getBottom()

    if self.last:getParam(2) == 1 or _.size(self.fxs) == 0 then
        self.addFx:setBounds(0,y,self.w, h)
        y = self.addFx:getBottom()
    else
        self.items:setBounds(0,y,self.w)
        y = self.items:getBottom()

    end

    self.gain:setBounds(0,y,self.w, h)
    y = self.gain:getBottom()

    self.h = y

end

return LAItem