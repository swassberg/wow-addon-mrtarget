-- MrTarget
-- =====================================================================
-- Copyright (C) 2014 Lock of War, Developmental (Pty) Ltd
--
-- This Work is provided under the Creative Commons
-- Attribution-NonCommercial-NoDerivatives 4.0 International Public License
--
-- Please send any bugs or feedback to mrtarget@lockofwar.com.
-- /run print((select(4, GetBuildInfo())));

local VERSION = 'v2.2.3';

local MAX_FRAMES = 15;
local MAX_AURAS = 9;
local LAST_REQUEST = 0;
local REQUEST_TICK = 1;
local REQUEST_DELAY = 10;
local RANGE_TICK = 0.1;
local RANGE_DELAY = 6;
local HIDDEN = false;
local FRAMES = {};
local ENEMIES = {};
local RANGE = {};
local UNITS = {};
local NAMES = {};
local ROLES = {};

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
local GetSpellBookItemName = GetSpellBookItemName;
local GetSpellInfo = GetSpellInfo;
local IsSpellInRange = IsSpellInRange;
local IsHarmfulSpell = IsHarmfulSpell;

local PLAYER_NAME = nil;
local PLAYER_CLASS = nil;
local PLAYER_SPEC = nil;
local PLAYER_RANGE = nil;
local PLAYER_TARGET = nil;
local LEADER_TARGET = nil;
local BATTLEFIELD = 'BATTLEGROUND';
local CHAT_PREFIX = 'MrTarget';

local DEFAULT_OPTIONS = {
  VERSION=VERSION,
  BATTLEGROUND={
    ENABLED=true,
    POSITION={ 'TOPLEFT', nil, 'TOPLEFT', 100, -150 },
    BORDERLESS=false,
    ICONS=true,
    SIZE=100,
    NAMING='Transmute',
    POWER=true,
    RANGE=true,
    TARGETED=true,
    DEBUFFS=true,
    MAX_FRAMES=15
  },
  ARENA={
    ENABLED=true,
    POSITION={ 'TOPLEFT', nil, 'TOPLEFT', 100, -150 },
    BORDERLESS=false,
    ICONS=true,
    SIZE=100,
    NAMING='Transmute',
    POWER=true,
    RANGE=true,
    TARGETED=true,
    DEBUFFS=true,
    MAX_FRAMES=5
  }
};

local POWER_BAR_COLORS = {
  MANA={ r=0.00,g=0.00,b=1.00 },
  RAGE={ r=1.00,g=0.00,b=0.00 },
  FOCUS={ r=1.00,g=0.50,b=0.25 },
  ENERGY={ r=1.00,g=1.00,b=0.00 },
  CHI={ r=0.71,g=1.0,b=0.92 },
  RUNES={ r=0.50,g=0.50,b=0.50 }
};

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

local RANGE_SPELLS = {
  WARRIOR=355, PALADIN=20271, HUNTER=75, ROGUE=1725, PRIEST=589, DEATHKNIGHT=49576,
  SHAMAN=403, MAGE=44614, WARLOCK=686, MONK=115546, DRUID=5176
};

local LFGRoleTexCoords = { TANK={ 0.5,0.75,0,1 }, DAMAGER={ 0.25,0.5,0,1 }, HEALER={ 0.75,1,0,1 }};

local function GetTexCoordsForRole(role, borderless)
  local c = borderless and LFGRoleTexCoords[role] or {GetTexCoordsForRoleSmallCircle(role)};
  return unpack(c);
end

local MrTarget = CreateFrame('Frame', 'MrTarget', UIParent, 'MrTargetRaidFrameTemplate');

function MrTarget:SayHello()
  ChatFrame1:AddMessage('|cFF00FFFF <MrTarget-'..VERSION..'>|cFFFF0000 Even the Score.|r Type /mrt for interface options.', 0, 0, 0, GetChatTypeIndex('SYSTEM'));
end

function MrTarget:OnLoad()
  self:SayHello();
  self:GetRoles();
  self:RegisterForDrag('RightButton');
  self:SetClampedToScreen(true);
  self:EnableMouse(true);
  self:SetMovable(true);
  self:SetUserPlaced(true);
  self:CreateFrames();
  self:RegisterEvent('PLAYER_LOGIN');
  self:RegisterEvent('PLAYER_LOGOUT');
  self:RegisterEvent('PARTY_MEMBERS_CHANGED');
  self:RegisterEvent('ZONE_CHANGED');
  self:RegisterEvent('ZONE_CHANGED_NEW_AREA');
  self:RegisterEvent('ZONE_CHANGED_INDOORS');
  self:RegisterEvent('CHAT_MSG_ADDON');
  self:InitOptions();
  self:UpdateZone();
end

local NAME_COUNT = 1;
local NAME_OPTIONS = {
  'Pikachu', 'Bellsprout', 'Zubat', 'Bulbasaur', 'Charmander', 'Diglett', 'Slowpoke', 'Squirtle', 'Oddish', 'Geodude',
  'Mew', 'Gastly', 'Onix', 'Golduck', 'Spearow', 'Butterfree', 'Charizard', 'Graveler', 'Psyduck', 'Meowth',
  'Krabby', 'Mankey', 'Rattata', 'Metapod', 'Alakazam', 'Pidgeotto', 'Poliwag', 'Kadabra',  'Primeape', 'Caterpie',
  'Gloom', 'Raichu', 'Golem', 'Sandshrew', 'Kakuna', 'Tentacool', 'Vulpix', 'Weedle', 'Jigglypuff', 'Blastoise'
};

function MrTarget:Transmute(name)
  if self:IsUTF8(name) then
    name = NAME_OPTIONS[NAME_COUNT];
    NAME_COUNT=NAME_COUNT+1;
  end
  return name;
end

