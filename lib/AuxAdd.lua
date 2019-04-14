local TextButton = require 'TextButton'
local AuxUI = require 'AuxUI'
local colors = require 'colors'

local AuxAdd = class(TextButton)

function AuxAdd:create(track, name)

    local self = TextButton:create(name or '+aux')
    setmetatable(self, AuxAdd)
    self.track = track
    self.color = colors.aux:fade(0.8)
    return self

end


function AuxAdd:onButtonClick(mouse)

    if mouse:wasRightButtonDown() then
        AuxUI.pickAndCreate(self.track)
    else
        AuxUI.pickOrCreateMenu(self.track)
    end

end

return AuxAdd