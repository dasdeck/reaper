local App = require 'App'
local Window = require 'Window'
local Component = require 'Component'
local WindowApp = class(App)

function WindowApp:create(name, component)

    local self = App:create(name)
    self.component = component
    setmetatable(self, WindowApp)

    return self

end

function WindowApp:getProfileData()
    return {
        window = {
            numComps = #self.window.component:getAllChildren()
        },
        component = {
            numComps = Component.numInstances
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