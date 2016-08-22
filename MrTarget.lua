-- MrTarget v3.0.1
-- =====================================================================
-- Copyright (C) 2014 Lock of War, Developmental (Pty) Ltd
--
-- This Work is provided under the Creative Commons
-- Attribution-NonCommercial-NoDerivatives 4.0 International Public License
--
-- Please send any bugs or feedback to mrtarget@lockofwar.com.
-- Debug /run print((select(4, GetBuildInfo())));

local DEFAULT_OPTIONS = {
  VERSION=3.01,
  ENABLED=true, 
  POSITION={ HARMFUL={ 'LEFT', nil, 'LEFT', 200, 0 }},
  BORDERLESS=false,
  ICONS=true,
  SIZE=100,
  NAMING='Transmute',
  POWER=true,
  RANGE=true,
  TARGETED=true,
  AURAS=true
};

local RUSSIANS = {
  'Афила', 'Сэйбот', 'Яджун', 'Найнс', 'Айвен', 'Аллорион', 'Марги', 'Атжай',
  'Сигр', 'Вайлен', 'Меру', 'Игми', 'Вандерер', 'Биотикус', 'Эксдаркикс'
};

MrTarget = CreateFrame('Frame', 'MrTarget', UIParent);

function MrTarget:Load()
  self.active=false;
  self.version=DEFAULT_OPTIONS.VERSION;
  self.version_text='v3.0.1';
  self.frames={};
  self.player={};
  self:HelloWorld();
  self:Initialize(); 
  self:Options();
end

function MrTarget:Initialize()
  self.frames.HARMFUL = MrTargetGroup:New('HARMFUL');
end

function MrTarget:Activate()  
  self.frames.HARMFUL:Activate();
end

function MrTarget:ZoneChanged()
  local battlefield = select(2, GetInstanceInfo());  
  if OPTIONS.ENABLED and battlefield == 'pvp' then
    self.active = true;
    self:DisableOptions();  
    self:ObjectivesFrame(true);
    self:Activate();
  else  
    self.active = false;
    self:EnableOptions(); 
    self:ObjectivesFrame(false);
    self:Destroy();
  end
end

function MrTarget:ObjectivesFrame(active)
  if ObjectiveTrackerFrame then
    if active then ObjectiveTracker_Collapse();  
    else ObjectiveTracker_Expand();
    end
    ObjectiveTracker_Update();
  end
end

function MrTarget:PlayerLogin()
  self.player.NAME = UnitName('player');
  self.player.CLASS = select(2, UnitClass('player'));
  self.player.SPEC = select(2, GetSpecializationInfo(GetSpecialization()));
  self.player.FACTION = GetBattlefieldArenaFaction(); 
  MrTargetRange:UpdateSpells();
end

function MrTarget:HelloWorld()
  local message = '|cFF00FFFF <MrTarget-'..self.version_text..'>|cFFFF0000 Even the Score.|r Type /mrt for interface options.';
  ChatFrame1:AddMessage(message, 0, 0, 0, GetChatTypeIndex('SYSTEM'));
end

function MrTarget:Options()
  OPTIONS = OPTIONS or {};
  if not OPTIONS or OPTIONS.VERSION ~= self.version then
    OPTIONS = DEFAULT_OPTIONS;
  else
    for k, value in pairs(DEFAULT_OPTIONS) do
      if OPTIONS[k] == nil then
        OPTIONS[k] = value;
      end
    end
  end
  self:InitOptions();
end