local CYRILLIC = {
  ["А"]="A", ["а"]="a", ["Б"]="B", ["б"]="b", ["В"]="V", ["в"]="v", ["Г"]="G", ["г"]="g", ["Д"]="D", ["д"]="d", ["Е"]="E",
  ["е"]="e", ["Ё"]="E", ["ё"]="e", ["Ж"]="Zh", ["ж"]="zh", ["З"]="Z", ["з"]="z", ["И"]="I", ["и"]="i", ["Й"]="I", ["й"]="i",
  ["К"]="K", ["к"]="k", ["Л"]="L", ["л"]="l", ["М"]="M", ["м"]="m", ["Н"]="N", ["н"]="n", ["О"]="O", ["о"]="o", ["П"]="P", ["п"]="p",
  ["Р"]="R",["р"]="r", ["С"]="S", ["с"]="s", ["Т"]="T", ["т"]="t", ["У"]="U", ["у"]="u", ["Ф"]="F", ["ф"]="f", ["Х"]="Kh", ["х"]="kh",
  ["Ц"]="Ts", ["ц"]="ts", ["Ч"]="Ch", ["ч"]="ch", ["Ш"]="Sh", ["ш"]="sh", ["Щ"]="Shch", ["щ"]="shch", ["Ъ"]="Ie", ["ъ"]="ie",
  ["Ы"]="Y", ["ы"]="y", ["Ь"]="X", ["ь"]="x", ["Э"]="E", ["э"]="e", ["Ю"]="Iu", ["ю"]="iu", ["Я"]="Ia", ["я"]="ia"
};

function MrTarget:ResetNames()
  NAME_COUNT = 1;
  wipe(NAMES);
end

function MrTarget:Transliterate(name)
  if name then
    for c, r in pairs(CYRILLIC) do
      name = string.gsub(name, c, r);
    end
  end
  return name;
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

function MrTarget:SetReadableName(name)
  if name then
    NAMES[name] = name;
    if OPTIONS[BATTLEFIELD].NAMING == 'Transmute' then
      NAMES[name] = self:Transmute(name);
    elseif OPTIONS[BATTLEFIELD].NAMING == 'Transliterate' then
      NAMES[name] = self:Transliterate(name);
    end
    return NAMES[name];
  else
    return '';
  end
end

function MrTarget:GetReadableName(name)
  if name then
    if NAMES[name] then
      return NAMES[name];
    elseif self.instanceType == 'arena' then
      return self:SetReadableName(name);
    else
      return name;
    end
  else
    return '';
  end
end

function MrTarget:UnitNameReadable(unit)
  local name, server = UnitName(unit);
  if UnitIsEnemy('player', unit) then
    name = MrTarget:GetReadableName(name);
  end
  return name, server;
end

function MrTarget:GetUnitNameReadable(unit)
  local name, server = self:UnitNameReadable(unit);
  if not server then
    return name..FOREIGN_SERVER_LABEL;
  else
    return name, server;
  end
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
    return '', '';
  end
end

function MrTarget:UpdateName(frame, name, server)
  if name then
    name, server = self:SplitName(name);
    if name and server ~= nil then
      frame.unit.display = self:GetReadableName(name)..server;
      frame.name:SetText(frame.unit.display);
    end
  end
end

function MrTarget:UpdatePowerColor(frame, unit)
  local powerType, powerToken = UnitPowerType(unit);
  local color = POWER_BAR_COLORS[powerToken] or POWER_BAR_COLORS.MANA;
  if color then
    frame.powerBar:SetStatusBarColor(color.r, color.g, color.b);
  end
end

function MrTarget:UpdateHealthColor(frame, classToken)
  local color = RAID_CLASS_COLORS[classToken];
  frame.healthBar:SetStatusBarColor(color.r, color.g, color.b);
  frame.healthBar.r, frame.healthBar.g, frame.healthBar.b = color.r, color.g, color.b;
end

function MrTarget:UpdateRange(frame, unit)
  RANGE[frame.unit.target] = GetTime();
  if OPTIONS[BATTLEFIELD].RANGE then
    if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then
      self:SetTransparency(frame, 0.5);
    elseif IsSpellInRange(RANGE_SPELLS[PLAYER_CLASS], 'spell', unit) or CheckInteractDistance(unit, 1)  then
      self:SetTransparency(frame, 1.0);
    else
      self:SetTransparency(frame, 0.5);
    end
  end
end

function MrTarget:CheckRangeDelay()
  for i=1, OPTIONS[BATTLEFIELD].MAX_FRAMES do
    if FRAMES[i].unit then
      local time = RANGE[FRAMES[i].unit.target];
      if not time or time+RANGE_DELAY <= GetTime() then
        self:SetTransparency(FRAMES[i], 0.5);
      end
    end
  end
end

function MrTarget:CheckRange(fullname, range, time)
  if fullname then
    local frame = self:UnitFrame(fullname)
    if frame then
      RANGE[frame.unit.target] = time;
      if range > 0 and range <= PLAYER_RANGE then
        self:SetTransparency(frame, 1.0);
      end
    end
  end
end

function MrTarget:ParseCombatEvent(source, sourceflags, target, targetflags, range, time)
  if sourceflags and bit.band(sourceflags, COMBATLOG_OBJECT_TYPE_PLAYER) then
    if source and CheckInteractDistance(source, 1) then
      self:CheckRange(target, range, time);
      if bit.band(sourceflags, COMBATLOG_OBJECT_REACTION_HOSTILE) then
        self:CheckRange(source, 28, time);
      end
    end
  end
end

function MrTarget:CombatEvent(...)
  local time = GetTime();
  local _, event, _, _, source, sourceflags, _, _, target, targetflags, _, spell = ...;
  if source ~= target and spell then
    local range = select(6, GetSpellInfo(spell));
    if range then
      if target == PLAYER_NAME then
        self:CheckRange(source, range, time);
      elseif bit.band(sourceflags, COMBATLOG_OBJECT_REACTION_HOSTILE) then
        self:ParseCombatEvent(source, sourceflags, target, targetflags, range, time);
      end
    end
  end
  self:CheckRangeDelay();
end

function MrTarget:SetTransparency(frame, alpha)
  frame.name:SetAlpha(alpha);
  frame.specIcon:SetAlpha(alpha);
  frame.spec:SetAlpha(alpha);
  self:SetStatusBarAlpha(frame.healthBar, alpha);
  self:SetStatusBarAlpha(frame.powerBar, alpha);
