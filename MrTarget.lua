-- MrTarget v4.0.1
-- =====================================================================
-- This Work is provided under the Creative Commons
-- Attribution-NonCommercial-NoDerivatives 4.0 International Public License
--
-- Please send any bugs or feedback to mrtarget@lockofwar.com.
-- Debug /run print((select(4, GetBuildInfo())));

local BATTLEFIELD_SIZES = { 10, 15, 40 };

local DEFAULT_BATTLEFIELD_OPTIONS = {
  VERSION=4.01,
  ENABLED=true,
  ENEMY=true,
  FRIENDLY=false,
  POSITION={
    HARMFUL={ 'RIGHT', nil, 'RIGHT', -100, 0 },
    HELPFUL={ 'LEFT', nil, 'LEFT', 100, 0 }
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

local DEFAULT_OPTIONS = {}
for k,v in pairs(BATTLEFIELD_SIZES) do
  DEFAULT_OPTIONS[v] = DEFAULT_BATTLEFIELD_OPTIONS;
  if v > 10 then
    DEFAULT_OPTIONS[v].AURAS = false;
    if v == 40 then
      DEFAULT_OPTIONS[v].COLUMNS = 2;
    end
  end
end

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
  ['The Battle for Gilneas'] = { size=10 },
  ['Silvershard Mines'] = { size=10 },
  ['Warsong Gulch'] = { size=10 },
  ['Twin Peaks'] = { size=10 },
  ['Temple of Kotmogu'] = { size=10 },
  ['Arathi Basin'] = { size=15 },
  ['Strand of the Ancients'] = { size=15 },
  ['Eye of the Storm'] = { size=15 },
  ['Deepwind Gorge'] = { size=15 },
  ['Alterac Valley'] = { size=40 },
  ['Isle of Conquest'] = { size=40 }
};

MrTarget = CreateFrame('Frame', 'MrTarget', UIParent);

function MrTarget:Load()
  self.loaded=true;
  self.active=false;
  self.version=DEFAULT_OPTIONS.VERSION;
  self.version_text='v4.0.1';
  self.difficulty = false;
  self.frames={};
  self.player={};
  self.size=40;
  self.objectives=false;
  self:HelloWorld();
  self:GetOptions();
  self:Initialize();
  self:InitOptions();
end

function MrTarget:Initialize()
  self.frames.HARMFUL = MrTargetGroup:New('HARMFUL', false, self.OPTIONS[self.size].COLUMNS, self.size);
  self.frames.HELPFUL = MrTargetGroup:New('HELPFUL', true, self.OPTIONS[self.size].COLUMNS, self.size);
end

function MrTarget:Activate()
  if self.OPTIONS.ENEMY then
    self.frames.HARMFUL:Activate();
  end
  if self.OPTIONS.FRIENDLY then
    self.frames.HELPFUL:Activate();
  end
end

function MrTarget:ZoneChanged()
  local active, battlefield = IsInInstance();
  if self.OPTIONS.ENABLED and not self.active and battlefield == 'pvp' then
    for i=1, GetMaxBattlefieldID() do
      local status, name, size = GetBattlefieldStatus(i);
      if status == 'active' then
        if BATTLEFIELDS[name] then
          self.size = BATTLEFIELDS.size;
          self.active = active;
          self:DisableOptions();
          self:ObjectivesFrame(active);
          self:UpdateOptions();
          self:Activate();
        end
      end
    end
  elseif not active then
    if self.options_frame and not self.options_frame:IsVisible() then
      self.active = active;
      self:EnableOptions();
      self:ObjectivesFrame(active);
      self:Destroy();
    end
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

function MrTarget:PlayerLogin()
  if self.loaded then
    self.player.NAME = UnitName('player');
    self.player.CLASS = select(2, UnitClass('player'));
    self.player.FACTION = GetBattlefieldArenaFaction();
  end
end

function MrTarget:HelloWorld()
  local message = '|cFF00FFFF <MrTarget-'..self.version_text..'>|cFFFF0000 Even the Score.|r Type /mrt for interface options.';
  ChatFrame1:AddMessage(message, 0, 0, 0, GetChatTypeIndex('SYSTEM'));
end

function MrTarget:GetOptions()
  self.OPTIONS = MRTARGET_SETTINGS or MRTARGET_OPTIONS or nil;
  if not self.OPTIONS then
    self.OPTIONS = DEFAULT_OPTIONS;
  else
    if self.OPTIONS.VERSION < 4.01 or not self.OPTIONS[10] then
      for k,v in pairs(BATTLEFIELD_SIZES) do
        self.OPTIONS[v] = self.OPTIONS;
      end
    end
    for i, value in pairs(DEFAULT_OPTIONS) do
      for k,v in pairs(BATTLEFIELD_SIZES) do
        if self.OPTIONS[v][i] == nil then
          self.OPTIONS[v][i] = value;
        end
      end
    end
  end
end

function MrTarget:InitOptions()
  self.options_frame = CreateFrame('Frame', 'MrTargetOptions', UIParent);
  self.options_frame.name = GetAddOnMetadata('MrTarget', 'Title');
  self.options_frame.tabs = {};
  InterfaceOptions_AddCategory(self.options_frame);
  for k,v in pairs(BATTLEFIELD_SIZES) do
    self.options_frame.tabs[v] = CreateFrame('Frame', 'MrTargetOptions'..v, self.options_frame, 'MrTargetOptionsTemplate');
    self.options_frame.tabs[v].name = v..' man';
    self.options_frame.tabs[v].parent = self.options_frame.name;
    self.options_frame.tabs[v].size = v;
    self.options_frame.tabs[v].Title:SetText(string.upper(v..' Man Battlegrounds'));
    self.options_frame.tabs[v].Subtitle:SetText('MrTarget '..self.version_text);
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
    UIDropDownMenu_Initialize(self.options_frame.tabs[v].Naming, function()
      for i, option in pairs({ 'Transmute', 'Transliterate', 'Ignore' }) do
        UIDropDownMenu_AddButton({ owner=self.options_frame.tabs[v].Naming, text=option, value=option, checked=nil, arg1=option, func=(function(_, value)
          UIDropDownMenu_ClearAll(self.options_frame.tabs[v].Naming);
          UIDropDownMenu_SetSelectedValue(self.options_frame.tabs[v].Naming, value);
          self:SetOption('naming', value);
        end)});
      end
    end);
    UIDropDownMenu_SetAnchor(self.options_frame.tabs[v].Naming, 16, 22, 'TOPLEFT', self.options_frame.tabs[v].Naming:GetName()..'Left', 'BOTTOMLEFT');
    UIDropDownMenu_JustifyText(self.options_frame.tabs[v].Naming, 'LEFT');
    UIDropDownMenu_SetSelectedValue(self.options_frame.tabs[v].Naming, default);
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
end

function MrTarget:UpdateOptions(max)
  self:SetOptionSize(self.OPTIONS[max].SIZE);
  self:SetOptionPosition(self.OPTIONS[max].POSITION);
  self:SetOptionColumns(self.OPTIONS[max].COLUMNS);
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

function MrTarget:CancelOptions() MrTarget:SetOptions(self.OPTIONS); end
function MrTarget:DefaultOptions() self:SetOptions(DEFAULT_OPTIONS); end

function MrTarget:DisableOptions()
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

function MrTarget:EnableOptions()
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

function MrTarget:GetOption(option)
  return self.OPTIONS[self.size][string.upper(option)];
end

function MrTarget:SetOption(option, value)
  if self.size then
    self.OPTIONS[self.size][string.upper(option)] = value;
    if self.options_frame.tabs[self.size]:IsVisible() then
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
  if self.options_frame.tabs[self.size] then
    if columns > 1 then
      self.options_frame.tabs[self.size].Auras:SetChecked(false);
      self.OPTIONS[self.size][string.upper('auras')] = false;
      self.options_frame.tabs[self.size].Auras:Disable();
    else
      self.options_frame.tabs[self.size].Auras:Enable();
    end
  end
end

function MrTarget:SetOptionPosition(position)
  self:SetOptionPositionHARMFUL(position.HARMFUL);
  self:SetOptionPositionHELPFUL(position.HELPFUL);
end

function MrTarget:SetOptionPositionHARMFUL(position)
  self.frames.HARMFUL.frame:ClearAllPoints();
  local ok, point, relativeTo, relativePoint, x, y = pcall(unpack, position);
  if not ok then point, relativeTo, relativePoint, x, y = unpack(DEFAULT_OPTIONS.POSITION.HARMFUL);
  end
  self.frames.HARMFUL.frame:SetPoint(point, relativeTo, relativePoint, x, y);
end

function MrTarget:SetOptionPositionHELPFUL(position)
  self.frames.HELPFUL.frame:ClearAllPoints();
  local ok, point, relativeTo, relativePoint, x, y = pcall(unpack, position);
  if not ok then point, relativeTo, relativePoint, x, y = unpack(DEFAULT_OPTIONS.POSITION.HELPFUL);
  end
  self.frames.HELPFUL.frame:SetPoint(point, relativeTo, relativePoint, x, y);
end

function MrTarget:SetOptionSize(size)
  if self.frames.HELPFUL then
    self.frames.HELPFUL.frame:SetScale(size/100);
  end
  if self.frames.HARMFUL then
    self.frames.HARMFUL.frame:SetScale(size/100);
  end
end

function MrTarget:OpenOptions(size)
  if not self.active then
    self.size = size;
    self:Initialize();
    if self.OPTIONS[size].ENABLED then
      self:ObjectivesFrame(true);
      if self.OPTIONS[size].ENEMY then
         self.frames.HARMFUL:CreateStub(ENEMIES, size);
      else
        self.frames.HARMFUL:Destroy();
      end
      if self.OPTIONS[size].FRIENDLY then
        self.frames.HELPFUL:CreateStub(FRIENDS, size);
      else
        self.frames.HELPFUL:Destroy();
      end
      if self.OPTIONS[size].BORDERLESS then
        self.options_frame.tabs[size].Icons:Show();
      else
        self.options_frame.tabs[size].Icons:Hide();
      end
      self:UpdateOptions(self.size);
    else
      self:Destroy();
    end
  end
end

function MrTarget:CloseOptions()
  if not self.active then
    self:ObjectivesFrame(false);
    self.options_frame:Hide();
    self:Destroy();
  end
end

function MrTarget:Destroy()
  self.frames.HARMFUL:Destroy();
  self.frames.HELPFUL:Destroy();
  self.size = 40;
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
  else
    InterfaceOptionsFrame_OpenToCategory(MrTarget.options_frame);
    InterfaceOptionsFrame_OpenToCategory(MrTarget.options_frame.tabs[10]);
  end
end