-- MrTargetAuras
-- =====================================================================
-- Copyright (C) 2016 Lock of War, Renevatium
--

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



local COOLDOWNS = {};
local COOLDOWNS_TEMP = {
  42292, -- PVP Trinket
  59752, -- Every Man for Himself
  208683 -- Gladiators Medallion
};

for i=1, #COOLDOWNS_TEMP do
  local name, _, icon = GetSpellInfo(COOLDOWNS_TEMP[i]);
  if name then
    COOLDOWNS[i] = name;
  end
end

MrTargetAuras = {
  parent=nil,
  max=9,
  count=1
};

MrTargetAuras.__index = MrTargetAuras;

function MrTargetAuras:New(parent)
  local this = setmetatable({}, MrTargetAuras);
  this.frames = setmetatable({}, nil);
  this.auras = setmetatable({}, nil);
  this.parent = parent;
  for i=1, this.max do
    this.frames[i] = CreateFrame('Button', parent.frame:GetName()..'Aura'..i, parent.frame, 'MrTargetAuraTemplate');
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
    if self.parent.parent.reverse then frame:SetPoint('TOPRIGHT', frame:GetParent(), 'TOPLEFT', -4-((count-1)*38), 0);
    else frame:SetPoint('TOPLEFT', frame:GetParent(), 'TOPRIGHT', 4+((count-1)*38), 0);
    end
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
  if MrTarget:GetOption('AURAS') then
    self.auras = table.wipe(self.auras);
    self.count = self:UpdateCooldowns(1, unit);
    self.count = self:UpdateCarriers(self.count, unit);
    self.count = self:UpdateDebuff(self.count, unit);
    for i=self.count,self.max do
      self:UnsetAura(self.frames[i]);
    end
  end
end

function MrTargetAuras:UpdateCooldowns(count, unit)
  for i=1,#COOLDOWNS do
    if count > self.max then break; end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitAura(unit, COOLDOWNS[i]);
    if name and icon then
      local cooldown = GetSpellCooldown(id)
    end
  end
  return count;
end

function MrTargetAuras:UpdateCarriers(count, unit)
  for i=1,#AURAS do
    if count > self.max then break; end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitAura(unit, AURAS[i]);
    if name and icon then
      count = count+self:SetAura(count, self.frames[count], id, name, duration, expires, icon);
    end
  end
  return count;
end

function MrTargetAuras:UpdateAuras(count, unit)
  if self.parent.parent.friendly then
    return self:UpdateBuff(self.count, unit);
  else
    return self:UpdateDebuff(self.count, unit);
  end
end

function MrTargetAuras:UpdateDebuff(count, unit)
  for i=1,40 do
    if count > self.max then break; end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitDebuff(unit, i, 'PLAYER');
    if name and icon then
      count = count+self:SetAura(count, self.frames[count], id, name, duration, expires, icon);
    end
  end
  return count;
end

function MrTargetAuras:UpdateBuff(count, unit)
  for i=1,40 do
    if count > self.max then break; end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitBuff(unit, i, 'PLAYER');
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
      if self.parent.parent.reverse then self.frames[i]:SetPoint('TOPRIGHT', self.frames[i]:GetParent(), 'TOPLEFT', -4-((count-1)*38), 0);
      else self.frames[i]:SetPoint('TOPLEFT', self.frames[i]:GetParent(), 'TOPRIGHT', 4+((count-1)*38), 0);
      end
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



-- local defaultcdtime = 6
-- local channel = "RAID_WARNING"

-- local frame = CreateFrame("frame", nil)
-- SlashCmdList['COUNTDOWN'] = function(newtime)
--     if newtime ~= "" then
--         cdtime = newtime+1
--     else
--         cdtime = defaultcdtime+1
--     end
--     local ending = false
--     local start = floor(GetTime())
--     local throttle = cdtime
--     frame:SetScript("OnUpdate", function()
--         if ending == true then return end
--         local countdown = (start - floor(GetTime()) + cdtime)
--         if (countdown + 1) == throttle and countdown >= 0 then
--             if countdown == 0 then
--                 SendChatMessage('Pulling', channel)
--                 throttle = countdown
--                 ending = true
--             else
--                 SendChatMessage(countdown, channel)
--                 throttle = countdown
--             end
--         end
--     end)
-- end