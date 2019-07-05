local _ = require '_'

local default = {1,3,5,6,8,10,12}


local data = {
    {
        name = 'major (default)',
        scale = default,
        default = default
    },
    {
        name = 'melodic minor',
        scale = {1,3,4,6,8,10,12}
    },
    {
        name = 'harmonic minor',
        scale = {1,3,4,6,8,9,12}
    },
    {
        name = 'gipsy',
        scale = {1,2,5,6,8,9,11}
    },
    {
        name = 'blues',
        scale = {1,4,6,7,8,11}
    }
}

return _.map(data, function(entry)

    entry.scale = _.map(entry.scale, function(key, index)
        local offset = key - default[index]
        return offset, index
    end)

    return entry

end)