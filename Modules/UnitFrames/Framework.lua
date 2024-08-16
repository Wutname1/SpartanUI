---@class SUI
local SUI = SUI
local L, MoveIt = SUI.L, SUI.MoveIt
---@class SUI.UF : SUI.Module
local UF = SUI:NewModule('Module_UnitFrames')
UF.DisplayName = L['Unit frames']
UF.description = 'CORE: SUI Unitframes'
UF.Core = true
UF.CurrentSettings = {}

---@class SUI.UF.FramePositions
local UFPositionDefaults = {
	['player'] = 'BOTTOMRIGHT,UIParent,BOTTOM,-60,250',
	['pet'] = 'RIGHT,SUI_UF_player,BOTTOMLEFT,-60,0',
	['pettarget'] = 'RIGHT,SUI_UF_pet,LEFT,0,-5',
	['target'] = 'LEFT,SUI_UF_player,RIGHT,150,0',
	['targettarget'] = 'LEFT,SUI_UF_target,BOTTOMRIGHT,4,0',
	['targettargettarget'] = 'LEFT,SUI_UF_targettarget,RIGHT,4,0',
	['focus'] = 'BOTTOMLEFT,SUI_UF_target,TOP,0,30',
	['focustarget'] = 'BOTTOMLEFT,SUI_UF_focus,BOTTOMRIGHT,5,0',
	['boss'] = 'RIGHT,UIParent,RIGHT,-9,162',
	['party'] = 'TOPLEFT,UIParent,TOPLEFT,20,-40',
	['partypet'] = 'BOTTOMRIGHT,frame,BOTTOMLEFT,-2,0',
	['partytarget'] = 'LEFT,frame,RIGHT,2,0',
	['raid'] = 'TOPLEFT,UIParent,TOPLEFT,20,-40',
	['arena'] = 'RIGHT,UIParent,RIGHT,-366,191',
}
UF.Artwork = {}
UF.MountIds = {}

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
	local defaultTexture = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\Smoothv2'
	---@diagnostic disable-next-line: return-type-mismatch
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
		'targettarget',
	}
	if SUI:IsInTable(FriendlyFrame, frameName) or frameName:match('party') or frameName:match('raid') then return true end
	return false
end

---@param unit? UnitFrameName
function UF:PositionFrame(unit)
	local positionData = UFPositionDefaults
	-- If artwork is enabled load the art's position data if supplied
	local posData = UF.Style:Get(SUI.DB.Artwork.Style).positions
	if SUI:IsModuleEnabled('Artwork') and posData then positionData = SUI:CopyData(posData, UFPositionDefaults) end

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
		for frameName, config in pairs(UF.Unit:GetBuiltFrameList()) do
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
	if SUI:IsModuleDisabled('UnitFrames') then return end

	-- Setup Database
	local defaults = {
		profile = {
			Style = 'War',
			UserSettings = {
				['**'] = { ['**'] = { ['**'] = { ['**'] = { ['**'] = { ['**'] = { ['**'] = { ['**'] = {} } } } } } } },
			},
		},
	}
	UF.Database = SUI.SpartanUIDB:RegisterNamespace('UnitFrames', defaults)
	UF.DB = UF.Database.profile

	LoadDB()

	if SUI.IsRetail then
		for _, mountID in next, C_MountJournal.GetMountIDs() do
			local _, spellID = C_MountJournal.GetMountInfoByID(mountID)
			UF.MountIds[spellID] = spellID
		end
	end
end

function UF:OnEnable()
	if SUI:IsModuleDisabled('UnitFrames') then return end

	-- Spawn Frames
	UF:SpawnFrames()

	-- Put frames into their inital position
	UF:PositionFrame()

	-- Create movers
	for unit, config in pairs(UF.Unit:GetBuiltFrameList()) do
		if not config.isChild then MoveIt:CreateMover(UF.Unit:Get(unit), unit, nil, nil, 'Unit frames') end
	end

	-- Build options
	UF.Options:Initialize()

	SUI:AddChatCommand('BuffDebug', function(args)
		local unit, spellId = strsplit(' ', args)

		if not spellId then
			print('Please specify a SpellID')
			return
		end

		if not SUI.UF.MonitoredBuffs[unit] then SUI.UF.MonitoredBuffs[unit] = {} end

		for i, v in ipairs(SUI.UF.MonitoredBuffs[unit]) do
			if v == tonumber(spellId) then
				print('Removed ' .. spellId .. ' from the list of monitored buffs')
				table.remove(SUI.UF.MonitoredBuffs[unit], i)
				return
			end
		end

		table.insert(SUI.UF.MonitoredBuffs[unit], tonumber(spellId))
		print('Added ' .. spellId .. ' to the list of monitored buffs')
	end, 'Add/Remove a spellID to the list of spells to debug')
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

---@param style string
function UF:SetActiveStyle(style)
	UF.Style:Change(style)
	UF.DB.Style = style

	-- Refersh Settings
	UF:Update()
end

---@param scale integer
function UF:ScaleFrames(scale)
	if SUI:IsModuleDisabled('MoveIt') then return end

	for unitName, config in pairs(UF.Unit:GetBuiltFrameList()) do
		if not config.isChild then
			local UFrame = UF.Unit:Get(unitName)
			if UFrame and UFrame.mover then
				local newScale = UFrame.mover.defaultScale * (scale + 0.08) -- Add .08 to use .92 (the default scale) as 1.
				UFrame:scale(newScale)
			end
		end
	end
end

SUI.UF = UF
