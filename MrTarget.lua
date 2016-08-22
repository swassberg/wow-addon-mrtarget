--
-- MrTarget
-- =====================================================================
-- Copyright (C) 2014 Lock of War, Developmental (Pty) Ltd
--
-- MrT provides Blizzard style PVP ENEMY Unit Frames and Replaces UNREADABLE Player Names for Target Calling purposes
--
-- This Work is provided under the Creative Commons
-- Attribution-NonCommercial-NoDerivatives 4.0 International Public License
--
-- Please send any bugs or feedback to mrtarget@lockofwar.com.
--
-- For more information see the README and LICENSE files respectively
--

local MAX_FRAMES = 15;
local LAST_REQUEST = 0;
local REQUEST_FREQUENCY = 1;
local MAX_REQUEST_TIME = 10;

local FRAMES = {};
local ENEMIES = {};
local UNITS = {};
local ROLES = {};

local POWER_BAR_COLORS = {
  ["MANA"]={ r=0.00,g=0.00,b=1.00 };
  ["RAGE"]={ r=1.00,g=0.00,b=0.00 };
  ["FOCUS"]={ r=1.00,g=0.50,b=0.25 };
  ["ENERGY"]={ r=1.00,g=1.00,b=0.00 };
  ["CHI"]={ r=0.71,g=1.0,b=0.92 };
}

local MAX_CLASSES = MAX_CLASSES;
local RAID_CLASS_COLORS = RAID_CLASS_COLORS;
local RequestBattlefieldScoreData = RequestBattlefieldScoreData;
local UnitName = UnitName;
local GetUnitName = GetUnitName;
local UnitIsEnemy = UnitIsEnemy;
local UnitAura = UnitAura;
local UnitBuff = UnitBuff;
local UnitDebuff = UnitDebuff;
local HookSecureFunc = hooksecurefunc;

-- local SendAddonMessage = SendAddonMessage;
-- self:RegisterEvent('CHAT_MSG_ADDON');

local NAME_ACTIVE = true;
local NAME_COUNT = 1;
local NAME_READABLE = {};
local NAME_OPTIONS = {
  'Alakazam', 'Bellsprout', 'Blastoise', 'Bulbasaur', 'Butterfree', 'Caterpie', 'Charizard', 'Charmander', 'Diglett', 'Gastly',
  'Geodude', 'Gloom', 'Golduck', 'Golem', 'Graveler', 'Jigglypuff', 'Kadabra', 'Kakuna', 'Krabby', 'Mankey',
  'Meowth', 'Metapod', 'Mew', 'Oddish', 'Onix', 'Pidgeotto', 'Pikachu', 'Poliwag', 'Primeape', 'Psyduck',
  'Raichu', 'Rattata', 'Sandshrew', 'Slowpoke', 'Spearow', 'Squirtle', 'Tentacool', 'Vulpix', 'Weedle', 'Zubat'
}

