local Component = require 'Component'
local ButtonList = require 'ButtonList'
local TextButton = require 'TextButton'
local Directory = require 'Directory'
local PluginList = require 'PluginList'

local _ = require '_'
local rea = require 'rea'

local PluginGrid = class(Component)

function PluginGrid:create(dir)

    dir = Directory:create(dir)
    ratio = ratio or 1
    -- rea.log(dir.dir)
    local self = Component:create()
    setmetatable(self, PluginGrid)

    self.title = self:addChildComponent(TextButton:create(_.last(dir.dir:split('/'))))
    local subdirectories = dir:getDirectories()
    -- rea.log(subdirectories)
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
        -- rea.log(totalSubLists)

        _.forEach(self.subgrids.children, function(grid, i)

            local data = self.subgrids.data[i]
            local numLists = grid:getNumLists()
            data.size = -numLists/totalSubLists
            -- rea.log(self.w)
        end)


    else
        self.list = self:addChildComponent(PluginList:create(dir))
    end

    return self
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
    self.title:setBounds(0,0,self.w, h)
    if self.subgrids then
        self.subgrids:setBounds(0,30, self.w, h)
    else
        self.list:setBounds(0, self.title:getBottom(), self.w, h)
    end
end

return PluginGrid