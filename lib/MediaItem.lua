

local Take = require 'Take'
local MediaItem = class()

function MediaItem.getSelectedItems()
    local res = {}
    for i=0, reaper.CountSelectedMediaItems(0)-1 do
        local item = reaper.GetSelectedMediaItem(i)
    end
    return {}
end

function MediaItem:create(item)
    local self = {
        item = item
    }
    setmetatable(self, MediaItem)
    return self
end

function MediaItem:getTake(index)
    index = index == nil and 0 or index
    local t = reaper.GetTake(index)
    return t and Take:create(reaper.GetTake(index))
end

return MediaItem