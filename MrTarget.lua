-- MrTarget v5.2.4
-- =====================================================================
-- This Work is provided under the Creative Commons
-- Attribution-NonCommercial-NoDerivatives 4.0 International Public License
--
-- Please send any bugs or feedback to mrtarget@lockofwar.com.
-- MapID: /run print((select(8, GetInstanceInfo())));
-- Debug: /run print((select(4, GetBuildInfo())));

local BATTLEFIELD_SIZES = { 10, 15, 40 };
local SCALE = UIParent:GetEffectiveScale();

local DEFAULT_BATTLEFIELD_OPTIONS = {
  ENABLED=true,
  ENEMY=true,
  FRIENDLY=true,
  POSITION={
    HARMFUL={ 'TOPRIGHT', nil, 'TOPRIGHT', -(GetScreenWidth()*SCALE)/15, -(GetScreenHeight()*SCALE)/3 },
    HELPFUL={ 'TOPLEFT', nil, 'TOPLEFT', (GetScreenWidth()*SCALE)/15, -(GetScreenHeight()*SCALE)/3 },
  },
  BORDERLESS=false,
  ICONS=false,
  SIZE=100,
  NAMING='Transmute',
  POWER=true,
  RANGE=true,
  TARGETED=true,
  AURAS=true,
  COLUMNS=1
};

local function count_all(f)
  local seen = {}
  local count_table
  count_table = function(t)
    if seen[t] then return end
    f(t)
    seen[t] = true
    for k,v in pairs(t) do
      if type(v) == "table" then
        count_table(v)
      elseif type(v) == "userdata" then
        f(v)
      end
    end
  end
  count_table(_G)
end

local function type_count()
  local counts = {}
  local enumerate = function (o)
    local t = type_name(o)
    counts[t] = (counts[t] or 0) + 1
  end
  count_all(enumerate)
  return counts
end

function mrtarget_copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[mrtarget_copy(k, s)] = mrtarget_copy(v, s) end
  return res
end

function mrtarget_count(obj)
  local length = 0;
  for k, v in pairs(obj) do
     length = length + 1;
  end
  return length;
end

local DEFAULT_OPTIONS = {}
for k,v in pairs(BATTLEFIELD_SIZES) do
  DEFAULT_OPTIONS[v] = mrtarget_copy(DEFAULT_BATTLEFIELD_OPTIONS);
end

DEFAULT_OPTIONS[15].COLUMNS = 2;
DEFAULT_OPTIONS[40].COLUMNS = 4;
DEFAULT_OPTIONS[40].FRIENDLY = false;

local FRIENDS = {
  'Jaina', 'Uther', 'Anduin', 'Valeera', 'Thrall', 'Gul\'dan', 'Garrosh', 'Arthas',
  'Malfurian', 'Rexxar', 'Magni', 'Alleria', 'Medivh', 'Chen', 'Antonidas', 'Sylvanas',
  'Muradin', 'Falstad', 'Alleria', 'Illidan', 'Tyrande', 'Gazlowe', 'Cairne', 'Draka',
  'Aegwynn', 'Arthas', 'Bolvar', 'Khadgar', 'Rhonin', 'Tirion', 'Varian', 'Brann',
  'Llane', 'Grommash', 'Orgrim', 'Durotan', 'Millhouse', 'Garona', 'Vol\'jin', 'Maleki'
};

local ENEMIES = {
  'Афила', 'Сэйбот', 'Яджун', 'Найнс', 'Супералёнка', 'Аллорион', 'Марги', 'Алёнаболт',
  'Скорозасияем', 'Вайлен', 'Лукертс', 'Игми', 'Вандерер', 'Биотикус', 'Эксдаркикс', 'Мельда',
  'Альвеона', 'Сигр', 'Альвеоняша', 'Айвен', 'Эрриган', 'Иллиняша', 'Алеандра', 'Атжай',
  'Койрэ', 'Даблмид', 'Впередплотва', 'Десперрок', 'Лаафект', 'Гуолан', 'Дэйлинс', 'Кайперс',
  'Демьяна', 'Дамнейшен', 'Золмар', 'Атейн', 'Келаний', 'Дамнейшн', 'Погода', 'Шадоудва'
};

