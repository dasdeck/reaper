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
    self.h = 1000
    if self.dir ~= dir then

        -- rea.log('dirset:' .. tostring(dir))
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
                data.size = -numLists/totalSubLists
            end)
            self.w = totalSubLists * 160

        else
            self.list = self:addChildComponent(PluginList:create(dir))
        end
        self.dir = dir
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
    -- self.title:setBounds(0,0,self.w, h)
    if self.subgrids then
        self.subgrids:setBounds(0, self.title:getBottom(), self.w, h)
    else
        self.list:setBounds(0, self.title:getBottom(), self.w, self.list.h)
    end

    self.h = gfx.h --(self.subgrids or self.list):getBottom()
end


return PluginGrid