end

function MrTarget:SetStatusBarAlpha(statusBar, alpha)
  local r,g,b,a = statusBar:GetStatusBarColor();
  statusBar:SetStatusBarColor(r,g,b,alpha);
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
      self:UpdateName(frame, GetUnitName(unit, true));
      self:UpdateHealthColor(frame, frame.unit.class);
      frame.healthBar:SetMinMaxValues(0, UnitHealthMax(unit));
      frame.healthBar:SetValue(UnitHealth(unit));
      self:UpdatePowerColor(frame, unit);
      frame.powerBar:SetMinMaxValues(0, UnitPowerMax(unit));
      frame.powerBar:SetValue(UnitPower(unit));
      self:UpdateRange(frame, unit);
      self:UpdateTargeted(frame, unit);
      self:UpdateAuras(frame, unit);
    end
  end
end

function MrTarget:PlayerTargetUnit(unit)
  local frame = self:UnitFrame(unit);
  if frame then
    if PLAYER_TARGET then
      self:UpdateTargeted(PLAYER_TARGET, frame.unit.target);
      PLAYER_TARGET.specIcon:SetAlpha(PLAYER_TARGET.name:GetAlpha());
    end
    PLAYER_TARGET = frame;
    self.targetIcon:ClearAllPoints();
    self.targetIcon:SetPoint('TOPRIGHT', frame, 'TOPLEFT', -4, -2);
    self.targetIcon:Show();
    frame.specIcon:SetAlpha(0.5);
    if UnitIsGroupLeader('player') then
      self:LeaderTargetUnit(unit);
    end
  else
    self.targetIcon:Hide();
    PLAYER_TARGET = nil;
  end
end

function MrTarget:LeaderTargetUnit(unit)
  local frame = self:UnitFrame(unit);
  if frame then
    if LEADER_TARGET then
      self:UpdateTargeted(LEADER_TARGET, frame.unit.target);
      LEADER_TARGET.specIcon:SetAlpha(LEADER_TARGET.name:GetAlpha());
    end
    LEADER_TARGET = frame;
    self.assistIcon:ClearAllPoints();
    self.assistIcon:SetPoint('TOPRIGHT', frame, 'TOPLEFT', -6, -4);
    self.assistIcon:Show();
    frame.specIcon:SetAlpha(0.5);
  else
    self.assistIcon:Hide();
    LEADER_TARGET = nil;
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
  for i=1, OPTIONS[BATTLEFIELD].MAX_FRAMES do
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
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitAura(unit, i);
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

function MrTarget:UpdateAuras(frame, unit)
  local count = 1;
  self:HideAuras(frame);
  if self.instanceType == 'pvp' then
    count = self:UpdateBattlegroundAuras(frame, count, unit);
    count = self:UpdateCastDebuffs(frame, count, unit);
  elseif self.instanceType == 'arena' then
    count = self:UpdateCastDebuffs(frame, count, unit);
    count = self:UpdateArenaDebuffs(frame, count, unit);
  end
end

function MrTarget:UpdateTargeted(frame, unit)
  local count = 0;
  if OPTIONS[BATTLEFIELD].TARGETED then
    for i=1, OPTIONS[BATTLEFIELD].MAX_FRAMES do
      if UnitIsUnit(unit, 'raid'..i..'target') then
        count=count+1;
      end
    end
  end
  if count == 0 then
    count = '';
  end
  frame.targeted:SetText(count);
end

function MrTarget:PlayerDied()
  for i=1, OPTIONS[BATTLEFIELD].MAX_FRAMES do
    if FRAMES[i].unit then
      self:UpdateTargeted(FRAMES[i], FRAMES[i].unit.target);
      self:UpdateAuras(FRAMES[i], FRAMES[i].unit.target);
    end
  end
  self:ResetAlpha(BATTLEFIELD);
  self.targetIcon:Hide();
  self.assistIcon:Hide();
end

function MrTarget:UpdateZone()
  self.inInstance, self.instanceType = IsInInstance();
  if self.instanceType == 'arena' and OPTIONS.ARENA.ENABLED and not HIDDEN then
    self:Initialize('ARENA');
  elseif self.instanceType == 'pvp' and OPTIONS.BATTLEGROUND.ENABLED and not HIDDEN then
    self:Initialize('BATTLEGROUND');
  elseif self.instanceType ~= 'pvp' and self.instanceType ~= 'arena' then
    HIDDEN = false;
    if InterfaceOptionsFrame:IsShown() then
      self:OpenOptions(BATTLEFIELD);
    else
      self:Destroy();
    end
  else
    self:Destroy();
  end
end

function MrTarget:SetBattlefield()
  if self.battlefield == nil then
    for i=1, GetMaxBattlefieldID() do
      local status, name, size = GetBattlefieldStatus(i);
      if status == 'active' then
        local auras = BG_AURAS;
        if self.instanceType == 'pvp' then
          size = select(5, GetBattlefieldTeamInfo(i));
        elseif self.instanceType == 'arena' then
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
  local numScores, numEnemies = GetNumArenaOpponentSpecs(), 0;
  if numScores > 0 then
    local units = {};
    for i=1,numScores do
      local class, role, spec = self:GetArenaSpecialization(i);
      if spec then
        local target = 'arena'..i;
        local name = GetUnitName(target) or 'Unknown';
        table.insert(units, {
          name=name, display=name, target=target, class=class, spec=spec,
          role=role, icon=ROLES[class][spec].icon
        });
        numEnemies = numEnemies+1;
      end
    end
    if numEnemies > 0 then
      self:ResetNames();
      table.sort(units, SortAlphabetically);
      table.sort(units, SortByRole);
      UNITS = units;
      self:UpdateFrames();
      if not InCombatLockdown() then
        self:Show();
      end
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
      local name, _, _, _, _, faction, race, _, class, _, _, _, _, _, _, spec = GetBattlefieldScore(i);
      if faction ~= playerFaction then
        table.insert(units, {
          name=name, display=name, target=name, class=class, spec=spec,
          role=ROLES[class][spec].role, icon=ROLES[class][spec].icon
        });
        numEnemies = numEnemies+1;
      end
    end
    if numEnemies > 0 then
      self:ResetNames();
      table.sort(units, SortAlphabetically);
      for i=1, numEnemies do
        if units[i].name then
          local name, server = self:SplitName(units[i].name);
          units[i].display = self:SetReadableName(name)..server;
        end
      end
      table.sort(units, SortByRole);
      UNITS = units;
      self:UpdateFrames();
      if not InCombatLockdown() then
        self:Show();
      end
    end
  end
