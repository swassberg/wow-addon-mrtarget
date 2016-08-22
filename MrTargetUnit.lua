-- MrTargetUnit
-- =====================================================================
-- Copyright (C) 2014 Lock of War, Developmental (Pty) Ltd
--

local POWER_BAR_COLORS = {
  MANA={ r=0.00,g=0.00,b=1.00 },
  RAGE={ r=1.00,g=0.00,b=0.00 },
  FOCUS={ r=1.00,g=0.50,b=0.25 },
  ENERGY={ r=1.00,g=1.00,b=0.00 },
  CHI={ r=0.71,g=1.0,b=0.92 },
  RUNES={ r=0.50,g=0.50,b=0.50 }
};

local LFGRoleTexCoords = { TANK={ 0.5,0.75,0,1 }, DAMAGER={ 0.25,0.5,0,1 }, HEALER={ 0.75,1,0,1 }};
local function GetTexCoordsForRole(role, borderless)
  role = role or 'DAMAGER';
  local c = borderless and LFGRoleTexCoords[role] or {GetTexCoordsForRoleSmallCircle(role)};
  return unpack(c);
end

MrTargetUnit = {
  update=0,
  group=0,
  dead=false,
  test=false,
  name=nil,
  icon=nil,
  display=nil,
  unit=nil,
  frame=nil,
  spec=nil,
  class=nil,
  role=nil,
  health=1,
  healthMax=1,
  power=1,
  powerMax=1,
  targeted='',
  range=nil,
  last_update=0,
  update_targeted=true,
  auras=nil
};

MrTargetUnit.__index = MrTargetUnit;

function MrTargetUnit:New(group, count)
  local this = setmetatable({}, MrTargetUnit);
  this.group = group;
  this.frame = CreateFrame('Button', group.frame:GetName()..'MrTargetUnit'..count, group.frame, 'MrTargetUnitTemplate');
  this.frame:SetScript('OnEvent', function(frame, ...) this:OnEvent(...); end);
  this.frame:SetScript('OnUpdate', function(frame, ...) this:OnUpdate(...); end);
  this.frame:SetScript('OnEnter', function(frame, ...) this:OnEnter(...); end);
  this.frame:SetScript('OnLeave', function(frame, ...) this:OnLeave(...); end); 
  this.frame:SetScript('OnDragStart', function(frame, ...) group:OnDragStart(...); end);
  this.frame:SetScript('OnDragStop', function(frame, ...) group:OnDragStop(...); end);
  this.frame.UPDATE_TARGETED:SetScript('OnUpdate', function(frame, ...) this:UpdateTargeted(...); end);  
  this.frame:EnableMouse(true);
  this.frame:RegisterForDrag('RightButton');
  this.frame:RegisterForClicks('LeftButtonUp', 'RightButtonUp');
  this.frame:SetAttribute('type1', 'macro');
  this.frame:SetAttribute('type2', 'macro');
  this.frame:SetAttribute('macrotext1', '');
  this.frame:SetAttribute('macrotext2', '');  
  this.auras = MrTargetAuras:New(this.frame);  
  return this;
end

function MrTargetUnit:SetUnit(name, display, class, spec, role, icon, test)
  self.name = name;
  self.display = display;
  self.class = class;
  self.spec = spec;
  self.role = role;
  self.unit = name;
  self.icon = icon;
  self.test = test;
  self:RegisterEvents();
  self:SetFrameStyle();
  self.frame:Show();
end

function MrTargetUnit:UnsetUnit()
  self.name = nil;
  self.display = nil;
  self.class = nil;
  self.spec = nil;
  self.role = nil;
  self.unit = nil;
  self.dead = false;
  self.test = false;
  self.frame.SPEC:SetText('');
  self.frame.SPEC_ICON:SetTexture(nil);
  self.frame.NAME:SetText('');
  self.health = 1;
  self.healthMax = 1;
  self.power = 1;
  self.powerMax = 1;
  self:UnregisterEvents();
  self:Hide();
end

function MrTargetUnit:PlayerRegenEnabled()
  self.frame:UnregisterEvent('PLAYER_REGEN_ENABLED');
  self.frame:SetAttribute('macrotext1', nil);
  self.frame:SetAttribute('macrotext2', nil);
  self.frame:Hide();
end

function MrTargetUnit:Hide()
  if InCombatLockdown() then
    self.frame:RegisterEvent('PLAYER_REGEN_ENABLED');
  else
    self.frame:Hide();
  end  
end

function MrTargetUnit:Destroy()
  self:UnsetUnit();
  self.auras:Destroy();
end

