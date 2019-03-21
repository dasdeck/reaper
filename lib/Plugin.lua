local Slider = require 'Slider'

local rea = require 'Reaper'

local Plugin = class()

Plugin.plugins = {}

function Plugin.exists(name)

    local track = reaper.GetMasterTrack(0)
    local plugin = reaper.TrackFX_AddByName(track, name, false, -1)
    if plugin >= 0 then
        reaper.TrackFX_Delete(track, plugin)
        return true
    end
    return false
end

function Plugin.deferAll()
    Plugin.plugins = {}
end

function Plugin.getByGUID(track, guid)
    for i=0, reaper.TrackFX_GetCount(track)-1 do
        if reaper.TrackFX_GetFXGUID(track, i) == guid then return i end
    end
end

--

function Plugin:resolveIndex(nameOrIndex)
    if type(nameOrIndex) == 'string' then
        return rea.getFxByName(self.track, nameOrIndex, self.rec)
    else
        return nameOrIndex
    end
end

function Plugin:resolveParamIndex(nameOrIndex)
    if type(nameOrIndex) == 'string' then
        return rea.getParamByName(self.track, self.index, nameOrIndex)
    else
        return nameOrIndex
    end
end


function Plugin:create(track, index)
    local guid = reaper.TrackFX_GetFXGUID(track, index)

    if not Plugin.plugins[guid] then
        local p = {}
        setmetatable(p, Plugin)
        p.track = track
        p.rec = rec
        p.guid = guid
        Plugin.plugins[guid] = p
    end

    Plugin.plugins[guid].index = index

    return Plugin.plugins[guid]
end

function Plugin:isValid()
    return self.guid == reaper.TrackFX_GetFXGUID(self.track, self.index)
end

function Plugin:reconnect()
    self.index = Plugin.getByGUID(self.track, self.guid)
end

function Plugin:refresh()
    if not self:isValid() then self:reconnect() end
    return self:isValid()
end

function Plugin:setIndex(index)
    if self.index ~= index then
        reaper.TrackFX_CopyToTrack(self.track, self.index, self.track, index, true)
        self.index = index
    end
    return self
end

function Plugin:isOpen()
    return reaper.TrackFX_GetOpen(self.track, self.index)
end

function Plugin:getName()
    local success, name = reaper.TrackFX_GetFXName(self.track, self.index, '')
    return success and name
end

function Plugin:setPreset(nameOrIndex)
    reaper.TrackFX_SetPreset(self.track, self.index, nameOrIndex)
end

function Plugin:getPreset()
    local s, name = reaper.TrackFX_GetPreset(self.track, self.index, 1)
    return name
end

function Plugin:remove()
    reaper.TrackFX_Delete(self.track, self.index)
    Plugin.plugins[self.guid] = nil
end

function Plugin:open(show)
    reaper.TrackFX_SetOpen(self.track, self.index, show == nil and false or true)
end

function Plugin:setParam(nameOrIndex, value)

    if not self:refresh() then return end

    if type(nameOrIndex) == 'string' then
        local res = reaper.TrackFX_SetNamedConfigParm(self.track, self.index, nameOrIndex, value)
        if not res then self:setParam(self:resolveParamIndex(nameOrIndex), value) end
    else
        return reaper.TrackFX_SetParam(self.track, self.index, nameOrIndex, value)
    end

end

function Plugin:getParam(nameOrIndex)

    if type(nameOrIndex) == 'string' then
        local res, val = reaper.TrackFX_GetNamedConfigParm(self.track, self.index, nameOrIndex)
        if res then
            return val
        else
            return self:getParam(self:resolveParamIndex(nameOrIndex))
        end
    elseif type(nameOrIndex) == 'number' then
        return reaper.TrackFX_GetParam(self.track, self.index, nameOrIndex)
    end

end

function Plugin:createSlider(index)
    local slider = Slider:create()
    local plugin = self
    slider.getValue = function()
        return plugin:getParam(index)
    end
    function slider:setValue(value)
        plugin:setParam(index, value)
    end
    return slider
end

return Plugin