end

function MrTarget:GetFrame(unit)
  if ENEMIES[unit] then
    if FRAMES[ENEMIES[unit]] then
      return FRAMES[ENEMIES[unit]], ENEMIES[unit];
    end
  end
end

function MrTarget:UnitFrame(unit)
  if not ENEMIES[unit] then
    if self.instanceType == 'arena' then
      for i=1, #FRAMES do
        if FRAMES[i].unit then
          if UnitIsUnit(unit, FRAMES[i].unit.target) then
            unit = FRAMES[i].unit.target;
            break;
          end
        end
      end
    else
      unit = GetUnitName(unit, true);
    end
  end
  return self:GetFrame(unit);
end

function MrTarget:UpdateFrames()
  local visible = 0;
  wipe(ENEMIES);
  for i=1, OPTIONS[BATTLEFIELD].MAX_FRAMES do
    if UNITS[i] then
      FRAMES[i].unit = UNITS[i];
      FRAMES[i].spec:SetText(UNITS[i].spec);
      FRAMES[i].specIcon:SetTexture(UNITS[i].icon);
      FRAMES[i].roleIcon.icon:SetTexCoord(GetTexCoordsForRole(UNITS[i].role, OPTIONS[BATTLEFIELD].BORDERLESS));
      FRAMES[i].targeted:SetText('');
      self:UpdateName(FRAMES[i], UNITS[i].name);
      self:UpdateHealthColor(FRAMES[i], UNITS[i].class);
      self:UpdatePowerColor(FRAMES[i], UNITS[i].name);
      if self.battlefield then
        self:UpdateRange(FRAMES[i], UNITS[i].target);
        self:UpdateAuras(FRAMES[i], UNITS[i].target);
      end
      if not InCombatLockdown() then
        FRAMES[i]:SetAttribute('macrotext1', '/targetexact '..UNITS[i].target);
        FRAMES[i]:SetAttribute('macrotext2', '/targetexact '..UNITS[i].target..'\n/focus\n/targetlasttarget');
        FRAMES[i]:Show();
      end
      ENEMIES[UNITS[i].target] = i;
      visible = visible+1;
    else
      FRAMES[i].unit = nil;
      if not InCombatLockdown() then
        FRAMES[i]:Hide();
      end
    end
  end
  if not InCombatLockdown() then
    self:SetSize(100, (visible*FRAMES[1]:GetHeight())+14.5);
  end
end

function MrTarget:CreateFrames()
  for i=1, OPTIONS[BATTLEFIELD].MAX_FRAMES do
    if FRAMES[i] == nil then
      FRAMES[i] = CreateFrame('Button', 'MrTargetUnitFrame'..i, self, 'MrTargetUnitFrameTemplate');
      FRAMES[i]:EnableMouse(true);
      FRAMES[i]:RegisterForDrag('RightButton');
      FRAMES[i]:RegisterForClicks('LeftButtonUp', 'RightButtonUp');
      FRAMES[i]:SetAttribute('type1', 'macro');
      FRAMES[i]:SetAttribute('type2', 'macro');
      FRAMES[i]:SetAttribute('macrotext1', '');
      FRAMES[i]:SetAttribute('macrotext2', '');
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

function MrTarget:UpdatePlayer()
  PLAYER_NAME = UnitName('player');
  PLAYER_CLASS = select(2, UnitClass('player'));
  PLAYER_SPEC = GetSpecialization();
  PLAYER_RANGE = select(6, GetSpellInfo(RANGE_SPELLS[PLAYER_CLASS])) or 0;
  local specId = GetSpecializationInfo(PLAYER_SPEC);
  if SPEC_CORE_ABILITY_DISPLAY[specId] then
    for i, id in pairs(SPEC_CORE_ABILITY_DISPLAY[specId]) do
      local name, _, _, _, _, range = GetSpellInfo(id);
      if IsHarmfulSpell(name) then
        if range >= PLAYER_RANGE then
          RANGE_SPELLS[PLAYER_CLASS] = id;
          PLAYER_RANGE = range;
        end
      end
    end
  end
end

function MrTarget:GetRoles()
  for classID=1, MAX_CLASSES do
    local className, classTag, classID = GetClassInfoByID(classID);
    local numTabs = GetNumSpecializationsForClassID(classID);
    ROLES[classTag] = {};
    for i=1, numTabs do
      local id, name, description, icon, background, role = GetSpecializationInfoForClassID(classID, i);
      ROLES[classTag][name] = { class=className, role=role, id=id, description=description, icon=icon, spec=name };
    end
  end
end

function MrTarget:ObjectivesFrame()
  if ObjectiveTrackerFrame then
    if not InCombatLockdown() then
      if self.instanceType == 'pvp' then
        ObjectiveTrackerFrame:Hide();
      elseif self.instanceType == 'arena' then
        ObjectiveTrackerFrame:Hide();
      else
        ObjectiveTrackerFrame:Show();
      end
    end
  end
end

function MrTarget:Reset()
  LAST_REQUEST = 0;
  self:ResetNames();
  for i=1, #FRAMES do
    if FRAMES[i].unit then
      FRAMES[i].unit = nil;
    end
  end
  wipe(UNITS);
  wipe(ENEMIES);
  wipe(RANGE);
end

