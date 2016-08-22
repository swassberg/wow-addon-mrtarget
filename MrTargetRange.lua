 -- MrTargetRange
-- =====================================================================
-- Copyright (C) 2014 Lock of War, Developmental (Pty) Ltd
--

MrTargetRange = { HARMFUL={} };

function MrTargetRange:UpdateSpells() 
  self.HARMFUL = table.wipe(self.HARMFUL);
  local numTabs = GetNumSpellTabs();
  for i=1,numTabs do
    local name,texture,offset,numSpells = GetSpellTabInfo(i);
    for id=1,numSpells do
      if IsHarmfulSpell(id, 'spell') then
        local name, rank = GetSpellBookItemName(id, 'spell');
        local range = select(6, GetSpellInfo(name));
        table.insert(self.HARMFUL, { name=name, range=range });
      end
    end
  end
end

function MrTargetRange:GetRange(unit)
  local range = nil;
  if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
    for i=1, #self.HARMFUL do
      if IsSpellInRange(self.HARMFUL[i].name, unit) == 1 then          
        range = range == nil and self.HARMFUL[i].range or math.min(range, self.HARMFUL[i].range);    
      end
    end
  end
  return range;
end