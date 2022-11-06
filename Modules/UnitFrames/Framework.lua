---@class SUI
local SUI = SUI
local L, print = SUI.L, SUI.print
---@class SUI_UnitFrames : AceAddon-3.0, AceEvent-3.0, AceTimer-3.0
local UF = SUI:NewModule('Module_UnitFrames')
local MoveIt = SUI.MoveIt
SUI.UF = UF
UF.DisplayName = L['Unit frames']
UF.description = 'CORE: SUI Unitframes'
UF.Core = true
UF.CurrentSettings = {}
---@class UFPositionDefaults
local UFPositionDefaults = {
	['player'] = 'BOTTOMRIGHT,UIParent,BOTTOM,-60,250',
	['pet'] = 'RIGHT,SUI_UF_player,BOTTOMLEFT,-60,0',
	['pettarget'] = 'RIGHT,SUI_UF_pet,LEFT,0,-5',
	['target'] = 'LEFT,SUI_UF_player,RIGHT,150,0',
	['targettarget'] = 'LEFT,SUI_UF_target,BOTTOMRIGHT,4,0',
	['focus'] = 'BOTTOMLEFT,SUI_UF_target,TOP,0,30',
	['focustarget'] = 'BOTTOMLEFT,SUI_UF_focus,BOTTOMRIGHT,5,0',
	['boss'] = 'RIGHT,UIParent,RIGHT,-9,162',
	['party'] = 'TOPLEFT,UIParent,TOPLEFT,20,-40',
	['partypet'] = 'BOTTOMRIGHT,frame,BOTTOMLEFT,-2,0',
	['partytarget'] = 'LEFT,frame,RIGHT,2,0',
	['raid'] = 'TOPLEFT,UIParent,TOPLEFT,20,-40',
	['arena'] = 'RIGHT,UIParent,RIGHT,-366,191'
}
UF.Artwork = {}

---@param msg string
---@param frame UnitId
---@param element string
function UF:debug(msg, frame, element)
	SUI.Debug((frame and frame .. '-' or '') .. (element and element .. '-' or '') .. msg, 'UnitFrames')
end
---Returns the path to the texture for the given LSM key, or the SUI default
---@param LSMKey string
---@return string
function UF:FindStatusBarTexture(LSMKey)
	local defaultTexture = 'Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2'
	return SUI.Lib.LSM:Fetch('statusbar', LSMKey, false) or defaultTexture
end

---@param frameName UnitId
function UF:IsFriendlyFrame(frameName)
	local FriendlyFrame = {
		'player',
		'pet',
		'party',
		'partypet',
		'target',
		'targettarget'
	}
	if SUI:IsInTable(FriendlyFrame, frameName) or frameName:match('party') or frameName:match('raid') then
		return true
	end
	return false
end

---@param unit UnitId
---@param data UnitAuraInfo
---@param rules SUI.UnitFrame.Aura.Rules
function UF:FilterAura(element, unit, data, rules)
	local ShouldDisplay = true
	-- if data.dispelName then
	-- print(unit .. '-' .. data.name .. '-' .. data.dispelName)
	-- end

	for k, v in pairs(rules) do
		UF:debug(k, unit, 'FilterAura')
		if data[k] then
			UF:debug(data.name, unit, 'FilterAura')
			if type(v) == 'table' then
				if k == 'duration' and v.enabled then
					local moreThanMax = data[k] > v.maxTime
					local lessThanMin = data[k] < v.minTime
					UF:debug('Durration is ' .. data[k], unit, 'FilterAura')
					if lessThanMin or moreThanMax then
						ShouldDisplay = false
					end
				elseif SUI:IsInTable(v, data[k]) then
					if v[data[k]] then
						UF:debug('Force show per rules', unit, 'FilterAura')
						return true
					else
						UF:debug('Force hide per rules', unit, 'FilterAura')
						return false
					end
				end
			elseif type(v) == 'boolean' then
				if v ~= data[k] then
					UF:debug('Not equal', unit, 'FilterAura')
					ShouldDisplay = false
				end
			end
		elseif k == 'whitelist' or k == 'blacklist' then
			if v[data.spellId] then
				return (k == 'whitelist' and true) or false
			end
		end
	end

	UF:debug('ShouldDisplay result ' .. (ShouldDisplay and 'true' or 'false'), unit, 'FilterAura')
	return ShouldDisplay
end

