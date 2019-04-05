local TextButton = require 'TextButton'
local Menu = require 'Menu'
local Track = require 'Track'
local colors = require 'colors'
local _ = require '_'

local Type = class(TextButton)

function Type:create(track)
    local self = TextButton:create('')
    setmetatable(self, Type)
    self.track = track
    self.color = colors[track:getType()] or colors.default
    return self
end

function Type:getText()
    return self.track:getType() or '--'
end

function Type:onButtonClick()
    local currentType = self.track:getType()
    local menu = Menu:create()
    _.forEach(Track.types, function(type)
        menu:addItem(type, {
            checked = type == currentType,
            callback = function()
                self.track:setType(type)
            end,
            transaction = 'set track type'
        })
    end)
    menu:show()
end

return Type