local JSFXCom = class()
local _ = require '_'

--package

JSFXCom.instances = {}
function JSFXCom.deferAll()
    _.forEach(JSFXCom.instances, function(instance)
        instance:defer()
    end)
end

function JSFXCom:create(memname, pluginname , instanceparam)
    local self = {
        memname = memname,
        pluginname = pluginname,
        instanceparam = instanceparam
    }
    setmetatable(self, JSFXCom)
    return self
end

function JSFXCom:updateInstances()

end

function JSFXCom:push(len, data)
    reaper.gmem_attach(self.memname)
    local numMessages = reaper.gmem_read(0)
end

function JSFXCom:defer()
    reaper.gmem_attach(self.memname)
    local val = reaper.gmem_read(0)
    if val < 0 then
        local instance = val
    end
    -- body
end

return JSFXCom