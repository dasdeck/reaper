local _require = require
local loadedLibs = {}

require = function(lib)
    local res = _require(lib)
    if type(res) == 'table' and lib ~= 'Profiler' then
        loadedLibs[lib] = res
    end

    return res
end

local _ = require '_'
local rea = require 'rea'

local timer = reaper.time_precise

local Profiler = {}
Profiler.__index = Profiler

function Profiler.getLib(name)
    return loadedLibs[name] or _G[name]
end

function Profiler:create(libs)

    libs = libs or {}
    libs = _.concat(libs, _.map(loadedLibs, function(e, name) return name end))

    rea.log({
        profiling = libs
    })
    local self = {
        libs = libs
    }

    Profiler.instance = self
    setmetatable(self, Profiler)

    self.unwrappedLibs = _.map(libs, function(name)
        return Profiler.getLib(name), name
    end)

    self.wrappedLibs = _.map(self.unwrappedLibs, function(lib, key)
        return _.map(lib, function(member, name)
            local fullname = key .. '.' .. name
            if type(member) == 'function' then
                return function(...)

                    self.profile.totalCalls = self.profile.totalCalls + 1

                    local meth = self:getSlot(fullname)
                    local methPlus = self:getSlot(self:getStackAddress() .. ':' .. fullname, meth.children)

                    self.profile:push(meth)

                    local pre = timer()

                    local res = {member(...)}

                    local t = (timer() - pre) * 1000

                    methPlus.calls = methPlus.calls + 1
                    methPlus.time = methPlus.time + t

                    meth.calls = meth.calls + 1
                    meth.time = meth.time + t

                    self.profile:pop()

                    return table.unpack(res)
                end, name
            else
                return member
            end
        end), key
    end)

    return self
end

function Profiler:getStackAddress()
    local pos = self.profile.tree

    local res = ''

    while pos do
        res = (pos.method.name) .. '::' .. res
        pos = pos.caller
    end
    return res
end

function Profiler:getSlot(name, parent)
    parent = parent or self.profile.methods
    local meth = parent[name]
    if not meth then
        meth = {
            time = 0,
            calls = 0,
            name = name,
            children = {},
            __tostring = function(self)
                local header = name .. ':' .. tostring(self.calls) .. ', ' .. tostring(self.time)
                if _.size(self.children) > 0 then
                    header = header .. '\n' .. _.join(_.map(self.children, function(child) return child.__tostring(child) end), '\n')
                end
                return header
            end
        }

        parent[name] = meth
    end
    return meth
end

function Profiler:unWrap()
    _.forEach(self.unwrappedLibs, function(lib, libName)
        _.forEach(lib, function(func, name)
            Profiler.getLib(libName)[name] = func
        end)
    end)
end

function Profiler:wrap()
    _.forEach(self.wrappedLibs, function(lib, libName)
        _.forEach(lib, function(func, name)
            Profiler.getLib(libName)[name] = func
        end)
    end)
end

function Profiler:reset()
    self.profile = {
        totalCalls = 0,
        methods = {},
        tree = {
            method = {name = 'ROOT'},
            children = {}
        },
        push = function(self, method)
            local next = {
                caller = self.tree,
                method = method,
                children = {}
            }
            table.insert(self.tree.children, next)
            self.tree = next
        end,
        pop = function(self)
            self.tree = self.tree.caller
        end
    }
end

function Profiler:run(func, loop, reset)

    loop = loop or 100000

    if reset or not self.profile then
        self:reset()
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