---@param unit? UnitFrameName
function UF:PositionFrame(unit)
	local positionData = UFPositionDefaults
	-- If artwork is enabled load the art's position data if supplied
	local posData = UF.Style:Get(SUI.DB.Artwork.Style).positions
	if SUI:IsModuleEnabled('Artwork') and posData then
		positionData = SUI:CopyData(posData, UFPositionDefaults)
	end

	if unit then
		local UnitFrame = UF.Unit:Get(unit)
		local point, anchor, secondaryPoint, x, y = strsplit(',', positionData[unit])

		if UnitFrame.position then
			UnitFrame:position(point, anchor, secondaryPoint, x, y, false, true)
		else
			UnitFrame:ClearAllPoints()
			UnitFrame:SetPoint(point, anchor, secondaryPoint, x, y)
		end
	else
		for frameName, config in pairs(UF.Unit:GetFrameList()) do
			if not config.isChild then
				local UnitFrame = UF.Unit:Get(frameName)
				local point, anchor, secondaryPoint, x, y = strsplit(',', positionData[frameName])

				if UnitFrame.position then
					UnitFrame:position(point, anchor, secondaryPoint, x, y, false, true)
				else
					UnitFrame:ClearAllPoints()
					UnitFrame:SetPoint(point, anchor, secondaryPoint, x, y)
				end
			end
		end
	end
end

function UF:ResetSettings()
	--Reset the DB
	UF.DB.UserSettings[UF.DB.Style] = nil
	-- Trigger update
	UF:Update()
end

local function LoadDB()
	-- Load Default Settings
	UF.CurrentSettings = SUI:MergeData({}, UF.Unit.defaultConfigs)
	-- Import theme settings
	if SUI.DB.Styles[UF.DB.Style] and SUI.DB.Styles[UF.DB.Style].Frames then
		UF.CurrentSettings = SUI:MergeData(UF.CurrentSettings, SUI.DB.Styles[UF.DB.Style].Frames, true)
	elseif UF.Artwork[UF.DB.Style] then
		local skin = UF.Artwork[UF.DB.Style].skin
		UF.CurrentSettings = SUI:MergeData(UF.CurrentSettings, SUI.DB.Styles[skin].Frames, true)
	end

	-- Import player customizations
	UF.CurrentSettings = SUI:MergeData(UF.CurrentSettings, UF.DB.UserSettings[UF.DB.Style], true)

	SpartanUI.UFdefaultConfigs = UF.Unit.defaultConfigs
	SpartanUI.UFCurrentSettings = UF.CurrentSettings
end

function UF:OnInitialize()
	if SUI:IsModuleDisabled('UnitFrames') then
		return
	end

	-- Setup Database
	local defaults = {
		profile = {
			Style = 'War',
			UserSettings = {
				['**'] = {['**'] = {['**'] = {['**'] = {['**'] = {['**'] = {}}}}}}
			}
		}
	}
	UF.Database = SUI.SpartanUIDB:RegisterNamespace('UnitFrames', defaults)
	UF.DB = UF.Database.profile

	LoadDB()
end

function UF:OnEnable()
	if SUI:IsModuleDisabled('UnitFrames') then
		return
	end

	-- Spawn Frames
	UF:SpawnFrames()

	-- Put frames into their inital position
	UF:PositionFrame()

	-- Create movers
	for unit, config in pairs(UF.Unit:GetFrameList()) do
		if not config.isChild then
			MoveIt:CreateMover(UF.Unit:Get(unit), unit, nil, nil, 'Unit frames')
		end
	end

	-- Build options
	UF.Options:Initialize()

	if EditModeManagerFrame then
		-- function EditModeManagerFrame.AccountSettings.Settings.PartyFrames:ShouldEnable()
		-- 	return false
		-- end
		-- function EditModeManagerFrame.AccountSettings.Settings.ArenaFrames:ShouldEnable()
		-- 	return false
		-- end
		-- function EditModeManagerFrame.AccountSettings.Settings.RaidFrames:ShouldEnable()
		-- 	return false
		-- end

		local CheckedItems = {}
		local frames = {['boss'] = 'Boss', ['raid'] = 'Raid', ['arena'] = 'Arena', ['party'] = 'Party'}
		for k, v in pairs(frames) do
			EditModeManagerFrame.AccountSettings.Settings[v .. 'Frames'].Button:HookScript(
				'OnClick',
				function(...)
					if EditModeManagerFrame.AccountSettings.Settings[v .. 'Frames']:IsControlChecked() then
						CheckedItems[k] = v
					else
						CheckedItems[k] = nil
					end

					SUI.MoveIt:MoveIt(k)
				end
			)
		end

		EditModeManagerFrame:HookScript(
			'OnHide',
			function()
				for k, v in pairs(CheckedItems) do
					EditModeManagerFrame.AccountSettings.Settings[v .. 'Frames']:SetControlChecked(false)
					SUI.MoveIt:MoveIt(k)
				end
				MoveIt.MoverWatcher:Hide()
				MoveIt.MoveEnabled = false
			end
		)

	-- EditModeManagerFrame:HookScript(
	-- 	'OnShow',
	-- 	function()
	-- 	end
	-- )
	end
