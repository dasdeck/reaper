local Component = require 'Component'
local Key = require 'Key'
local Project = require 'Project'
local _ = require '_'

local Keyboard = class(Component)

function Keyboard.create(lo, hi, vert)

    local self = Component:create()
    setmetatable(self, Keyboard)
    self.vert = vert
    self.lo = lo or 0
    self.hi = hi or 127

    self:update()

    self.watchers:watch(Project.watch.project, function()
        self:update()
    end, false)

    return self
end

function Keyboard:update()

    self:deleteChildren()
    self.keys = {}
    local num = (self.hi - self.lo) + 1
    for i = 0, num do
        table.insert(self.keys, self:addChildComponent(Key.create(i + self.lo)))
    end

    self:resized()
end

function Keyboard:resized()

    local size = self[self.vert and 'h' or 'w'] / _.size(self.children)

    _.forEach(self.keys, function(child, i)
        if self.vert then
            child:setBounds(0 , (i-1) * size, self.w , size - 1)
        else
            child:setBounds((i-1) * size , 0, size - 1 , self.h)
        end
    end)

end

return Keyboard