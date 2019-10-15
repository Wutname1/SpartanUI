local _G, SUI, L = _G, SUI, SUI.L
local module = SUI:NewModule('Component_UnitFrames', 'AceTimer-3.0', 'AceEvent-3.0')
local MoveIt = SUI:GetModule('Component_MoveIt')
module.DisplayName = L['Unit frames']
local loadstring = loadstring
local function_cache = {}
local DB
module.CurrentSettings = {}
module.FramePos = {
	default = {
		['player'] = 'BOTTOMRIGHT,UIParent,BOTTOM,-60,250',
		['pet'] = 'RIGHT,SUI_UF_player,BOTTOMLEFT,-60,0',
		['pettarget'] = 'RIGHT,SUI_UF_pet,LEFT,0,-5',
		['target'] = 'LEFT,SUI_UF_player,RIGHT,150,0',
		['targettarget'] = 'LEFT,SUI_UF_target,BOTTOMRIGHT,4,0',
		['focus'] = 'BOTTOMLEFT,SUI_UF_target,TOP,0,30',
		['focustarget'] = 'BOTTOMLEFT,SUI_UF_focus,BOTTOMRIGHT,5,0',
		['boss'] = 'TOPRIGHT,UIParent,TOPRIGHT,-50,-490',
		['party'] = 'TOPLEFT,UIParent,TOPLEFT,20,-40',
		['partypet'] = 'BOTTOMRIGHT,frame,BOTTOMLEFT,-2,0',
		['partytarget'] = 'LEFT,frame,RIGHT,2,0',
		['raid'] = 'TOPLEFT,UIParent,TOPLEFT,20,-40',
		['arena'] = 'TOPRIGHT,UIParent,TOPRIGHT,-50,-490'
	}
}
module.frames = {
	arena = {},
	boss = {},
	party = {},
	raid = {},
	containers = {}
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
	local positionData = module.FramePos.default
	-- If artwork is enabled load the art's position data if supplied
	if SUI.DB.EnabledComponents.Artwork and module.FramePos[SUI.DBMod.Artwork.Style] then
		positionData = SUI:MergeData(module.FramePos[SUI.DBMod.Artwork.Style], module.FramePos.default)
	end

	if b then
		local point, anchor, secondaryPoint, x, y = strsplit(',', positionData[b])
		module.frames[b]:ClearAllPoints()
		module.frames[b]:SetPoint(point, anchor, secondaryPoint, x, y)
	else
		local frameList = {
			'player',
			'target',
			'targettarget',
			'pet',
			'pettarget',
			'focus',
			'focustarget',
			'boss',
			'party',
			'raid',
			'arena'
		}

		for _, frame in ipairs(frameList) do
			local frameName = 'SUI_UF_' .. frame
			if _G[frameName] then
				local point, anchor, secondaryPoint, x, y = strsplit(',', positionData[frame])

				_G[frameName]:ClearAllPoints()
				_G[frameName]:SetPoint(point, anchor, secondaryPoint, x, y)
			end
		end
	end
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
	DB = SUI.DB.Unitframes
	-- Setup Database
	module:LoadDB()
end

function module:OnEnable()
	if not SUI.DB.EnabledComponents.UnitFrames then
		return
	end

	-- Create Party & Raid frame holder
	do -- Party frame
		local elements = module.CurrentSettings.party.elements
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
		local height = module.CurrentSettings.party.unitsPerColumn * (FrameHeight + module.CurrentSettings.party.yOffset)

		local width =
			module.CurrentSettings.party.maxColumns *
			(module.CurrentSettings.party.width + module.CurrentSettings.party.columnSpacing)

		local frame = CreateFrame('Frame', 'SUI_UF_party')
		frame:SetSize(width, height)
		module.frames.containers.party = frame
	end
	do -- Raid frame
		local elements = module.CurrentSettings.raid.elements
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
		local width =
			module.CurrentSettings.raid.maxColumns *
			(module.CurrentSettings.raid.width + module.CurrentSettings.raid.columnSpacing)

		local height = module.CurrentSettings.raid.unitsPerColumn * (FrameHeight + module.CurrentSettings.raid.yOffset)

		local frame = CreateFrame('Frame', 'SUI_UF_raid')
		frame:SetSize(width, height)
		module.frames.containers.raid = frame
	end

	-- Spawn Frames
	module:SpawnFrames()

	-- Put frames into their inital position
	module:PositionFrame()

	-- Create movers
	local FramesList = {
		[1] = 'pet',
		[2] = 'target',
		[3] = 'targettarget',
		[4] = 'focus',
		[5] = 'focustarget',
		[6] = 'player'
	}
	for _, b in pairs(FramesList) do
		MoveIt:CreateMover(module.frames[b], b, nil, true)
	end

	-- Create Party & Raid Mover
	MoveIt:CreateMover(module.frames.containers.party, 'Party', nil, true)
	MoveIt:CreateMover(module.frames.containers.raid, 'Raid', nil, true)

	-- Build options
	module:InitializeOptions()
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
