local _G, SUI, L = _G, SUI, SUI.L
local module = SUI:NewModule('Component_UnitFrames', 'AceTimer-3.0', 'AceEvent-3.0')
module.DisplayName = L['Unit frames']

local loadstring = loadstring
local function_cache = {}

local DB = SUI.DB.Unitframes
module.CurrentSettings = {}

module.frameList = {
	'player',
	'target',
	'targettarget',
	'boss',
	'bosstarget',
	'pet',
	'pettarget',
	'focus',
	'focustarget',
	'party',
	'partypet',
	'partytarget',
	'raid',
	'arena'
}

module.frames = {
	arena = {},
	boss = {},
	party = {}
}
----------------------------------------------------------------------------------------------------
-- New Unitframe workflow
--
-- 1.  Styles are initalized and calls AddStyleSettings to pass the styles config into the unitframes module
-- 2.  A table is created with all of the settings from all the styles
-- 3.  UnitFrames OnEnable is called
-- 4.  Frames are spawned
--
-- DB is used for Player Customization. It uses the format:
-- DB.STYLE.FRAME
--
-- Styles DB Format
-- Style = {
--		id = 'MYSTYLE', -- One word, used in backend.
-- 		name = 'My Style', -- Human Readable
--		artskin = 'Artwork Skin Name',
--		FrameOptions = { Settings defined here override anything set in the default FrameOptions }
--	}
--
----------------------------------------------------------------------------------------------------

function module:IsFriendlyFrame(frameName)
	local FriendlyFrame = {
		'player',
		'pet',
		'party',
		'partypet',
		'raid',
		'target',
		'targettarget'
	}
	if SUI:isInTable(FriendlyFrame, frameName) or frameName:match('party') or frameName:match('raid') then
		return true
	end
	return false
end

function module:UpdatePosition()
	module:PositionFrame()
end

function module:TextFormat(element, frameName, textID)
	local textstyle = module.CurrentSettings[frameName].font[element].textstyle
	local textmode = module.CurrentSettings[frameName].font[element].textmode
	local a, m, t, z
	if text == 'mana' then
		z = 'pp'
	else
		z = 'hp'
	end

	-- textstyle
	-- "Long: 			 Displays all numbers."
	-- "Long Formatted: Displays all numbers with commas."
	-- "Dynamic: 		 Abbriviates and formats as needed"
	if textstyle == 'long' then
		a = '[cur' .. z .. ']'
		m = '[missing' .. z .. ']'
		t = '[max' .. z .. ']'
	elseif textstyle == 'longfor' then
		a = '[cur' .. z .. 'formatted]'
		m = '[missing' .. z .. 'formatted]'
		t = '[max' .. z .. 'formatted]'
	elseif textstyle == 'disabled' then
		return ''
	else
		a = '[cur' .. z .. 'dynamic]'
		m = '[missing' .. z .. 'dynamic]'
		t = '[max' .. z .. 'dynamic]'
	end
	-- textmode
	-- [1]="Avaliable / Total",
	-- [2]="(Missing) Avaliable / Total",
	-- [3]="(Missing) Avaliable"

	if textmode == 1 then
		return a .. ' / ' .. t
	elseif textmode == 2 then
		return '(' .. m .. ') ' .. a .. ' / ' .. t
	elseif textmode == 3 then
		return '(' .. m .. ') ' .. a
	end
end