function MrTarget:Initialize(battlefield)
  BATTLEFIELD = battlefield;
  self:LoadOptions(BATTLEFIELD, OPTIONS[BATTLEFIELD]);
  self:Reset();
  self:RegisterEvent('UNIT_TARGET');
  self:RegisterEvent('UNIT_HEALTH_FREQUENT');
  self:RegisterEvent('UNIT_FLAGS');
  self:RegisterEvent('UNIT_COMBAT');
  self:RegisterEvent('PLAYER_DEAD');
  self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED');
  self:RegisterEvent('PARTY_LEADER_CHANGED');
  self:RegisterEvent('UPDATE_WORLD_STATES');
  self:RegisterEvent('UPDATE_BATTLEFIELD_SCORE');
  if battlefield == 'ARENA' then
    self:RegisterEvent('ARENA_OPPONENT_UPDATE');
    self:RegisterEvent('ARENA_PREP_OPPONENT_SPECIALIZATIONS');
    self:RegisterEvent('UNIT_AURA');
  end
  self:DisableOptions('BATTLEGROUND');
  self:DisableOptions('ARENA');
  self:ObjectivesFrame();
  self:SetScript('OnUpdate', self.OnUpdate);
  self:OnUpdate(GetTime());
end

function MrTarget:Destroy()
  if not InCombatLockdown() then
    self:Hide();
  else
    self:RegisterEvent('PLAYER_REGEN_ENABLED');
  end
  self:Reset();
  self.battlefield = nil;
  self:ObjectivesFrame();
  self:UnregisterEvent('UNIT_TARGET');
  self:UnregisterEvent('UNIT_HEALTH_FREQUENT');
  self:UnregisterEvent('UNIT_FLAGS');
  self:UnregisterEvent('UNIT_COMBAT');
  self:UnregisterEvent('PLAYER_DEAD');
  self:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED');
  self:UnregisterEvent('PARTY_LEADER_CHANGED');
  self:UnregisterEvent('UPDATE_WORLD_STATES');
  self:UnregisterEvent('UPDATE_BATTLEFIELD_SCORE');
  if battlefield == 'ARENA' then
    self:UnregisterEvent('ARENA_OPPONENT_UPDATE');
    self:UnregisterEvent('ARENA_PREP_OPPONENT_SPECIALIZATIONS');
    self:UnregisterEvent('UNIT_AURA');
  end
  self:SetScript('OnUpdate', nil);
  self:EnableOptions('BATTLEGROUND');
  self:EnableOptions('ARENA');
end

function MrTarget:OnUpdate(time)
  LAST_REQUEST = LAST_REQUEST + time;
  if LAST_REQUEST < REQUEST_TICK or (WorldStateScoreFrame and WorldStateScoreFrame:IsShown()) then
    return;
  end
  RequestBattlefieldScoreData();
  if self.instanceType == 'arena' then
    self:UpdateArenaScore();
  end
  LAST_REQUEST = 0;
end

function MrTarget:UpdateNaming()
  self:ResetNames();
  for i=1, OPTIONS[BATTLEFIELD].MAX_FRAMES do
    if FRAMES[i].unit then
      local name, server = self:SplitName(FRAMES[i].unit.name);
      FRAMES[i].unit.display = self:SetReadableName(name)..server;
      FRAMES[i].name:SetText(FRAMES[i].unit.display);
    end
  end
end

function MrTarget:UpdateUI(borderless)
  if borderless then
    self.Options[BATTLEFIELD].Icons:Show();
    self:SetBorderless();
  else
    self.Options[BATTLEFIELD].Icons:Hide();
    self:SetStandard();
  end
end

function MrTarget:SetPower(enabled)
  if not self.battlefield then
    self:UpdateUI(OPTIONS[BATTLEFIELD].BORDERLESS);
  end
end

function MrTarget:SetTargeted(enabled)
  if enabled then
    if not self.battlefield then
      FRAMES[1].targeted:SetText(OPTIONS[BATTLEFIELD].MAX_FRAMES);
    end
  else
    for i=1, OPTIONS[BATTLEFIELD].MAX_FRAMES do
      FRAMES[i].targeted:SetText('');
    end
  end
end

function MrTarget:FakeDebuff(frame)
  for a=1, MAX_AURAS do
    if not frame['auraIcon'..a]:IsShown() then
      self:SetAura(frame, a, 5025, '', 'Interface\\Icons\\INV_Misc_QuestionMark', 1, GetTime()+(math.random(10, 50)/10));
      break;
    end
  end
end

function MrTarget:SetDebuffs(enabled)
  if not self.battlefield then
    if enabled then
      self:FakeDebuff(FRAMES[1]);
    else
      for a=1, MAX_AURAS do
        if FRAMES[1]['auraIcon'..a].id == 5025 then
          FRAMES[1]['auraIcon4'].id = nil;
          FRAMES[1]['auraIcon4'].icon:SetTexture(nil);
          FRAMES[1]['auraIcon4']:Hide();
        end
      end
    end
  end
end

