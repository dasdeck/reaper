local _ = require '_'
local paths = require 'paths'
local rea = require 'rea'

local Builder = class()


function Builder.build(file)

    local content = readFile(file)

    local sources = Builder.walk(content)

    local deps = '-- dep header --\n'
    deps = deps .. 'local _dep_cache = {} \n'
    deps = deps .. 'local _deps = { \n'
    deps = deps .. _.join(_.map(sources, function(src, name)
        local wrapper = name .. ' = function()\n'
        wrapper = wrapper .. src .. '\nend\n'
        return wrapper
    end), ',\n') .. '\n'
    deps = deps .. '} \n'

    deps = deps .. 'require = function(name) \n'
    deps = deps .. '    if not _dep_cache[name] then \n'
    deps = deps .. '        _dep_cache[name] = _deps[name]() \n'
    deps = deps .. '        end\n'
    deps = deps .. '    return _dep_cache[name] \n'
    deps = deps .. 'end \n'


    return deps .. content

end

function Builder.walk(src, sources)

    sources = sources or {}

    local deps = {}
    for match in src:gmatch("require '(.-)'") do
        table.insert(deps, match)
    end

    _.forEach(deps, function(dep)

        if not sources[dep] then

            local depFile = paths.scriptDir:findFile(function(file)
                return file == (dep .. '.lua')
            end)

            if not depFile then rea.log (dep) end

            local depSrc = readFile(depFile)

            sources[dep] = depSrc
            Builder.walk(depSrc, sources)

        end
    end)

    return sources

end

return Builder
