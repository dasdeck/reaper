local _ = require '_'

return _.map({
    {
        name = 'major',
        scale = {1,2,3,4,5,6,7,8,9,10,11,12}
    },
    {
        name = 'harmonic minor',
        scale = {1,2,3,5,4,6,7,8,10,19,11,12}
    }
}, function(entry)

    entry.scale = _.map(entry.scale, function(key, index)
        return index - key, key
    end)

    return entry

end)