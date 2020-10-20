local Slider = require 'Slider'

local rea = require 'rea'
local paths = require 'paths'
local colors = require 'colors'
local JSON = require 'json'

local Plugin = class()
local _ = require '_'

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

function Plugin:setIO(i, o)
    reaper.TrackFX_SetPinMappings(self.track.track, self.index, 1, 0, 2^(o*2),0)
    reaper.TrackFX_SetPinMappings(self.track.track, self.index, 1, 1, 2^(o*2+1),0)
    reaper.TrackFX_SetPinMappings(self.track.track, self.index, 0, 0, 2^(i*2),0)
    reaper.TrackFX_SetPinMappings(self.track.track, self.index, 0, 1, 2^(i*2+1),0)
end

function Plugin:getIO()
    local res, i ,o reaper.TrackFX_GetIOSize(self.track.track, self.index)
    if res then return i , o end
end

function Plugin.getByGUID(track, guid)
    for i=0, reaper.TrackFX_GetCount(track)-1 do
        if reaper.TrackFX_GetFXGUID(track, i) == guid then return i end
    end
end
--

function Plugin:create(track, index, rec)
    local guid = reaper.TrackFX_GetFXGUID(track.track, index)

    assert(guid, 'index:' ..  tostring(index))

    -- if not Plugin.plugins[guid] then
        local p = {}
        setmetatable(p, Plugin)
        p.track = track
        p.rec = rec
        p.guid = guid
        Plugin.plugins[guid] = p
    -- end

    Plugin.plugins[guid].index = index

    return Plugin.plugins[guid]
end

function Plugin:getJSONsettings()
    local instrName = self.track:getName()
    local settings = paths.imageDir:findFile(instrName .. '.json')
    if settings then
        self._settings = JSON.parse(readFile(settings))
    end
    return self._settings
end

function Plugin:getParamSteps(param)
    local index = self:resolveParamIndex(param)
    local retval,  step,  smallstep,  largestep,  istoggle = reaper.TrackFX_GetParameterStepSizes(self.track.track, self.index, index)
    -- rea.log(step)
    return step
end

function Plugin:getParamString(param)
    local index = self:resolveParamIndex(param)
    local retval, name = reaper.TrackFX_GetFormattedParamValue(self.track.track, self.index, index, '')
    -- rea.log(name)
    return name
end

function Plugin:initSettings()


    local settings = self:getJSONsettings()

    if settings then
        local res = self:getOutputs()
        if settings.outs then
            if settings.outs == 'all' then
                _.forEach(res, function(out)
                    out:createConnection()
                end)
            elseif settings.outs > 0 then
                for i=1,settings.outs do
                    if res[i] ~= nil then
                        res[i]:createConnection()
                    end
                end
            end
        end
    end
end

function Plugin:resolveIndex(nameOrIndex)
    if type(nameOrIndex) == 'string' then
        return rea.getFxByName(self.track.track, nameOrIndex, self.rec)
    else
        return nameOrIndex
    end
end

function Plugin:resolveParamIndex(nameOrIndex)
    if type(nameOrIndex) == 'string' then
        return rea.getParamByName(self.track.track, self.index, nameOrIndex, true)
    else
        return nameOrIndex
    end
end

function Plugin:getIndex()
    return self.index
end

function Plugin:__eq(other)
    self:refresh()
    other:refresh()

    return other.index == self.index and self.track == other.track
end

function Plugin:getState()
    return self.track:getState():getPlugins()[self.index + 1]
end

function Plugin:getModule()
    local res, name =  reaper.BR_TrackFX_GetFXModuleName(self.track.track, self.index, '', 10000)
    return name
end

function Plugin:isValid()
    return self.guid == reaper.TrackFX_GetFXGUID(self.track.track, self.index)
end

function Plugin:reconnect()
    self.index = Plugin.getByGUID(self.track.track, self.guid)
end

function Plugin:getEnabled()
    return reaper.TrackFX_GetEnabled(self.track.track, self.index)
end

function Plugin:setEnabled(enabled)
    reaper.TrackFX_SetEnabled(self.track.track, self.index, enabled)
end

