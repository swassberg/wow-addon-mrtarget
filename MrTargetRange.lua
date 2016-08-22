 -- MrTargetRange
-- =====================================================================
-- Copyright (C) 2014 Lock of War, Developmental (Pty) Ltd
--

MrTargetRange = {
  frame=nil,
  parent=nil,
  range=nil,
  update=0,
  harmful={},
  helpful={}
};

MrTargetRange.__index = MrTargetRange;

function MrTargetRange:New(parent)
  local this = setmetatable({}, MrTargetRange);
  this.harmful = setmetatable({}, nil);
  this.helpful = setmetatable({}, nil);
  this.parent = parent;
  this.frame = CreateFrame('Frame', parent.frame:GetName()..'Range', parent.frame);
  this.frame:SetScript('OnUpdate', function(frame, time) this:OnUpdate(time); end);
  this.frame:SetScript('OnEvent', function(frame, ...) this:OnEvent(...); end);
  this.frame:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED');
  this:UpdateSpells();
  this.frame:Show();
  return this;
end

function MrTargetRange:UpdateSpells()
  self.harmful = table.wipe(self.harmful);
  self.helpful = table.wipe(self.helpful);
  local numTabs = GetNumSpellTabs();
  for i=1,numTabs do
    local name,texture,offset,numSpells = GetSpellTabInfo(i);
    for id=1,numSpells do
      local name, rank = GetSpellBookItemName(id, 'spell');
      local range = select(6, GetSpellInfo(name));
      if IsHarmfulSpell(id, 'spell') then
        table.insert(self.harmful, { name=name, range=range });
      elseif IsHelpfulSpell(id, 'spell') then
        table.insert(self.helpful, { name=name, range=range });
      end
    end
  end
end

function MrTargetRange:GetHarmfulRange()
  local range = nil;
  for i=1, #self.harmful do
    if IsSpellInRange(self.harmful[i].name, self.parent.unit) == 1 then
      range = range == nil and self.harmful[i].range or math.min(range, self.harmful[i].range);
    end
  end
  return range;
end

function MrTargetRange:GetHelpfulRange()
  local range = nil;
  for i=1, #self.helpful do
    if IsSpellInRange(self.helpful[i].name, self.parent.unit) == 1 then
      range = range == nil and self.helpful[i].range or math.min(range, self.helpful[i].range);
    end
  end
  return range;
end

function MrTargetRange:OnUpdate(time)
  self.update = self.update + time;
  if self.update > 0.5 then
    if self.parent:GetUnit(self.parent.unit) then
      self.range = nil;
      if UnitIsConnected(self.parent.unit) and not UnitIsDeadOrGhost(self.parent.unit) then
        if UnitIsEnemy('player', self.parent.unit) then
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

function MrTargetRange:OnEvent(event, unit)
  if event == 'ACTIVE_TALENT_GROUP_CHANGED' then
    self:UpdateSpells();
  end
end