function module:PositionFrame(b)
	--Clear Point
	if b ~= nil and module.frames[b] then
		module.frames[b]:ClearAllPoints()
	end
	--Set Position
	-- if SUI_FramesAnchor then
	-- 	if b == 'player' or b == nil then
	-- 		module.frames.player:SetPoint('BOTTOMRIGHT', SUI_FramesAnchor, 'TOPLEFT', -60, 10)
	-- 	end
	-- else
	if b == 'player' or b == nil then
		module.frames.player:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOM', -60, 250)
	end
	-- end

	if b == 'pet' or b == nil then
		module.frames.pet:SetPoint('RIGHT', module.frames.player, 'BOTTOMLEFT', -60, 0)
	end

	if b == 'target' or b == nil then
		module.frames.target:SetPoint('LEFT', module.frames.player, 'RIGHT', 150, 0)
	end
	if b == 'targettarget' or b == nil then
		module.frames.targettarget:SetPoint('LEFT', module.frames.target, 'BOTTOMRIGHT', 4, 0)
	end

	if b == 'focus' or b == nil then
		module.frames.focus:SetPoint('BOTTOMLEFT', module.frames.target, 'TOP', 0, 30)
	end
	if b == 'focustarget' or b == nil then
		module.frames.focustarget:SetPoint('BOTTOMLEFT', module.frames.focus, 'BOTTOMRIGHT', 5, 0)
	end

	local FramesList = {
		[1] = 'pet',
		[2] = 'target',
		[3] = 'targettarget',
		[4] = 'focus',
		[5] = 'focustarget',
		[6] = 'player'
	}
	for _, c in pairs(FramesList) do
		module.frames[c]:SetScale(SUI.DB.scale)
	end

	-- module:UpdateAltBarPositions()
end

function module:LoadDB()
	-- Setup an empty memory state
	module.CurrentSettings = {}
	-- Load Default Settings
	module.CurrentSettings = SUI:MergeData(module.CurrentSettings, SUI.DB.Unitframes.FrameOptions)
	-- Import theme settings
	module.CurrentSettings = SUI:MergeData(module.CurrentSettings, SUI.DB.Styles[SUI.DB.Unitframes.Style].Frames, true)
	-- Import player customizations
	module.CurrentSettings =
		SUI:MergeData(module.CurrentSettings, SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style], true)
end

function module:OnInitialize()
	--[[
		Takes a target table and injects data from the source
		override allows the source to be put into the target
		even if its already populated
		function SUI:MergeData(target, source, override)
	]]
	-- Setup Database
	module:LoadDB()
	-- Build options
	module:InitializeOptions()
end

function module:OnEnable()
	if not SUI.DB.EnabledComponents.UnitFrames then
		return
	end

	module:SpawnFrames()

	-- Add mover to standard frames
	-- for _, b in pairs(module.frameList) do
	-- 	if module.frames[b] then
	-- 		module:AddMover(module.frames[b], b)
	-- 	end
	-- end

	-- -- Party, Raid, and boss mover
	-- if module.frames.arena[1] then
	-- 	module:AddMover(FrameList.arena[1], 'arena')
	-- end
	-- if module.frames.boss[1] then
	-- 	module:AddMover(FrameList.boss[1], 'boss')
	-- end
	-- if module.frames.party[1] then
	-- 	module:AddMover(FrameList.party[1], 'party')
	-- end
	-- if FrameList.raid[1] then
	-- 	module:AddMover(frame, 'raid')
	-- end

	module:PositionFrame()
end

