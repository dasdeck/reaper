local Component = require 'Component'
local ButtonList = require 'ButtonList'
local TextButton = require 'TextButton'
local Menu = require 'Menu'
local _ = require '_'

local DataBaseEntryUI = class(Component)

function DataBaseEntryUI:create(entry)
    local self = Component:create()

    setmetatable(self, DataBaseEntryUI)
    self.entry = entry

    entry.data = entry.data or {}
    entry.data.u = entry.data.u or {}

    if not self.entry.rating then

        if self.entry.data.u[1] and self.entry.data.u[1]:isNumber() then
            self.entry.rating = tonumber(self.entry.data.u[1])
            self.entry.data.u[1] = nil
        else
            self.entry.rating = 0
        end
    end

    local ratings = {}
    for i=1,5 do
        table.insert(ratings, {
            args = tostring(i),
            getToggleState = function()
                return i <= self.entry.rating
            end,
            onClick = function(s, mouse)
                entry.rating = (not mouse:isAltKeyDown()) and i or 0
                self:repaint(true)
            end
        })
    end

    self.rating = self:addChildComponent(ButtonList:create(ratings, true))

    self.tags = self:addChildComponent(TextButton:create(''))
    self.tags.getText = function()
        return _.join(self.entry.data.u, ',')
    end
    self.tags.onButtonClick = function(s, mouse)
        local menu = Menu:create()
        local tags = self.entry.db:getTags()
        if _.size(tags) > 0 then
            _.forEach(tags, function(tag)
                menu:addItem(tag, {
                    callback = function()
                    end,
                    checked = _.find(self.entry.data.u, tag)
                })
            end)

        end
        menu:show()
    end

    return self
end

function DataBaseEntryUI:resized()
    local h = 20
    self.rating:setBounds(0,0,self.w, h)
    self.tags:setBounds(0,self.rating:getBottom(),self.w, h)
end

return DataBaseEntryUI