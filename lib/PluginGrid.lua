local Component = require 'Component'
local ButtonList = require 'ButtonList'
local TextButton = require 'TextButton'
local Directory = require 'Directory'
local PluginList = require 'PluginList'

local _ = require '_'
local rea = require 'rea'

local PluginGrid = class(Component)

function PluginGrid:create(dir)
    local self = Component:create()
    setmetatable(self, PluginGrid)

    self:setDir(dir)

    return self
end

function PluginGrid:setDir(dir)

    dir = Directory:create(dir)
    self.h = gfx.h
    if self.dir ~= dir then

        self:deleteChildren()

        self.title = self:addChildComponent(TextButton:create(_.last(dir.dir:split('/'))))

        local subdirectories = dir:getDirectories()
        if _.size(subdirectories) > 0 then

            self.subgrids = self:addChildComponent(ButtonList:create(_.map(subdirectories, function(subdir)
                return {
                    proto = function()
                        local subgrid = PluginGrid:create(subdir)
                        return subgrid
                    end
                }
            end), true))

            local totalSubLists = self:getNumLists()

            _.forEach(self.subgrids.children, function(grid, i)
                local data = self.subgrids.data[i]
                local numLists = grid:getNumLists()
                data.size = -numLists / totalSubLists
            end)
            self.w = totalSubLists * 160

        else
            self.w = 160
            self.list = self:addChildComponent(PluginList:create(dir))

        end

        self.dir = dir
        self:resized()
    end
end

function PluginGrid:getNumLists()
    if self.subgrids then
        return _.reduce(self.subgrids.children, function(mem, row)
            return mem + row:getNumLists()
        end, 0)
    else
        return 1
    end
end

function PluginGrid:resized()

    local h = 20

    if self.subgrids then
        self.subgrids:setBounds(0, self.title:getBottom(), self.w)
    else
        self.list:setBounds(0, self.title:getBottom(), self.w)
    end

    self.h = gfx.h
end


return PluginGrid