function Plugin:toggleEnabled()
    self:setEnabled(not self:getEnabled())
end

function Plugin:setOffline(enabled)
    reaper.TrackFX_SetOffline(self.track.track, self.index, enabled)
end

function Plugin:getOffline()
    return reaper.TrackFX_GetOffline(self.track.track, self.index)
end

function Plugin:refresh()
    if not self:isValid() then self:reconnect() end
    return self:isValid()
end

function Plugin:setIndex(index, targetTrack, copy, noUpdate)

    self:refresh()
    targetTrack = targetTrack or self.track
    if self.index ~= index or targetTrack ~= self.track then
        reaper.TrackFX_CopyToTrack(self.track.track, self.index, targetTrack.track, index, not copy and true or false)
        self.index = index
        self.track = targetTrack
        if noUpdate then return end
        self.track:updateFxRouting()
    end
    return self
end

function Plugin:getName()
    local success, name = reaper.TrackFX_GetFXName(self.track.track, self.index, '')
    return success and name
end

function Plugin:getPluginName()
    local state = self.track:getState(true).text
    local title = self:getName():escaped()
    -- rea.log(state)
    -- rea.log(title)

    local type = state:match('\n<([AUVST3]-) "')
    local pattern
    if type == 'VST' then
        pattern = '\n<VST "'.. title ..'" (.-%..-) (.-)\n'
    elseif type == 'AU' then
        pattern = '\n<AU "'.. title ..'" "(.-)" (.-)\n'
    end


    local name, rest = state:match(pattern)
    -- rea.log({type, name, ending, rest})
    return name, type, rest
end

function Plugin:getCleanName()
    return self:getName():gsub('%(.-%)', ''):gsub('.-: ', ''):trim()
end

function Plugin:getImage()
    local pattern = self:getCleanName():escaped():gsub('ZL', '')
    return paths.imageDir:findFile(function(file) return file:lower() == pattern:lower() .. '.png' end) or paths.imageDir:findFile(pattern)
end