local BATTLEFIELDS = {
  ['Alterac Valley'] = { size=40 },
  ['Arathi Basin'] = { size=15 },
  ['Strand of the Ancients'] = { size=15 },
  ['Isle of Conquest'] = { size=40 },
  ['The Battle for Gilneas'] = { size=10 },
  ['Silvershard Mines'] = { size=10 },
  ['Warsong Gulch'] = { size=10, buffs=true, carriers={}, spells={
    [23333]={ name="Horde Flag", texture='Interface\\Icons\\INV_BannerPVP_01' },
    [23335]={ name="Alliance Flag", texture='Interface\\Icons\\INV_BannerPVP_02' },
    [156618]={ name="Horde Flag", texture='Interface\\Icons\\INV_BannerPVP_01' },
    [156621]={ name="Alliance Flag", texture='Interface\\Icons\\INV_BannerPVP_02' }
  }},
  ['Eye of the Storm'] = { size=15, buffs=true, carriers={}, spells={
    [34976]={ name="Netherstorm Flag", texture='Interface\\Icons\\INV_BannerPVP_03' },
    [100196]={ name="Netherstorm Flag", texture='Interface\\Icons\\INV_BannerPVP_03' }
  }},
  ['Twin Peaks'] = { size=10, buffs=true, carriers={}, spells={
    [23333]={ name="Horde Flag", texture='Interface\\Icons\\INV_BannerPVP_01' },
    [23335]={ name="Alliance Flag", texture='Interface\\Icons\\INV_BannerPVP_02' },
    [156618]={ name="Horde Flag", texture='Interface\\Icons\\INV_BannerPVP_01' },
    [156621]={ name="Alliance Flag", texture='Interface\\Icons\\INV_BannerPVP_02' }
  }},
  ['Deepwind Gorge'] = { size=15, buffs=true, carriers={}, spells={
    [140876]={ name="Horde Mine Cart", texture='Interface\\Icons\\INV_BannerPVP_01' },
    [141210]={ name="Alliance Mine Cart", texture='Interface\\Icons\\INV_BannerPVP_02' }
  }},
  ['Temple of Kotmogu'] = { size=10, debuffs=true, carriers={}, spells={
    [121164] = { name="Orb of Power", texture='Interface\\MiniMap\\TempleofKotmogu_ball_cyan' }, -- Blue Orb
    [121175] = { name="Orb of Power", texture='Interface\\MiniMap\\TempleofKotmogu_ball_purple' }, -- Purple Orb
    [121176] = { name="Orb of Power", texture='Interface\\MiniMap\\TempleofKotmogu_ball_green' }, -- Green Orb
    [121177] = { name="Orb of Power", texture='Interface\\MiniMap\\TempleofKotmogu_ball_orange' }, -- Orange Orb
    [125344] = { name="Orb of Power", texture='Interface\\MiniMap\\TempleofKotmogu_ball_cyan' }, -- Blue Orb
    [125345] = { name="Orb of Power", texture='Interface\\MiniMap\\TempleofKotmogu_ball_purple' }, -- Purple Orb
    [125346] = { name="Orb of Power", texture='Interface\\MiniMap\\TempleofKotmogu_ball_green' }, -- Green Orb
    [125347] = { name="Orb of Power", texture='Interface\\MiniMap\\TempleofKotmogu_ball_orange' } -- Orange Orb
  }}
};

local MrTarget = CreateFrame('Frame', 'MrTarget', UIParent, 'MrTargetRaidFrameTemplate');

function MrTarget:OnLoad()
  self.UnitAura = UnitAura;
  self:GetRoles();
  self:RegisterForDrag('RightButton');
  self:SetClampedToScreen(true);
  self:EnableMouse(true);
  self:SetMovable(true);
  self:SetUserPlaced(true);
  self:CreateFrames();
  self:RegisterEvent('ZONE_CHANGED_NEW_AREA');
  self:UpdateZone();
end

function MrTarget:CreateDebugFrame()
  local name, _, class = UnitName('player'), UnitClass('player');
  UNITS = {{ name=self:GetName(name, true), target='player', class=class, role='DAMAGER' }};
  self:UpdateFrames();
  self:PlayerTargetUnit('player', true);
  self:LeaderTargetUnit('player', true);
  ObjectiveTrackerFrame:Hide();
  self:Show();
end

function MrTarget:UnitNameReadable(unit)
  local name, server = UnitName(unit);
  if UnitIsEnemy('player', unit) then
    name = MrTarget:GetName(name, false);
  end
  return name, server;
end

function MrTarget:GetUnitNameReadable(unit, showServerName)
  local relationship = UnitRealmRelationship(unit);
  local name, server = self:UnitNameReadable(unit);
  if server and server ~= "" then
    if showServerName then
      return name.."-"..server;
    else
      if relationship == LE_REALM_RELATION_VIRTUAL then
        return name;
      else
        return name..FOREIGN_SERVER_LABEL;
      end
    end
  else
    return name;
  end
end

function MrTarget:GetName(name, insert)
  if NAME_ACTIVE and name then
    if NAME_READABLE[name] == nil then
      if insert then
        if self:IsUTF8(name) then
          NAME_READABLE[name] = NAME_OPTIONS[NAME_COUNT];
          NAME_COUNT = NAME_COUNT+1;
        else
          NAME_READABLE[name] = name;
        end
        return NAME_READABLE[name];
      else
        return name;
      end
    else
      return NAME_READABLE[name];
    end
  end
  return name;
