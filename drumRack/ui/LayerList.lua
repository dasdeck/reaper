local Component = require 'Component'
local Layer = require 'Layer'
local Project = require 'Project'
local rea = require 'Reaper'
local _ = require '_'

local LayerList = class(Component)

function LayerList:create(pad)
    self = Component:create()
    self.pad = pad
    setmetatable(self, LayerList)

    self._changeCallback = function()
        self:update()
    end
    Project.watch.project:onChange(self._changeCallback)

    self:update()
    return self
end

function LayerList:onDelete()
    Project.watch.project:removeListener(self._changeCallback)
end


function LayerList:update()

    local layers = self.pad:getLayers()

    if _.equal(layers, self.layers) then return end

    self.layers = layers

    self.children = {}

   _.forEach(layers, function(layer)
        self:addChildComponent(Layer:create(layer, self.pad))
   end)
end

function LayerList:resized()

    -- self:update()

    local size = 20
    for i, child in pairs(self.children) do
        child.w = self.w
        child.x = 0

        child.y = (i - 1) * size
        child.h = size
    end

end

return LayerList