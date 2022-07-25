---@class SUI
local SUI = SUI
local _G, L, print = _G, SUI.L, SUI.print
---@class SUI_UnitFrames : AceAddon-3.0, AceEvent-3.0, AceTimer-3.0
local UF = SUI:NewModule('Component_UnitFrames')
local MoveIt = SUI:GetModule('Component_MoveIt')
SUI.UF = UF
UF.DisplayName = L['Unit frames']
UF.description = 'CORE: SUI Unitframes'
UF.Core = true
UF.CurrentSettings = {}
UF.FramePos = {
	default = {
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
}
UF.Artwork = {}

---Returns the path to the texture for the given LSM key, or the SUI default
---@param LSMKey string
---@return string
function UF:FindStatusBarTexture(LSMKey)
	local defaultTexture = 'Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2'

	return SUI.Lib.LSM:Fetch('statusbar', LSMKey, true) or defaultTexture
end

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

---@param unit UnitFrameName
function UF:PositionFrame(unit)
	local positionData = UF.FramePos.default
	-- If artwork is enabled load the art's position data if supplied
	if SUI:IsModuleEnabled('Artwork') and UF.FramePos[SUI.DB.Artwork.Style] then
		positionData = SUI:MergeData(UF.FramePos[SUI.DB.Artwork.Style], UF.FramePos.default)
	end

	if unit then
		local UnitFrame = UF.Unit.Get(unit)
		local point, anchor, secondaryPoint, x, y = strsplit(',', positionData[unit])

		if UnitFrame.position then
			UnitFrame:position(point, anchor, secondaryPoint, x, y, false, true)
		else
			UnitFrame:ClearAllPoints()
			UnitFrame:SetPoint(point, anchor, secondaryPoint, x, y)
		end
	else
		local frameList = {
			'player',
			'target',
			'targettarget',
			'pet',
			'pettarget',
			'focus',
			'focustarget'
			-- 'boss',
			-- 'party',
			-- 'raid',
			-- 'arena'
		}

		for _, frame in ipairs(frameList) do
			-- local frameName = 'SUI_UF_' .. frame
			local UnitFrame = UF.Unit.Get(frame)
			if UnitFrame then
				local point, anchor, secondaryPoint, x, y = strsplit(',', positionData[frame])

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

	for frameKey, frameData in pairs(UF.DB.UserSettings[UF.DB.Style]) do
		if frameData.artwork then
			frameData.elements.SpartanArt = frameData.artwork
			frameData.artwork = nil
		end
	end

	LoadDB()
end

function UF:OnEnable()
	if SUI:IsModuleDisabled('UnitFrames') then
		return
	end

	-- Create Party & Raid frame holder
	local GroupedFrames = {
		'party',
		'raid',
		'boss',
		'arena'
	}
	for unit, config in ipairs(UF.Unit.UnitsLoaded) do
		if config.IsGroup then
			local CurFrameOpt = UF.CurrentSettings[unit]
			local elements = CurFrameOpt.elements
			local FrameHeight = 0
			if elements.Castbar.enabled then
				FrameHeight = FrameHeight + elements.Castbar.height
			end
			if elements.Health.enabled then
				FrameHeight = FrameHeight + elements.Health.height
			end
			if elements.Power.enabled then
				FrameHeight = FrameHeight + elements.Power.height
			end
			local height = (CurFrameOpt.unitsPerColumn or 10) * (FrameHeight + (CurFrameOpt.yOffset or 0))

			local width = (CurFrameOpt.maxColumns or 4) * (CurFrameOpt.width + (CurFrameOpt.columnSpacing or 1))

			local frame = CreateFrame('Frame', 'SUI_UF_' .. unit)
			frame:Hide()
			frame:SetSize(width, height)
			UF.Unit.GroupContainer[unit] = frame
		end
	end

	-- Build options
	-- UF:InitializeOptions()

	-- Spawn Frames
	UF:SpawnFrames()

	-- Put frames into their inital position
	UF:PositionFrame()

	-- Create movers
	for unit, config in pairs(UF.Unit.UnitsLoaded) do
		if not config.IsGroup then
			MoveIt:CreateMover(UF.Unit[unit], unit, nil, nil, 'Unit frames')
		end
	end

	-- Create Party & Raid Mover
	MoveIt:CreateMover(UF.Unit.GroupContainer.party, 'Party', nil, nil, 'Unit frames')
	MoveIt:CreateMover(UF.Unit.GroupContainer.raid, 'Raid', nil, nil, 'Unit frames')
	MoveIt:CreateMover(UF.Unit.GroupContainer.boss, 'Boss', nil, nil, 'Unit frames')
	if SUI.IsRetail then
		MoveIt:CreateMover(UF.Unit.GroupContainer.arena, 'Arena', nil, nil, 'Unit frames')
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

	for unitName, _ in ipairs(UF.Unit.UnitsLoaded) do
		local UFrame = UF.Unit.Get(unitName)
		if UFrame and UFrame.mover then
			local newScale = UFrame.mover.defaultScale * (scale + .08) -- Add .08 to use .92 (the default scale) as 1.
			UF.Unit[unitName]:scale(newScale)
		end
	end
end