local function isStereoPair(a, b)
    if b == a then return a end

    if a and b then
        local partsA = a:split(' ')
        local partsB = b:split(' ')
        if _.last(partsB):lower() == 'r' and (#partsB == #partsA + 1 or _.last(partsA):lower() == 'l') then
            return b:sub(1,-3)
        end
    end
end

function Plugin:getOutputs()
    local succ, i, o = reaper.TrackFX_GetIOSize(self.track.track, self.index)
    -- rea.log(i ..'o'..o)
    local res = {}
    if succ then

        local current = {}
        for i=0, o-1 do
            local succ, name = reaper.TrackFX_GetNamedConfigParm(self.track.track, self.index, 'out_pin_' .. tostring(i))
            local stereoName = isStereoPair(current.name, name)
            if  current and stereoName then -- hack for kontakt
                current.name = stereoName
                table.insert(current.channels, i)
            else

                current = {
                    fx = self,
                    name = name,
                    index = i,
                    channels = {
                        i
                    }
                }

                table.insert(res, current)
            end
        end

        local name = self.track:getName()

        _.forEach(res, function(current, i)


            current.sourceChan = function()
                local source = current.channels[1]
                if  _.size(current.channels) == 1 then
                    source = source | 1024
                end
                return source
            end
            current.createConnection = function()

                if current.getConnection() then
                    -- local out = current.getConnection():getTargetTrack()
                    -- if not out:getName() then out:setName(current.name) end
                    return
                end

                local outputTrack = self.track.insert()

                local numChansNeeded = current.channels[1] + _.size(current.channels)
                numChansNeeded = math.ceil(numChansNeeded / 2) * 2
                self.track:setValue('chans', math.max(self.track:getValue('chans'), numChansNeeded))

                outputTrack:setType(outputTrack.typeMap.output)
                outputTrack:setColor(colors.instrument:lighten_by(2))
                outputTrack:setName(current.name)
                outputTrack:setIcon(paths.imageDir:findFile(name .. '/' .. current.name) or self.track:getIcon())
                outputTrack:setVisibility(false, true)
                outputTrack:setOutput(self.track:getOutput())
                outputTrack:setManaged(self.track)
                outputTrack:setParent(self.track:getParent()    )

                local send = self.track:createSend(outputTrack)

                send:setAudioIO(current.sourceChan(), 0)
                send:setMidiBusIO(-1, -1)
                send:setMode(3)
                return send
            end

            current.getTrack = function()
                --  if i == 1 then
                --     return self.track
                --  else
                if current.getConnection() then
                    return current.getConnection():getTargetTrack()
                end
            end

            current.getConnection = function()
                return _.some(self.track:getSends(), function(send)
                    local i = send:getAudioIO()
                    return send:getMode() == 3 and
                    -- send:getTargetTrack():getName() == current.name and
                    i == current.sourceChan() and send
                end)
            end
        end)

        if _.size(res) == 2 and _.reduce(res, function(car, val)
            return car and _.size(val.channels) == 1
        end, true) then
            table.insert(res[1].channels, res[2].channels[1])
            res[2] = nil
        end

        if _.size(res) == 1 then
            local succ, name = reaper.TrackFX_GetNamedConfigParm(self.track.track, self.index, 'out_pin_' .. tostring(0))
            -- rea.log(tostring(succ) .. 'n:' .. name)
            res[1].name = succ and name or self.track:getSafeName()
        end

    end
    return res
end

function Plugin:canDoMultiOut()
    local outs = self:getOutputs()
    return _.size(outs) > 1 and _.size(outs[1].channels) > 1 or _.size(outs) > 2
end

function Plugin:isMultiOut()
    return _.some(self:getOutputs(), function(output)
        return output.channels[1] > 0 and output.getConnection()
    end)
end


-- function Plugin:createMultiOut()

--     local outs = self:getOutputs()
--     local track = self.track

--     track:setValue('chans', _.reduce(outs, function(car, out) return _.size(out.channels) end, 0))
--     track:setValue('toParent', false)
--     _.forEach(outs, function(output)
--         output.createConnection()
--     end)
-- end

function Plugin:setPreset(name)
    reaper.TrackFX_SetPreset(self.track.track, self.index, name)
end

function Plugin:getPreset()
    local s, name = reaper.TrackFX_GetPreset(self.track.track, self.index, '')
    return name, s
end

function Plugin:remove()
    reaper.TrackFX_Delete(self.track.track, self.index)
    Plugin.plugins[self.guid] = nil
    self.track:updateFxRouting()
end

function Plugin:isSampler()
    return self:getParam('FILE0') ~= nil
end

function Plugin:toggleOpen()
    self:open(not self:isOpen())
end

function Plugin:open(show)
    show = show == nil and true or show
    if show then
        reaper.TrackFX_Show(self.track.track, self.index, 3)
    else
        reaper.TrackFX_Show(self.track.track, self.index, 2)
    end
end

function Plugin:close()
    self:open(false)
end

function Plugin:isOpen()
    return reaper.TrackFX_GetOpen(self.track.track, self.index)
end

function Plugin:setParam(nameOrIndex, value)

    if not self:refresh() then return end

    if type(nameOrIndex) == 'string' then
        -- local res = reaper.TrackFX_SetNamedConfigParm(self.track.track, self.index, nameOrIndex, value)
        local index = self:resolveParamIndex(nameOrIndex)
        -- if nameOrIndex == 'Spk MidG' then rea.log(index .. '=>' .. value) end
        self:setParam(index, value)
    else
        -- if nameOrIndex == 6 then rea.log(self.index .. ':' .. nameOrIndex .. '=>' .. value) end
        return reaper.TrackFX_SetParam(self.track.track, self.index, nameOrIndex, value)
    end

end

function Plugin:getParam(nameOrIndex)

    if type(nameOrIndex) == 'string' then
        -- local res, val = reaper.TrackFX_GetNamedConfigParm(self.track.track, self.index, nameOrIndex)
        -- if res then
        --     return val
        -- else
            return self:getParam(self:resolveParamIndex(nameOrIndex))
        -- end
    elseif type(nameOrIndex) == 'number' then
        return reaper.TrackFX_GetParam(self.track.track, self.index, nameOrIndex)
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