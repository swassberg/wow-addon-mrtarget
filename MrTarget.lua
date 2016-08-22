--
-- MrTarget v1.0.0
-- =====================================================================
-- Copyright (C) 2014 Lock of War, Developmental (Pty) Ltd
-- 
-- In Battlegrounds, MrT provides Blizzard style ENEMY Unit Frames and replaces UNREADABLE Player Names for Target Calling purposes
-- 
-- This Work is provided under the Creative Commons 
-- Attribution-NonCommercial-NoDerivatives 4.0 International Public License
-- 
-- Every effort has been made to ensure instructional efficiency. While testing has shown virtually
-- no noticable system load, we cannot guarentee we were able to produce every possible 
-- combination of events. Please report any bugs to mrt@lockofwar.com.
--
-- For more information see README.md and LICENSE.txt respectively
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
local UnitNameOriginal = UnitName;
local GetUnitNameOriginal = GetUnitName;

local NAME_COUNT = 1;
local NAME_READABLE = {};
local NAME_OPTIONS = {
  'Alakazam', 'Bellsprout', 'Blastoise', 'Bulbasaur', 'Butterfree', 'Caterpie', 'Charizard', 'Charmander', 'Diglett', 'Gastly', 
  'Geodude', 'Gloom', 'Golduck', 'Golem', 'Graveler', 'Jigglypuff', 'Kadabra', 'Kakuna', 'Krabby', 'Mankey',
  'Meowth', 'Metapod', 'Mew', 'Oddish', 'Onix', 'Pidgeotto', 'Pikachu', 'Poliwag', 'Primeape', 'Psyduck', 
  'Raichu', 'Rattata', 'Sandshrew', 'Slowpoke', 'Spearow', 'Squirtle', 'Tentacool', 'Vulpix', 'Weedle', 'Zubat'
}

