

local Take = require 'Take'
local _ = require '_'
local rea = require 'rea'

local MediaItem = class()

function MediaItem.getSelectedItems()
    local res = {}
    for i=0, reaper.CountSelectedMediaItems(0)-1 do
        local item = reaper.GetSelectedMediaItem(0,i)
        table.insert(res, MediaItem:create(item))
    end
    return res
end

function MediaItem.getAllItems()
    local res = {}
    for i=0, reaper.CountMediaItems(0) - 1 do
        table.insert(res, MediaItem:create(reaper.GetMediaItem(0, i)))
    end
    return res
end

function MediaItem:getPos()
    return reaper.GetMediaItemInfo_Value(self.item, 'D_POSITION')
end

function MediaItem:getEnd()
    return self:getPos() + self:getLength()
end

function MediaItem:create(item)
    local self = {
        item = item
    }
    setmetatable(self, MediaItem)
    return self
end

function MediaItem:getTrack()
    local Track = require 'Track'
    return Track:create(reaper.GetMediaItem_Track(self.item))
end

function MediaItem:__eq(other)
    return self.item == other.item
end

function MediaItem:__tostring()
    return tostring(self:getPos()) .. '-' .. tostring(self:getEnd())
end

function MediaItem:getLength()
    return reaper.GetMediaItemInfo_Value(self.item ,'D_LENGTH')
end

function MediaItem:getTakes()
    local res = {}
    for i = 0, self:getNumTakes() - 1 do
        table.insert(res, self:getTake(i))
    end
    return res
end

function MediaItem:getNumTakes()
    return reaper.GetMediaItemNumTakes(self.item)
end

function MediaItem:getActiveTake()
    local items = _.filter(self:getTakes(), function(take) return take:isActive() end, true)
    return _.first(items)
end

function MediaItem:getTake(index)
    index = index == nil and 0 or index
    local t = reaper.GetTake(self.item, index)
    return t and Take:create(t, self)
end

return MediaItem