local BATTLEFIELDS = {
    [30] = { name='Alterac Valley', size=40 },
   [489] = { name='Warsong Gulch', size=10 },
   [529] = { name='Arathi Basin', size=15 },
   [566] = { name='Eye of the Storm', size=15 },
   [607] = { name='Strand of the Ancients', size=15 },
   [628] = { name='Isle of Conquest', size=40 },
   [726] = { name='Twin Peaks', size=10 },
   [727] = { name='Silvershard Mines', size=10 },
   [761] = { name='The Battle for Gilneas', size=10 },
   [968] = { name='Eye of the Storm (RBG)', size=10 },
   [998] = { name='Temple of Kotmogu', size=10 },
  [1105] = { name='Deepwind Gorge', size=15 },
  [1681] = { name='Arathi Blizzard', size=15 }
};

MrTarget = CreateFrame('Frame', 'MrTarget', UIParent);

function MrTarget:Load()
  self.loaded=true;
  self.active=false;
  self.version='v5.2.4';
  self.difficulty = false;
  self.frames={};
  self.size=40;
  self.objectives=false;
  self.options_open=false;
  self.locked = true;
  self.player={
    helpful=setmetatable({}, nil),
    harmful=setmetatable({}, nil)
  };
  self:HelloWorld();
  self:GetOptions();
  self:Initialize();
  self:InitOptions();
end

function MrTarget:Initialize()
  if not self.frames.HARMFUL then
    self.frames.HARMFUL = MrTargetGroup:New('HARMFUL', false);
  end
  if not self.frames.HELPFUL then
    self.frames.HELPFUL = MrTargetGroup:New('HELPFUL', true);
  end
end

function MrTarget:Activate()
  if self:GetOption('ENEMY') then
    self.frames.HARMFUL:Activate();
  end
  if self:GetOption('FRIENDLY') then
    self.frames.HELPFUL:Activate();
  end
end

function MrTarget:ZoneChanged()
  local mapId = select(8, GetInstanceInfo())
  if BATTLEFIELDS[mapId] then
    self.size = IsRatedBattleground() and 10 or BATTLEFIELDS[mapId].size;
    if self:GetOption('enabled') and not self.active then
      self.active = true;
      self:DisableOptions();
      self:ObjectivesFrame(true);
      self:UpdateOptions();
      return self:Activate();
    else
      return;
    end
  end
  if not self.options_open then
    self.active = false;
    self:EnableOptions();
    self:ObjectivesFrame(false);
    self:Destroy();
  end
end

function MrTarget:ObjectivesFrame(active)
  if ObjectiveTrackerFrame then
    if active and not ObjectiveTrackerFrame.collapsed then
      ObjectiveTracker_Collapse();
      self.objectives = true;
    elseif not active and self.objectives and ObjectiveTrackerFrame.collapsed then
      ObjectiveTracker_Expand();
      self.objectives = false;
    end
  end
end

local function SortByRange(u,v)
  if v and u then
    if u.range > v.range then
      return true;
    end
  elseif u then
    return true;
  end
end

function MrTarget:UpdateSpells()
  self.player.harmful = table.wipe(self.player.harmful);
  self.player.helpful = table.wipe(self.player.helpful);
  local numTabs = GetNumSpellTabs();
  for i=1,numTabs do
    local name,texture,offset,numSpells = GetSpellTabInfo(i);
    for j=1,numSpells do
      local id = j+offset;
      local name, rank = GetSpellBookItemName(id, 'spell');
      local range = select(6, GetSpellInfo(name));
      if range then
        if IsHarmfulSpell(id, 'spell') then
          table.insert(self.player.harmful, { name=name, range=range });
        elseif IsHelpfulSpell(id, 'spell') then
          table.insert(self.player.helpful, { name=name, range=range });
        end
      end
    end
  end
  table.sort(self.player.harmful, SortByRange);
  table.sort(self.player.helpful, SortByRange);
end

