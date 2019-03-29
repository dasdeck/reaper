local _ = require '_'
local rea = require 'rea'

local timer = reaper.time_precise

local Profiler = class()

function Profiler:create(libs)
    local self = {
        libs = libs
    }
    setmetatable(self, Profiler)

    self.unwrappedLibs = _.map(libs, function(name)
        return _G[name], name
    end)

    self.wrappedLibs = _.map(self.unwrappedLibs, function(lib, key)
        return _.map(lib, function(member, name)
            local fullname = key .. '.' .. name
            if type(member) == 'function' then
                return function(...)

                    self.profile.totalCalls = self.profile.totalCalls + 1

                    local meth = self.profile.methods[fullname]
                    if not meth then
                        meth = {
                            time = 0,
                            calls = 0
                        }
                        self.profile.methods[fullname] = meth
                    end

                    local pre = timer()
                    local res = {member(...)}

                    meth.calls = meth.calls + 1
                    meth.time = meth.time + timer() - pre

                    meth.__tostring = function(self)
                        return tostring(self.calls) .. ', ' .. tostring(self.time)
                    end

                    return table.unpack(res)
                end, name

            end
        end), key
    end)

    -- rea.logPin(dump(self.unwrappedLibs))

    return self
end

function Profiler:unWrap()
    _.forEach(self.unwrappedLibs, function(lib, libName)
        _.forEach(lib, function(func, name)
            _G[libName][name] = func
        end)
    end)
end

function Profiler:wrap()
    _.forEach(self.wrappedLibs, function(lib, libName)
        _.forEach(lib, function(func, name)
            _G[libName][name] = func
        end)
    end)
end

function Profiler:run(func, loop, reset)

    loop = loop or 100000

    if reset or not self.profile then
        self.profile = {
            totalCalls = 0,
            methods = {}
        }
    end

    self:wrap()

    local pre = timer()
    for i = 1, loop do
        func()
    end
    local time = timer() - pre

    self:unWrap()

    return {
        mem = collectgarbage('count'),
        time = time * 1000,
        calls = self.profile
    }


end

return Profiler