local Track = require 'Track'
local Watcher = require 'Watcher'
local _ = require '_'


local Project = class()

Project.watch = {
    project = Watcher:create(function () return reaper.GetProjectStateChangeCount(0) end)
}

function Project.getStates()

    local state = true
    local i = 0

    local res = {}

    while state do
        local success, key, value = reaper.EnumProjExtState(0, 'D3CK', i)
        i = i + 1
        state = success
        if state then
            res[key] = value
        end
    end

    res._wised = _.filter(res, function(val, key)
        local trackId = key:match(Track.metaMatch)
        local track = Track.getTrackMap()[trackId]
        return not track or not track:exists()
    end)

    return res
end


function Project.getCurrentProject()
    return Project:create(reaper.EnumProjects(-1, ''))
end

function Project.getAllProjects()
    local proj = true
    local res = {}
    local i = 0
    while proj do
        proj = reaper.EnumProjects(i, '')
        i = i + 1
        if proj then
            table.insert(res,Project:create(proj))
        end
    end
    return res
end

function Project:create(proj)
    local self = {proj = proj}
    setmetatable(self, Project)
    return self
end

function Project:focus()
    reaper.SelectProjectInstance(self.proj)
    return self
end

function Project:getState()
    local i = 0
    local state = {}
    while true do
        local suc, key, val = reaper.EnumProjExtState(0, 'D3CK', i)
        if not suc then return state end
        state[key] = val
        i = i + 1
    end
end

return Project