function MrTarget:PlayerLogin()
  if self.loaded then
    self.player.NAME = UnitName('player');
    self.player.CLASS = select(2, UnitClass('player'));
    self.player.FACTION = GetBattlefieldArenaFaction();
    self:UpdateSpells();
  end
end

function MrTarget:HelloWorld()
  local message = '|cFF00FFFF <MrTarget-'..self.version..'>|cFFFF0000 %s|r %s';
  message = string.format(message, MRTARGET_STRINGS_EVEN, MRTARGET_STRINGS_OPEN);
  ChatFrame1:AddMessage(message, 0, 0, 0, GetChatTypeIndex('SYSTEM'));
end

function MrTarget:GetSize()
  return self.size;
end

function MrTarget:GetOptions()
  self.OPTIONS = MRTARGET_SETTINGS;
  if not self.OPTIONS or not self.OPTIONS[40] then
    self.OPTIONS = mrtarget_copy(DEFAULT_OPTIONS);
  end
end

function MrTarget:InitOptions()
  self.options_frame = CreateFrame('Frame', 'MrTargetOptions', UIParent);
  self.options_frame.name = GetAddOnMetadata('MrTarget', 'Title');
  self.options_frame.tabs = {};
  InterfaceOptions_AddCategory(self.options_frame);
  for k,v in pairs(BATTLEFIELD_SIZES) do
    self.options_frame.tabs[v] = CreateFrame('Frame', 'MrTargetOptions'..v, self.options_frame, 'MrTargetOptionsTemplate');
    self.options_frame.tabs[v].name = string.format(MRTARGET_STRINGS_TAB_NAME, v);
    self.options_frame.tabs[v].parent = self.options_frame.name;
    self.options_frame.tabs[v].size = v;
    self.options_frame.tabs[v].Title:SetText(string.format(MRTARGET_STRINGS_TAB_TITLE, v));
    self.options_frame.tabs[v].Subtitle:SetText('MrTarget '..self.version);
    self.options_frame.tabs[v].okay = function() MrTarget:SaveOptions(); end;
    self.options_frame.tabs[v].default = function() MrTarget:DefaultOptions(); end;
    self.options_frame.tabs[v].cancel = function() MrTarget:CancelOptions(); end;
    self.options_frame.tabs[v]:SetScript('OnHide', function(self) MrTarget:CloseOptions(); end);
    self.options_frame.tabs[v]:SetScript('OnShow', function(self) MrTarget:OpenOptions(v); end);
    InterfaceOptions_AddCategory(self.options_frame.tabs[v]);
  end
  self:SetOptions(self.OPTIONS);
end

function MrTarget:InitNamingOptions(default)
  for k,v in pairs(BATTLEFIELD_SIZES) do
    securecall('UIDropDownMenu_Initialize', self.options_frame.tabs[v].Naming, function()
      for i, option in pairs({ 'Transmute', 'Transliterate', 'Ignore' }) do
        UIDropDownMenu_AddButton({ owner=self.options_frame.tabs[v].Naming, text=option, value=option, checked=nil, arg1=option, func=(function(_, value)
          UIDropDownMenu_ClearAll(self.options_frame.tabs[v].Naming);
          UIDropDownMenu_SetSelectedValue(self.options_frame.tabs[v].Naming, value);
          self:SetOption('naming', value);
        end)});
      end
    end);
    securecall('UIDropDownMenu_SetAnchor', self.options_frame.tabs[v].Naming, 16, 22, 'TOPLEFT', self.options_frame.tabs[v].Naming:GetName()..'Left', 'BOTTOMLEFT');
    securecall('UIDropDownMenu_JustifyText', self.options_frame.tabs[v].Naming, 'LEFT');
    securecall('UIDropDownMenu_SetSelectedValue', self.options_frame.tabs[v].Naming, default);
  end
end