end

function MrTarget:ResetNames()
  NAME_READABLE = {};
  NAME_COUNT = 1;
end

function MrTarget:SplitName(name)
  if name then
    local name, server, original = name, '', name;
    local hyphen = strfind(original, '-');
    if hyphen then
        name = strsub(original, 0, hyphen-1)
        server = '-'..strsub(original, hyphen+1);
    end
    return name, server;
  else
    return name;
  end
end

function MrTarget:IsUTF8(name)
    local c,a,n,i = nil,nil,0,1;
    while true do
        c = string.sub(name,i,i);
        i = i + 1;
        if c == '' then
            break;
        end
        a = string.byte(c);
        if a > 191 or a < 127 then
            n = n + 1;
        end
    end
    return (strlen(name) > n*1.5);
end

function MrTarget:UpdatePowerColor(frame, unit)
  local powerType, powerToken = UnitPowerType(unit);
  local color = POWER_BAR_COLORS[powerToken] or POWER_BAR_COLORS['MANA'];
  frame.powerBar:SetStatusBarColor(color.r, color.g, color.b);
end

function MrTarget:UpdateHealthColor(frame, classToken)
  local color = RAID_CLASS_COLORS[classToken];
  frame.healthBar:SetStatusBarColor(color.r, color.g, color.b);
  frame.healthBar.r, frame.healthBar.g, frame.healthBar.b = color.r, color.g, color.b;
end

function MrTarget:GetUnit(unit)
  local target = unit..'target';
  if UnitIsEnemy('player', unit) then
    return unit;
  elseif UnitIsEnemy('player', target) then
    return target;
  else
    return unit;
  end
end

function MrTarget:UpdateUnit(unit)
  unit = self:GetUnit(unit);
  if UnitIsEnemy('player', unit) then
    local frame = self:UnitFrame(unit);
    if frame then
      self:UpdateHealthColor(frame, frame.unit.class);
      frame.healthBar:SetMinMaxValues(0, UnitHealthMax(unit));
      frame.healthBar:SetValue(UnitHealth(unit));
      self:UpdatePowerColor(frame, unit);
      frame.powerBar:SetMinMaxValues(0, UnitPowerMax(unit));
      frame.powerBar:SetValue(UnitPower(unit));
    end
  end
end

function MrTarget:PlayerTargetUnit(unit, debug)
  if UnitIsEnemy('player', unit) or debug then
    local frame = self:UnitFrame(unit);
    self.targetIcon:ClearAllPoints();
    self.targetIcon:SetPoint('TOPRIGHT', frame, 'TOPLEFT', -8, -2);
    self.targetIcon:Show();
    if UnitIsGroupLeader('player') then
      self:LeaderTargetUnit(unit);
    end
  else
    self.targetIcon:Hide();
  end
end

function MrTarget:UpdateLeader()
  self.assistIcon:Hide();
end

function MrTarget:LeaderTargetUnit(unit, debug)
  if UnitIsEnemy('player', unit) or debug then
    local frame = self:UnitFrame(unit);
    self.assistIcon:ClearAllPoints();
    self.assistIcon:SetPoint('TOPRIGHT', frame, 'TOPLEFT', -10, -4);
    self.assistIcon:Show();
  else
    self.assistIcon:Hide();
  end
end

function MrTarget:UpdateTarget(unit)
  self:UpdateUnit(unit);
  if UnitIsUnit(unit, 'player') then
    self:PlayerTargetUnit(unit..'target');
  elseif UnitIsGroupLeader(unit) then
    self:LeaderTargetUnit(unit..'target');
  end
end

function MrTarget:PlayerDied()
  for i=1, MAX_FRAMES do
    FRAMES[i].auraIcon:Hide();
  end
  self.targetIcon:Hide();
  self.assistIcon:Hide();
end

