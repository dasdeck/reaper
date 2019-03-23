local Component = require 'Component'
local _ = require '_'

local Image = class(Component)

Image.images = {

}

function getSlot(file)
    if not Image.images[file] then

        for i = 0, 1024 do
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
    self:setAlpha(alpha or 1)
    self.slot = getSlot(file)

    local w, h = gfx.getimgdim(self.slot)

    self.w = w
    self.h = h

    return self

end

function Image:fitToWidth(wToFit)
    local w, h = gfx.getimgdim(self.slot)

    self.w = wToFit
    self.scale = wToFit / w
    self.h = h * self.scale

    return self
end

function Image:fitToHeight(hToFit)
    local w, h = gfx.getimgdim(self.slot)

    self.h = hToFit
    self.scale = hToFit / h
    self.w = w * self.scale

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
        g:drawImage(self.slot, 0, 0, self.scale)
    end

end

return Image