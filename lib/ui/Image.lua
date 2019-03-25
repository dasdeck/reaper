local Component = require 'Component'
local _ = require '_'
local rea = require 'rea'

local Image = class(Component)

Image.images = {

}

function getSlot(file)
    if not Image.images[file] then

        for i = 1, 1024 do
            if not _.find(Image.images, i) then

                Image.images[file] = i
                gfx.loadimg(i, file)

                return i
            end
        end

        assert(false, 'out of image slots')

    else
        return Image.images[file]
    end
end

function Image:create(file, scale, alpha)

    local self = Component:create()
    setmetatable(self, Image)
    self.scale = scale or 1
    if alpha ~= nil then
        self:setAlpha(alpha)
    end
    self.slot = getSlot(file)

    local w, h = gfx.getimgdim(self.slot)

    self.w = w
    self.h = h

    return self

end

function Image:paint(g)

    if self.scale == 'fit' then
        local padding = 4
        local w, h = gfx.getimgdim(self.slot)
        local scale = math.min((self.w-padding) / w, (self.h-padding) / h)

        w = w * scale
        h = h * scale

        g:drawImage(self.slot, (self.w - w) / 2, (self.h - h) / 2, scale)

    else
        -- rea.log('image:paint' .. tostring(self.scale))
        g:drawImage(self.slot, 0, 0, self.scale)
    end



end

return Image