local App = require 'App'
local State = require 'State'
local Window = require 'Window'
local PluginGrid = require 'PluginGrid'
local paths = require 'paths'
local rea = require 'rea'
local _ = require '_'

local PluginListApp = class(App)

function PluginListApp:create(name)
    name = name or 'pluginlist'
    local self = App:create(name)
    setmetatable(self, PluginListApp)

    self.watchers:watch(function()
        return self.mem:get(0)
    end, function(value)
        if value > 0 then
            if self:getWindow() then
                self.window.component:setDir(self.state:get('dir', paths.imageDir))
                self.window:show()
            end
            if self.onShow then
                self:onShow()
            end
        elseif value < 0 then

            if self.onClose then self:onClose() end
            if self:getWindow() then
                self.window:close()
            end
        end
    end, false)

    self.watchers:watch(function()
        return self.mem:get(1)
    end, function(value)
        if value > 0 then
            if self.onClick then
                self:onClick(self.state:get('lastclicked'))
            end
        end
    end, false)

    return self
end

function PluginListApp.pick(cat, callback)

    local instance = PluginListApp:create(cat)
    instance.onClick = function(s, res)
        callback(res)
        instance.onClick = nil
        instance:close()
    end

    instance:showModal(cat)
    local shownAgain = false
    instance.onShow = function()
        if shownAgain then
            instance.onClick = nil
            instance:delete()
        end
        shownAgain = true
    end

end

function PluginListApp:showModal(cat)
    self:setCategory(cat)
    self.onClose = function()
        self:delete()
    end
    self:show()
end

function PluginListApp:onStart()

    -- if self.options.debug and tonumber(self.state:get('window_open', 0)) > 0 then
    --     self:show()
    -- end

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

function PluginListApp:getWindow()
    if not self.window and self.running then
        self.window = Window:create(self.name, PluginGrid:create(self.state:get('dir', paths.imageDir)), {
            closeOnEsc = true,
            wFromComponent = true
        })
        self.window.onClose = function()
            self:close()
        end
    end
    return self.window
end

function PluginListApp:show()
    -- self.state:set('window_open', 1)
    self.mem:set(0, math.max(0, self.mem:get(0)) + 1)


    return self
end

function PluginListApp:close()
    -- self.state:set('window_open', 0)
    self.mem:set(0, math.min(0, self.mem:get(0)) - 1)


    return self
end

return PluginListApp