function MrTarget:SetOptions(options)
  for k,v in pairs(BATTLEFIELD_SIZES) do
    self.options_frame.tabs[v].Enabled:SetChecked(options[v].ENABLED);
    self.options_frame.tabs[v].Enemy:SetChecked(options[v].ENEMY);
    self.options_frame.tabs[v].Friendly:SetChecked(options[v].FRIENDLY);
    self.options_frame.tabs[v].Power:SetChecked(options[v].POWER);
    self.options_frame.tabs[v].Range:SetChecked(options[v].RANGE);
    self.options_frame.tabs[v].Targeted:SetChecked(options[v].TARGETED);
    self.options_frame.tabs[v].Auras:SetChecked(options[v].AURAS);
    self.options_frame.tabs[v].Borderless:SetChecked(options[v].BORDERLESS);
    self.options_frame.tabs[v].Icons:SetChecked(options[v].ICONS);
    self.options_frame.tabs[v].Size:SetValue(options[v].SIZE);
    self.options_frame.tabs[v].Columns:SetValue(options[v].COLUMNS);
    self:InitNamingOptions(options[v].NAMING);
  end
  if self.size then
    self:SetOption('position', options[self.size].POSITION);
  end
end

function MrTarget:UpdateOptions()
  self:SetOptionSize(self:GetOption('SIZE'));
  self:SetOptionPosition(self:GetOption('POSITION'));
  self:SetOptionColumns(self:GetOption('COLUMNS'));
  self.frames.HARMFUL:SetMax(self.size);
  self.frames.HELPFUL:SetMax(self.size);
end

function MrTarget:SaveOptions()
  MRTARGET_SETTINGS = self.OPTIONS;
  for k,v in pairs(BATTLEFIELD_SIZES) do
    MRTARGET_SETTINGS[v].ENABLED = self.options_frame.tabs[v].Enabled:GetChecked();
    MRTARGET_SETTINGS[v].ENEMY = self.options_frame.tabs[v].Enemy:GetChecked();
    MRTARGET_SETTINGS[v].FRIENDLY = self.options_frame.tabs[v].Friendly:GetChecked();
    MRTARGET_SETTINGS[v].POWER = self.options_frame.tabs[v].Power:GetChecked();
    MRTARGET_SETTINGS[v].RANGE = self.options_frame.tabs[v].Range:GetChecked();
    MRTARGET_SETTINGS[v].TARGETED = self.options_frame.tabs[v].Targeted:GetChecked();
    MRTARGET_SETTINGS[v].AURAS = self.options_frame.tabs[v].Auras:GetChecked();
    MRTARGET_SETTINGS[v].BORDERLESS = self.options_frame.tabs[v].Borderless:GetChecked();
    MRTARGET_SETTINGS[v].ICONS = self.options_frame.tabs[v].Icons:GetChecked();
    MRTARGET_SETTINGS[v].SIZE = self.options_frame.tabs[v].Size:GetValue();
    MRTARGET_SETTINGS[v].COLUMNS = self.options_frame.tabs[v].Columns:GetValue();
  end
end

function MrTarget:CancelOptions()
  self:SetOptions(self.OPTIONS);
end

function MrTarget:DefaultOptions()
  self:SetOptions(DEFAULT_OPTIONS);
  self:OpenOptions(self.size);
end

function MrTarget:DisableOptions()
  if self.options_frame then
    for k,v in pairs(BATTLEFIELD_SIZES) do
      UIDropDownMenu_DisableDropDown(self.options_frame.tabs[v].Naming);
      self.options_frame.tabs[v].Enabled:Disable();
      self.options_frame.tabs[v].Enemy:Disable();
      self.options_frame.tabs[v].Friendly:Disable();
      self.options_frame.tabs[v].Power:Disable();
      self.options_frame.tabs[v].Auras:Disable();
      self.options_frame.tabs[v].Borderless:Disable();
      self.options_frame.tabs[v].Icons:Disable();
    end
  end
end

function MrTarget:EnableOptions()
  if self.options_frame then
    for k,v in pairs(BATTLEFIELD_SIZES) do
      UIDropDownMenu_EnableDropDown(self.options_frame.tabs[v].Naming);
      self.options_frame.tabs[v].Enabled:Enable();
      self.options_frame.tabs[v].Enemy:Enable();
      self.options_frame.tabs[v].Friendly:Enable();
      self.options_frame.tabs[v].Power:Enable();
      self.options_frame.tabs[v].Borderless:Enable();
      self.options_frame.tabs[v].Icons:Enable();
      if self.OPTIONS.COLUMNS == 1 then
        self.options_frame.tabs[v].Auras:Enable();
      end
    end
  end
