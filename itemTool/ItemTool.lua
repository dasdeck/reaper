local Component = require 'Component'
local TextButton = require 'TextButton'


local ItemTool = Component.extent()

function ItemTool:create()
    local self = Component:create()

    setmetatable(ItemTool)
    return self
end

return ItemTool