function MrTarget:UpdateState()
  for i=1, MAX_FRAMES do
    FRAMES[i].auraIcon:Hide();
    for f=1, 5 do
      self:UpdateAura('arena'..f);
    end
  end
end

function MrTarget:UpdateAura(unit)
  -- local name, rank, icon, count, _, _, _, _, _, _, aura = self.UnitAura(unit, 'Horde Flag');
  -- if name then print(name, aura); end
  self:UpdateUnit(unit);
  if UnitIsEnemy('player', unit) then
    local frame, key = self:UnitFrame(unit);
    if frame and self.battlefield.spells then
      for spell in pairs(self.battlefield.spells) do
        local name, rank, icon, count, _, _, _, _, _, _, aura = self.UnitAura(unit, self.battlefield.spells[spell].name);
        if aura == spell then
          if self.battlefield.carriers[aura] and self.battlefield.carriers[aura] ~= key then
            FRAMES[self.battlefield.carriers[aura]].auraIcon:Hide();
          end
          self.battlefield.carriers[aura] = key;
          frame.auraIcon.icon:SetTexture(self.battlefield.spells[aura].texture);
          frame.auraIcon:Show();
          break;
        end
      end
    end
  end
end

function MrTarget:UpdateZone()
  self.inInstance, self.instanceType = IsInInstance();
  if self.instanceType == 'arena' then
    -- self:Initialize(); NOT YET
  elseif self.instanceType == 'pvp' then
    self:Initialize();
  else
    self:Destroy();
  end
end

function MrTarget:SetBattlefield()
  if self.battlefield == nil then
    local status, name;
    for i=1, GetMaxBattlefieldID() do
      local status, name, size = GetBattlefieldStatus(i);
      if status == 'active' then
        self.UnitAura = UnitAura;
        if BATTLEFIELDS[name] then
          self.battlefield = BATTLEFIELDS[name];
          if self.battlefield.debuffs then
            self.UnitAura = UnitDebuff;
          end
        else
          self.battlefield = { size=size };
        end
        self.battlefield.name = name;
      end
    end
  end
end

local function SortAlphabetically(u,v)
  if v ~= nil and u ~= nil then
    if u.name < v.name then
      return true;
    end
  elseif u then
    return true;
  end
end

local function SortByRole(u,v)
  if v ~= nil and u ~= nil then
    if u.role == v.role then
      if u.name < v.name then
        return true;
      end
    elseif u.role == 'TANK' then
      return true;
    elseif u.role == 'HEALER' and v.role ~= 'TANK' then
      return true;
    end
  elseif u then
    return true;
  end
end

function MrTarget:UpdateArenaScore()
  self:SetBattlefield();
  local numEnemies = GetNumArenaOpponentSpecs();
  if numEnemies > 0 then
    local units = {};
    for i=1, numEnemies do
      local target = 'arena'..i;
      local specid = GetArenaOpponentSpec(i);
      local id, spec, description, icon, background, role, class = GetSpecializationInfoByID(specid);
      local name = GetUnitName(target);
      if name then
        table.insert(units, { name=name, target=target, class=class, role=role });
        numEnemies = numEnemies+1;
      end
    end
    if numEnemies > 0 then
      table.sort(units, SortAlphabetically);
      for i=1, numEnemies do
         local name, server = self:SplitName(units[i].name);
         units[i].name = self:GetName(name, true)..server;
      end
      table.sort(units, SortByRole);
      UNITS = units;
      self:UpdateFrames();
      self:Show();
    end
  end
end

function MrTarget:UpdateBattlegroundScore()
  self:SetBattlefield();
  local playerFaction = GetBattlefieldArenaFaction();
  local numScores, numEnemies = GetNumBattlefieldScores(), 0;
  if numScores > 0 then
    local units = {};
    for i=1, numScores do
      local target, _, _, _, _, faction, race, _, class, _, _, _, _, _, _, talent = GetBattlefieldScore(i);
      if faction ~= playerFaction then
        table.insert(units, { name=target, server=server, target=target, class=class, role=ROLES[class][talent].role });
        numEnemies = numEnemies+1;
      end
    end
    if numEnemies > 0 then
      table.sort(units, SortAlphabetically);
      for i=1, numEnemies do
         local name, server = self:SplitName(units[i].name);
         units[i].name = self:GetName(name, true)..server;
      end
      table.sort(units, SortByRole);
      UNITS = units;
      REQUEST_FREQUENCY = math.max(REQUEST_FREQUENCY+1, MAX_REQUEST_TIME);
      if self.battlefield and numEnemies < self.battlefield.size then
        REQUEST_FREQUENCY = 1;
      end
      self:UpdateFrames();
      self:Show();
    end
  else
    RequestBattlefieldScoreData();
  end