end

function MrTarget:GetOption(option)
  return self.OPTIONS[self.size][string.upper(option)];
end

function MrTarget:SetOption(option, value)
  if self.size then
    self.OPTIONS[self.size][string.upper(option)] = value;
    if self.options_frame.tabs[self.size] and self.options_frame.tabs[self.size]:IsVisible() then
      self:OpenOptions(self.size);
    end
  end
end

function MrTarget:SetOptionColumns(columns)
  if self.frames.HELPFUL then
    self.frames.HELPFUL:SetColumns(columns);
  end
  if self.frames.HARMFUL then
    self.frames.HARMFUL:SetColumns(columns);
  end
end

function MrTarget:SetOptionPosition(position)
  self:SetOptionPositionHARMFUL(position.HARMFUL);
  self:SetOptionPositionHELPFUL(position.HELPFUL);
end

function MrTarget:SetOptionPositionHARMFUL(position)
  self.frames.HARMFUL.frame:ClearAllPoints();
  local ok, point, relativeTo, relativePoint, x, y = pcall(unpack, position);
  if not ok then point, relativeTo, relativePoint, x, y = unpack(DEFAULT_BATTLEFIELD_OPTIONS.POSITION.HARMFUL);
  end
  self.frames.HARMFUL.frame:SetPoint(point, relativeTo, relativePoint, x, y);
  self.frames.HARMFUL:UpdateOrientation();
end

function MrTarget:SetOptionPositionHELPFUL(position)
  self.frames.HELPFUL.frame:ClearAllPoints();
  local ok, point, relativeTo, relativePoint, x, y = pcall(unpack, position);
  if not ok then point, relativeTo, relativePoint, x, y = unpack(DEFAULT_BATTLEFIELD_OPTIONS.POSITION.HELPFUL);
  end
  self.frames.HELPFUL.frame:SetPoint(point, relativeTo, relativePoint, x, y);
  self.frames.HELPFUL:UpdateOrientation();
end

function MrTarget:SetOptionSize(size)
  if self.frames.HELPFUL then
    self.frames.HELPFUL.frame:SetScale(size/100);
  end
  if self.frames.HARMFUL then
    self.frames.HARMFUL.frame:SetScale(size/100);
  end
end

function MrTarget:CreateDemoAura(frame)
  if self:GetOption('AURAS') then
    frame.auras.auras = table.wipe(frame.auras.auras);
    frame.auras:SetAura(1, 208683, select(1, GetSpellInfo(208683)), 120, GetTime()+120, select(3, GetSpellInfo(208683)));
  end
end

function MrTarget:CreateDemo()
  if self:GetOption('ENEMY') then
    self.frames.HARMFUL:SetTarget(self.frames.HARMFUL.frames[1]);
    self.frames.HARMFUL:SetAssist(self.frames.HARMFUL.frames[1]);
    self:CreateDemoAura(self.frames.HARMFUL.frames[1]);
    if self:GetOption('TARGETED') then
      self.frames.HARMFUL.frames[1].update_targeted = false;
      self.frames.HARMFUL.frames[1].targeted = 1;
    else
      self.frames.HARMFUL.frames[1].update_targeted = true;
      self.frames.HARMFUL.frames[1].targeted = nil;
    end
  end
  if self:GetOption('FRIENDLY') then
    self.frames.HELPFUL:SetTarget(self.frames.HELPFUL.frames[1]);
    self.frames.HELPFUL:SetAssist(self.frames.HELPFUL.frames[1]);
    self:CreateDemoAura(self.frames.HELPFUL.frames[1])
    if self:GetOption('TARGETED') then
      self.frames.HELPFUL.frames[1].update_targeted = false;
      self.frames.HELPFUL.frames[1].targeted = 1;
    else
      self.frames.HELPFUL.frames[1].update_targeted = true;
      self.frames.HELPFUL.frames[1].targeted = nil;
    end
  end
end

function MrTarget:DestroyDemoAura(frame)
  frame.auras.auras = table.wipe(frame.auras.auras);
  frame.auras:UnsetAura(frame.auras.frames[1]);