end

function UF:Update()
	-- Refresh Settings
	LoadDB()
	-- Update positions
	UF:PositionFrame()
	--Send Custom change event
	SUI.Event:SendEvent('UNITFRAME_STYLE_CHANGED')
	-- Update all display elements
	UF:UpdateAll()
end

function UF:SetActiveStyle(style)
	UF.Style:Change(style)
	UF.DB.Style = style

	-- Refersh Settings
	UF:Update()

	--Analytics
	SUI.Analytics:Set(UF, 'Style', style)
end

function UF.PostCreateAura(element, button)
	local function UpdateAura(self, elapsed)
		if (self.expiration) then
			self.expiration = math.max(self.expiration - elapsed, 0)

			if (self.expiration > 0 and self.expiration < 60) then
				self.Duration:SetFormattedText('%d', self.expiration)
			else
				self.Duration:SetText()
			end
		end
	end

	if button.SetBackdrop then
		button:SetBackdrop(nil)
		button:SetBackdropColor(0, 0, 0)
	end
	button.cd:SetReverse(true)
	button.cd:SetHideCountdownNumbers(true)
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon:SetDrawLayer('ARTWORK')
	-- button:SetScript('OnEnter', OnAuraEnter)

	-- We create a parent for aura strings so that they appear over the cooldown widget
	local StringParent = CreateFrame('Frame', nil, button)
	StringParent:SetFrameLevel(20)

	button.count:SetParent(StringParent)
	button.count:ClearAllPoints()
	button.count:SetPoint('BOTTOMRIGHT', button, 2, 1)
	button.count:SetFont(SUI:GetFontFace('UnitFrames'), select(2, button.count:GetFont()) - 3)

	local Duration = StringParent:CreateFontString(nil, 'OVERLAY')
	Duration:SetFont(SUI:GetFontFace('UnitFrames'), 11)
	Duration:SetPoint('TOPLEFT', button, 0, -1)
	button.Duration = Duration

	button:HookScript('OnUpdate', UpdateAura)
end

function UF.PostUpdateAura(element, unit, button, index)
	local _, _, _, _, duration, expiration, owner, canStealOrPurge = UnitAura(unit, index, button.filter)
	if (duration and duration > 0) then
		button.expiration = expiration - GetTime()
	else
		button.expiration = math.huge
	end

	if button.SetBackdrop then
		if (unit == 'target' and canStealOrPurge) then
			button:SetBackdropColor(0, 1 / 2, 1 / 2)
		elseif (owner ~= 'player') then
			button:SetBackdropColor(0, 0, 0)
		end
	end
end

function UF.InverseAnchor(anchor)
	if anchor == 'TOPLEFT' then
		return 'BOTTOMLEFT'
	elseif anchor == 'TOPRIGHT' then
		return 'BOTTOMRIGHT'
	elseif anchor == 'BOTTOMLEFT' then
		return 'TOPLEFT'
	elseif anchor == 'BOTTOMRIGHT' then
		return 'TOPRIGHT'
	elseif anchor == 'BOTTOM' then
		return 'TOP'
	elseif anchor == 'TOP' then
		return 'BOTTOM'
	elseif anchor == 'LEFT' then
		return 'RIGHT'
	elseif anchor == 'RIGHT' then
		return 'LEFT'
	end
end

function UF:ScaleFrames(scale)
	if SUI:IsModuleDisabled('MoveIt') then
		return
	end

	for unitName, config in pairs(UF.Unit:GetFrameList()) do
		if not config.isChild then
			local UFrame = UF.Unit:Get(unitName)
			if UFrame and UFrame.mover then
				local newScale = UFrame.mover.defaultScale * (scale + .08) -- Add .08 to use .92 (the default scale) as 1.
				UFrame:scale(newScale)
			end
		end
	end
end
