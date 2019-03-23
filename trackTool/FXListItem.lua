local Image = require 'Image'
local Label = require 'Label'
local paths = require 'paths'

local FXListItem = class(Image)

function FXListItem:create(plugin)

    local name = plugin:getModule():split('%.')[1] .. '.png'
    local file = paths.imageDir:findFile(name)
    local self = file and Image:create(file, 'fit', 1) or Label:create(name)
    self.fx = plugin
    setmetatable(self, FXListItem)
    return self

end

function FXListItem:onClick(mouse)

    if mouse:isShiftKeyDown() then
        self.fx:setEnabled(not self.fx:getEnabled())
    end

end

function FXListItem:getAlpha()
    return self.fx:getEnabled() and 1 or 0.5
end

return FXListItem