end

function MrTarget:DestroyDemo()
  if self:GetOption('ENEMY') then
    self.frames.HARMFUL.frames[1].update_targeted = true;
    self:DestroyDemoAura(self.frames.HARMFUL.frames[1]);
  end
  if self:GetOption('FRIENDLY') then
    self.frames.HELPFUL.frames[1].update_targeted = true;
    self:DestroyDemoAura(self.frames.HELPFUL.frames[1]);
  end
end

function MrTarget:OpenOptions(size)
  if not self.active then
    self.size = size;
    self:Unlock();
    self:Initialize();
    self.options_open = true;
    if self:GetOption('ENABLED') then
      self:ObjectivesFrame(true);
      if self:GetOption('ENEMY') then
         self.frames.HARMFUL:CreateStub(ENEMIES, size);
      else
        self.frames.HARMFUL:Destroy();
      end
      if self:GetOption('FRIENDLY') then
        self.frames.HELPFUL:CreateStub(FRIENDS, size);
      else
        self.frames.HELPFUL:Destroy();
      end
      if self:GetOption('BORDERLESS') then
        self.options_frame.tabs[size].Icons:Show();
      else
        self.options_frame.tabs[size].Icons:Hide();
      end
      self:UpdateOptions();
      self:CreateDemo();
    else
      self:Destroy();
    end
  end
end

function MrTarget:CloseOptions()
  if not self.active then
    self:ObjectivesFrame(false);
    self.options_frame:Hide();
    self.options_open = false;
    self:DestroyDemo();
    self:Lock();
    self:Destroy();
  end
end

function MrTarget:GetLocked()
  return self.locked;
end

function MrTarget:Lock()
  self.locked = true;
end

function MrTarget:Unlock()
  self.locked = false;
end

function MrTarget:Destroy()
  self.frames.HARMFUL:Destroy();
  self.frames.HELPFUL:Destroy();
  collectgarbage('collect');
end

function MrTarget:AddonLoaded(addon)
  if addon == 'MrTarget' then
    self:Load();
  end
end

function MrTarget:OnEvent(event, ...)
  if event == 'ADDON_LOADED' then self:AddonLoaded(...);
  elseif event == 'PLAYER_LOGIN' then self:PlayerLogin();
  elseif event == 'ACTIVE_TALENT_GROUP_CHANGED' then self:PlayerLogin();
  elseif event == 'PLAYER_ENTERING_WORLD' then self:ZoneChanged();
  elseif event == 'ZONE_CHANGED' then self:ZoneChanged();
  elseif event == 'ZONE_CHANGED_NEW_AREA' then self:ZoneChanged();
  elseif event == 'ZONE_CHANGED_INDOORS' then self:ZoneChanged();
  elseif event == 'ACTIVE_TALENT_GROUP_CHANGED' then
    self:UpdateSpells();
  end
end

MrTarget:SetScript('OnEvent', MrTarget.OnEvent);

MrTarget:RegisterEvent('PLAYER_ENTERING_WORLD');
MrTarget:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED');
MrTarget:RegisterEvent('ZONE_CHANGED');
MrTarget:RegisterEvent('ZONE_CHANGED_NEW_AREA');
MrTarget:RegisterEvent('ZONE_CHANGED_INDOORS');
MrTarget:RegisterEvent('PLAYER_LOGIN');
MrTarget:RegisterEvent('ADDON_LOADED');

SLASH_MRTARGET1 = '/mrt';
SLASH_MRTARGET2 = '/mrtarget';
function SlashCmdList.MRTARGET(cmd, box)
  if cmd == 'show' then
    MrTarget:Activate();
  elseif cmd == 'hide' then
    MrTarget:Destroy();
  elseif cmd == 'unlock' then
    MrTarget:Unlock()
  elseif cmd == 'lock' then
    MrTarget:Lock()
  else
    InterfaceOptionsFrame_OpenToCategory(MrTarget.options_frame);
    InterfaceOptionsFrame_OpenToCategory(MrTarget.options_frame.tabs[10]);
  end
end
