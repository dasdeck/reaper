local App = require 'App'
local State = require 'State'
local Window = require 'Window'
local Component = require 'Component'

local rea = require 'rea'
local _ = require '_'

local WindowApp = class(App)

function WindowApp:create(name, options)

    local self = App:create(name)
    setmetatable(self, WindowApp)

    if instanceOf(options, Component) then
        -- rea.log('legacy')
        options = {
            exitOnClose = true,
            component = options,
            showOnStart = true
        }
    end

    self.options = options or {}

    self.watchers:watch(function()
        return self.mem:get(0)
    end, function(value)
        if value > 0 then
            if self:getWindow() then
                self.window:show()
            end
            if self.onShow then
                self:onShow()
            end
        elseif value < 0 then

            if self:getWindow() then
                self.window:close()
            else
            end

            if self.onClose then
                self:onClose()
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

function WindowApp.pick(cat, callback)

    local instance = WindowApp:create(cat)
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

function WindowApp:onStart()
    -- rea.log('stratShow')
    if self.options.showOnStart then
        self:show()
    end
end

function WindowApp:getProfileData()
    return {
        watchers = {
            num = #_.filter(Watcher.watchers, function(w)
                return (#w.listeners) > 0
            end)
        },
        window = {
            numComps = #self.window.component:getAllChildren(),
            paints = self.window.paints
        },
        component = {
            numComps = Component.numInstances,
            numCompsInMem = Component.numInMem,
            noSlots = #_.filter(Component.slots, function(slot) return slot end),
            -- slots = _.filter(Component.slots, function(slot) return slot end)
        }
    }
end


function WindowApp:showModal(cat)
    self.onClose = function()
        self:delete()
    end
    self:show()
end

function WindowApp:getWindowOptions()
    return self.options.window or {}
end

function WindowApp:createComponent()
    return self.options.component
end

function WindowApp:getWindow()
    if not self.window and self.running then
        self.window = Window:create(self.name, self:createComponent(), self:getWindowOptions())

        if self.options.exitOnClose then
            self.window.onClose = function()
                self:stop()
            end
        end

        self.window.onClose = function()
            self:close()
        end
    end
    return self.window
end

function WindowApp:show()
    self.mem:set(0, math.max(0, self.mem:get(0)) + 1)
    return self
end

function WindowApp:close()
    self.mem:set(0, math.min(0, self.mem:get(0)) - 1)
    return self
end

return WindowApp
