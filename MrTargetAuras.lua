-- MrTargetAuras
-- =====================================================================
-- Copyright (C) Lock of War, Renevatium
--

local COOLDOWNS = {};
local COOLDOWNS_TEMP = {
    7744, -- Will of the Forsaken (Undead)
   42292, -- PVP Trinket
   59752, -- Every Man for Himself
  195710, -- Honorable Medallion
  208683  -- Gladiators Medallion
};

for i=1, #COOLDOWNS_TEMP do
  local name, _, icon = GetSpellInfo(COOLDOWNS_TEMP[i]);
  if name then
    COOLDOWNS[COOLDOWNS_TEMP[i]] = name;
  end
end

local AURAS = {};
local AURAS_TEMP = {
  23333,23335,34976,46393,46392,141210,140876,156618,156621,121164,
  121175,121176,121177,125344,125345,125346,125347
};

for i=1, #AURAS_TEMP do
  local name, _, icon = GetSpellInfo(AURAS_TEMP[i]);
  if name then
    AURAS[i] = name;
  end
end

MrTargetAuras = {
  parent=nil,
  cooldowns={},
  auras={},
  max=6,
  count=1,
  frequency=1,
  update=0
};

MrTargetAuras.__index = MrTargetAuras;

function MrTargetAuras:New(parent)
  local this = setmetatable({}, MrTargetAuras);
  this.frames = setmetatable({}, nil);
  this.auras = setmetatable({}, nil);
  this.cooldowns = setmetatable({}, nil);
  this.parent = parent;
  this.frame = CreateFrame('Frame', parent.frame:GetName()..'Auras', parent.frame);
  this.frame:SetScript('OnUpdate', function(frame, time) this:OnUpdate(time); end);
  this.frame:SetScript('OnEvent', function(frame, ...) this:OnEvent(...); end);
  this.frame:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED');
  for i=1, this.max do
    this.frames[i] = CreateFrame('Button', parent.frame:GetName()..'Aura'..i, parent.frame, 'MrTargetAuraTemplate');
    this.frames[i]:SetScript('OnUpdate', function(frame) this:OnUpdateFrame(frame); end);
    this.frames[i]:Show();
  end
  return this;
end

function MrTargetAuras:UpdateAura(count, id, name, duration, expires, icon, cooldown)
  self.auras[id] = count;
  self.frames[count].id = id;
  self.frames[count].spell = name;
  self.frames[count].update = GetTime();
  self.frames[count].duration = duration;
  self.frames[count].time = expires > 0 and expires-GetTime() or nil;
  self.frames[count].icon = icon;
  self.frames[count].cooldown = cooldown;
  self.frames[count].ICON:SetTexture(icon);
  self.frames[count]:ClearAllPoints();
  self:UpdatePositions();
  return 1;
end

function MrTargetAuras:SetAura(count, id, name, duration, expires, icon, cooldown)
  if self.frames[count] and not self.auras[id] then
    return self:UpdateAura(count, id, name, duration, expires, icon, cooldown);
  elseif self.auras[id] and self.frames[self.auras[id]] then
    return self:UpdateAura(self.auras[id], id, name, duration, expires, icon, cooldown);
  else
    return 0;
  end
end

function MrTargetAuras:UnsetAura(frame)
  if frame.id then
    self.auras[frame.id] = false;
    if frame.cooldown then
      self.cooldowns[frame.id] = false;
    end
    frame.id = nil;
    frame.spell = nil;
    frame.update = GetTime();
    frame.duration = 0;
    frame.time = 0;
    frame.icon = nil;
    frame.cooldown = false;
    frame.ICON:SetTexture(nil);
    frame.expires:SetText('');
  end
end

function MrTargetAuras:ClearAuras()
  for i=1,self.max do
    if not self.frames[i].id or (self.frames[i].time and self.frames[i].time <= 0) then
      self:UnsetAura(self.frames[i]);
    end
  end
  self:UpdatePositions();
end

function MrTargetAuras:UnitAura(unit)
  if UnitExists(unit) then
    self:ClearAuras();
    self.count = self:UpdateCarriers(mrtarget_count(self.cooldowns)+1, unit);
    if MrTarget:GetOption('AURAS') then
      self.count = self:UpdateAuras(self.count, unit);
    end
  end
end

function MrTargetAuras:UpdateCarriers(count, unit)
  for i=1,#AURAS do
    if count > self.max then break; end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitAura(unit, AURAS[i]);
    if name and icon then
      count = count+self:SetAura(count, id, name, duration, expires, icon, false);
    else
      id = select(7, GetSpellInfo(AURAS[i]));
      if self.auras[id] then
        self:UnsetAura(self.frames[self.auras[id]]);
      end
    end
  end
  self:UpdatePositions();
  return count;
end

function MrTargetAuras:UpdateAuras(count, unit)
  if not self.parent.parent.friendly then
    return self:UpdateDebuff(count, unit);
  else
    return self:UpdateBuff(count, unit);
  end
end