end

function MrTarget:GetFrame(name)
  if ENEMIES[name] then
    if FRAMES[ENEMIES[name]] then
      return FRAMES[ENEMIES[name]], ENEMIES[name];
    end
  end
end

function MrTarget:UnitFrame(unit)
  local name = self:GetUnitNameReadable(unit, true);
  return self:GetFrame(name);
end

function MrTarget:UpdateFrames()
  local visible = 0;
  self:ResetNames();
  ENEMIES = {};
  for i=1, MAX_FRAMES do
    if UNITS[i] then
      FRAMES[i].unit = UNITS[i];
      FRAMES[i].name:SetText(UNITS[i].name);
      FRAMES[i].roleIcon.icon:SetTexCoord(GetTexCoordsForRoleSmallCircle(UNITS[i].role));
      FRAMES[i]:SetAttribute('macrotext1', '/targetexact '..UNITS[i].target);
      self:UpdateHealthColor(FRAMES[i], UNITS[i].class);
      self:UpdatePowerColor(FRAMES[i], UNITS[i].name);
      FRAMES[i]:Show();
      ENEMIES[UNITS[i].name] = i;
      visible = visible+1;
    else
      FRAMES[i].unit = nil;
      FRAMES[i]:Hide();
    end
  end
  self:SetSize(100, visible*36+14);
end

function MrTarget:CreateFrames()
  for i=1, MAX_FRAMES do
    if FRAMES[i] == nil then
      FRAMES[i] = CreateFrame('Button', 'MrTargetUnitFrame'..i, self, 'MrTargetUnitFrameTemplate');
      FRAMES[i]:EnableMouse(true);
      FRAMES[i]:RegisterForDrag('RightButton');
      FRAMES[i]:RegisterForClicks('LeftButtonUp');
      FRAMES[i]:SetAttribute('type1', 'macro');
      FRAMES[i]:SetAttribute('macrotext1', '');
      if i>1 then
        FRAMES[i]:ClearAllPoints();
        FRAMES[i]:SetPoint('TOP', FRAMES[i-1], 'BOTTOM', 0, 0);
      end
    end
  end
end

function MrTarget:GetRoles()
    for classID=1, MAX_CLASSES do
        local _, classTag, classID = GetClassInfoByID(classID);
        local numTabs = GetNumSpecializationsForClassID(classID);
        ROLES[classTag] = {};
        for i=1, numTabs do
            local id, name, description, icon, background, role = GetSpecializationInfoForClassID(classID, i);
            ROLES[classTag][name] = { role=role, id=id, description=description, icon=icon };
        end
    end
end

function MrTarget:Initialize()
  self:RegisterEvent('PLAYER_DEAD');
  self:RegisterEvent('UNIT_AURA');
  self:RegisterEvent('UNIT_TARGET');
  self:RegisterEvent('UNIT_HEALTH');
  self:RegisterEvent('UNIT_FLAGS');
  self:RegisterEvent('UNIT_COMBAT');
  self:RegisterEvent('PARTY_LEADER_CHANGED');
  self:RegisterEvent('UPDATE_WORLD_STATES');
  if self.instanceType == 'arena' then
    self:RegisterEvent('ARENA_PREP_OPPONENT_SPECIALIZATIONS');
    self:RegisterEvent('ARENA_OPPONENT_UPDATE');
  elseif self.instanceType == 'pvp' then
    self:SetScript('OnUpdate', self.OnUpdate);
    self:RegisterEvent('UPDATE_BATTLEFIELD_SCORE');
    RequestBattlefieldScoreData();
  end
  ObjectiveTrackerFrame:Hide();