function module:AddMover(frame, framename)
	if frame == nil then
		SUI:Err('PlayerFrames', DB.UnitFrames.Style .. ' did not spawn ' .. framename)
	else
		frame.mover = CreateFrame('Frame')
		frame.mover:SetSize(20, 20)

		if framename == 'boss' then
			frame.mover:SetPoint('TOPLEFT', PlayerFrames.boss[1], 'TOPLEFT')
			frame.mover:SetPoint('BOTTOMRIGHT', PlayerFrames.boss[MAX_BOSS_FRAMES], 'BOTTOMRIGHT')
		elseif framename == 'arena' then
			frame.mover:SetPoint('TOPLEFT', PlayerFrames.boss[1], 'TOPLEFT')
			frame.mover:SetPoint('BOTTOMRIGHT', PlayerFrames.boss[MAX_BOSS_FRAMES], 'BOTTOMRIGHT')
		else
			frame.mover:SetPoint('TOPLEFT', frame, 'TOPLEFT')
			frame.mover:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT')
		end

		frame.mover:EnableMouse(true)
		frame.mover:SetFrameStrata('LOW')

		frame:EnableMouse(enable)
		frame:SetScript(
			'OnMouseDown',
			function(self, button)
				if button == 'LeftButton' and IsAltKeyDown() then
					frame.mover:Show()
					DB.UnitFrames[framename].moved = true
					frame:SetMovable(true)
					frame:StartMoving()
				end
			end
		)
		frame:SetScript(
			'OnMouseUp',
			function(self, button)
				frame.mover:Hide()
				frame:StopMovingOrSizing()
				local Anchors = {}
				Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = frame:GetPoint()
				Anchors.relativeTo = 'UIParent'
				for k, v in pairs(Anchors) do
					DB.UnitFrames[framename].Anchors[k] = v
				end
			end
		)

		frame.mover.bg = frame.mover:CreateTexture(nil, 'BACKGROUND')
		frame.mover.bg:SetAllPoints(frame.mover)
		frame.mover.bg:SetTexture('Interface\\BlackMarket\\BlackMarketBackground-Tile')
		frame.mover.bg:SetVertexColor(1, 1, 1, 0.5)

		frame.mover:SetScript(
			'OnEvent',
			function()
				PlayerFrames.locked = 1
				frame.mover:Hide()
			end
		)
		frame.mover:RegisterEvent('VARIABLES_LOADED')
		frame.mover:RegisterEvent('PLAYER_REGEN_DISABLED')
		frame.mover:Hide()

		--Set Position if moved
		if DB.UnitFrames[framename].moved then
			frame:SetMovable(true)
			frame:SetUserPlaced(false)
			local Anchors = {}
			for k, v in pairs(DB.UnitFrames[framename].Anchors) do
				Anchors[k] = v
			end
			frame:ClearAllPoints()
			frame:SetPoint(Anchors.point, UIParent, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
		else
			frame:SetMovable(false)
		end
	end
end

local blockedFunctions = {
	-- Lua functions that may allow breaking out of the environment
	getfenv = true,
	setfenv = true,
	loadstring = true,
	pcall = true,
	xpcall = true,
	-- blocked WoW API
	SendMail = true,
	SetTradeMoney = true,
	AddTradeMoney = true,
	PickupTradeMoney = true,
	PickupPlayerMoney = true,
	TradeFrame = true,
	MailFrame = true,
	EnumerateFrames = true,
	RunScript = true,
	AcceptTrade = true,
	SetSendMailMoney = true,
	EditMacro = true,
	SlashCmdList = true,
	DevTools_DumpCommand = true,
	hash_SlashCmdList = true,
	CreateMacro = true,
	SetBindingMacro = true,
	GuildDisband = true,
	GuildUninvite = true,
	securecall = true
}

local TestFunction = function(unit)
	return 'value'
end

local helperFunctions = {
	TestFunction = TestFunction
}

local sandbox_env =
	setmetatable(
	{},
	{
		__index = function(t, k)
			if k == '_G' then
				return t
			elseif k == 'getglobal' then
				return env_getglobal
			elseif k == 'aura_env' then
				return current_aura_env
			elseif blockedFunctions[k] then
				return forbidden
			elseif helperFunctions[k] then
				return helperFunctions[k]
			else
				return _G[k]
			end
		end
	}
)

function module.LoadFunction(string, id, trigger)
	if function_cache[string] then
		return function_cache[string]
	else
		local loadedFunction, errormsg =
			loadstring("--[[ Error in '" .. (id or 'Unknown') .. (trigger and ("':'" .. trigger) or '') .. "' ]] " .. string)
		if errormsg then
			print(errormsg)
		else
			setfenv(loadedFunction, sandbox_env)
			local success, func = pcall(assert(loadedFunction))
			if success then
				function_cache[string] = func
				return func
			end
		end
	end
end