function MrTarget:InitOptions()
  self.options_frame = CreateFrame('Frame', 'MrTargetOptions', UIParent, 'MrTargetOptionsTemplate');
  self.options_frame.name = GetAddOnMetadata('MrTarget', 'Title');
  self.options_frame.Title:SetText(string.upper('Battlegrounds'));
  self.options_frame.Subtitle:SetText('MrTarget '..self.version_text);
  self.options_frame.okay = function() MrTarget:SaveAllOptions(); end;
  self.options_frame.default = function() MrTarget:DefaultOptions(); end;
  self.options_frame.cancel = function() MrTarget:CancelOptions(); end;
  self.options_frame:SetScript('OnHide', function(self) MrTarget:CloseOptions(); end);
  self.options_frame:SetScript('OnShow', function(self) MrTarget:OpenOptions(); end);
  InterfaceOptions_AddCategory(self.options_frame);
  self:SetOptions(OPTIONS);
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
  self.options_frame.Power:SetChecked(options.POWER);
  self.options_frame.Range:SetChecked(options.RANGE);
  self.options_frame.Targeted:SetChecked(options.TARGETED);
  self.options_frame.Auras:SetChecked(options.AURAS);
  self.options_frame.Borderless:SetChecked(options.BORDERLESS);
  self.options_frame.Icons:SetChecked(options.ICONS);
  self.options_frame.Size:SetValue(options.SIZE);
  self:InitNamingOptions(options.NAMING);
  if not InCombatLockdown() then
    self:SetOptionSize(options.SIZE);
    self:SetOptionPosition(options.POSITION);
  end
end

function MrTarget:SaveOptions()
  OPTIONS.ENABLED = self.options_frame.Enabled:GetChecked();
  OPTIONS.POWER = self.options_frame.Power:GetChecked();
  OPTIONS.RANGE = self.options_frame.Range:GetChecked();
  OPTIONS.TARGETED = self.options_frame.Targeted:GetChecked();
  OPTIONS.AURAS = self.options_frame.Auras:GetChecked();
  OPTIONS.BORDERLESS = self.options_frame.Borderless:GetChecked();
  OPTIONS.ICONS = self.options_frame.Icons:GetChecked();
  OPTIONS.SIZE = self.options_frame.Size:GetValue();
end

function MrTarget:SaveAllOptions()
  self:SaveOptions();
end

function MrTarget:CancelOptions() MrTarget:SetOptions(OPTIONS); end
function MrTarget:DefaultOptions() self:SetOptions(DEFAULT_OPTIONS); end
function MrTarget:QuickSave() self:SaveOptions(); end

function MrTarget:DisableOptions()
  UIDropDownMenu_DisableDropDown(self.options_frame.Naming);
  self.options_frame.Enabled:Disable();
  self.options_frame.Power:Disable();
  self.options_frame.Auras:Disable();
  self.options_frame.Borderless:Disable();
  self.options_frame.Icons:Disable();
end

function MrTarget:EnableOptions()
  UIDropDownMenu_EnableDropDown(self.options_frame.Naming);
  self.options_frame.Enabled:Enable();
  self.options_frame.Power:Enable();
  self.options_frame.Auras:Enable();
  self.options_frame.Borderless:Enable();
  self.options_frame.Icons:Enable();
end

function MrTarget:SetOption(option, value) 
  OPTIONS[string.upper(option)] = value; 
  self:OpenOptions();
end

function MrTarget:SetOptionPosition(position)
  self.frames.HARMFUL.frame:ClearAllPoints();
  local ok, point, relativeTo, relativePoint, x, y = pcall(unpack, position.HARMFUL);
  if not ok then point, relativeTo, relativePoint, x, y = unpack(DEFAULT_OPTIONS.POSITION.HARMFUL);
  end
  self.frames.HARMFUL.frame:SetPoint(point, relativeTo, relativePoint, x, y);
end

function MrTarget:SetOptionSize(size)
  self.frames.HARMFUL.frame:SetScale(size/100);
end

function MrTarget:OpenOptions()
  if not self.active then
    if OPTIONS.ENABLED then
      self:ObjectivesFrame(true);
      self.frames.HARMFUL:CreateStub(RUSSIANS);
      self.frames.HARMFUL:Show();
      if OPTIONS.BORDERLESS then 
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
  InterfaceOptionsFrame_OpenToCategory(MrTarget.options_frame);
  InterfaceOptionsFrame_OpenToCategory(MrTarget.options_frame);
end