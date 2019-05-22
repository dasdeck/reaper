local rea = require 'rea'

local Sampler = class()

function Sampler.create(path)
    local Instrument = require 'Instrument'

    local newTrack = Instrument.createInstrument('ReaSamplomatic5000')
    local fx = newTrack:getInstrument()
    fx:setParam('FILE0', path)
    fx:setParam('DONE', '')
    newTrack:setIcon(rea.findIcon('wave decrease'))

    return newTrack
end

return Sampler