-- MrTargetRange
-- =====================================================================
-- Copyright (C) 2016 Lock of War, Renevatium
--

MrTargetRange = {
  frame=nil,
  parent=nil,
  range=nil,
  update=0,
  frequency=1
};

MrTargetRange.__index = MrTargetRange;

function MrTargetRange:New(parent)
  local this = setmetatable({}, MrTargetRange);
  this.parent = parent;
  this.frame = CreateFrame('Frame', parent.frame:GetName()..'Range', parent.frame);
  this.frame:SetScript('OnUpdate', function(frame, time) this:OnUpdate(time); end);
  this.frame:SetScript('OnEvent', function(frame, ...) this:OnEvent(...); end);
  this.frame:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED');
  this.frame:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED');
  this.frame:Show();
  return this;
end

function MrTargetRange:GetHarmfulRange()
  local range = nil;
  for i=1, #MrTarget.player.harmful do
    if IsSpellInRange(MrTarget.player.harmful[i].name, self.parent.unit) == 1 then
      range = range == nil and MrTarget.player.harmful[i].range or math.min(range, MrTarget.player.harmful[i].range);
      if range then
        break;
      end
    end
  end
  return range;
end

function MrTargetRange:GetHelpfulRange()
  local range = nil;
  for i=1, #MrTarget.player.helpful do
    if IsSpellInRange(MrTarget.player.helpful[i].name, self.parent.unit) == 1 then
      range = range == nil and MrTarget.player.helpful[i].range or math.min(range, MrTarget.player.helpful[i].range);
      if range then
        break;
      end
    end
  end
  return range;
end

function MrTargetRange:OnUpdate(time)
  if UnitIsDeadOrGhost('player') then
    self.parent.range = nil;
    self.range = nil;
    self.update = 0;
    return;
  end
  self.update = self.update + time;
  if self.update > self.frequency then
    if self.parent:GetUnit(self.parent.name) then
      if UnitIsConnected(self.parent.name) and not UnitIsDeadOrGhost(self.parent.name) then
        if UnitIsEnemy('player', self.parent.name) then
          self.range = self:GetHarmfulRange();
        else
          self.range = self:GetHelpfulRange();
        end
      end
      self.parent.range = self.range;
      self.update = 0;
    end
  end
end

function MrTargetRange:CombatLogRangeCheck(sourceName, destName, spellId)
  if self.parent.unit then
    if sourceName and self.parent.name == sourceName then
      if UnitIsEnemy('player', self.parent.unit) then
        self.range = self:GetHarmfulRange();
        self.parent.range = self.range;
        return;
      else
        self.range = self:GetHelpfulRange();
        self.parent.range = self.range;
        return;
      end
    end
    if destName and self.parent.name == destName then
      if UnitIsEnemy('player', self.parent.unit) then
        self.range = self:GetHarmfulRange();
        self.parent.range = self.range;
        return;
      else
        self.range = self:GetHelpfulRange();
        self.parent.range = self.range;
        return;
      end
    end
  end
end

function MrTargetRange:OnEvent(event, unit, ...)
  if MrTarget.active then
    if event == 'COMBAT_LOG_EVENT_UNFILTERED' then
      local _, _, _, sourceName, _, _, _, destName, _, _, spellId = ...;
      self:CombatLogRangeCheck(sourceName, destName, spellId);
    end
  end
end