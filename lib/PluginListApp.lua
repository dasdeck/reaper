local WindowApp = require 'WindowApp'
local PluginGrid = require 'PluginGrid'
local paths = require 'paths'
local rea = require 'rea'
local _ = require '_'

local PluginListApp = class(WindowApp)

function PluginListApp:create(name)
    name = name or 'pluginlist'
    local self = WindowApp:create(name)
    setmetatable(self, PluginListApp)

    return self
end

function PluginListApp:onShow()
    if self.window then
        self.window.component:setDir(self.state:get('dir', paths.imageDir))
    end
end

function PluginListApp.pick(cat, callback)

    local instance = PluginListApp:create(cat)
    instance.onClick = function(s, res)
        callback(res)
        instance.onClick = nil
        instance:close()
    end

    instance:showModal(cat)

    local shown = false
    instance.onShow = function()
        if shown then
            instance.onClick = nil
            instance:delete()
        end
        shown = true
    end

end

function PluginListApp:showModal(cat)
    self:setCategory(cat)
    WindowApp.showModal(self)
end


PluginListApp.catMap = {
    instruments = paths.imageDir:childDir('instruments'),
    effects = paths.imageDir:childDir('effects')
}

PluginListApp.cats = _.map(PluginListApp.catMap, function(dir, cat) return cat, cat end)

function PluginListApp:setCategory(cat)
    self.state:set('dir', tostring(cat and PluginListApp.catMap[cat] or paths.imageDir))
    if self.window then
        self.window.component:setDir(self.state:get('dir', paths.imageDir))
    end
end

function PluginListApp:getWindowOptions()
    return {
        closeOnEsc = true,
        wFromComponent = true
    }
end

function PluginListApp:createComponent()
    return PluginGrid:create(self.state:get('dir', paths.imageDir))
end

return PluginListApp