function MrTarget:SetBorderless()
  for i=1, OPTIONS[BATTLEFIELD].MAX_FRAMES do
    FRAMES[i]:DisableDrawLayer('BORDER');
    FRAMES[i].roleIcon.icon:SetTexture('Interface\\LFGFrame\\LFGRole');
    FRAMES[i].roleIcon.icon:SetPoint('TOPLEFT', FRAMES[i], 'TOPLEFT', 2.5, -3);
    if FRAMES[i].unit then
      FRAMES[i].roleIcon.icon:SetTexCoord(GetTexCoordsForRole(FRAMES[i].unit.role, true));
    end
    FRAMES[i].name:SetFontObject("GameFontHighlightBorderless");
    FRAMES[i].targeted:SetFontObject("TextStatusBarTextRedBorderless");
    FRAMES[i].healthBar:ClearAllPoints();
    FRAMES[i].powerBar:ClearAllPoints();
    FRAMES[i].healthBar:SetPoint('TOPLEFT', FRAMES[i], 'TOPLEFT', 0, 0);
    if OPTIONS[BATTLEFIELD].POWER then
      FRAMES[i].healthBar:SetPoint('BOTTOMRIGHT', FRAMES[i], 'BOTTOMRIGHT', 0, 15);
      FRAMES[i].powerBar:SetPoint('TOPLEFT', FRAMES[i].healthBar, 'BOTTOMLEFT', 0, -1);
      FRAMES[i].powerBar:SetPoint('BOTTOMRIGHT', FRAMES[i], 'BOTTOMRIGHT', 0, 1);
      FRAMES[i].powerBar:Show();
      FRAMES[i].horizDivider:Show();
    else
      FRAMES[i].healthBar:SetPoint('BOTTOMRIGHT', FRAMES[i], 'BOTTOMRIGHT', 0, 1);
      FRAMES[i].horizDivider:Hide();
      FRAMES[i].powerBar:Hide();
    end
    FRAMES[i].spec:Hide();
    if OPTIONS[BATTLEFIELD].ICONS then
      FRAMES[i].specIcon:Show();
    else
      FRAMES[i].specIcon:Hide();
    end
    for a=1, MAX_AURAS do
      FRAMES[i]['auraIcon'..a].time:SetFontObject('TextStatusBarTextLargeBorderless');
      FRAMES[i]['auraIcon'..a].icon:SetTexCoord(0.1, 0.9, 0.1, 0.9);
      FRAMES[i]['auraIcon'..a].icon:SetSize(35, 35);
    end
  end
  self.borderFrame:Hide();
end

function MrTarget:SetStandard()
  for i=1, OPTIONS[BATTLEFIELD].MAX_FRAMES do
    FRAMES[i]:EnableDrawLayer('BORDER');
    FRAMES[i].roleIcon.icon:SetTexture('Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES');
    FRAMES[i].roleIcon.icon:SetPoint('TOPLEFT', FRAMES[i], 'TOPLEFT', 2.5, -2.5);
    if FRAMES[i].unit then
      FRAMES[i].roleIcon.icon:SetTexCoord(GetTexCoordsForRole(FRAMES[i].unit.role, false));
    end
    FRAMES[i].name:SetFontObject("GameFontHighlight");
    FRAMES[i].targeted:SetFontObject("TextStatusBarTextRed");
    FRAMES[i].healthBar:ClearAllPoints();
    FRAMES[i].powerBar:ClearAllPoints();
    FRAMES[i].healthBar:SetPoint('TOPLEFT', FRAMES[i], 'TOPLEFT', 1, -1);
    if OPTIONS[BATTLEFIELD].POWER then
      FRAMES[i].healthBar:SetPoint('BOTTOMRIGHT', FRAMES[i], 'BOTTOMRIGHT', -1, 9);
      FRAMES[i].powerBar:SetPoint('TOPLEFT', FRAMES[i].healthBar, 'BOTTOMLEFT', 0, -2);
      FRAMES[i].powerBar:SetPoint('BOTTOMRIGHT', FRAMES[i], 'BOTTOMRIGHT', -1, 0);
      FRAMES[i].powerBar:Show();
      FRAMES[i].horizDivider:Show();
    else
      FRAMES[i].healthBar:SetPoint('BOTTOMRIGHT', FRAMES[i], 'BOTTOMRIGHT', -1, 0);
      FRAMES[i].horizDivider:Hide();
      FRAMES[i].powerBar:Hide();
    end
    FRAMES[i].spec:Show();
    FRAMES[i].specIcon:Hide();
    for a=1, MAX_AURAS do
      FRAMES[i]['auraIcon'..a].time:SetFontObject('TextStatusBarTextLarge');
      FRAMES[i]['auraIcon'..a].icon:SetTexCoord(0, 1, 0, 1);
      FRAMES[i]['auraIcon'..a].icon:SetSize(36, 36);
    end
  end
  self.borderFrame:Show();
end

function MrTarget:ResetAlpha(on)
  local alpha = (on and 0.5) or 1.0;
  for i=1, OPTIONS[BATTLEFIELD].MAX_FRAMES do
    self:SetTransparency(FRAMES[i], alpha);
  end
end

local RUSSIANS = {
  'Афила', 'Сэйбот', 'Яджун', 'Найнс', 'Айвен', 'Аллорион', 'Марги', 'Атжай',
  'Сигр', 'Вайлен', 'Меру', 'Игми', 'Вандерер', 'Биотикус', 'Эксдаркикс'
};

