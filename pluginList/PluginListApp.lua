local App = require 'App'
local State = require 'State'
local Window = require 'Window'
local PluginGrid = require 'PluginGrid'
local paths = require 'paths'
local rea = require 'rea'

local PluginListApp = class(App)

function PluginListApp:create()
    local self = App:create('pluginlist')
    setmetatable(self, PluginListApp)

    self.watchers:watch(function()
        return self.mem:get(0)
    end, function(value)
        if value == 1 then self:show() else self:close() end
    end)

    self.watchers:watch(function()
        return self.mem:get(1)
    end, function(value)
        if value > 0 then
            if self.onClick then
                -- rea.log('clicked:' .. tostring(value) ..  ':' .. self.state:get('lastclicked'))
                self:onClick(self.state:get('lastclicked'))
            end
        end
    end, false)

    return self
end

function PluginListApp:onStart()

    self.window = Window:create(self.name, PluginGrid:create(self.state:get('dir', paths.imageDir)))
    self.window.onClose = function()
        rea.log('closed')
        self:close()
    end

    if tonumber(self.state:get('window_open', 0)) > 0 then
        self:show()
    end

end

local cats = {

}
function PluginListApp:setCategory(cat)
    self.state.set('dir', cats[cat] or paths.imageDir)
end


function PluginListApp:show()
    self.state:set('window_open', 1)
    self.mem:set(0, 1)
    if self.window then
        self.window:show()
    end
end

function PluginListApp:close()
    self.state:set('window_open', 0)
    self.mem:set(0, 0)
    if self.window then
        self.window:close()
    end
end

return PluginListApp