function MrTargetAuras:UpdateDebuff(count, unit)
  local auras = {};
  for i=1,40 do
    if count > self.max then break; end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitDebuff(unit, i, 'PLAYER');
    if name and icon then
      count = count+self:SetAura(count, id, name, duration, expires, icon, false);
      auras[id] = name;
    end
  end
  for i=self.count,self.max do
    if self.frames[i].id and not auras[self.frames[i].id] then
      self:UnsetAura(self.frames[i]);
    end
  end
  self:UpdatePositions();
  return count;
end

function MrTargetAuras:UpdateBuff(count, unit)
  local auras = {};
  for i=1,40 do
    if count > self.max then break; end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitBuff(unit, i, 'PLAYER');
    if name and icon and tonumber(expires) > 0 and not COOLDOWNS[id] then -- and tonumber(duration) < 3600
      count = count+self:SetAura(count, id, name, duration, expires, icon, false);
      auras[id] = name;
    end
  end
  for i=self.count,self.max do
    if self.frames[i].id and not auras[self.frames[i].id] then
      self:UnsetAura(self.frames[i]);
    end
  end
  self:UpdatePositions();
  return count;
end

function MrTargetAuras:UpdatePositions()
  local count = 1;
  for i=1,self.max do
    if self.frames[i].id then
      self.frames[i]:ClearAllPoints();
      if MrTarget:GetOption('COLUMNS') == 1 then
        if self.parent.parent.reverse then self.frames[i]:SetPoint('TOPRIGHT', self.frames[i]:GetParent(), 'TOPLEFT', -4-((count-1)*38), 0);
        else self.frames[i]:SetPoint('TOPLEFT', self.frames[i]:GetParent(), 'TOPRIGHT', 4+((count-1)*38), 0); end
        self.frames[i]:SetSize(36, 36);
        self.frames[i].expires:Show();
      else
        self.frames[i]:SetPoint('BOTTOMLEFT', self.frames[i]:GetParent(), 'BOTTOMLEFT', 2+((count-1)*16), 3);
        self.frames[i]:SetSize(16, 16);
        self.frames[i].expires:Hide();
      end
      count = count+1;
    end
  end
end

function MrTargetAuras:MovePositions()
  for i=self.max,1,-1 do
    if self.frames[i].id and self.frames[i+1] then
      self.auras[self.frames[i].id] = false;
      self:SetAura(i+1,
        self.frames[i].id,
        self.frames[i].spell,
        self.frames[i].duration,
        GetTime()+(self.frames[i].time or 0),
        self.frames[i].icon,
        self.frames[i].cooldown
      );
    end
  end
end

function MrTargetAuras:UnitDead()
  self:Destroy();
end

function MrTargetAuras:Destroy()
  for i=1,self.max do
    self:UnsetAura(self.frames[i]);
  end
end

function MrTargetAuras:UpdateExpires(frame)
  if frame.time ~= nil then
    frame.time = tonumber(frame.time) - (GetTime()-frame.update);
    frame.time = math.floor((frame.time*10)+0.5)/10;
    if frame.expires == 0 then
      frame.expires:SetText('');
    elseif frame.time < 0 then
      self:UnsetAura(frame);
      self:UpdatePositions();
    elseif frame.time <= 60 then
      frame.expires:SetText(frame.time);
      local time = frame.time > 0 and frame.time or '';
      frame.expires:SetText(time);
    else
      local msg, val = SecondsToTimeAbbrev(frame.time);
      frame.expires:SetText(format(msg, val));
    end
  end
end

function MrTargetAuras:OnUpdateFrame(frame)
  if frame.id then
    if GetTime()-frame.update >= 0.1 then
      self:UpdateExpires(frame);
      frame.ICON:SetTexture(frame.icon);
      frame.update = GetTime();
    end
  end
end

function MrTargetAuras:OnUpdate(time)
  self.update = self.update + time;
  if self.update > self.frequency then
    self.update = 0;
    self:UnitAura(self.parent.unit);
  end
end

function MrTargetAuras:CombatLogRangeCheck(sourceName, destName, spellId)
  if MrTarget.active then
    if self.parent.unit then
      if (sourceName and self.parent.name == sourceName) or (destName and self.parent.name == destName) then
        if COOLDOWNS[spellId] then
          local name, rank, icon, castingTime, minRange, maxRange, id = GetSpellInfo(COOLDOWNS[spellId]);
          if id and not self.auras[id] and not self.cooldowns[id] then
            self.cooldowns[id] = true;
            self:MovePositions();
            self:SetAura(1, id, name, 120, GetTime()+120, icon, true);
          end
        end
        self:UnitAura(self.parent.unit);
      end
    end
  end
end

function MrTargetAuras:OnEvent(event, ...)
  if event == 'COMBAT_LOG_EVENT_UNFILTERED' then
    local _, _, _, _, sourceName, _, _, _, destName, _, _, spellId = ...;
    self:CombatLogRangeCheck(sourceName, destName, spellId);
  end
end