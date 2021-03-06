local Component = require 'Component'
local ButtonList = require 'ButtonList'
local SequenceEditor = require 'SequenceEditor'
local Project = require 'Project'
local MediaItem = require 'MediaItem'
local Track = require 'Track'

local rea = require 'rea'
local _ = require '_'

local Sequencer = class(Component)

function Sequencer:create()
    local self = Component:create()
    setmetatable(self, Sequencer)

    self.buttons = self:addChildComponent(ButtonList:create({}, true))
    self.buttons.isDisabled = function()
        return not self.sequence
    end
    self.buttons.getData = function()
        local taks = self.item and _.map(self.item:getTakes(), function(take, i)
            return {
                args = tostring(i),
                getToggleState = function()
                    return take:isActive()
                end,
                onClick = function(s, mouse)
                    if mouse:isAltKeyDown() then
                        take:remove()
                    else
                        rea.transaction('set active take', function()
                            take:setActive()
                        end)
                    end
                end
            }
        end)
        local btn = _.concat(taks, {
            {
                args = '+',
                onClick = function()
                    rea.transaction('copy active take', function()
                        reaper.Main_OnCommand(40639, 0)
                    end)
                end
            }
        },_.map({3,6,2,4,8,16,32}, function(num)
            return {
                onClick = function()
                    self.sequence.numSteps = num
                    self:repaint(true)
                end,
                args = tostring(num) .. '/4',
                getToggleState = function()
                    return self.sequence and self.sequence.numSteps == num
                end
            }
        end))
        return btn
    end

    self.watchers:watch(Project.watch.project, function()
            -- local all = MediaItem.getSelectedItems()
            -- local item = _.first(all)
            -- if item then

            --     local a = item:getPos()
            --     local b = a + item:getLength()

            --     local s, e = reaper.GetSet_LoopTimeRange(false, false, 0 , 0, false)
            --     -- rea.log({
            --     --     startItem = a,
            --     --     endItem = b,
            --     --     startLoop = s,
            --     --     endLoop = e,
            --     --     startMatch = a - s,
            --     --     endMatch = b - e
            --     -- })
            -- end


        self.item = nil
        self.buttons:updateList()
        local lanes = {}
        local Zone = require 'Zone'
        local tracks = Track.getAllTracks()



        _.forEach(tracks, function(track)
            if track:isArmed() then
                local zone = Zone.create(track)
                if zone then
                    table.insert(lanes, {
                        key = zone:getKey(),
                        track = track
                    })
                else
                    -- rea.log('key lanes')
                    local keys = {
                        36,38,40,41,
                        43,45,47,48,
                        50,52,53,55,
                        57,59,61,62
                    }
                    _.forEach(keys, function(key)
                        table.insert(lanes, {
                            key = key,
                            track = track
                        })
                    end)
                end
            end
        end)

        self:setLanes(lanes)
    end)

    -- end)

    return self
end

-- function Sequencer:setMediaItem(item)
--     self.item = item
--     self:setLanes(item and item:getActiveTake())
--     self.buttons:updateList()
--     self:resized()
--     self:repaint(true)

-- end

function Sequencer:setLanes(lanes)

    -- if take and self.sequence and self.sequence.take == take then return end
    if lanes and self.sequence and _.equal(self.sequence.lanes, lanes) then
        self:repaint(true)
        return
    end

    if self.sequence then
        self.sequence:delete()
    end

    if lanes and _.size(lanes) > 0 then
        self.sequence = self:addChildComponent(SequenceEditor:create(lanes))
    end

    -- if take then
    --     local inst = take.item:getTrack():getInstrument()
    --     if inst and inst.track:getFx('DrumRack') then
    --         local DrumRack = require 'DrumRack'
    --         self.drumRack = DrumRack:create(inst.track)
    --         self.sequence.getLanes = function()
    --             return _.map(self.drumRack.pads, function(pad)
    --                 return pad:hasContent() and pad:getKeyRange() or nil
    --             end)
    --         end
    --     end
    -- end

    self:resized()

    self:repaint(true)

end

function Sequencer:resized()
    local h = 20
    self.buttons:setBounds(0,0,self.w, h)
    if self.sequence then
        self.sequence:setBounds(0,h, self.w, self.h - h)
    end
end

return Sequencer