function MrTargetUnit:UnitHealthColor()
  local color = RAID_CLASS_COLORS[self.class];
  self.frame.HEALTH_BAR:SetStatusBarColor(color.r, color.g, color.b);
  self.frame.HEALTH_BAR.r, self.frame.HEALTH_BAR.g, self.frame.HEALTH_BAR.b = color.r, color.g, color.b;
end

function MrTargetUnit:UnitPowerColor()
  local powerType, powerToken = UnitPowerType(self.name);
  local color = POWER_BAR_COLORS[powerToken] or POWER_BAR_COLORS.MANA;
  self.frame.POWER_BAR:SetStatusBarColor(color.r, color.g, color.b);
end

function MrTargetUnit:UnitUpdate()
  if self.unit then
    self.last_update = GetTime();
    self.health = UnitHealth(self.unit);
    self.healthMax = UnitHealthMax(self.unit);
    self.power = UnitPower(self.unit);
    self.powerMax = UnitPowerMax(self.unit); 
    if UnitIsDeadOrGhost(self.unit) or UnitHealth(self.unit) == 0 then
      self.auras:Destroy();
      self.health = 0;
      self.power = 0;
      self.range = nil;    
      self.dead = true; 
    else         
      self.range = MrTargetRange:GetRange(self.unit);
      self.auras:UnitAura(self.unit);
      self.dead = false; 
    end
  end
end

function MrTargetUnit:UnitCheck(unit)
  if self:GetUnit(unit) then
    self:UnitUpdate();
  end
end

function MrTargetUnit:UpdateTargeted(unit)
  if OPTIONS.TARGETED then
    if self.update_targeted then
      self.targeted = 0;
      self.update_targeted = false;
      for i=1, GetNumGroupMembers() do
        if GetUnitName('raid'..i..'target', true) == self.name then
          self.targeted = self.targeted+1;
        end
      end
      self.targeted = self.targeted>0 and self.targeted or '';
      self.update_targeted = true;
    end
  end
end

function MrTargetUnit:GetUnit(unit)  
  if GetUnitName(unit, true) == self.name then
    self.unit = unit;
  elseif GetUnitName(unit..'target', true) == self.name then
    self.unit = unit..'target';
  else
    self.unit = false;
  end
  return self.unit;
end

function MrTargetUnit:UnitLost()
  for i=1, GetNumGroupMembers() do
    if GetUnitName('raid'..i..'target', true) == self.name then
      self.unit = 'raid'..i..'target'; 
      self:UnitUpdate();
      return;
    end
  end
  self.auras:Destroy();
end

function MrTargetUnit:OnUpdate(time)  
  self.update = self.update + time;
  if self.update < 0.1 then
    return;
  end
  self.update = 0;
  self:UpdateDisplay();
end

function MrTargetUnit:UpdateDisplay() 
  self.frame.NAME:SetText(self.display);
  self.frame.SPEC:SetText(self.spec);
  self.frame.SPEC_ICON:SetTexture(self.icon);
  self.frame.SPEC_ICON:SetAlpha(1);
  self.frame.HEALTH_BAR:SetMinMaxValues(0, self.healthMax);
  self.frame.HEALTH_BAR:SetValue(self.health);
  self.frame.POWER_BAR:SetMinMaxValues(0, self.powerMax);
  self.frame.POWER_BAR:SetValue(self.power);
  self.frame.TARGETED:SetText(self.targeted);
  self:UnitHealthColor();
  self:UnitPowerColor();
  self:ResetTargetMacro();
  if GetTime() - self.last_update > 3 and not self.test then
    if GetTime() - self.last_update > 30 then
      self.health = self.healthMax;
      self.power = self.powerMax;
    end
    self.frame:SetAlpha(0.5);
    self:UnitLost();
  elseif OPTIONS.RANGE and self.range == nil then 
    self.frame:SetAlpha(0.5); 
  else
    self.frame:SetAlpha(1);
  end
end

function MrTargetUnit:ResetTargetMacro()
  if not InCombatLockdown() then
    self.frame:SetAttribute('macrotext1', '/targetexact '..self.name);
    self.frame:SetAttribute('macrotext2', '/targetexact '..self.name..'\n/focus\n/targetlasttarget');
  end
end

function MrTargetUnit:OnEnter() self.frame.HOVER:Show(); end
function MrTargetUnit:OnLeave() self.frame.HOVER:Hide(); end