local BATTLEGROUNDS = {
  ['Alterac Valley'] = { size=40 },
  ['Arathi Basin'] = { size=15 },
  ['Strand of the Ancients'] = { size=15 },
  ['Isle of Conquest'] = { size=40 },
  ['The Battle for Gilneas'] = { size=10 },
  ['Silvershard Mines'] = { size=10 },
  ['Warsong Gulch'] = { size=10, buffs=true, carriers={}, spells={ 
    [23333]={ name="Horde Flag", texture='Interface\\Icons\\INV_BannerPVP_01' }, 
    [23335]={ name="Alliance Flag", texture='Interface\\Icons\\INV_BannerPVP_02' }
  }},
  ['Eye of the Storm'] = { size=15, buffs=true, carriers={}, spells={ 
    [34976]={ name="Netherstorm Flag", texture='Interface\\Icons\\INV_BannerPVP_03' }, 
    [100196]={ name="Netherstorm Flag", texture='Interface\\Icons\\INV_BannerPVP_03' } 
  }},
  ['Twin Peaks'] = { size=10, buffs=true, carriers={}, spells={ 
    [23333]={ name="Horde Flag", texture='Interface\\Icons\\INV_BannerPVP_01' }, 
    [23335]={ name="Alliance Flag", texture='Interface\\Icons\\INV_BannerPVP_02' }
  }},
  ['Deepwind Gorge'] = { size=15, buffs=true, carriers={}, spells={ 
    [140876]={ name="Alliance Mine Cart", texture='Interface\\Minimap\\Vehicle-SilvershardMines-MineCartBlue' },
    [141210]={ name="Horde Mine Cart", texture='Interface\\Minimap\\Vehicle-SilvershardMines-MineCartRed' }
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

local function UnitNameReadable(unit)
  local name, server = UnitNameOriginal(unit);
  if UnitIsEnemy('player', unit) then
    name = MrTarget:GetName(name);
  end
  return name, server;
end

local function GetUnitNameReadable(unit, showServerName)
  local name, server = UnitNameReadable(unit);
  local relationship = UnitRealmRelationship(unit);
  if ( server and server ~= "" ) then
    if ( showServerName ) then
      return name.."-"..server;
    else
      if (relationship == LE_REALM_RELATION_VIRTUAL) then
        return name;
      else
        return name..FOREIGN_SERVER_LABEL;
      end
    end
  else
    return name;
  end
end

function MrTarget:GetName(name)  
  if NAME_READABLE[name] == nil then
    if name and self:IsUTF8(name) then      
      NAME_READABLE[name] = NAME_OPTIONS[NAME_COUNT];       
      NAME_COUNT = NAME_COUNT+1      
    else
      NAME_READABLE[name] = name;
    end
  end
  return NAME_READABLE[name];
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

function MrTarget:OnLoad()
  self:GetRoles();
  self.UnitAura = UnitBuff;
  self:RegisterForDrag('RightButton');  
  self:SetClampedToScreen(true);
  self:EnableMouse(true);    
  self:SetMovable(true);
  self:SetUserPlaced(true);     
  self:CreateFrames();
  self:RegisterEvent('ZONE_CHANGED_NEW_AREA');  
  self:UpdateZone();   
  -- self:SetSize(100, 15*36+14);
  -- self:Show(); 
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

function MrTarget:UpdateUnit(unit)
  unit = unit ..'target';
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

function MrTarget:PlayerTargetUnit(unit)
  if UnitIsEnemy('player', unit) then
    local frame = self:UnitFrame(unit);
    self.targetIcon:ClearAllPoints();
    self.targetIcon:SetPoint('TOPLEFT', frame, 'TOPRIGHT', 2, -6);
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

function MrTarget:LeaderTargetUnit(unit)
  if UnitIsEnemy('player', unit) then
    local frame = self:UnitFrame(unit);
    self.assistIcon:ClearAllPoints();
    self.assistIcon:SetPoint('TOPLEFT', frame, 'TOPRIGHT', 1, -4);
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
  self:UpdateUnit(unit);
  if UnitIsEnemy('player', unit) then
    local frame, key = self:UnitFrame(unit);   
    if frame and self.battleground.spells then
      for spell in pairs(self.battleground.spells) do  
        local name, rank, icon, count, _, _, _, _, _, _, aura = self.UnitAura(unit, self.battleground.spells[spell].name);        
        if aura == spell then          
          if self.battleground.carriers[aura] then
            FRAMES[self.battleground.carriers[aura]].auraIcon:Hide();
          end
          self.battleground.carriers[aura] = key;
          frame.auraIcon.icon:SetTexture(self.battleground.spells[aura].texture);
          frame.auraIcon:Show();
          break;
        end
      end
    end
  end
end 

function MrTarget:UpdateZone()
  local _, instanceType = IsInInstance();
  if instanceType == 'pvp' then      
      self:Initialize();
  else        
      self:Destroy();
  end
end 

function MrTarget:SetBattleground()
  if self.battleground == nil then
    local status, name;
    for i=1, GetMaxBattlefieldID() do
      status, name = GetBattlefieldStatus(i);
      if status == 'active' then
        self.battleground = BATTLEGROUNDS[name];
        if self.battleground.buffs then
          self.UnitAura = UnitBuff;
        elseif self.battleground.debuffs then
          self.UnitAura = UnitDebuff;
        end    
      end
    end
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
  end
end

function MrTarget:UpdateScore()  
  self:SetBattleground();
  local playerFaction = GetBattlefieldArenaFaction();
  local numScores, numEnemies = GetNumBattlefieldScores(), 0;  
  if numScores > 0 then            
    local units = {};
    for i=1, numScores do
      local target, _, _, _, _, faction, race, _, class, _, _, _, _, _, _, talents = GetBattlefieldScore(i);
      if faction ~= playerFaction then         
        local spec = ROLES[class][talents];
        local name, server = target, '';
        local hyphen = strfind(target, '-');
        if hyphen then
            name = strsub(target, 0, hyphen-1)
            server = '-'..strsub(target, hyphen+1);
        end
        name = self:GetName(name)..server;
        table.insert(units, { name=name, target=target, class=class, role=spec.role });
        numEnemies = numEnemies+1;
      end
    end
    if numEnemies > 0 then
      table.sort(units, SortByRole);
      UNITS = units;
      GetUnitName = GetUnitNameReadable;
      REQUEST_FREQUENCY = math.max(REQUEST_FREQUENCY+1, MAX_REQUEST_TIME); 
      if self.battleground and numEnemies < self.battleground.size then
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
  -- for i=1, MAX_FRAMES do
  --   if FRAMES[i].unit and FRAMES[i].unit.name == name then
  --     return FRAMES[i], i;
  --   end
  -- end
end

function MrTarget:UnitFrame(unit)
  local name = GetUnitName(unit, true);
  return self:GetFrame(name);
end

function MrTarget:UpdateFrames()
  local visible = 0;
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
  -- self:SetSize(95*math.ceil(visible/10), math.min(visible, 10)*36+14);
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
        -- FRAMES[i]:SetPoint('TOPLEFT', FRAMES[i-10], 'TOPRIGHT', 0, 0);        
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
  WatchFrame:Hide();   
  self:SetScript('OnUpdate', self.OnUpdate);
  self:RegisterEvent('UPDATE_BATTLEFIELD_SCORE');
  self:RegisterEvent('UNIT_AURA');
  self:RegisterEvent('UNIT_TARGET'); 
  self:RegisterEvent('UNIT_HEALTH');
  self:RegisterEvent('UNIT_FLAGS');
  self:RegisterEvent('UNIT_COMBAT');
  self:RegisterEvent('UPDATE_WORLD_STATES');
  self:RegisterEvent('PARTY_LEADER_CHANGED');
  self:RegisterEvent('PLAYER_DEAD');
  RequestBattlefieldScoreData();
end

function MrTarget:Destroy()
  GetUnitName = GetUnitNameOriginal;
  WatchFrame:Show();
  self:SetScript('OnUpdate', nil);
  self:UnregisterEvent('UPDATE_BATTLEFIELD_SCORE');
  self:UnregisterEvent('UNIT_AURA');
  self:UnregisterEvent('UNIT_TARGET'); 
  self:UnregisterEvent('UNIT_HEALTH');
  self:UnregisterEvent('UNIT_FLAGS');
  self:UnregisterEvent('UNIT_COMBAT');
  self:UnregisterEvent('UPDATE_WORLD_STATES');
  self:UnregisterEvent('PARTY_LEADER_CHANGED');
  self:UnregisterEvent('PLAYER_DEAD');
  self:Hide();
end

function MrTarget:OnUpdate(time)
    LAST_REQUEST = LAST_REQUEST + time;
    if LAST_REQUEST < REQUEST_FREQUENCY or (WorldStateScoreFrame and WorldStateScoreFrame:IsShown()) then 
      return;
    end
    RequestBattlefieldScoreData();
    LAST_REQUEST = 0;
end

function MrTarget:OnEvent(event, unit)
  if event == 'ADDON_LOADED' and unit == 'MrTarget' then
    self:OnLoad();
  elseif event == 'ZONE_CHANGED_NEW_AREA' then
    self:UpdateZone();
  elseif event == 'UPDATE_BATTLEFIELD_SCORE' then
    if UnitAffectingCombat('player') == nil then
      self:UpdateScore(self);
    end
  elseif self.battleground then
    if event == 'UNIT_COMBAT' or event == 'UNIT_HEALTH' or event == 'UNIT_FLAGS' then
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

function SlashCmdList.MRTARGET(cmd, box)
 if cmd == 'show' then
  MrTarget:UpdateZone();
 elseif cmd == 'hide' then
  MrTarget:Destroy();
 end
end

SLASH_MRTARGET1, SLASH_MRTARGET2 = '/mrt', '/mrtarget';

MrTarget:SetScript('OnLoad', MrTarget.OnLoad);
MrTarget:SetScript('OnEvent', MrTarget.OnEvent);

MrTarget:RegisterEvent('ADDON_LOADED');