local function RandomKey(t)
  local keys, i = {}, 1;
  for k in pairs(t) do
    keys[i] = k;
    i = i+1;
  end
  return keys[math.random(1, #keys)];
end

function MrTarget:OpenOptions(key)
  if not self.battlefield then
    self:Reset();
    self:LoadOptions(key, OPTIONS[key]);
    if not InCombatLockdown() then
      local class, spec = nil, nil;
      for i=1, OPTIONS[BATTLEFIELD].MAX_FRAMES do
        class = RandomKey(ROLES);
        spec = RandomKey(ROLES[class]);
        table.insert(UNITS, {
          name=RUSSIANS[i], display=self:SetReadableName(RUSSIANS[i]),
          role=GetSpecializationRoleByID(ROLES[class][spec].id),
          target='raid'..i, class=class, spec=spec, icon=ROLES[class][spec].icon
        });
      end
      table.sort(UNITS, SortByRole);
      self:UpdateFrames();
      self:HideAuras(FRAMES[1]);
      self:ResetAlpha(OPTIONS[BATTLEFIELD].RANGE);
      if BATTLEFIELD == 'BATTLEGROUND' then
        self:SetAura(FRAMES[1], 1, 23333, '', BG_AURAS[23333].icon, 1, 0);
        self:SetAura(FRAMES[1], 2, 46392, '', BG_AURAS[46392].icon, 1, GetTime()+(math.random(10, 50)/10));
        self:SetAura(FRAMES[1], 3, 46393, '', BG_AURAS[46393].icon, 1, GetTime()+(math.random(10, 50)/10));
      elseif BATTLEFIELD == 'ARENA' then
        self:FakeDebuff(FRAMES[1]);
        self:FakeDebuff(FRAMES[1]);
        self:FakeDebuff(FRAMES[1]);
      end
      self:PlayerTargetUnit('raid1');
      self:LeaderTargetUnit('raid1');
      self:SetPower(OPTIONS[BATTLEFIELD].POWER);
      self:SetTargeted(OPTIONS[BATTLEFIELD].TARGETED);
      self:SetDebuffs(OPTIONS[BATTLEFIELD].DEBUFFS);
      self:Show();
    end
  end
end

function MrTarget:CloseOptions()
  if not self.battlefield then
    if self:IsVisible() then
      self:Reset();
      if not InCombatLockdown() then
        self:Hide();
      else
        self:RegisterEvent('PLAYER_REGEN_ENABLED');
      end
    end
  end
end

function MrTarget:GetPosition()
  for i=1, self:GetNumPoints() do
    local point, relativeTo, relativePoint, x, y = self:GetPoint(i);
    return { point, relativeTo, relativePoint, x, y };
  end
end

function MrTarget:SavePosition()
  if InterfaceOptionsFrame:IsShown() then
    OPTIONS[BATTLEFIELD].POSITION = self:GetPosition();
    self:StopMovingOrSizing();
  end
end

function MrTarget:ChangePosition()
  if InterfaceOptionsFrame:IsShown() then
    self:ClearAllPoints();
    self:StartMoving();
  end
end

function MrTarget:Resize(size)
  self:SetScale(size/100);
end

function MrTarget:InitOptions()
  self.Options = CreateFrame('Frame', 'MrTargetOptions', UIParent);
  self.Options.name = GetAddOnMetadata('MrTarget', 'Title');
  InterfaceOptions_AddCategory(self.Options);
  self:AddOptionsFrame('BATTLEGROUND', 'Battlegrounds');
  self:AddOptionsFrame('ARENA', 'Arena and Skirmish');
  self:LoadOptions('BATTLEGROUND', OPTIONS.BATTLEGROUND);
  self:LoadOptions('ARENA', OPTIONS.ARENA);
end

function MrTarget:AddOptionsFrame(key, title)
  self.Options[key] = CreateFrame('Frame', 'MrTargetOptions'..key, self.Options, 'MrTargetOptionsTemplate');
  self.Options[key].name = title;
  self.Options[key].parent = self.Options.name;
  self.Options[key].Title:SetText(string.upper(title));
  self.Options[key].Subtitle:SetText('MrTarget '..VERSION);
  self.Options[key].Enabled.text:SetText('Enable in '..title);
  self.Options[key].okay = function() MrTarget:SaveAllOptions(); end;
  self.Options[key].default = function() MrTarget:DefaultOptions(key); end;
  self.Options[key].cancel = function() MrTarget:CancelOptions(key); end;
  self.Options[key]:SetScript('OnHide', function(self) MrTarget:CloseOptions(); end);
  self.Options[key]:SetScript('OnShow', function(self) MrTarget:OpenOptions(key); end);
  self.Options[key]:Hide();
  InterfaceOptions_AddCategory(self.Options[key]);
end

function MrTarget:InitNamingOptions(key, default)
  UIDropDownMenu_Initialize(self.Options[key].Naming, function()
    for i, option in pairs({ 'Transmute', 'Transliterate', 'Ignore' }) do
      UIDropDownMenu_AddButton({ owner=self.Options[key].Naming, text=option, value=option, checked=nil, arg1=option, func=(function(_, value)
        UIDropDownMenu_ClearAll(self.Options[key].Naming);
        UIDropDownMenu_SetSelectedValue(self.Options[key].Naming, value);
        OPTIONS[BATTLEFIELD].NAMING = value;
        self:UpdateNaming();
      end)});
    end
  end);
  UIDropDownMenu_SetAnchor(self.Options[key].Naming, 16, 22, 'TOPLEFT', self.Options[key].Naming:GetName()..'Left', 'BOTTOMLEFT');
  UIDropDownMenu_JustifyText(self.Options[key].Naming, 'LEFT');
  UIDropDownMenu_SetSelectedValue(self.Options[key].Naming, default);
end

function MrTarget:LoadOptions(key, options)
  BATTLEFIELD=key;
  self.Options[key].Enabled:SetChecked(options.ENABLED);
  self.Options[key].Power:SetChecked(options.POWER);
  self.Options[key].Range:SetChecked(options.RANGE);
  self.Options[key].Targeted:SetChecked(options.TARGETED);
  self.Options[key].Debuffs:SetChecked(options.DEBUFFS);
  self.Options[key].Borderless:SetChecked(options.BORDERLESS);
  self.Options[key].Icons:SetChecked(options.ICONS);
  self.Options[key].Size:SetValue(options.SIZE);
  self:InitNamingOptions(key, options.NAMING);
  if not InCombatLockdown() then
    self:UpdateUI(options.BORDERLESS);
    self:Resize(options.SIZE);
    self:ClearAllPoints();
    local ok, point, relativeTo, relativePoint, x, y = pcall(unpack, options.POSITION);
    if not ok then
      point, relativeTo, relativePoint, x, y = unpack(DEFAULT_OPTIONS.BATTLEGROUND.POSITION);
    end
    self:SetPoint(point, relativeTo, relativePoint, x, y);
  end
end

function MrTarget:SaveOptions(key)
  OPTIONS[key].ENABLED = self.Options[key].Enabled:GetChecked();
  OPTIONS[key].POWER = self.Options[key].Power:GetChecked();
  OPTIONS[key].RANGE = self.Options[key].Range:GetChecked();
  OPTIONS[key].TARGETED = self.Options[key].Targeted:GetChecked();
  OPTIONS[key].DEBUFFS = self.Options[key].Debuffs:GetChecked();
  OPTIONS[key].BORDERLESS = self.Options[key].Borderless:GetChecked();
  OPTIONS[key].ICONS = self.Options[key].Icons:GetChecked();
  OPTIONS[key].SIZE = self.Options[key].Size:GetValue();
end

function MrTarget:SaveAllOptions()
  self:SaveOptions('BATTLEGROUND');
  self:SaveOptions('ARENA');
end

function MrTarget:CancelOptions(key) MrTarget:LoadOptions(key, OPTIONS[key]); end
function MrTarget:DefaultOptions(key) self:LoadOptions(key, DEFAULT_OPTIONS[key]); end
function MrTarget:QuickSave() self:SaveOptions(BATTLEFIELD); end

function MrTarget:DisableOptions(key)
  UIDropDownMenu_DisableDropDown(self.Options[key].Naming);
  self.Options[key].Power:Disable();
  self.Options[key].Debuffs:Disable();
  self.Options[key].Borderless:Disable();
  self.Options[key].Icons:Disable();
end

function MrTarget:EnableOptions(key)
  UIDropDownMenu_EnableDropDown(self.Options[key].Naming);
  self.Options[key].Power:Enable();
  self.Options[key].Debuffs:Enable();
  self.Options[key].Borderless:Enable();
  self.Options[key].Icons:Enable();
end

function MrTarget:ProcessMessage(prefix, message, type, sender)
  if prefix == CHAT_PREFIX then
  end
end

function MrTarget:PlayerLogout()
  if not InCombatLockdown() then
    self:Destroy();
  end
end

function MrTarget:OnShow()
  if not InCombatLockdown() then
    for i=1, MAX_FRAMES do
      if FRAMES[i].unit then
        FRAMES[i]:Show();
      end
    end
  else
    self:RegisterEvent('PLAYER_REGEN_ENABLED');
  end
end

function MrTarget:OnHide()
  if not InCombatLockdown() then
    for i=1, MAX_FRAMES do
      if FRAMES[i] then
        FRAMES[i]:Hide();
      end
    end
    self.targetIcon:Hide();
    self.assistIcon:Hide();
  else
    self:RegisterEvent('PLAYER_REGEN_ENABLED');
  end
end

function MrTarget:OnOptions()
  OPTIONS = OPTIONS or {};
  if not OPTIONS.BATTLEGROUND or not OPTIONS.ARENA then
    OPTIONS = DEFAULT_OPTIONS;
  else
    for i,v in pairs(DEFAULT_OPTIONS.BATTLEGROUND) do
      if OPTIONS.BATTLEGROUND[i] == nil then
        OPTIONS.BATTLEGROUND[i] = v;
      end
    end
    for i,v in pairs(DEFAULT_OPTIONS.ARENA) do
      if OPTIONS.ARENA[i] == nil then
        OPTIONS.ARENA[i] = v;
      end
    end
  end
end

function MrTarget:OnEvent(event, ...)
  if event == 'ADDON_LOADED' and select(1, ...) == 'MrTarget' then
    self:OnOptions();
    self:OnLoad();
  elseif event == 'PLAYER_LOGIN' then
    self:UpdatePlayer();
  elseif event == 'CHAT_MSG_ADDON' then
    self:ProcessMessage(...);
  elseif event == 'ZONE_CHANGED' then self:UpdateZone();
  elseif event == 'ZONE_CHANGED_NEW_AREA' then self:UpdateZone();
  elseif event == 'ZONE_CHANGED_INDOORS' then self:UpdateZone();
  elseif event == 'ARENA_PREP_OPPONENT_SPECIALIZATIONS' then self:UpdateArenaScore();
  elseif event == 'UPDATE_BATTLEFIELD_SCORE' then
    if self.instanceType == 'pvp' then
      self:UpdateBattlegroundScore();
    elseif self.instanceType == 'arena' then
      self:UpdateArenaScore();
    end
  elseif event == 'PLAYER_REGEN_ENABLED' then
    self:UnregisterEvent('PLAYER_REGEN_ENABLED');
    if self.instanceType ~= 'pvp' and self.instanceType ~= 'arena' then
      self:Destroy();
    else
      self:Show();
    end
  elseif event == 'PLAYER_LOGOUT' then
    self:PlayerLogout();
  elseif self.battlefield then
    if event == 'UPDATE_WORLD_STATES' then self:UpdateState();
    elseif event == 'PARTY_LEADER_CHANGED' then self:UpdateState();
    elseif event == 'GROUP_ROSTER_UPDATE' then self:UpdateState();
    elseif event == 'PARTY_MEMBERS_CHANGED' then self:UpdateState();
    elseif event == 'ARENA_OPPONENT_UPDATE' then self:UpdateState();
    elseif event == 'UNIT_HEALTH_FREQUENT' then self:UpdateUnit(...);
    elseif event == 'UNIT_COMBAT' then self:UpdateUnit(...);
    elseif event == 'UNIT_AURA' then self:UpdateUnit(...);
    elseif event == 'UNIT_FLAGS' then self:UpdateUnit(...);
    elseif event == 'PLAYER_DEAD' then self:PlayerDied();
    elseif event == 'UNIT_TARGET' then
      self:UpdateTarget(...);
      self:UpdateUnit(...);
    elseif event == 'COMBAT_LOG_EVENT_UNFILTERED' then
      if OPTIONS[BATTLEFIELD].RANGE then
        self:CombatEvent(...);
      end
    end
  end
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
        button.name.text:SetText(MrTarget:GetReadableName(name)..server);
      end
    end
  end
end);

MrTarget:SetScript('OnLoad', MrTarget.OnLoad);
MrTarget:SetScript('OnEvent', MrTarget.OnEvent);
MrTarget:SetScript('OnHide', MrTarget.OnHide);
MrTarget:SetScript('OnShow', MrTarget.OnShow);

MrTarget:RegisterEvent('ADDON_LOADED');

SLASH_MRTARGET1 = '/mrt';
SLASH_MRTARGET2 = '/mrtarget';
function SlashCmdList.MRTARGET(cmd, box)
  if cmd == 'show' then
    HIDDEN = false;
    MrTarget:UpdateZone();
  elseif cmd == 'hide' then
    HIDDEN = true;
    MrTarget:Destroy();
  else
    InterfaceOptionsFrame_OpenToCategory(MrTarget.Options);
    InterfaceOptionsFrame_OpenToCategory(MrTarget.Options.BATTLEGROUND);
  end
end
