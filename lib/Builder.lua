local _ = require '_'
local paths = require 'paths'
local rea = require 'rea'

local Builder = class()

function Builder.build(file, done)
    done = done or {}

    local content = readFile(file)
    deps = {}

    for match in content:gmatch("require '(.-)'") do
        table.insert(deps, match)
    end

    _.forEach(deps, function(dep)

        local patternA = "local "..dep.." = require '"..dep.. "'\n"
        local patternB = "require '"..dep.. "'\n"
        local pattern = content:match(patternA) and patternA or patternB

        if not _.find(done, dep) then

            table.insert(done, dep)
            local lookup = dep .. '.lua'
            local depFile = paths.scriptDir:findFile(function(file)
                return file == lookup
            end)
            assert(depFile, lookup)

            local depContent = Builder.build(depFile, done)
            content = content:gsub(pattern, depContent:gsub('%%', '%%%%') .. '\n')
        else
            content = content:gsub(pattern, '')
        end
    end)

    return content

end

return Builder