function MrTargetUnit:OnEvent(event, unit, x, y, z)
  if event == 'UNIT_HEALTH_FREQUENT' then self:UnitCheck(unit);  
  elseif event == 'UNIT_COMBAT' then self:UnitCheck(unit);
  elseif event == 'UNIT_TARGET' then self:UnitCheck(unit); 
  elseif event == 'UPDATE_MOUSEOVER_UNIT' then self:UnitCheck('mouseover');  
  elseif event == 'PLAYER_REGEN_ENABLED' then self:PlayerRegenEnabled(); 
  end
end

function MrTargetUnit:RegisterEvents()
  self.frame:RegisterEvent('UNIT_HEALTH_FREQUENT');
  self.frame:RegisterEvent('UPDATE_MOUSEOVER_UNIT');
  self.frame:RegisterEvent('UNIT_COMBAT');
  self.frame:RegisterEvent('UNIT_TARGET');
end

function MrTargetUnit:UnregisterEvents()
  self.frame:UnregisterEvent('UNIT_HEALTH_FREQUENT');
  self.frame:UnregisterEvent('UPDATE_MOUSEOVER_UNIT');
  self.frame:UnregisterEvent('UNIT_COMBAT');
  self.frame:UnregisterEvent('UNIT_TARGET');
end

function MrTargetUnit:SetFrameStyle()
  if OPTIONS.BORDERLESS then self:SetStyleBorderless();
  else self:SetStyleDefault();
  end
end

function MrTargetUnit:SetStyleDefault()
  self.frame:EnableDrawLayer('BORDER');
  self.frame.NAME:SetFontObject("GameFontHighlight");
  self.frame.TARGETED:SetFontObject("TextStatusBarTextRed");
  self.frame.HEALTH_BAR:ClearAllPoints();
  self.frame.HEALTH_BAR:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', 1, -1);  
  if OPTIONS.POWER then
    self.frame.POWER_BAR:ClearAllPoints();
    self.frame.HEALTH_BAR:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', -1, 10);
    self.frame.POWER_BAR:SetPoint('TOPLEFT', self.frame.HEALTH_BAR, 'BOTTOMLEFT', 0, -2);
    self.frame.POWER_BAR:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', -1, 0);
    self.frame.POWER_BAR:Show();
    self.frame.horizDivider:Show();
  else
    self.frame.HEALTH_BAR:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', -1, 2);
    self.frame.POWER_BAR:Hide();
    self.frame.horizDivider:Hide();    
  end
  self.frame.ROLE_ICON:ClearAllPoints();
  self.frame.ROLE_ICON:SetTexture('Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES');
  self.frame.ROLE_ICON:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', 2.5, -2.5);
  self.frame.ROLE_ICON:SetTexCoord(GetTexCoordsForRole(self.role, false));
  self.frame.ROLE_ICON:Show();
  self.frame.SPEC:Show();
  self.frame.SPEC_ICON:Hide();
end

function MrTargetUnit:SetStyleBorderless()
  self.frame:DisableDrawLayer('BORDER');
  self.frame.NAME:SetFontObject("GameFontHighlightBorderless");
  self.frame.TARGETED:SetFontObject("TextStatusBarTextRedBorderless");
  self.frame.HEALTH_BAR:ClearAllPoints();
  self.frame.HEALTH_BAR:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', 0, 0);
  if OPTIONS.POWER then
    self.frame.POWER_BAR:ClearAllPoints();
    self.frame.HEALTH_BAR:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', 0, 15);
    self.frame.POWER_BAR:SetPoint('TOPLEFT', self.frame.HEALTH_BAR, 'BOTTOMLEFT', 0, -1);
    self.frame.POWER_BAR:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', 0, 1);
    self.frame.POWER_BAR:Show();
    self.frame.horizDivider:Show();
  else
    self.frame.HEALTH_BAR:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', 0, 1);
    self.frame.POWER_BAR:Hide();
    self.frame.horizDivider:Hide();
  end
  self.frame.POWER_BAR:ClearAllPoints();
  self.frame.POWER_BAR:SetPoint('TOPLEFT', self.frame.HEALTH_BAR, 'BOTTOMLEFT', 0, -1);
  self.frame.POWER_BAR:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', 0, 1);
  self.frame.POWER_BAR:Show();
  self.frame.ROLE_ICON:ClearAllPoints();
  self.frame.ROLE_ICON:SetTexture('Interface\\LFGFrame\\LFGRole');
  self.frame.ROLE_ICON:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', 2.5, -3);
  self.frame.ROLE_ICON:SetTexCoord(GetTexCoordsForRole(self.role, true));
  self.frame.ROLE_ICON:Show();
  self.frame.SPEC:Hide();
  if OPTIONS.ICONS then
    self.frame.SPEC_ICON:Show();
  else
    self.frame.SPEC_ICON:Hide();
  end
end
