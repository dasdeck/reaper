local Image = require 'Image'
local Label = require 'Label'
local Component = require 'Component'

local paths = require 'paths'
local colors = require 'colors'
local rea = require 'rea'

local FXListItem = class(Component)

function FXListItem:create(plugin)

    local file = plugin:getImage()
    local comp = file and Image:create(file, 'fit', 1) or Label:create(plugin:getCleanName(), 0,0,200,40)

    local self = Component:create(0,0, comp.w, comp.h)
    setmetatable(self, FXListItem)

    self.fx = plugin
    --
    self.comp = self:addChildComponent(comp)

    return self

end

function FXListItem:onClick(mouse)

    if mouse:isShiftKeyDown() then
        self.fx:setEnabled(not self.fx:getEnabled())
    elseif mouse:isAltKeyDown() then
        self.fx:remove()
    end

end

function FXListItem:onDblClick(mouse)
    self.fx:open()
end

function FXListItem:onDrag()
    Component.dragging = self
end

function FXListItem:paintOverChildren(g)

    if Component.dragging and Component.dragging.fx and Component.dragging.fx ~= self.fx then
        if self.mouse.y < (self.h / 2) then
            g:setColor(colors.mute:with_alpha(0.75))
            g:rect(0,0,self.w, self.h/2, true)
        else

        end
    end
end

function FXListItem:getAlpha()
    return self.fx:getEnabled() and 1 or 0.5
end

return FXListItem