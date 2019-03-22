
local rea = require 'Reaper'
local Menu = class()
local _ = require '_'

function Menu:create(options)
    local self = {
        items = {}
    }

    setmetatable(self, Menu)

    _.forEach(options, function(opt, key)
        if type(opt) == 'function' then opt = {callback = opt} end
        self:addItem(opt.name or key, opt)
    end)

    return self
end

function Menu:__gc()

    -- assert(self.wasShown)

end

function Menu:show()

    self.wasShown = true
    local map = {}
    local menu = self:renderItems(self.items, map)

    gfx.x = gfx.mouse_x
    gfx.y = gfx.mouse_y
    local res = gfx.showmenu(menu)

    if res > 0 and map[res] then
        return map[res]()
    end

end

function Menu:renderItems(items, map)

    local isSubMenu = map ~= nil
    map = map or {}
    items = items or self.items

    local flat = {}

    for key, item in pairs(items) do
        if item == false then --seperator
            table.insert(flat, '')
        elseif type(item.children) == 'table' then
            local menu = '>' .. item.name .. '|' .. self:renderItems(item.children, map)
            table.insert(flat, menu)
        else
            local name = item.name
            if item.getToggleState and item:getToggleState() or item.checked then
                name = '!' .. name
            end

            if item.isDisabled and item:isDisabled() or item.disabled then
                name = '#' .. name
            end

            table.insert(flat, name)
            if type(item.callback) == 'function' then
                if item.transaction then
                    table.insert(map, function()
                        rea.transaction(item.transaction, item.callback)
                    end)
                else
                    table.insert(map, item.callback)
                end
            else
                table.insert(map, function()end)
            end
        end
    end

    if isSubMenu then
        flat[#flat] = '<' .. flat[#flat]
    end

    return _.join(flat, '|')

end

function Menu:addItem(name, data, transaction)
    local item = {
        name =  name,
        callback = type(data) == 'function' and data,
        children = getmetatable(data) == Menu and data.items,
        transaction = transaction
    }

    if type(data) == 'table' then
        _.assign(item, data)
    end

    table.insert(self.items, item)
end

function Menu:addSeperator()
    table.insert(self.items, false)
end

return Menu