local App = require 'App'
local Window = require 'Window'
local Component = require 'Component'
local Watcher = require 'Watcher'
local _ = require '_'

local WindowApp = class(App)

function WindowApp:create(name, component)

    local self = App:create(name)
    self.component = component
    setmetatable(self, WindowApp)

    return self

end

function WindowApp:getProfileData()
    return {
        watchers = {
            num = #_.filter(Watcher.watchers, function(w)
                return (#w.listeners) > 0
            end)
        },
        window = {
            -- numComps = #self.window.component:getAllChildren(),
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

function WindowApp:onStart()
    self.window = Window.openComponent(self.name, self.component)
    self.window.onClose = function()
        self:stop()
    end
end

return WindowApp