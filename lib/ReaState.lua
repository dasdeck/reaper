local _ = require '_'

local ReaState = class()

function ReaState.parse(string)

    local section = {
        name = '__ROOT__',
        header = {},
        entries = {},
        sections = {}
    }
    _.forEach(string:split('\n'), function(line)
        line = line:trim()
        local entry = line:split(' ', '"')
        if _.size(entry) > 1 then
            local name = entry[1]
            local values = clone(entry)
            values[1] = nil

            if line:startsWith('<') then
                local subSection = {
                    parent = section,
                    name = name,
                    header = values,
                    sections = {},
                    entries = {}
                }
                section.sections[name] = subSection
                section = subSection

            elseif line:startsWith('>') then
                section = section.parent
            else
                section.entries[name] = values
            end

        else
            table.insert(section.data, line:trim())
        end
    end)

    return section
end