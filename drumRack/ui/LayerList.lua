local Component = require 'Component'
local Layer = require 'Layer'
local Project = require 'Project'
local rea = require 'rea'
local _ = require '_'

local LayerList = class(Component)

function LayerList:create(pad)
    self = Component:create()
    self.pad = pad
    setmetatable(self, LayerList)

    self.watchers:watch(Project.watch.project, function()
        self:update()
    end)

    self:update()
    return self
end


function LayerList:update()

    local layers = self.pad:getLayers()

    -- if _.equal(layers, self.layers) then return end

    -- self.layers = layers


    self:deleteChildren()

   _.forEach(layers, function(layer)
        self:addChildComponent(Layer:create(layer, self.pad))
   end)
end

function LayerList:resized()

    local size = 20
    for i, child in pairs(self.children) do
        child:setBounds(0, (i - 1) * size,self.w, size)
    end
end

return LayerList