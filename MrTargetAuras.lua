-- MrTargetAuras
-- =====================================================================
-- Copyright (C) 2014 Lock of War, Developmental (Pty) Ltd
--

local PVP_AURAS = {};
local PVP_AURAS_TEMP = { 23333,23335,34976,46393,46392,141210,140876,156618,156621,121164,121175,121176,121177,125344,125345,125346,125347 };
for i=1, #PVP_AURAS_TEMP do
  local name, _, icon = GetSpellInfo(PVP_AURAS_TEMP[i]);
  if name then 
    PVP_AURAS[i] = name;
  end
end

local ARENA_AURAS = {};
local ARENA_AURAS_TEMP = {
  108843,65081,108212,68992,1850,137452,114239,118922,85499,2983,06898,116841,1,5116,120,13809,16188,31842,
  6346,112965,1044,1022,114039,6940,11426,53271,132158,69369,12043,48108,3,108978,108271,22812,18499,111397,
  74001,31224,108359,118038,498,5277,47788,48792,1463,116267,66,102342,12975,49039,116849,114028,30884,124974,
  137562,33206,53480,30823,871,112833,23920,4,13750,107574,106952,12292,51271,1719,51713,5,91807,96294,61685,
  116706,87194,114404,64695,64803,63685,111340,107566,339,113770,33395,122,102051,102359,136634,105771,12042,
  114049,31884,113858,113861,113860,16166,12472,33891,102560,102543,102558,10060,3045,48505,7,31821,115723,
  8178,131558,104773,124488,159630,1330,15487,47476,31935,137460,28730,80483,25046,50613,69179,108194,
  91800,91797,89766,117526,24394,105421,7922,119392,1833,118895,77505,120086,44572,99,31661,123393,105593,
  47481,1776,853,119072,88625,19577,408,119381,22570,5211,113801,118345,115001,30283,22703,46968,118905,132169,
  20549,16979,10,710,2094,137143,33786,605,118699,3355,51514,5484,5246,115268,6789,115078,118,8122,64044,20066,
  82691,6770,107079,6358,9484,10326,19386,48707,46924,110913,19263,47585,642,45438,118358
};

for i=1, #ARENA_AURAS_TEMP do
  local name, _, icon = GetSpellInfo(ARENA_AURAS_TEMP[i]);
  if name then 
    ARENA_AURAS[i] = name;
  end
end

MrTargetAuras = {
  parent=nil,
  max=15,
  count=1
};

MrTargetAuras.__index = MrTargetAuras;

function MrTargetAuras:New(parent)
  local this = setmetatable({}, MrTargetAuras);
  this.frames = setmetatable({}, nil); 
  this.auras = setmetatable({}, nil);  
  for i=1, this.max do
    this.frames[i] = CreateFrame('Button', parent:GetName()..'Aura'..i, parent, 'MrTargetAuraTemplate');
    this.frames[i]:SetScript('OnUpdate', function(frame) this:OnUpdate(frame); end);        
    this.frames[i]:Show();
  end
  return this;
end

function MrTargetAuras:SetAura(count, frame, id, name, duration, expires, icon)
  if not self.auras[id] then
    self.auras[id] = name;
    frame.id = id;
    frame.spell = name;
    frame.update = GetTime();
    frame.duration = duration;
    frame.time = expires-GetTime();
    frame.icon = icon;
    frame.ICON:SetTexture(icon);
    frame:ClearAllPoints();
    frame:SetPoint('TOPLEFT', frame:GetParent(), 'TOPRIGHT', 4+((count-1)*38), 0);
    return 1;
  end
  return 0;
end

function MrTargetAuras:UnsetAura(frame)
  frame.id = nil;
  frame.spell = nil;
  frame.update = GetTime();
  frame.duration = 0;
  frame.time = 0;
  frame.icon = nil;
  frame.ICON:SetTexture(nil);
  frame.expires:SetText('');
end

function MrTargetAuras:UnitAura(unit)
  if OPTIONS.AURAS then
    self.auras = table.wipe(self.auras);
    self.count = self:UpdateCarriers(1, unit);
    self.count = self:UpdateAuras(self.count, unit);
    self.count = self:UpdateDebuffs(self.count, unit);
    for i=self.count,self.max do
      self:UnsetAura(self.frames[i]);
    end
  end
end

function MrTargetAuras:UpdateCarriers(count, unit)
  for i=1,#PVP_AURAS do
    if count > self.max then break; end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitBuff(unit, PVP_AURAS[i]);
    if name and icon then
      count = count+self:SetAura(count, self.frames[count], id, name, duration, expires, icon);
    else
      name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitDebuff(unit, PVP_AURAS[i]);
      if name and icon then
        count = count+self:SetAura(count, self.frames[count], id, name, duration, expires, icon);
      end
    end
  end
  return count;
end

function MrTargetAuras:UpdateAuras(count, unit)
  for i=1,#ARENA_AURAS do
    if count > self.max then break; end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitBuff(unit, ARENA_AURAS[i]);
    if name and icon then
      count = count+self:SetAura(count, self.frames[count], id, name, duration, expires, icon);
    end
  end
  return count;
end

function MrTargetAuras:UpdateDebuffs(count, unit)
  for i=1,40 do
    if count > self.max then break; end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitDebuff(unit, i, 'PLAYER');
    if name and icon then
      count = count+self:SetAura(count, self.frames[count], id, name, duration, expires, icon);
    end
  end
  return count;
end

function MrTargetAuras:UpdatePositions()
  local count = 1;
  for i=1,self.max do
    if self.frames[i].id then
      self.frames[i]:ClearAllPoints();
      self.frames[i]:SetPoint('TOPLEFT', self.frames[i]:GetParent(), 'TOPRIGHT', 4+((count-1)*38), 0);
      count = count+1;
    end
  end
end

function MrTargetAuras:Destroy()
  for i=1,self.max do
    self:UnsetAura(self.frames[i]);
  end
end

function MrTargetAuras:UpdateExpires(frame)
  if frame.time then
    frame.time = tonumber(frame.time) - (GetTime()-frame.update);
    frame.time = math.floor((frame.time*10)+0.5)/10;
    if frame.duration == 0 then
      frame.expires:SetText('');
    elseif frame.time < 0 then
      self:UnsetAura(frame);
      self:UpdatePositions();
    elseif frame.time <= 60 then
      local time = frame.time > 0 and frame.time or '';
      frame.expires:SetText(time);
    else
      local msg, val = SecondsToTimeAbbrev(frame.time);
      frame.expires:SetText(format(msg, val));
    end
  end
end

function MrTargetAuras:OnUpdate(frame)
  if frame.id then
    if GetTime()-frame.update >= 0.1 then
      self:UpdateExpires(frame);
      frame.ICON:SetTexture(frame.icon);
      frame.update = GetTime();
    end
  end
end