local ChangeStacker = class()

function ChangeStacker:create(name)
  local self = {
    name = name,
    timeToStore = 0,
    time = 0.5
  }
  setmetatable(self,ChangeStacker)
  return self
end

function ChangeStacker:apply(delta)

  local currentValue = self:getValue()
  local newValue = currentValue + delta

  if newValue ~= self.lastValue then
    if not self.previousValue then
      self.previousValue = self:getValue()
    end

    self:setValue(newValue)
    self.timeToStore = reaper.time_precise() + self.time

  elseif self.previousValue and self.timeToStore < reaper.time_precise() then
    if self.previousValue ~= currentValue then
      local futureValue = self:getValue()
      self:setValue(self.previousValue)
      reaper.Undo_BeginBlock()
      self:setValue(futureValue)
      reaper.Undo_EndBlock(self.name, -1)
    end
    self.previousValue = nil
  end

  self.lastValue = newValue
end

return ChangeStacker