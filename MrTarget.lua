-- MrTarget v4.0.0
-- =====================================================================
-- This Work is provided under the Creative Commons
-- Attribution-NonCommercial-NoDerivatives 4.0 International Public License
--
-- Please send any bugs or feedback to mrtarget@lockofwar.com.
-- Debug /run print((select(4, GetBuildInfo())));

local DEFAULT_OPTIONS = {
  VERSION=4.00,
  ENABLED=true,
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

local FRIENDS = {
  'Malfurian', 'Jaina', 'Uther', 'Anduin', 'Valeera', 'Thrall', 'Guldan', 'Garrosh',
  'Rexxar', 'Magni', 'Alleria', 'Medivh', 'Arthas', 'Chen', 'Maleki'
};

local ENEMIES = {
  'Афила', 'Сэйбот', 'Яджун', 'Найнс', 'Айвен', 'Аллорион', 'Марги', 'Атжай',
  'Сигр', 'Вайлен', 'Меру', 'Игми', 'Вандерер', 'Биотикус', 'Эксдаркикс'
};

MrTarget = CreateFrame('Frame', 'MrTarget', UIParent);

function MrTarget:Load()
  self.loaded=true;
  self.active=false;
  self.version=DEFAULT_OPTIONS.VERSION;
  self.version_text='v4.0.0';
  self.difficulty = false;
  self.frames={};
  self.player={};
  self.objectives=false;
  self:HelloWorld();
  self:GetOptions();
  self:Initialize();
  self:InitOptions();
end

function MrTarget:Initialize()
  self.frames.HELPFUL = MrTargetGroup:New('HELPFUL', true, self.OPTIONS.COLUMNS);
  self.frames.HARMFUL = MrTargetGroup:New('HARMFUL', false, self.OPTIONS.COLUMNS);
end

function MrTarget:Activate()
  if self.OPTIONS.FRIENDLY then
    self.frames.HELPFUL:Activate();
  end
  self.frames.HARMFUL:Activate();
end

function MrTarget:ZoneChanged()
  local active, battlefield = IsInInstance();
  if self.OPTIONS.ENABLED and not self.active and battlefield == 'pvp' then
    self.active = active;
    self:DisableOptions();
    self:ObjectivesFrame(active);
    self:Activate();
  elseif not active and not self.options_frame:IsVisible() then
    self.active = active;
    self:EnableOptions();
    self:ObjectivesFrame(active);
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
  self.OPTIONS = MRTARGET_OPTIONS or nil;
  if not self.OPTIONS or self.OPTIONS.VERSION ~= self.version then
    self.OPTIONS = DEFAULT_OPTIONS;
  else
    for k, value in pairs(DEFAULT_OPTIONS) do
      if self.OPTIONS[k] == nil then
        self.OPTIONS[k] = value;
      end
    end
  end
end

function MrTarget:InitOptions()
  self.options_frame = CreateFrame('Frame', 'MrTargetOptions', UIParent, 'MrTargetOptionsTemplate');
  self.options_frame.name = GetAddOnMetadata('MrTarget', 'Title');
  self.options_frame.Title:SetText(string.upper('Battlegrounds'));
  self.options_frame.Subtitle:SetText('MrTarget '..self.version_text);
  self.options_frame.okay = function() MrTarget:SaveOptions(); end;
  self.options_frame.default = function() MrTarget:DefaultOptions(); end;
  self.options_frame.cancel = function() MrTarget:CancelOptions(); end;
  self.options_frame:SetScript('OnHide', function(self) MrTarget:CloseOptions(); end);
  self.options_frame:SetScript('OnShow', function(self) MrTarget:OpenOptions(); end);
  InterfaceOptions_AddCategory(self.options_frame);
  self:SetOptions(self.OPTIONS);
end

function MrTarget:InitNamingOptions(default)
  UIDropDownMenu_Initialize(self.options_frame.Naming, function()
    for i, option in pairs({ 'Transmute', 'Transliterate', 'Ignore' }) do
      UIDropDownMenu_AddButton({ owner=self.options_frame.Naming, text=option, value=option, checked=nil, arg1=option, func=(function(_, value)
        UIDropDownMenu_ClearAll(self.options_frame.Naming);
        UIDropDownMenu_SetSelectedValue(self.options_frame.Naming, value);
        self:SetOption('naming', value);
      end)});
    end
  end);
  UIDropDownMenu_SetAnchor(self.options_frame.Naming, 16, 22, 'TOPLEFT', self.options_frame.Naming:GetName()..'Left', 'BOTTOMLEFT');
  UIDropDownMenu_JustifyText(self.options_frame.Naming, 'LEFT');
  UIDropDownMenu_SetSelectedValue(self.options_frame.Naming, default);
end

function MrTarget:SetOptions(options)
  self.options_frame.Enabled:SetChecked(options.ENABLED);
  self.options_frame.Friendly:SetChecked(options.FRIENDLY);
  self.options_frame.Power:SetChecked(options.POWER);
  self.options_frame.Range:SetChecked(options.RANGE);
  self.options_frame.Targeted:SetChecked(options.TARGETED);
  self.options_frame.Auras:SetChecked(options.AURAS);
  self.options_frame.Borderless:SetChecked(options.BORDERLESS);
  self.options_frame.Icons:SetChecked(options.ICONS);
  self.options_frame.Size:SetValue(options.SIZE);
  self.options_frame.Columns:SetValue(options.COLUMNS);
  self:InitNamingOptions(options.NAMING);
  if not InCombatLockdown() then
    self:SetOptionSize(options.SIZE);
    self:SetOptionPosition(options.POSITION);
    self:SetOptionColumns(options.COLUMNS);
  end
end

function MrTarget:SaveOptions()
  MRTARGET_OPTIONS = self.OPTIONS;
  MRTARGET_OPTIONS.ENABLED = self.options_frame.Enabled:GetChecked();
  MRTARGET_OPTIONS.FRIENDLY = self.options_frame.Friendly:GetChecked();
  MRTARGET_OPTIONS.POWER = self.options_frame.Power:GetChecked();
  MRTARGET_OPTIONS.RANGE = self.options_frame.Range:GetChecked();
  MRTARGET_OPTIONS.TARGETED = self.options_frame.Targeted:GetChecked();
  MRTARGET_OPTIONS.AURAS = self.options_frame.Auras:GetChecked();
  MRTARGET_OPTIONS.BORDERLESS = self.options_frame.Borderless:GetChecked();
  MRTARGET_OPTIONS.ICONS = self.options_frame.Icons:GetChecked();
  MRTARGET_OPTIONS.SIZE = self.options_frame.Size:GetValue();
  MRTARGET_OPTIONS.COLUMNS = self.options_frame.Columns:GetValue();
end

function MrTarget:CancelOptions() MrTarget:SetOptions(self.OPTIONS); end
function MrTarget:DefaultOptions() self:SetOptions(DEFAULT_OPTIONS); end

function MrTarget:DisableOptions()
  UIDropDownMenu_DisableDropDown(self.options_frame.Naming);
  self.options_frame.Enabled:Disable();
  self.options_frame.Friendly:Disable();
  self.options_frame.Power:Disable();
  self.options_frame.Auras:Disable();
  self.options_frame.Borderless:Disable();
  self.options_frame.Icons:Disable();
end

function MrTarget:EnableOptions()
  UIDropDownMenu_EnableDropDown(self.options_frame.Naming);
  self.options_frame.Enabled:Enable();
  self.options_frame.Friendly:Enable();
  self.options_frame.Power:Enable();
  self.options_frame.Borderless:Enable();
  self.options_frame.Icons:Enable();
  if self.OPTIONS.COLUMNS == 1 then
    self.options_frame.Auras:Enable();
  end
end

function MrTarget:SetOption(option, value)
  self.OPTIONS[string.upper(option)] = value;
  self:OpenOptions();
end

function MrTarget:SetOptionColumns(columns)
  self.frames.HELPFUL:SetColumns(columns);
  self.frames.HARMFUL:SetColumns(columns);
  if self.options_frame then
    if columns > 1 then
      self.options_frame.Auras:SetChecked(false);
      MrTarget:SetOption('auras', false);
      self.options_frame.Auras:Hide();
    else
      self.options_frame.Auras:Show();
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
  self.frames.HELPFUL.frame:SetScale(size/100);
  self.frames.HARMFUL.frame:SetScale(size/100);
end

function MrTarget:OpenOptions()
  if not self.active then
    if self.OPTIONS.ENABLED then
      self:ObjectivesFrame(true);
      if self.OPTIONS.FRIENDLY then self.frames.HELPFUL:CreateStub(FRIENDS);
      end
      self.frames.HARMFUL:CreateStub(ENEMIES);
      if self.OPTIONS.BORDERLESS then
        self.options_frame.Icons:Show();
      else
        self.options_frame.Icons:Hide();
      end
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
    InterfaceOptionsFrame_OpenToCategory(MrTarget.options_frame);
  end
end