end


function MrTarget:Destroy()
  self:Hide();
  self:UnregisterEvent('PLAYER_DEAD');
  self:UnregisterEvent('UNIT_AURA');
  self:UnregisterEvent('UNIT_TARGET');
  self:UnregisterEvent('UNIT_HEALTH');
  self:UnregisterEvent('UNIT_FLAGS');
  self:UnregisterEvent('UNIT_COMBAT');
  self:UnregisterEvent('PARTY_LEADER_CHANGED');
  self:UnregisterEvent('UPDATE_WORLD_STATES');
  if self.instanceType == 'arena' then
    self:UnregisterEvent('ARENA_PREP_OPPONENT_SPECIALIZATIONS');
    self:UnregisterEvent('ARENA_OPPONENT_UPDATE');
  elseif self.instanceType == 'pvp' then
    self:SetScript('OnUpdate', nil);
    self:UnregisterEvent('UPDATE_BATTLEFIELD_SCORE');
    RequestBattlefieldScoreData();
  end
  ObjectiveTrackerFrame:Show();
end

function MrTarget:OnUpdate(time)
  LAST_REQUEST = LAST_REQUEST + time;
  if LAST_REQUEST < REQUEST_FREQUENCY or (WorldStateScoreFrame and WorldStateScoreFrame:IsShown()) then
    return;
  end
  RequestBattlefieldScoreData();
  LAST_REQUEST = 0;
end

function MrTarget:OnEvent(event, unit, desc)
  if event == 'ADDON_LOADED' and unit == 'MrTarget' then
    self:OnLoad();
  elseif event == 'ZONE_CHANGED_NEW_AREA' then
    self:UpdateZone();
  elseif event == 'ARENA_PREP_OPPONENT_SPECIALIZATIONS' then
    self:UpdateArenaScore(self);
  elseif event == 'ARENA_OPPONENT_UPDATE' then
    self:UpdateArenaScore(self);
  elseif event == 'UPDATE_BATTLEFIELD_SCORE' then
    if UnitAffectingCombat('player') == false then
      self:UpdateBattlegroundScore(self);
    end
  elseif self.battlefield then
    if event == 'UNIT_COMBAT' then
      self:UpdateUnit(unit);
    elseif event == 'UNIT_HEALTH' then
      self:UpdateUnit(unit);
    elseif event == 'UNIT_FLAGS' then
      self:UpdateUnit(unit);
    elseif event == 'UPDATE_WORLD_STATES' then
      self:UpdateState();
    elseif event == 'PARTY_LEADER_CHANGED' then
      self:UpdateLeader();
    elseif event == 'UNIT_AURA' then
      self:UpdateAura(unit);
    elseif event == 'PLAYER_DEAD' then
      self:PlayerDied();
    elseif event == 'UNIT_TARGET' then
      self:UpdateTarget(unit);
    end
  end
end

HookSecureFunc("UnitFrame_Update", function(self)
  if UnitIsEnemy('player', self.unit) then
    self.name:SetText(MrTarget:GetUnitNameReadable(self.unit));
  end
end);

HookSecureFunc("WorldStateScoreFrame_Update", function(self)
  for i=1, MAX_WORLDSTATE_SCORE_BUTTONS do
    local button = _G["WorldStateScoreButton" .. i];
    local text = button.name.text:GetText();
    if text then
      local name, server = MrTarget:SplitName(button.name.text:GetText());
      button.name.text:SetText(MrTarget:GetName(name, false)..server);
    end
  end
end);

MrTarget:SetScript('OnLoad', MrTarget.OnLoad);
MrTarget:SetScript('OnEvent', MrTarget.OnEvent);

MrTarget:RegisterEvent('ADDON_LOADED');

SLASH_MRTARGET1, SLASH_MRTARGET2 = '/mrt', '/mrtarget';

function SlashCmdList.MRTARGET(cmd, box)
  if cmd == 'show' then
    MrTarget:UpdateZone();
  elseif cmd == 'hide' then
    MrTarget:Destroy();
  end
end