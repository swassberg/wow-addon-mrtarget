--
-- MrTarget v2.0.1
-- =====================================================================
-- Copyright (C) 2014 Lock of War, Developmental (Pty) Ltd
--
-- MrT provides Blizzard style PVP ENEMY Unit Frames and Replaces UNREADABLE Player Names for Target Calling purposes
--
-- Please send any bugs or feedback to mrtarget@lockofwar.com.
--
-- This Work is provided under the Creative Commons
-- Attribution-NonCommercial-NoDerivatives 4.0 International Public License
--
-- For more information see the README and LICENSE files respectively
--

local VERSION = 'v2.0.0';

local MAX_FRAMES = 15;
local MAX_AURAS = 5;
local LAST_REQUEST = 0;
local REQUEST_FREQUENCY = 1;
local MAX_REQUEST_TIME = 10;

local FRAMES = {};
local ENEMIES = {};
local UNITS = {};
local ROLES = {};

local POWER_BAR_COLORS = {
  ['MANA']={ r=0.00,g=0.00,b=1.00 };
  ['RAGE']={ r=1.00,g=0.00,b=0.00 };
  ['FOCUS']={ r=1.00,g=0.50,b=0.25 };
  ['ENERGY']={ r=1.00,g=1.00,b=0.00 };
  ['CHI']={ r=0.71,g=1.0,b=0.92 };
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
local SendAddonMessage = SendAddonMessage;
local GetSpecializationRoleByID = GetSpecializationRoleByID;
local GetSpecializationInfo = GetSpecializationInfo;
local GetSpecialization = GetSpecialization;
local CheckInteractDistance = CheckInteractDistance;

local CHAT_CHANNEL = 'INSTANCE_CHAT';
local CHAT_PREFIX = 'MrTarget';

local DEFAULT_OPTIONS = {
  ['SIZE']=100,
  ['SET']='Pokemon',
  ['MAX_FRAMES']=15,
  ['MAX_AURAS']=5
};

local NAME_ACTIVE = true;
local NAME_COUNT = 1;
local NAME_READABLE = {};

local NAME_SETS = {
  ['Pokemon'] = {
    'Pikachu', 'Bellsprout', 'Zubat', 'Bulbasaur', 'Charmander', 'Diglett', 'Slowpoke', 'Squirtle', 'Oddish', 'Geodude',
    'Mew', 'Gastly', 'Onix', 'Golduck', 'Spearow', 'Butterfree', 'Charizard', 'Graveler', 'Psyduck', 'Meowth',
    'Krabby', 'Mankey', 'Rattata', 'Metapod', 'Alakazam', 'Pidgeotto', 'Poliwag', 'Kadabra',  'Primeape', 'Caterpie',
    'Gloom', 'Raichu', 'Golem', 'Sandshrew', 'Kakuna', 'Tentacool', 'Vulpix', 'Weedle', 'Jigglypuff', 'Blastoise'
  },
  ['Heroes'] = {
    'Kerrigan', 'Tychus', 'Tyrael', 'Diablo', 'Zeratul', 'Malfurian', 'Rexxar', 'Jaina', 'Uther', 'Anduin',
    'Valeera', 'Thrall', 'Guldan', 'Garrosh', 'Jaraxxus', 'Sylvanas', 'Baine', 'Voljin', 'Varian', 'Illidan',
    'Raynor', 'Arthas', 'Tassadar', 'Nova', 'Deckard', 'Leoric', 'Izual', 'Alexstrasza', 'Ysera', 'Onyxia',
    'Deathwing', 'Malygos', 'Azmodan', 'Aegwynn', 'Cairne', 'Gelbin', 'Jastor', 'Rhonin', 'Tirion', 'Wrathion'
  },
  ['Mythology'] = {
    'Zeus', 'Cerberus', 'Apollo', 'Kronos', 'Athena', 'Agamemnon', 'Hades', 'Perseus', 'Hermes', 'Poseidon',
    'Artemis', 'Ares', 'Erebus', 'Gaia', 'Tartarus', 'Cyclops', 'Odysseus', 'Aphrodite', 'Mormo', 'Dionysus',
    'Helios', 'Nyx', 'Iris', 'Orpheus', 'Hector', 'Heracles', 'Ajax', 'Electra', 'Hypnos', 'Hecuba',
    'Hera', 'Hecuba', 'Theseus', 'Diomedes', 'Achilles', 'Chimera', 'Bellerophon', 'Jason', 'Midas', 'Helen'
  },
  ['Xmen'] = {
    'ProfessorX', 'Cyclops', 'Iceman', 'Archangel', 'Beast', 'Phoenix', 'Mimic', 'Changeling', 'Polaris', 'Havok',
    'Nightcrawler', 'Wolverine', 'Banshee', 'Storm', 'Sunfire', 'Colossus', 'Thunderbird', 'Rogue', 'Magneto', 'Gambit',
    'Jubilee', 'Bishop', 'Juggernaut', 'Mystique', 'Warpath', 'Sabretooth', 'Vulcan', 'Shadowcat', 'Lockhead', 'Northstar',
    'Karma', 'Magma', 'Magik', 'Domino', 'Cypher', 'Frenzy', 'Legion', 'Warbird', 'Blink', 'Mirage'
  },
  ['Justice'] = {
    'Superman', 'Batman', 'WonderWoman', 'Flash', 'GreenLantern', 'Aquaman', 'Manhunter', 'Atom', 'Hawkman', 'Stargirl',
    'Catwoman', 'Zatanna', 'Firestorm', 'Steel', 'Vixen', 'Vibe', 'Gypsy', 'Huntress', 'DoctorFate', 'Lightray',
    'Orion', 'Kasumi', 'Maxima', 'Zauriel', 'Obsidian', 'Bloodwynd', 'Metamorpho', 'PowerGirl', 'CrimsonFox', 'Icemaiden',
    'Nuklon', 'Cluemaster', 'Shazam', 'Cyborg', 'Olympian', 'Godiva', 'Firehawk', 'Bulleteer', 'BigBarda', 'Oracle'
  }
};

local NAME_OPTIONS = NAME_SETS[DEFAULT_OPTIONS.SET];

local BG_AURAS = {
   [23333]={ name='Horde Flag', icon='Interface\\Icons\\INV_BannerPVP_01' },
   [23335]={ name='Alliance Flag', icon='Interface\\Icons\\INV_BannerPVP_02' },
   [34976]={ name='Netherstorm Flag', icon='Interface\\Icons\\INV_BannerPVP_01' },
   [46393]={ name='Brutal Assualt', icon='Interface\\Icons\\Spell_Misc_WarsongFocus' },
   [46392]={ name='Focused Assualt', icon='Interface\\Icons\\Spell_Misc_WarsongBrutal' },
  [100196]={ name='Netherstorm Flag', icon='Interface\\Icons\\INV_BannerPVP_02' },
  [141210]={ name='Horde Mine Cart', icon='Interface\\Icons\\INV_BannerPVP_01' },
  [140876]={ name='Alliance Mine Cart', icon='Interface\\Icons\\INV_BannerPVP_02' },
  [156618]={ name='Horde Flag', icon='Interface\\Icons\\INV_BannerPVP_01' },
  [156621]={ name='Alliance Flag', icon='Interface\\Icons\\INV_BannerPVP_02' },
  [121164]={ name='Orb of Power', icon='Interface\\MiniMap\\TempleofKotmogu_ball_cyan' },
  [121175]={ name='Orb of Power', icon='Interface\\MiniMap\\TempleofKotmogu_ball_purple' },
  [121176]={ name='Orb of Power', icon='Interface\\MiniMap\\TempleofKotmogu_ball_green' },
  [121177]={ name='Orb of Power', icon='Interface\\MiniMap\\TempleofKotmogu_ball_orange' },
  [125344]={ name='Orb of Power', icon='Interface\\MiniMap\\TempleofKotmogu_ball_cyan' },
  [125345]={ name='Orb of Power', icon='Interface\\MiniMap\\TempleofKotmogu_ball_purple' },
  [125346]={ name='Orb of Power', icon='Interface\\MiniMap\\TempleofKotmogu_ball_green' },
  [125347]={ name='Orb of Power', icon='Interface\\MiniMap\\TempleofKotmogu_ball_orange' }
}

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
  ARENA_AURAS[ARENA_AURAS_TEMP[i]] = { name=name, icon=icon };
end

local MrTarget = CreateFrame('Frame', 'MrTarget', UIParent, 'MrTargetRaidFrameTemplate');

function MrTarget:OnLoad()
  self:GetRoles();
  self:RegisterForDrag('RightButton');
  self:SetClampedToScreen(true);
  self:EnableMouse(true);
  self:SetMovable(true);
  self:SetUserPlaced(true);
  self:CreateFrames();
  self:RegisterEvent('PLAYER_LOGOUT');
  self:RegisterEvent('PARTY_MEMBERS_CHANGED');
  self:RegisterEvent('ZONE_CHANGED_NEW_AREA');
  self:RegisterEvent('CHAT_MSG_ADDON');
  self:OptionsFrame();
  self:UpdateZone();
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
  if server and server ~= '' then
    if showServerName then
      return name..'-'..server;
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
        if self:IsUTF8(name) and NAME_OPTIONS[NAME_COUNT] then
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

function MrTarget:GetNextName(name)
  NAME_READABLE[name] = NAME_OPTIONS[NAME_COUNT];
  NAME_COUNT = NAME_COUNT+1;
  return NAME_READABLE[name];
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

function MrTarget:UpdateName(unit, frame)
  local name, server = GetUnitName(unit, true);
  if name then
    name, server = self:SplitName(name);
    frame.unit.name = self:GetName(name)..server;
    frame.name:SetText(frame.unit.name);
  end
end

function MrTarget:UpdateRange(unit, frame)
  -- if CheckInteractDistance(unit, 1) then
  --   frame:SetAlpha(1);
  -- else
  --   frame:SetAlpha(0.4);
  -- end
end

function MrTarget:UpdateUnit(unit)
  unit = self:GetUnit(unit);
  if UnitIsEnemy('player', unit) then
    local frame = self:UnitFrame(unit);
    if frame then
      if frame.unit.uid == unit then
        frame.unit.uid = UnitGUID(unit);
        ENEMIES[frame.unit.uid] = ENEMIES[unit];
      end
      frame:SetAlpha(1);
      self:UpdateName(unit, frame);
      self:UpdateRange(unit, frame);
      self:UpdateHealthColor(frame, frame.unit.class);
      frame.healthBar:SetMinMaxValues(0, UnitHealthMax(unit));
      frame.healthBar:SetValue(UnitHealth(unit));
      self:UpdatePowerColor(frame, unit);
      frame.powerBar:SetMinMaxValues(0, UnitPowerMax(unit));
      frame.powerBar:SetValue(UnitPower(unit));
      self:UpdateAuras(unit);
      if UnitIsDeadOrGhost(unit) then
        frame.healthBar:SetValue(0);
        self:Wait(30, (function(f)
          self:UnitDied(f);
        end), frame);
      end
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
  if UnitIsUnit(unit, 'player') then
    self:PlayerTargetUnit(unit..'target');
  elseif UnitIsGroupLeader(unit) then
    self:LeaderTargetUnit(unit..'target');
  end
end

function MrTarget:UpdateState()
  for i=1, MAX_FRAMES do
    for f=1, 5 do
      self:UpdateUnit('arena'..f);
    end
  end
end

function MrTarget:HideAuras(frame)
  for a=1, MAX_AURAS do
    frame['auraIcon'..a].id = nil;
    frame['auraIcon'..a].icon:SetTexture(nil);
    frame['auraIcon'..a]:Hide();
  end
end

function MrTarget:SetAura(frame, count, id, name, icon, stack, expires)
  if frame then
    expires = (expires and expires > 0) and math.abs(math.floor(((GetTime()-expires)*10)+0.5)/(10)) or '';
    frame['auraIcon'..count].id = id;
    frame['auraIcon'..count].icon:SetTexture(icon);
    frame['auraIcon'..count].time:SetText(expires);
    frame['auraIcon'..count]:Show();
  end
end

function MrTarget:UpdateBattlegroundAuras(frame, count, unit)
  for aid, aura in pairs(self.battlefield.auras) do
    if count > MAX_AURAS then
      break;
    end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitBuff(unit, aura.name)
    if not name then
      name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitDebuff(unit, aura.name);
    end
    if id == aid and self.battlefield.auras[id] then
      self:SetAura(frame, count, id, name, self.battlefield.auras[id].icon, stack, expires);
      count = count+1;
    end
  end
  return count;
end

function MrTarget:UpdateArenaDebuffs(frame, count, unit)
  for i=1,40 do
    if count > MAX_AURAS then
      break;
    end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitDebuff(unit, i);
    if not source or not UnitIsUnit('player', source) then
      if self.battlefield.auras[id] then
        self:SetAura(frame, count, id, name, self.battlefield.auras[id].icon, stack, expires);
        count = count+1;
      end
    end
  end
  return count;
end

function MrTarget:UpdateCastDebuffs(frame, count, unit)
  for i=1,40 do
    if count > MAX_AURAS then
      break;
    end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitDebuff(unit, i, 'PLAYER');
    if name then
      self:SetAura(frame, count, id, name, icon, stack, expires);
      count = count+1;
    end
  end
  return count;
end

function MrTarget:UpdateAuras(unit)
  if UnitIsEnemy('player', unit) then
    local count = 1;
    local frame, key = self:UnitFrame(unit);
    if frame then
      self:HideAuras(frame);
      if self.instanceType == 'pvp' then
        count = self:UpdateBattlegroundAuras(frame, count, unit);
      elseif self.instanceType == 'arena' then
        count = self:UpdateCastDebuffs(frame, count, unit);
        count = self:UpdateArenaDebuffs(frame, count, unit);
      end
    end
  end
end

function MrTarget:PlayerDied()
  self.targetIcon:Hide();
end

function MrTarget:UnitDied(frame)
  if frame and frame.healthBar:GetValue() == 0 then
    frame.healthBar:SetValue(select(2, frame.healthBar:GetMinMaxValues()));
    frame.powerBar:SetValue(select(2, frame.powerBar:GetMinMaxValues()));
    frame:SetAlpha(0.4);
  end
end

function MrTarget:UpdateZone()
  if not InCombatLockdown() then
    self:Hide();
  end
  self.inInstance, self.instanceType = IsInInstance();
  if self.instanceType == 'pvp' then
    self:Initialize();
  elseif self.instanceType == 'arena' then
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
        local auras = BG_AURAS;
        if self.instanceType == 'arena' then
          size = GetNumArenaOpponents();
          auras = ARENA_AURAS;
        end
        self.battlefield = { name=name, size=size, auras=auras };
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

function MrTarget:GetArenaSpecialization(i)
  local specid = GetArenaOpponentSpec(i);
  if specid then
    local id, spec, desc, icon, background, role, class = GetSpecializationInfoByID(specid);
    return class, role, spec;
  end
  return nil, nil, nil;
end

function MrTarget:UpdateArenaScore()
  self:SetBattlefield();
  local units = {};
  local numEnemies = 0;
  for i=1,5 do
    local class, role, spec = self:GetArenaSpecialization(i);
    if spec then
      local target = 'arena'..i;
      local name = GetUnitName(target) or 'Unknown';
      table.insert(units, { uid=target, name=name, target=target, class=class, spec=spec, role=role });
      numEnemies = numEnemies+1;
    end
  end
  if numEnemies > 0 then
    table.sort(units, SortAlphabetically);
    for i=1, numEnemies do
      if units[i].name ~= 'Unknown' then
        local name, server = self:SplitName(units[i].name);
        units[i].name = self:GetName(name, true)..server;
      end
    end
    table.sort(units, SortByRole);
    UNITS = units;
    self:SetScript('OnUpdate', nil);
    self:UpdateFrames();
    if not InCombatLockdown() then
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
      local target, _, _, _, _, faction, race, _, class, _, _, _, _, _, _, spec = GetBattlefieldScore(i);
      if faction ~= playerFaction then
        table.insert(units, { uid=target, name=target, target=target, class=class, spec=spec, role=ROLES[class][spec].role });
        numEnemies = numEnemies+1;
      end
    end
    if numEnemies > 0 then
      self:ResetNames();
      table.sort(units, SortAlphabetically);
      for i=1, numEnemies do
         local name, server = self:SplitName(units[i].name);
         units[i].name = self:GetName(name, true)..server;
         units[i].uid = units[i].name;
      end
      table.sort(units, SortByRole);
      UNITS = units;
      REQUEST_FREQUENCY = math.max(REQUEST_FREQUENCY+1, MAX_REQUEST_TIME);
      if self.battlefield and numEnemies < self.battlefield.size then
        REQUEST_FREQUENCY = 1;
      end
      self:UpdateFrames();
      if not InCombatLockdown() then
        self:Show();
      end
    end
  else
    RequestBattlefieldScoreData();
  end
end

function MrTarget:GetFrame(uid)
  if ENEMIES[uid] then
    if FRAMES[ENEMIES[uid]] then
      return FRAMES[ENEMIES[uid]], ENEMIES[uid];
    end
  end
end

function MrTarget:UnitFrame(unit)
  local uid = unit;
  if not ENEMIES[uid] then
    uid = UnitGUID(unit);
    if self.instanceType == 'pvp' then
      uid = self:GetUnitNameReadable(unit, true);
    end
  end
  return self:GetFrame(uid);
end

function MrTarget:UpdateFrames()
  local visible = 0;
  ENEMIES = {};
  for i=1, MAX_FRAMES do
    if UNITS[i] then
      FRAMES[i].unit = UNITS[i];
      FRAMES[i].name:SetText(UNITS[i].name);
      FRAMES[i].spec:SetText(UNITS[i].spec);
      if UNITS[i].role then
        FRAMES[i].roleIcon.icon:SetTexCoord(GetTexCoordsForRoleSmallCircle(UNITS[i].role));
      end
      self:UpdateHealthColor(FRAMES[i], UNITS[i].class);
      self:UpdatePowerColor(FRAMES[i], UNITS[i].name);
      self:HideAuras(FRAMES[i]);
      if not InCombatLockdown() then
        FRAMES[i]:SetAttribute('macrotext1', '/targetexact '..UNITS[i].target);
        FRAMES[i]:Show();
      end
      ENEMIES[UNITS[i].uid] = i;
      visible = visible+1;
    else
      FRAMES[i].unit = nil;
      if not InCombatLockdown() then
        FRAMES[i]:Hide();
      end
    end
  end
  if not InCombatLockdown() then
    self:SetSize(100, visible*36+14);
  end
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
      for a=1, MAX_AURAS do
        FRAMES[i]['auraIcon'..a] = CreateFrame('Button', FRAMES[i]:GetName()..'AuraIcon'..a, FRAMES[i], 'MrTargetUnitFrameAuraIconTemplate');
        FRAMES[i]['auraIcon'..a]:ClearAllPoints();
        if a == 1 then
          FRAMES[i]['auraIcon'..a]:SetPoint('TOPLEFT', FRAMES[i], 'TOPRIGHT', 4, 0);
        else
          FRAMES[i]['auraIcon'..a]:SetPoint('TOPLEFT', FRAMES[i]['auraIcon'..(a-1)], 'TOPRIGHT', 2, 0);
        end
      end
      if i>1 then
        FRAMES[i]:ClearAllPoints();
        FRAMES[i]:SetPoint('TOP', FRAMES[i-1], 'BOTTOM', 0, 0);
      end
    end
  end
end

function MrTarget:OnEnter(frame)
  frame.targetHighlight:Show();
  -- GameTooltip_SetDefaultAnchor(GameTooltip, frame);
  -- GameTooltip:SetUnit('target');
  -- GameTooltip:Show();
end

function MrTarget:OnLeave(frame)
  frame.targetHighlight:Hide();
  -- GameTooltip:Hide();
end

function MrTarget:GetRoles()
  for classID=1, MAX_CLASSES do
    local _, classTag, classID = GetClassInfoByID(classID);
    local numTabs = GetNumSpecializationsForClassID(classID);
    ROLES[classTag] = {};
    for i=1, numTabs do
      local id, name, description, icon, background, role = GetSpecializationInfoForClassID(classID, i);
      ROLES[classTag][name] = { role=role, id=id, description=description, icon=icon, spec=name };
    end
  end
end

function MrTarget:Initialize()
  UNITS = {};
  self:RegisterEvent('PLAYER_DEAD');
  self:RegisterEvent('UNIT_AURA');
  self:RegisterEvent('UNIT_TARGET');
  self:RegisterEvent('UNIT_HEALTH_FREQUENT');
  self:RegisterEvent('UNIT_FLAGS');
  self:RegisterEvent('UNIT_COMBAT');
  self:RegisterEvent('PARTY_LEADER_CHANGED');
  self:RegisterEvent('UPDATE_WORLD_STATES');
  self:RegisterEvent('ARENA_PREP_OPPONENT_SPECIALIZATIONS');
  self:RegisterEvent('ARENA_OPPONENT_UPDATE');
  self:RegisterEvent('UPDATE_BATTLEFIELD_SCORE');
  self:SetScript('OnUpdate', self.OnUpdate);
end

function MrTarget:Destroy()
  if not InCombatLockdown() then
    self:Hide();
  else
    self:RegisterEvent('PLAYER_REGEN_ENABLED');
  end
  UNITS = {};
  self.battlefield = nil;
  self:UnregisterEvent('PLAYER_DEAD');
  self:UnregisterEvent('UNIT_AURA');
  self:UnregisterEvent('UNIT_TARGET');
  self:UnregisterEvent('UNIT_HEALTH_FREQUENT');
  self:UnregisterEvent('UNIT_FLAGS');
  self:UnregisterEvent('UNIT_COMBAT');
  self:UnregisterEvent('PARTY_LEADER_CHANGED');
  self:UnregisterEvent('UPDATE_WORLD_STATES');
  self:UnregisterEvent('ARENA_PREP_OPPONENT_SPECIALIZATIONS');
  self:UnregisterEvent('ARENA_OPPONENT_UPDATE');
  self:UnregisterEvent('UPDATE_BATTLEFIELD_SCORE');
  self:SetScript('OnUpdate', nil);
end

function MrTarget:OnUpdate(time)
  LAST_REQUEST = LAST_REQUEST + time;
  if REQUEST_FREQUENCY == 0 or LAST_REQUEST < REQUEST_FREQUENCY or (WorldStateScoreFrame and WorldStateScoreFrame:IsShown()) then
    return;
  end
  if self.instanceType == 'pvp' then
    RequestBattlefieldScoreData();
  elseif self.instanceType == 'arena' then
    self:UpdateArenaScore();
  end
  LAST_REQUEST = 0;
end

local function RandomKey(t)
  local keys, i = {}, 1;
  for k in pairs(t) do
    keys[i] = k;
    i = i+1;
  end
  return keys[math.random(1, #keys)];
end

function MrTarget:OpenDebugFrame()
  if not self.battlefield and not InCombatLockdown() then
    self:ResetNames();
    local class = select(2, UnitClass('player'));
    local specid, spec = GetSpecializationInfo(GetSpecialization());
    local player = self:GetName(UnitName('player'), true);
    UNITS = {{ uid=UnitGUID('player'), name=player, target='player', class=class, spec=spec, role=GetSpecializationRoleByID(specid) }};
    for i=1,MAX_FRAMES-1 do
      class = RandomKey(ROLES);
      spec = RandomKey(ROLES[class]);
      table.insert(UNITS, {
        uid=i, name=self:GetNextName(i),
        role=GetSpecializationRoleByID(ROLES[class][spec].id),
        target='raid'..i, class=class, spec=spec
      });
    end
    table.sort(UNITS, SortByRole);
    self:UpdateFrames();
    self:PlayerTargetUnit('player', true);
    self:LeaderTargetUnit('player', true);
    local frame = self:UnitFrame('player');
    local faction = UnitFactionGroup('player');
    self:SetAura(frame, 1, 23333, '', BG_AURAS[23333].icon, 1, 0);
    self:SetAura(frame, 2, 46392, '', BG_AURAS[46392].icon, 1, 0);
    self:SetAura(frame, 3, 46393, '', BG_AURAS[46393].icon, 1, 0);
    self:Show();
  end
end

function MrTarget:CloseDebugFrame()
  if not self.battlefield then
    if not InCombatLockdown() then
      self:Hide();
    else
      self:RegisterEvent('PLAYER_REGEN_ENABLED');
    end
  end
end

function MrTarget:Resize(size)
  self:SetScale(size/100);
end

function MrTarget:OptionsFrame()
  self.Options = CreateFrame('Frame', 'MrTargetOptions', UIParent, 'MrTargetOptionsTemplate');
  self.Options.name = GetAddOnMetadata('MrTarget', 'Title');
  self.Options.title:SetText('MrTarget '..VERSION);
  _G[self.Options.Size:GetName()..'Low']:SetText('50%');
  _G[self.Options.Size:GetName()..'High']:SetText('150%');
  self.Options.okay = function() MrTarget:SaveOptions(); MrTarget:CloseDebugFrame(); end;
  self.Options.default = function() MrTarget:DefaultOptions(); end;
  self.Options.cancel = function() MrTarget:LoadOptions(OPTIONS); MrTarget:CloseDebugFrame(); end;
  self.Options:SetScript('OnShow', function() if InterfaceOptionsFrame:IsShown() then MrTarget:OpenDebugFrame(); end end);
  self.Options:SetScript('OnHide', function() MrTarget:CloseDebugFrame(); end);
  InterfaceOptions_AddCategory(self.Options);
  self:InitSetOptions();
  self:LoadOptions(OPTIONS);
end

function MrTarget:InitSetOptions()
  UIDropDownMenu_Initialize(self.Options.Set, function()
    for set in pairs(NAME_SETS) do
      UIDropDownMenu_AddButton({ owner=self.Options.Set, text=set, value=set, checked=nil, arg1=set, func=(function(_, value)
        UIDropDownMenu_ClearAll(self.Options.Set);
        UIDropDownMenu_SetSelectedValue(self.Options.Set, value);
        NAME_OPTIONS = NAME_SETS[value];
        self:OpenDebugFrame();
      end)});
    end
  end);
  UIDropDownMenu_SetAnchor(self.Options.Set, 16, 22, 'TOPLEFT', self.Options.Set:GetName()..'Left', 'BOTTOMLEFT');
  UIDropDownMenu_JustifyText(self.Options.Set, 'LEFT');
end

function MrTarget:LoadOptions(options)
  self:Resize(options.SIZE);
  self.Options.Size:SetValue(options.SIZE);
  UIDropDownMenu_SetSelectedValue(self.Options.Set, options.SET);
  NAME_OPTIONS = NAME_SETS[options.SET];
  MAX_FRAMES = options.MAX_FRAMES or DEFAULT_OPTIONS.MAX_FRAMES;
  MAX_AURAS = options.MAX_AURAS or DEFAULT_OPTIONS.MAX_AURAS;
end

function MrTarget:SaveOptions()
  OPTIONS.SET = UIDropDownMenu_GetSelectedValue(self.Options.Set);
  OPTIONS.SIZE = self.Options.Size:GetValue();
end

function MrTarget:DefaultOptions()
  self:LoadOptions(DEFAULT_OPTIONS);
end

function MrTarget:ProcessMessage(prefix, message, type, sender)
  if prefix == CHAT_PREFIX then
    if UnitIsGroupLeader(sender) then
      if NAME_SETS[message] then
        NAME_OPTIONS = NAME_SETS[message];
      end
    end
  end
end

function MrTarget:BroadcastOptions()
  if RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(CHAT_PREFIX);
  end
  SendAddonMessage(CHAT_PREFIX, OPTIONS.SET, CHAT_CHANNEL);
  self.assistIcon:Hide();
end

function MrTarget:PlayerLogout()
  if not InCombatLockdown() then
    self:Destroy();
  end
end

function MrTarget:OnHide()
  for i=1, MAX_FRAMES do
    if FRAMES[i] then
      FRAMES[i]:Hide();
    end
  end
  self.targetIcon:Hide();
  self.assistIcon:Hide();
end

function MrTarget:OnEvent(event, arg1, arg2, arg3, arg4)
  if event == 'ADDON_LOADED' and arg1 == 'MrTarget' then
    OPTIONS = OPTIONS or {};
    for i,v in pairs(DEFAULT_OPTIONS) do
      if not OPTIONS[i] then
        OPTIONS[i] = v;
      end
    end
    self:OnLoad();
  elseif event == 'CHAT_MSG_ADDON' then
    self:ProcessMessage(arg1, arg2, arg3, arg4);
  elseif event == 'ZONE_CHANGED_NEW_AREA' then
    self:UpdateZone();
  elseif event == 'ARENA_PREP_OPPONENT_SPECIALIZATIONS' then
    self:UpdateArenaScore();
  elseif event == 'ARENA_OPPONENT_UPDATE' then
    self:UpdateArenaScore();
  elseif event == 'UPDATE_BATTLEFIELD_SCORE' then
    if not InCombatLockdown() then
      if self.instanceType == 'pvp' then
        self:UpdateBattlegroundScore();
      end
    end
  elseif event == 'PLAYER_REGEN_ENABLED' then
    self:UnregisterEvent('PLAYER_REGEN_ENABLED');
    if self.instanceType == 'none' then
      self:Hide();
    end
  elseif event == 'PLAYER_LOGOUT' then
    self:PlayerLogout();
  elseif self.battlefield then
    if event == 'UNIT_COMBAT' then
      self:UpdateUnit(arg1);
    elseif event == 'UNIT_HEALTH_FREQUENT' then
      self:UpdateUnit(arg1);
    elseif event == 'UNIT_FLAGS' then
      self:UpdateUnit(arg1);
    elseif event == 'UPDATE_WORLD_STAfES' then
      self:UpdateState();
    elseif event == 'PARTY_LEADER_CHANGED' then
      self:BroadcastOptions();
    elseif event == 'GROUP_ROSTER_UPDATE' then
      self:BroadcastOptions();
    elseif event == 'PARTY_MEMBERS_CHANGED' then
      self:BroadcastOptions();
    elseif event == 'UNIT_AURA' then
      self:UpdateUnit(arg1);
    elseif event == 'UNIT_TARGET' then
      self:UpdateUnit(arg1);
      self:UpdateTarget(arg1);
    elseif event == 'PLAYER_DEAD' then
      self:PlayerDied();
    end
  end
end

local waitTable, waitFrame = {}, nil;
function MrTarget:Wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame", "WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end

HookSecureFunc('UnitFrame_Update', function(frame)
  if UnitIsEnemy('player', frame.unit) then
    frame.name:SetText(MrTarget:GetUnitNameReadable(frame.unit));
  end
end);

HookSecureFunc('WorldStateScoreFrame_Update', function(frame)
  for i=1, MAX_WORLDSTATE_SCORE_BUTTONS do
    local button = _G['WorldStateScoreButton' .. i];
    local text = button.name.text:GetText();
    if text then
      local name, server = MrTarget:SplitName(text);
      if name and server then
        button.name.text:SetText(MrTarget:GetName(name, false)..server);
      end
    end
  end
end);

MrTarget:SetScript('OnLoad', MrTarget.OnLoad);
MrTarget:SetScript('OnEvent', MrTarget.OnEvent);
MrTarget:SetScript('OnHide', MrTarget.OnHide);

MrTarget:RegisterEvent('ADDON_LOADED');

SLASH_MRTARGET1 = '/mrt';
SLASH_MRTARGET2 = '/mrtarget';
function SlashCmdList.MRTARGET(cmd, box)
  InterfaceOptionsFrame_OpenToCategory(MrTarget.Options);
  InterfaceOptionsFrame_OpenToCategory(MrTarget.Options);
  MrTarget:OpenDebugFrame();
end
