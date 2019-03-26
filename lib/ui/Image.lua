local Component = require 'Component'
local _ = require '_'
local rea = require 'rea'

local Image = class(Component)

Image.images = {}

function Image:create(file, scale, alpha)

    local self = Component:create()
    setmetatable(self, Image)
    self.scale = scale or 1
    if alpha ~= nil then
        self:setAlpha(alpha)
    end

    -- rea.logCount('img:')
    -- rea.logPin('images', Image.images)

    if not Image.images[file] then
        Image.images[file] = 0
    end

    Image.images[file] = Image.images[file] + 1

    self.file = file
    self.imgSlot = self:getSlot(file, gfx.loadimg)
    self.uislots[file] = nil

    local w, h = gfx.getimgdim(self.imgSlot)


    self.w = w
    self.h = h

    return self

end

function Image:onDelete()
    local file = self.file

    Image.images[file] = Image.images[file] - 1

    if Image.images[file] == 0 then
        -- rea.logCount('clear:' .. file)
        Component.slots[self.imgSlot] = false
    end

    -- assert(Image.images[file] >= 0, 'image tracking failed')
end

function Image:paint(g)

    if self.scale == 'fit' then
        local padding = 4
        local w, h = gfx.getimgdim(self.imgSlot)
        local scale = math.min((self.w-padding) / w, (self.h-padding) / h)

        w = w * scale
        h = h * scale

        g:drawImage(self.imgSlot, (self.w - w) / 2, (self.h - h) / 2, scale)

    else
        g:drawImage(self.imgSlot, 0, 0, self.scale)
    end



end

return Image