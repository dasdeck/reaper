local Profiler = require 'Profiler'
local Window = require 'Window'
local Track = require 'Track'
local Mem = require 'Mem'
local Plugin = require 'Plugin'
local Watcher = require 'Watcher'
local WatcherManager = require 'WatcherManager'
local State = require 'State'
local json = require 'json'

local rea = require 'rea'
local _ = require '_'

local App = class()

function App:create(name)
    local self = {}
    assert(type(name) == 'string', 'app must have a name')
    self.state = State:create(name)

    self.mem = Mem:create(name)
    self.name = name
    self.watchers = WatcherManager:create()

    setmetatable(self, App)


    return self
end

function App:delete()
    self.watchers:clear()
end

function App:defer()

    local res, err = xpcall(function()

        Track.deferAll()
        Plugin.deferAll()
        Watcher.deferAll()

        if Window.currentWindow then
            Window.currentWindow:defer()
        end

        if self.onAfterDefer then self:onAfterDefer() end

    end, debug.traceback)

    if not res and self.options.debug then
        local context = {reaper.get_action_context()}
        rea.logPin('context', context)
        rea.logPin('error', err)
    else
        if self.running then
            reaper.defer(function()
                self:defer()
            end)
        end

    end

end

function App:stop()
    self.running = false
end

function App:start(options)

    options = options or {}
    options.debug = true
    self.running = true
    _.assign(self.options, options)
    App.current = self
    State.app = self.state
    Mem.app = self.mem

    if self.onStart then self:onStart() end

    if options.profile then

        options.debug = true

        local def = self.defer

        local profiler = Profiler:create({'gfx', 'reaper'})

        self.defer = function()

            local log = profiler:run(function() def(self) end, 1, options.profile == 'defer')


            local rank = _.map(log.calls.methods, function(meth) return meth end)
            table.sort(rank, function (a,b)
                return a.time > b.time
                -- return a.calls > b.calls
            end)

            local limitedRank = {}
            for i=1, math.min(100,#rank) do
                local sub = _.map(rank[i].children, function(meth) return meth end)
                table.sort(sub, function (a,b)
                    return a.time > b.time
                end)
                rank[i].children = sub
                table.insert(limitedRank, rank[i])
            end


            if self.getProfileData then
                log.data = self:getProfileData()
            end

            rea.logPin('profile', limitedRank)
            rea.logPin('getProfileData', log.data)


        end
    end

    if options.debug then
        reaper.atexit(function()
            rea.log('exited')
        end)

    end

    self:defer()
    return self
end


return App