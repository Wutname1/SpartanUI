--[===[ File
NAME: TitanLootType.lua
DESC:
This Titan plugin will show group type and loot type in the button text.
A roll tracker is used to show rolls in party to help make passing out loot and chests.
This is a simplistic roll helper! It is NOT intended as a loot tracker!

On right-click it will show the normal Titan options.
The left-click it will depend whether the user is group leader or loot master :
  if not leader a /roll will be done.
  if leader the tracker window will pop, giving them additional options
  - Start   : Start a new roll
  - Remind  : Nag those who have not rolled with a whisper
  - Results : State the results

Once a leader initiates a roll, the tracker will pop for other Titan users who are using LootType.
:DESC
--]===]
TitanPanelLootType                 = {} -- declare name space
local LT                           = TitanPanelLootType -- save some typing...

-- ******************************** Constants *******************************
local TITAN_LOOTTYPE_ID            = "LootType";
local _G                           = getfenv(0);
local L                            = LibStub("AceLocale-3.0"):GetLocale(TITAN_ID, true)
local TitanLootMethod              = {};
local updateTable                  = { TITAN_LOOTTYPE_ID, TITAN_PANEL_UPDATE_ALL };
TitanLootMethod["freeforall"]      = { text = L["TITAN_LOOTTYPE_FREE_FOR_ALL"] };
TitanLootMethod["roundrobin"]      = { text = L["TITAN_LOOTTYPE_ROUND_ROBIN"] };
TitanLootMethod["master"]          = { text = L["TITAN_LOOTTYPE_MASTER_LOOTER"] };
TitanLootMethod["group"]           = { text = L["TITAN_LOOTTYPE_GROUP_LOOT"] };
TitanLootMethod["needbeforegreed"] = { text = L["TITAN_LOOTTYPE_NEED_BEFORE_GREED"] };
--TitanLootMethod["personalloot"] = {text = L["TITAN_LOOTTYPE_PERSONAL"]};

local TOCNAME                      = "TitanLootType"
local Track                        = {}
Track.DB = {}

-- High level constants
Track.IconDice                     = "Interface\\Buttons\\UI-GroupLoot-Dice-Up"
--Track.IconGreed= "Interface\\Buttons\\UI-GroupLoot-Coin-Up"
Track.IconPass                     = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
Track.IconLoot                     = "Interface\\GroupFrame\\UI-Group-MasterLooter"
Track.TxtEscapePicture             = "|T%s:0|t"
Track.TxtEscapeIcon                = "|T%s:0:0:0:0:64:64:4:60:4:60|t"

-- These are encoded 'messages' this addon searches for to start and end the roll process
Track.MSGPREFIX                    = "Titan LootType Roller: " -- also frame title
Track.MSGPREFIX_START              = Track.MSGPREFIX .. ">>: "
Track.MSGPREFIX_END                = Track.MSGPREFIX .. "<<: "
Track.MSGPREFIX_CLOSE              = Track.MSGPREFIX .. "__: "


-- This will be debugged real-time so put the debug on 'switches'
-- Also useful when debugging 'solo'
LT.Debug = {
	-- Used when creating dummy player list (see flags) or solo debug to get 'self'
	-- And debug output
	on    = false,

	show  = {      -- for LootDebug messages
		events = false, -- show debug for events
		players = false, -- show debug for players
		-- nil will show regardless
	},
	flags = { -- solo debug
		force_leader = false,
		force_master = false,
		force_loot_master = false,
		-- These 3 are used when creating dummy player list WITH 'on' = true
		add_players = false,
		is_raid = false,
		is_party = false,
	},
}
--[[
The commands (use WoWLua addon) below will
- set debug depending on what you want to test
- create a player list (via GetPlayerList on start roll) to play with
AND add_players is true
	is_raid will make a 40 player list...
	is_party will make a 5 player list
	if neither makes you a group of 1
- update rolls to check various errors conditions

TitanPanelLootType.Debug.on = true
TitanPanelLootType.Debug.flags.is_raid = true
TitanPanelLootType.Debug.show.players = true
TitanPanelLootType.Debug.show.events = true

TitanPanelLootType.AddAllRollsDebug()

TitanPanelLootType.AddRollDebug("raid6", "999", "1", "1000")
--]]
-- ******************************** Variables *******************************

-- ******************************** Functions *******************************
--[[ local
NAME: LootDebug
DESC: Set the Tian bars and plugins to the selected scale then adjust other frames as needed.
VAR: msg   - message to be output
VAR: mtype - the type of message
OUT: None
--]]
local function LootDebug(msg, mtype)
	local show = false
	if mtype == nil then
		show = true                   -- just show it
	elseif mtype == "events" and LT.Debug.show.events then
		show = true
	elseif mtype == "players" and LT.Debug.show.players then
		show = true
	end

	if show then
		TitanPluginDebug(TITAN_LOOTTYPE_ID, tostring(msg))
	end
end


-- Tools for the tracker
local Tool = {}
Tool.IconClassTexture = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
Tool.IconClassTextureWithoutBorder = "Interface\\WorldStateFrame\\ICONS-CLASSES"
Tool.IconClassTextureCoord = CLASS_ICON_TCOORDS
Tool.IconClass = {
	["WARRIOR"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:0:64:0:64|t",
	["MAGE"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:64:128:0:64|t",
	["ROGUE"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:128:192:0:64|t",
	["DRUID"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:192:256:0:64|t",
	["HUNTER"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:0:64:64:128|t",
	["SHAMAN"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:64:128:64:128|t",
	["PRIEST"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:128:192:64:128|t",
	["WARLOCK"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:192:256:64:128|t",
	["PALADIN"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:0:64:128:192|t",
}
Tool.IconClassBig = {
	["WARRIOR"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:0:64:0:64|t",
	["MAGE"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:64:128:0:64|t",
	["ROGUE"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:128:192:0:64|t",
	["DRUID"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:192:256:0:64|t",
	["HUNTER"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:0:64:64:128|t",
	["SHAMAN"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:64:128:64:128|t",
	["PRIEST"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:128:192:64:128|t",
	["WARLOCK"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:192:256:64:128|t",
	["PALADIN"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:0:64:128:192|t",
}

Tool.RaidIconNames = ICON_TAG_LIST
Tool.RaidIcon = {
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t", -- [1]
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t", -- [2]
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t", -- [3]
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t", -- [4]
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t", -- [5]
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t", -- [6]
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t", -- [7]
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t", -- [8]
}

Tool.Classes = CLASS_SORT_ORDER
Tool.ClassName = LOCALIZED_CLASS_NAMES_MALE
Tool.ClassColor = RAID_CLASS_COLORS

Tool.ButtonFontObj = {}
Tool.Font = ""
Tool.FontSize = ""
--[[ local
NAME: Tool.CreatePattern
DESC: Set the Tian bars and plugins to the selected scale then adjust other frames as needed.
VAR: pattern  - string to be parsed
VAR: maximize - do min or max substitution
OUT: None
--]]
function Tool.CreatePattern(pattern, maximize)
	pattern = string.gsub(pattern, "[%(%)%-%+%[%]]", "%%%1")
	if not maximize then
		pattern = string.gsub(pattern, "%%s", "(.-)")
	else
		pattern = string.gsub(pattern, "%%s", "(.+)")
	end
	pattern = string.gsub(pattern, "%%d", "%(%%d-%)")
	if not maximize then
		pattern = string.gsub(pattern, "%%%d%$s", "(.-)")
	else
		pattern = string.gsub(pattern, "%%%d%$s", "(.+)")
	end
	pattern = string.gsub(pattern, "%%%d$d", "%(%%d-%)")
	--pattern = string.gsub(pattern, "%[", "%|H%(%.%-%)%[")
	--pattern = string.gsub(pattern, "%]", "%]%|h")
	return pattern
end

--[[ local
NAME: Sizing routines
DESC: These allow the frame to be resized as needed.
OUT: None
--]]
---@class ResizeCursorType
---@field Texture? table
---@diagnostic disable-next-line: missing-fields
local ResizeCursor = {} ---@type Frame
local SizingStop = function(self, button)
	self:GetParent():StopMovingOrSizing()
	if self.GPI_DoStop then self.GPI_DoStop(self:GetParent()) end
end

local SizingStart = function(self, button)
	self:GetParent():StartSizing(self.GPI_SIZETYPE)
	if self.GPI_DoStart then self.GPI_DoStart(self:GetParent()) end
end

local SizingEnter = function(self)
	if not (GetCursorInfo()) then
		ResizeCursor:Show()
		ResizeCursor.Texture:SetTexture(self.GPI_Cursor)
-- Causes an error in 1.15.5 but not 4.4.*...
--		ResizeCursor.Texture:SetRotation(math.rad(self.GPI_Rotation), { 0.5, 0.5 })
	end
end

local SizingLeave = function(self, button)
	ResizeCursor:Hide()
end

-- Titan Loot

---@class FrameSizeBorder
---@field GPI_SIZETYPE string
---@field GPI_Cursor string
---@field GPI_Rotation string
---@field GPI_DoStart string
---@field GPI_DoStop string
local FrameSizeBorder ---@type Frame
local sizecount = 0
local CreateSizeBorder = function(frame, name, a1, x1, y1, a2, x2, y2, cursor, rot, OnStart, OnStop)
	sizecount = sizecount + 1
	FrameSizeBorder = CreateFrame("Frame", (frame:GetName() or TOCNAME .. sizecount) .. "_size_" .. name, frame)
	FrameSizeBorder:SetPoint("TOPLEFT", frame, a1, x1, y1)
	FrameSizeBorder:SetPoint("BOTTOMRIGHT", frame, a2, x2, y2)
	FrameSizeBorder.GPI_SIZETYPE = name
	FrameSizeBorder.GPI_Cursor = cursor
	FrameSizeBorder.GPI_Rotation = rot
	FrameSizeBorder.GPI_DoStart = OnStart
	FrameSizeBorder.GPI_DoStop = OnStop
	FrameSizeBorder:SetScript("OnMouseDown", SizingStart)
	FrameSizeBorder:SetScript("OnMouseUp", SizingStop)
	FrameSizeBorder:SetScript("OnEnter", SizingEnter)
	FrameSizeBorder:SetScript("OnLeave", SizingLeave)
	return FrameSizeBorder
end

local ResizeCursor_Update = function(self)
	local X, Y = GetCursorPosition()
	local Scale = self:GetEffectiveScale()
	self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", X / Scale, Y / Scale)
end

function Tool.EnableSize(frame, border, OnStart, OnStop)
	if ResizeCursor == {} then
		-- use existing frame
	else
		ResizeCursor = CreateFrame("Frame", nil, UIParent)
		ResizeCursor:Hide()
		ResizeCursor:SetWidth(24)
		ResizeCursor:SetHeight(24)
		ResizeCursor:SetFrameStrata("TOOLTIP")
		ResizeCursor.Texture = ResizeCursor:CreateTexture()
		ResizeCursor.Texture:SetAllPoints()
		ResizeCursor:SetScript("OnUpdate", ResizeCursor_Update)
	end
	border = border or 8

	frame:EnableMouse(true)
	frame:SetResizable(true)

--	path = "Interface\\AddOns\\" .. TOCNAME .. "\\Resize\\"

	CreateSizeBorder(frame, "BOTTOM", "BOTTOMLEFT", border, border, "BOTTOMRIGHT", -border, 0,
		"Interface\\CURSOR\\UI-Cursor-SizeLeft", 45, OnStart, OnStop)
	CreateSizeBorder(frame, "TOP", "TOPLEFT", border, 0, "TOPRIGHT", -border, -border,
		"Interface\\CURSOR\\UI-Cursor-SizeLeft", 45, OnStart, OnStop)
	CreateSizeBorder(frame, "LEFT", "TOPLEFT", 0, -border, "BOTTOMLEFT", border, border,
		"Interface\\CURSOR\\UI-Cursor-SizeRight", 45, OnStart, OnStop)
	CreateSizeBorder(frame, "RIGHT", "TOPRIGHT", -border, -border, "BOTTOMRIGHT", 0, border,
		"Interface\\CURSOR\\UI-Cursor-SizeRight", 45, OnStart, OnStop)

	CreateSizeBorder(frame, "TOPLEFT", "TOPLEFT", 0, 0, "TOPLEFT", border, -border,
		"Interface\\CURSOR\\UI-Cursor-SizeRight", 0, OnStart, OnStop)
	CreateSizeBorder(frame, "BOTTOMLEFT", "BOTTOMLEFT", 0, 0, "BOTTOMLEFT", border, border,
		"Interface\\CURSOR\\UI-Cursor-SizeLeft", 0, OnStart, OnStop)
	CreateSizeBorder(frame, "TOPRIGHT", "TOPRIGHT", 0, 0, "TOPRIGHT", -border, -border,
		"Interface\\CURSOR\\UI-Cursor-SizeLeft", 0, OnStart, OnStop)
	CreateSizeBorder(frame, "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0, "BOTTOMRIGHT", -border, border,
		"Interface\\CURSOR\\UI-Cursor-SizeRight", 0, OnStart, OnStop)
end

--[[ local
NAME: Moving routines
DESC: These allow the frame to be moved as needed.
OUT: None
--]]
local function MovingStart(self)
	self:StartMoving()
end

local function MovingStop(self)
	self:StopMovingOrSizing()
	if self._GPIPRIVAT_MovingStopCallback then
		self._GPIPRIVAT_MovingStopCallback(self)
	end
end

function Tool.EnableMoving(frame, callback)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", MovingStart)
	frame:SetScript("OnDragStop", MovingStop)
	frame._GPIPRIVAT_MovingStopCallback = callback
end

function Tool.SetButtonFont(button)
	-- Just Return. This changed WAY too much...
end

--[[ local
NAME: Tool routines
DESC: Such as split, color, combine.
OUT: None
--]]
function Tool.Split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		if tContains(t, str) == false then
			table.insert(t, str)
		end
	end
	return t
end

function Tool.RGBtoEscape(r, g, b, a)
	if type(r) == "table" then
		a = r.a
		g = r.g
		b = r.b
		r = r.r
	end

	r = r ~= nil and r <= 1 and r >= 0 and r or 1
	g = g ~= nil and g <= 1 and g >= 0 and g or 1
	b = b ~= nil and b <= 1 and b >= 0 and b or 1
	a = a ~= nil and a <= 1 and a >= 0 and a or 1
	return string.format("|c%02x%02x%02x%02x", a * 255, r * 255, g * 255, b * 255)
	--	return ""
end

function Tool.Combine(t, sep, first, last)
	if type(t) ~= "table" then return "" end
	sep = sep or " "
	first = first or 1
	last = last or #t

	local ret = ""
	for i = first, last do
		ret = ret .. sep .. tostring(t[i])
	end
	return string.sub(ret, string.len(sep) + 1)
end

-- Routines for the 'track' rolls feature
--[[ local
NAME: IsRoll
DESC: Determine if the roll is valid.
VAR: roll - string
VAR: low  - low end
VAR: high - high end
OUT: valid_roll - true / false
OUT: valid_bounds - true / false
OUT: ro - numeric roll
OUT: lo - numeric low
OUT: hi - numeric high
--]]
local function IsRoll(roll, low, high)
	local lo = tonumber(low)
	local hi = tonumber(high)
	local ro = tonumber(roll)

	local valid_roll = false
	local valid_bounds = false

	if (lo == 1 and hi == 100) then
		valid_bounds = true
	end
	if (ro >= 0) and (ro <= 100) then -- allows a pass as valid
		valid_roll = true
	end

	if valid_bounds then
		-- all is good
	else
		-- for now roll is invalid, treat as a pass
		valid_roll = false
		ro = 0
	end

	local str = " >>"
		.. " vr'" .. tostring(valid_roll) .. "'"
		.. " vb'" .. tostring(valid_bounds) .. "'"
		.. " r'" .. tostring(ro) .. "'"
		.. " l'" .. tostring(lo) .. "'"
		.. " h'" .. tostring(hi) .. "'"
	LootDebug(str, "players")

	return valid_roll, valid_bounds, ro, lo, hi
end
--[[ local
NAME: GetPlayer
DESC: Get name, class, guild rank (if in same guild) a the given player.
VAR: id - id of player
OUT: name - name of the player
OUT: rank - guild rank
OUT: englishClass - English class name
--]]
local function GetPlayer(id)
	local name = GetUnitName(id)
	local localizedClass, englishClass, classIndex = UnitClass(id)

	local rank = ""
	if IsInGuild() and UnitIsInMyGuild(id) then
		rank = "<" .. GuildControlGetRankName(C_GuildInfo.GetGuildRankOrder(UnitGUID(id))) .. ">"
	else
		local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo(id)
		if guildName and guildRankName then
			rank = "<" .. guildName .. " / " .. guildRankName .. ">"
		end
	end

	return name, rank, englishClass
end
--[[ local
NAME: IsLead
DESC: Determine whether the player is the leader of the group.
VAR: None
OUT: true / false
--]]
local function IsLead()
	--[[
lootmethod, masterlooterPartyID, masterlooterRaidID = GetLootMethod()
lootmethod
String (LootMethod) - One of 'freeforall', 'roundrobin', 'master', 'group', 'needbeforegreed'. Appears to be 'freeforall' if you are not grouped.: At least as of 7.3 the possible return values appear to be "freeforall", "master", "group" and "personalloot". "roundrobin" and "needbeforegreed" appear to be deprecated.
masterlooterPartyID
Number - Returns 0 if player is the mater looter, 1-4 if party member is master looter (corresponding to party1-4) and nil if the master looter isn't in the player's party or master looting is not used.
masterlooterRaidID
Number - Returns index of the master looter in the raid (corresponding to a raidX unit), or nil if the player is not in a raid or master looting is not used.

raidIndex = UnitInRaid("unit")
raidIndex of "unit" if he is in your raid group, otherwise nil.

isTrue = UnitInParty("arg1")
inGroup = IsInGroup([groupType])

isTrue = UnitIsGroupLeader("unit"[, groupType])
isLeader = IsRaidLeader()

isLeader = UnitIsGroupLeader("unit" or "player name") -- may need in later patches?
--]]
	--[[
	if IsInRaid() and IsRaidLeader() then
		return true
	end
	if IsInGroup() and UnitIsGroupLeader("player") then
		return true
	end
--]]
	if UnitIsGroupLeader("player") then
		return true
	end
	-- The way this flows is both leader AND master looter will have the extra buttons
	local lootmethod, masterlooterPartyID, masterlooterRaidID = GetLootMethod()
	if lootmethod == "master" then
		if IsInRaid() and (masterlooterRaidID == UnitInRaid("player")) then
			return true
		end
		if IsInGroup() and (masterlooterPartyID == UnitInParty("player")) then
			return true
		end
	end
	if LT.Debug.flags.force_leader then
		return true
	end
	if LT.Debug.flags.force_master then
		return true
	end
	return false
end

--[[ local
NAME: Track.GetPlayerList
DESC: Collect name, class, and guild rank (if in same guild) of players in the group.
This routine will generate group lists (5 or 40) for debug based on debug flags.
:DESC
VAR: unsort		- if true sort by class then name
OUT: ret		- indexed table of players in  the group
OUT: retName	- table of player names pointing into ret
--]]
local function OutPlayer(player)
	if LT.Debug.on then --
		if player then
			TitanPluginDebug(TITAN_LOOTTYPE_ID, "GetPlayerList:"
				.. " p'" .. (player.name or "nyl") .. "'"
				.. " r'" .. (player.rank or "nyl") .. "'"
				.. " c'" .. (player.class or "nyl") .. "'"
			)
		end
	end
end
function Track.GetPlayerList(unsort)
	local count, start
	local prefix
	local ret = {}
	local retName = {}

	if IsInRaid() or LT.Debug.flags.is_raid then
		prefix = "raid"
		count = MAX_RAID_MEMBERS
		start = 1
	elseif IsInGroup() or LT.Debug.flags.is_group then
		prefix = "party"
		count = MAX_PARTY_MEMBERS
		start = 0
	else
		prefix = "solo"
		count = 0
		start = 0
	end

	if LT.Debug.on then -- safety...
		if LT.Debug.flags.add_players then
			-- player list has already been created, just return
		elseif prefix == "solo" then
			local name, rank, englishClass = GetPlayer("player")
			if name ~= nil then
				local entry = {
					["name"] = name,
					["rank"] = rank,
					["class"] = englishClass,
				}
				tinsert(ret, entry)
				retName[name] = entry
			end
		else
			local class = 0
			for index = start, count do
				local guildName, guildRankName, guildRankIndex, realm
				local id
				if index > 0 then
					id = prefix .. index
					if class >= 9 then
						class = 1
					else
						class = class + 1
					end
				else
					id = "player"
				end
				-- handle name and class
				local name = id
				local localizedClass, englishClass, classIndex
				if index == 0 then -- get the real player info
					localizedClass, englishClass, classIndex = UnitClass(id)
				elseif class == 1 then
					englishClass = "WARRIOR"
				elseif class == 2 then
					englishClass = "PALADIN"
				elseif class == 3 then
					englishClass = "HUNTER"
				elseif class == 4 then
					englishClass = "ROGUE"
				elseif class == 5 then
					englishClass = "PRIEST"
				elseif class == 6 then
					englishClass = "MAGE"
				elseif class == 7 then
					englishClass = "WARLOCK"
				elseif class == 8 then
					englishClass = "DRUID"
				elseif class == 9 then
					englishClass = "WARRIOR"
				end

				-- Guild section assume this works... :)
				local rank = ""

				if name ~= nil then
					local entry = {
						["name"] = name,
						["rank"] = rank,
						["class"] = englishClass,
					}
					tinsert(ret, entry)
					retName[name] = entry
					OutPlayer(entry)
				end
			end
		end
	else
		-- normal operation
		for index = start, count do
			local guildName, guildRankName, guildRankIndex, realm
			local id
			if index > 0 then
				id = prefix .. index
			else
				id = "player"
			end
			if UnitInParty(id) then
				local name, rank, englishClass = GetPlayer(id)

				if name ~= nil then
					local entry = {
						["name"] = name,
						["rank"] = rank,
						["class"] = englishClass,
					}
					tinsert(ret, entry)
					retName[name] = entry
					OutPlayer(entry)
				end
			end
		end
	end

	if unsort then
		sort(ret, function(a, b) return (a.class < b.class or (a.class == b.class and a.name < b.name)) end)
	end

	return ret, retName
end

--[[ local
NAME: Track.GetAutoChannel
DESC: Select the channel type depending on the  type of group the player is in.
:DESC
VAR: None
OUT: channel - String for SendChatMessage
--]]
function Track.GetAutoChannel()
	-- Return an appropriate channel in order of preference: /raid, /p, /s
	local channel
	if IsInRaid() then
		channel = "RAID"
	elseif IsInGroup() then
		channel = "PARTY"
	else
		channel = "SAY"
	end
	return channel
end

--[[ local
NAME: Track.AddChat
DESC: Send the message to the channel type depending on the type of group the player is in.
:DESC
VAR: msg - string message to send
OUT: None
--]]
function Track.AddChat(msg)
	if msg ~= nil and msg ~= "" then
		if IsInGroup() or IsInRaid() then
			SendChatMessage(msg, Track.GetAutoChannel())
		else
			DEFAULT_CHAT_FRAME:AddMessage(msg, Track.DB.ColorChat.r, Track.DB.ColorChat.g, Track.DB.ColorChat.b,
				Track.DB.ColorChat.a)
		end
	end
end

--[[ local
NAME: Track.SaveAnchors
DESC: Save where the window is and its size.
:DESC
VAR: None
OUT: None
--]]
function Track.SaveAnchors()
	Track.DB.X = TitanPanelLootTypeMainWindow:GetLeft()
	Track.DB.Y = TitanPanelLootTypeMainWindow:GetTop()
	Track.DB.Width = TitanPanelLootTypeMainWindow:GetWidth()
	Track.DB.Height = TitanPanelLootTypeMainWindow:GetHeight()
end

--[[ local
NAME: Track.ShowWindow
DESC:
- Enable buttons
- Show window
- Update the player list with any rolls
:DESC
VAR: None
OUT: None
--]]
function Track.ShowWindow()
	if IsLead() then
		TitanPanelLootTypeFrameClearButton:Enable()
		TitanPanelLootTypeFrameAnnounceButton:Enable()
		TitanPanelLootTypeFrameNotRolledButton:Enable()
	else
		TitanPanelLootTypeFrameClearButton:Disable()
		TitanPanelLootTypeFrameAnnounceButton:Disable()
		TitanPanelLootTypeFrameNotRolledButton:Disable()
	end
	TitanPanelLootTypeMainWindow:Show()
	Track.UpdateRollList()
end

--[[ local
NAME: Track.ResetWindow
DESC:
- Reset window to default position and size
:DESC
VAR: None
OUT: None
--]]
function Track.ResetWindow()
	TitanPanelLootTypeMainWindow:ClearAllPoints()
	TitanPanelLootTypeMainWindow:SetPoint("Center", UIParent, "Center", 0, 0)
	TitanPanelLootTypeMainWindow:SetWidth(200)
	TitanPanelLootTypeMainWindow:SetHeight(200)
	Track.SaveAnchors()
	Track.ShowWindow()
end

--[[ local
NAME: Track.HideWindow
DESC:
- Hide the main tracker window
:DESC
VAR: None
OUT: None
--]]
function Track.HideWindow()
	TitanPanelLootTypeMainWindow:Hide()
end

--[[ local
NAME: Track.Init
DESC:
- Initialize variables
- Get last position and size of main frame
- Register for needed events
:DESC
VAR: None
OUT: None
--]]
function Track.Init()
	-- Add color
	Track.DB.ColorChat     = { a = 1, r = 1, g = 1, b = 1 }
	Track.DB.ColorNormal   = { a = 1, r = 1, g = 1, b = 1 }
	Track.DB.ColorCheat    = { a = 1, r = 1, g = .8, b = .8 }
	Track.DB.ColorGuild    = { a = 1, r = .2, g = 1, b = .2 }
	Track.DB.ColorInfo     = { a = 1, r = .6, g = .6, b = .6 }
	Track.DB.ColorScroll   = { a = 1, r = .8, g = .8, b = .8 }

	-- For now, hard code some options
	Track.DB.ClearOnStart  = true
	Track.DB.OpenOnStart   = true
	Track.DB.ShowNotRolled = true
	Track.DB.ShowGuildRank = true

	Track.DB.tie_breaker   = 0

	Track.rollArray        = {}
	Track.rollNames        = {}

	Track.allRolled        = false

	--	TitanPanelLootTypeMainWindow:SetMinResize(194,170)
	TitanPanelLootTypeMainWindow:SetResizeBounds(225, 250, 225, 250)
	local x, y, w, h = Track.DB.X, Track.DB.Y, Track.DB.Width, Track.DB.Height
	if not x or not y or not w or not h then
		Track.SaveAnchors()
	else
		TitanPanelLootTypeMainWindow:ClearAllPoints()
		TitanPanelLootTypeMainWindow:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
		TitanPanelLootTypeMainWindow:SetWidth(w)
		TitanPanelLootTypeMainWindow:SetHeight(h)
	end

	-- using strings from GlobalStrings.lua
	Track.PatternRoll = Tool.CreatePattern(RANDOM_ROLL_RESULT)

	local media = LibStub("LibSharedMedia-3.0")
	local newfont = media:Fetch("font", TitanPanelGetVar("FontName"))
	Tool.Font = newfont
	Tool.FontSize = TitanPanelGetVar("FontSize")

	--	TitanPanelLootTypeMainWindowTitle:SetFont(Tool.Font, Tool.FontSize)
	TitanPanelLootTypeMainWindowTitle:SetText(
		string.format(Track.TxtEscapePicture, Track.IconDice)
		.. " " .. Track.MSGPREFIX
	)
	Tool.SetButtonFont(TitanPanelLootTypeFrameRollButton) -- sets all buttons...

	TitanPanelLootTypeFrameRollButton:SetText(string.format(Track.TxtEscapePicture, Track.IconDice) ..
	L["TITAN_LOOTTYPE_TRACKER_BTNROLL"])
	TitanPanelLootTypeFramePassButton:SetText(string.format(Track.TxtEscapePicture, Track.IconPass) ..
	L["TITAN_LOOTTYPE_TRACKER_BTNPASS"])

	TitanPanelLootTypeFrameAnnounceButton:SetText(L["TITAN_LOOTTYPE_TRACKER_BTNANNOUNCE"])
	TitanPanelLootTypeFrameNotRolledButton:SetText(L["TITAN_LOOTTYPE_TRACKER_BTNNOTROLLED"])
	TitanPanelLootType.ResizeButtons()
	TitanPanelLootTypeFrameClearButton:SetText(L["TITAN_LOOTTYPE_TRACKER_BTNCLEAR"])

	Tool.EnableSize(TitanPanelLootTypeMainWindow, 8, nil, Track.SaveAnchors)
	Tool.EnableMoving(TitanPanelLootTypeMainWindow, Track.SaveAnchors)
	TitanPanelLootTypeFrame:Show()

	local str = ".Init"
		.. " register for events"
	LootDebug(str, "events")
	-- Should be ready for events we are interested in
	TitanPanelLootTypeButton:RegisterEvent("CHAT_MSG_SYSTEM", TitanPanelLootTypeButton_OnEvent)

	TitanPanelLootTypeButton:RegisterEvent("CHAT_MSG_PARTY", TitanPanelLootTypeButton_OnEvent)
	TitanPanelLootTypeButton:RegisterEvent("CHAT_MSG_PARTY_LEADER", TitanPanelLootTypeButton_OnEvent)
	TitanPanelLootTypeButton:RegisterEvent("CHAT_MSG_RAID", TitanPanelLootTypeButton_OnEvent)
	TitanPanelLootTypeButton:RegisterEvent("CHAT_MSG_RAID_LEADER", TitanPanelLootTypeButton_OnEvent)
end

--[[ local
NAME: Track.Close
DESC:
- Stop the
- Get last position and size of main frame
- Register for needed events
:DESC
VAR: None
OUT: None
--]]
function Track.Close()
	Track.DB.RollInProcess = false
	Track.HideWindow()
	if Track.DB.ClearOnClose then
		Track.ClearRolls()
	end
end

--[[ local
NAME: Track.Event_CHAT_MSG_SYSTEM
DESC:
- Monitor system chat for player rolls; add the roll when one is found
:DESC
VAR: arg1 - the message sent
OUT: None
--]]
function Track.Event_CHAT_MSG_SYSTEM(arg1)
	local str = "Event_CHAT_MSG_SYSTEM"
		.. " m'" .. tostring(arg1) .. "'"
	LootDebug(str, "events")

	if Track.DB.RollInProcess then
		for name, roll, low, high in string.gmatch(arg1, Track.PatternRoll) do
			--print(".."..name.." "..roll.." "..low.." "..high)		
			Track.AddRoll(name, roll, low, high)
		end
	end
end

--[[ local
NAME: Track.Event_Generic_CHAT_MSG
DESC:
- Monitor general chat for:
- a pass ('pass' or localized version)
- Roll start
- Roll end
:DESC
VAR: msg - the message sent
VAR: name - player that sent the message
OUT: None
--]]
function Track.Event_Generic_CHAT_MSG(msg, name)
	local str = "Event_Generic_CHAT_MSG"
		.. " '" .. tostring(name) .. "'"
		.. " m'" .. tostring(msg) .. "'"
	LootDebug(str, "events")

	-- prevent 'random' rolls from popping windows
	if Track.DB.RollInProcess then
		if msg == L["TITAN_LOOTTYPE_TRACKER_TEXTPASS"] or msg == "pass" then
			name = Tool.Split(name, "-")[1]
			Track.AddRoll(name, "0", "1", "100")
		end
	end

	-- Assume a 'leader' requested a roll so pop the window
	if string.sub(msg, 1, string.len(Track.MSGPREFIX_START)) == Track.MSGPREFIX_START then
		Track.DB.RollInProcess = true
		if Track.DB.ClearOnStart then
			Track.ClearRolls()
		end
		if Track.DB.OpenOnStart then
			Track.ShowWindow()
		end
	end
	-- Check for the 'end' of the roll
	if string.sub(msg, 1, string.len(Track.MSGPREFIX_END)) == Track.MSGPREFIX_END then
		Track.DB.RollInProcess = false
		if Track.DB.ClearOnStart then
			Track.ClearRolls()
		end
	end
	-- Check for the 'close' of the roll
	if string.sub(msg, 1, string.len(Track.MSGPREFIX_CLOSE)) == Track.MSGPREFIX_CLOSE then
		Track.Close()
	end
end

--[[ local
NAME: Track.AddRoll
DESC:
Process the roll the player made
- A pass has a roll of "0"
- Only the first roll is marked as valid / invalid
- The number of rolls is saved (Count)
- A running number (tie_breaker) is added to ensure the first arrived of a tie wins; stored in Place
- Always show the main frame to ensure it pops, no harm if already shown
:DESC
VAR: name - player that sent the roll
VAR: roll - player roll - string
VAR: low - low value player used - string
VAR: high - high player used - string
OUT: None
--]]
function Track.AddRoll(name, roll, low, high)
	local act = "nyl"
	local valid = false

	local valid_ro, valid_bounds, ro, lo, hi = IsRoll(roll, low, high)             -- numeric
	if Track.rollNames[name] == nil then
		Track.DB.tie_breaker = Track.DB.tie_breaker + 1                            -- only count the first roll for each player
		act = "insert"
		Track.rollNames[name] = Track.rollNames[name] and Track.rollNames[name] + 1 or 1 -- mark player as having rolled
		table.insert(Track.rollArray, {
			Name = name,
			Roll = ro,
			Low = lo,
			High = hi,
			Count = Track.rollNames[name],
			Place = Track.DB.tie_breaker,
			Valid_roll = valid_ro,
			Valid_bounds = valid_bounds,
		})
		local str = "AddRoll >>"
			.. " '" .. tostring(act) .. "'"
			.. " '" .. tostring(name) .. "'"
			.. " r'" .. tostring(roll) .. "'"
			.. " l'" .. tostring(low) .. "'"
			.. " h'" .. tostring(high) .. "'"
			.. " #'" .. tostring(Track.rollNames[name]) .. "'"
		LootDebug(str, "players")
	else
		-- check for re-rolls. >1 if rolled before
		act = "update"
		Track.rollNames[name] = Track.rollNames[name] and Track.rollNames[name] + 1 or
		1                                                                          -- mark player as having rolled again
		for i, p in ipairs(Track.rollArray) do
			if p.Name == name then
				-- Only first roll is valid, Ignore additional rolls but count them for display
				p.Count = Track.rollNames[name]
				local str = "AddRoll >>"
					.. " '" .. tostring(act) .. "'"
					.. " '" .. tostring(name) .. "'"
					.. " r'" .. tostring(roll) .. "'"
					.. " l*'" .. tostring(low) .. "'"
					.. " h*'" .. tostring(high) .. "'"
					.. " #*'" .. tostring(Track.rollNames[name]) .. "'"
				LootDebug(str, "players")
			end
		end
	end
	Track.ShowWindow()
end

--[[ local
NAME: Track.SortRolls
DESC:
Sort ascending by name then place
:DESC
VAR: a - player a roll info
VAR: b - player b roll info
OUT: true / false
--]]
function Track.SortRolls(a, b)
	--	return a.Roll < b.Roll
	if a.Roll ~= b.Roll then
		return a.Roll < b.Roll
	elseif a.Roll == b.Roll then
		return a.Place > b.Place
	end
end

--[[ local
NAME: Track.SortRollsRev
DESC:
Sort descending by name then place
:DESC
VAR: a - player a roll info
VAR: b - player b roll info
OUT: true / false
--]]
function Track.SortRollsRev(a, b)
	--	return a.Roll > b.Roll
	if a.Roll ~= b.Roll then
		return a.Roll > b.Roll
	elseif a.Roll == b.Roll then
		return a.Place < b.Place
	end
end

--[[ local
NAME: Track.FormatRollText
DESC:
Format the given roll for display
:DESC
VAR: roll - numeric
VAR: party - player list
VAR: partyName - given player list entry
OUT: String to use
--]]
function Track.FormatRollText(roll, party, partyName)
	local colorTied = Tool.RGBtoEscape(Track.DB.ColorNormal)
	local colorCheat = ((roll.Low ~= 1 or roll.High ~= 100)
		or (roll.Count > 1)) and Tool.RGBtoEscape(Track.DB.ColorCheat) or colorTied
	local txtRange = (not roll.Valid_bounds) and format(" (%d-%d)", roll.Low, roll.High) or ""

	local colorName
	local iconClass
	local colorRank = Tool.RGBtoEscape(Track.DB.ColorGuild)
	local rank = ""

	if partyName[roll.Name] and partyName[roll.Name].class then
		colorName = "|c" .. RAID_CLASS_COLORS[partyName[roll.Name].class].colorStr
		iconClass = Tool.IconClass[partyName[roll.Name].class]
	end
	if colorName == nil or Track.DB.ColorName == false then colorName = colorCheat end
	if iconClass == nil or Track.DB.ShowClassIcon == false then iconClass = "" end
	if Track.DB.ColorName == false then colorRank = colorCheat end

	if Track.DB.ShowGuildRank and partyName[roll.Name] and partyName[roll.Name].rank then
		rank = " " .. partyName[roll.Name].rank
	end

	local txtCount = roll.Count > 1 and format(" [%d]", roll.Count) or ""

	return "|Hplayer:" .. roll.Name .. "|h" ..
		string.format("%3d", roll.Roll) .. ": " ..
		iconClass .. colorName .. roll.Name .. colorRank .. rank .. "|r " ..
		colorCheat .. txtRange .. "|r " ..
		colorCheat .. txtCount .. "|h" ..
		--			colorCheat..roll.Place.."|h"..
		"\n"
end

--[[ local
NAME: Track.UpdateRollList
DESC:
Create the player list for display including rolls, 'cheats', guild rank (if in same guild)
Rolls are above the line; no rolls yet are below the line
:DESC
VAR: None
OUT: None
--]]
function Track.UpdateRollList()
	local rollText = ""

	local party, partyName = Track.GetPlayerList()

	table.sort(Track.rollArray, Track.SortRolls)

	-- format and print rolls, check for ties
	for i, roll in pairs(Track.rollArray) do
		rollText = Track.FormatRollText(roll, party, partyName) .. rollText
	end

	--if IsInGroup() or IsInRaid() then
	rollText = rollText .. Tool.RGBtoEscape(Track.DB.ColorInfo) .. L["TITAN_LOOTTYPE_TRACKER_TXTLINE"] .. "\n"
	local gtxt = Tool.RGBtoEscape(Track.DB.ColorInfo)
	local missClasses = {}
	Track.allRolled = true
	for i, p in ipairs(party) do
		if Track.rollNames[p.name] == nil or Track.rollNames[p.name] == 0 then
			local iconClass = Tool.IconClass[partyName[p.name].class]
			local rank = ""
			if iconClass == nil or Track.DB.ShowClassIcon == false then
				iconClass = ""
			else
				missClasses[partyName[p.name].class] = missClasses[partyName[p.name].class] and
				missClasses[partyName[p.name].class] + 1 or 1
			end
			if Track.DB.ShowGuildRank and partyName[p.name] and partyName[p.name].rank then
				rank = " " .. partyName[p.name].rank
			end
			gtxt = gtxt .. "|Hplayer:" .. p.name .. "|h" .. iconClass .. p.name .. rank .. "|h\n"
			Track.allRolled = false
		end
	end

	local ctxt = ""
	if IsInRaid() then
		local isHorde = (UnitFactionGroup("player")) == "Horde"
		for i, class in pairs(Tool.Classes) do
			--for class,count in pairs(missClasses) do
			if not (isHorde and class == "PALADIN") and not (not isHorde and class == "SHAMAN") then
				ctxt = ctxt .. Tool.IconClass[class] .. (missClasses[class] or 0) .. " "
			end
		end
		if ctxt ~= "" then ctxt = ctxt .. "\n" .. L["TxtLine"] .. "\n" end
	end
	if LT.Debug.on then --
		TitanPluginDebug(TITAN_LOOTTYPE_ID, "UpdateRollList"
			.. " '" .. (rollText or "nyl") .. "'"
			.. " '" .. (ctxt or "nyl") .. "'"
			.. " '" .. (gtxt or "nyl") .. "'"
		)
	end

	rollText = rollText .. ctxt .. gtxt
	LootDebug(rollText, "rolls")

	--end

	--	RollTrackerRollText:SetFont(Tool.Font, Tool.FontSize)
	RollTrackerRollText:SetText(rollText)

	--	TitanPanelLootTypeFrameStatusText:SetFont(Tool.Font, Tool.FontSize)
	TitanPanelLootTypeFrameStatusText:SetText(string.format(L["TITAN_LOOTTYPE_TRACKER_MSGNBROLLS"],
		#Track.rollArray))

	--	TitanPanelLootTypeFrameClearButton:SetFont(Tool.Font, Tool.FontSize)
	TitanPanelLootTypeFrameClearButton:SetText(L["TITAN_LOOTTYPE_TRACKER_BTNCLEAR"])
end

--[[ local
NAME: Track.ClearRolls
DESC:
Clear the player list of any rolls rolls
:DESC
VAR: None
OUT: None
--]]
function Track.ClearRolls()
	if #Track.rollArray > 0 then
		Track.rollArray = {}
		Track.rollNames = {}
	end

	Track.DB.tie_breaker = 0
	Track.UpdateRollList()
end

--[[ local
NAME: Track.NotRolled
DESC:
- Send a nag message via whisper to players who have not rolled
- Send a message to group that reminders were sent
- Only an IsLead can do this!
:DESC
VAR: None
OUT: None
--]]
function Track.NotRolled()
	if IsLead() then
		local party, partyName = Track.GetPlayerList()
		local names = ""

		local group = ""
		if IsInRaid() then
			group = L["TITAN_LOOTTYPE_TRACKER_RAIDPASS"]
		elseif IsInGroup() then
			group = L["TITAN_LOOTTYPE_TRACKER_PARTYPASS"]
		else
			group = ""
		end

		for i, p in ipairs(party) do
			if Track.rollNames[p.name] == nil or Track.rollNames[p.name] == 0 then
				SendChatMessage(Track.MSGPREFIX .. L["TITAN_LOOTTYPE_TRACKER_NOTROLLEDNAG"] .. group, WHISPER, nil,
					p.name)
				names = "send"
			end
		end

		if names == "send" then
			Track.AddChat(Track.MSGPREFIX .. L["TITAN_LOOTTYPE_TRACKER_MSGNOTROLLED"])
		end
	end
end

--[[ local
NAME: Track.StartRoll
DESC:
- Pop the main frame
- Clear all rolls for a new set
- Start a new roll process
- Send a message to the group of a new roll
- Only an IsLead can do this!
:DESC
VAR: None
OUT: None
--]]
function Track.StartRoll()
	Track.ShowWindow()
	Track.ClearRolls()
	Track.DB.RollInProcess = true
	Track.AddChat(Track.MSGPREFIX_START ..
	"{circle} " .. string.format(L["TITAN_LOOTTYPE_TRACKER_MSGSTART"], L["TITAN_LOOTTYPE_TRACKER_TEXTPASS"]))
	Track.AddChat(L["TITAN_LOOTTYPE_TRACKER_MSGBAR"])
end

--[[ local
NAME: Track.RollAnnounce
DESC:
- Send a message to the group of the winner
- Stop the roll process so new rolls are not processed
- Only an IsLead can do this!
:DESC
VAR: None
OUT: None
--]]
function Track.RollAnnounce()
	local winName = ""
	local winRoll = 0
	local addPrefix = ""
	local msg = ""
	local list = {}

	table.sort(Track.rollArray, Track.SortRollsRev)

	for i, roll in pairs(Track.rollArray) do
		local str = "AddRoll >>"
			.. " '" .. roll.Name .. "'"
			.. " r'" .. tostring(roll.Roll) .. "'"
		LootDebug(str, "players")
		if roll.Valid_roll then
			winName = roll.Name
			winRoll = roll.Roll
			break -- sort breaks ties, grab first one
		end
	end

	if winName == "" then
		msg = Track.MSGPREFIX_END .. addPrefix .. "{circle} No winners"
	else
		msg = Track.MSGPREFIX_END ..
		addPrefix .. "{circle} " .. string.format(L["TITAN_LOOTTYPE_TRACKER_MSGANNOUNCE"], winName, winRoll)
	end

	Track.AddChat(msg)

	Track.DB.RollInProcess = false
end

--[[ TitanPanelLootType
NAME: TitanPanelLootType.ResizeButtons
DESC: Determine the size of the buttons so they fill the line on the main frame.
VAR: None
OUT: None
--]]
function TitanPanelLootType.ResizeButtons()
	local w = TitanPanelLootTypeFrameHelperButton:GetWidth()
	TitanPanelLootTypeFrameRollButton:SetWidth(w / 2)
	TitanPanelLootTypeFramePassButton:SetWidth(w / 2)

	if Track.DB.ShowNotRolled then
		TitanPanelLootTypeFrameAnnounceButton:SetWidth(w / 3)
		TitanPanelLootTypeFrameClearButton:SetWidth(w / 3)
		TitanPanelLootTypeFrameNotRolledButton:Show()
	else
		TitanPanelLootTypeFrameAnnounceButton:SetWidth(w / 2)
		TitanPanelLootTypeFrameClearButton:SetWidth(w / 2)
		TitanPanelLootTypeFrameNotRolledButton:Hide()
	end
end

--[[ TitanPanelLootType
NAME: TitanPanelLootType.BtnClose
DESC: On click of the main frame 'X':
Close the main frame; clear rolls; end current roll process
VAR: None
OUT: None
--]]
function TitanPanelLootType.BtnClose()
	Track.Close()

	if IsLead() then
		Track.AddChat(Track.MSGPREFIX_CLOSE .. L["TITAN_LOOTTYPE_TRACKER_MSGCLOSING"])
	end
end

--[[ TitanPanelLootType
NAME: TitanPanelLootType.BtnRoll
DESC: On click of the main frame Roll: Send the roll to be processed
VAR: None
OUT: None
--]]
function TitanPanelLootType.BtnRoll()
	RandomRoll(1, 100)
end

--[[ TitanPanelLootType
NAME: TitanPanelLootType.BtnPass
DESC: On click of the main frame Pass: Send the pass to be processed
VAR: None
OUT: None
--]]
function TitanPanelLootType.BtnPass()
	Track.AddChat(L["TITAN_LOOTTYPE_TRACKER_TEXTPASS"])
	--[[
	Note: When in solo debug mode, this just does a /say pass
	which is NOT picked up by an event. This only monitors party & raid chat...
	--]]
end

--[[ TitanPanelLootType
NAME: TitanPanelLootType.BtnClearRolls
DESC: On click of the main frame Clear:
- Clear all rolls
- Start a new roll process
- Only an IsLead can do this!
  This handled by enable / disable of buttons when the main frame is created.
:DESC
VAR: None
OUT: None
--]]
function TitanPanelLootType.BtnClearRolls()
	if #Track.rollArray > 0 then
		Track.ClearRolls()
		if Track.DB.CloseOnClear then
			Track.HideWindow()
		end
	end
	Track.StartRoll()
end

--[[ TitanPanelLootType
NAME: TitanPanelLootType.BtnAnnounce
DESC: On click of the main frame "start":
- Start a new roll process
- Only an IsLead can do this!
  This handled by enable / disable of buttons when the main frame is created.
:DESC
VAR: None
OUT: None
--]]
function TitanPanelLootType.BtnAnnounce(button)
	Track.RollAnnounce()
	if Track.DB.ClearOnAnnounce then
		Track.ClearRolls()
	end
	if Track.DB.CloseOnAnnounce then
		Track.HideWindow()
	end
end

--[[ TitanPanelLootType
NAME: TitanPanelLootType.BtnNotRolled
DESC: On click of the main frame "remind":
- Call the routine to nag those who have not rolled
- Only an IsLead can do this!
  This handled by enable / disable of buttons when the main frame is created.
:DESC
VAR: None
OUT: None
--]]
function TitanPanelLootType.BtnNotRolled()
	Track.NotRolled()
end

-- Debug!!!
function TitanPanelLootType.AddAllRollsDebug() -- rolls for all players
	local party, partyName = Track.GetPlayerList()

	-- walk the player list, adding rolls
	for i, p in ipairs(party) do
		-- 0 (zero) allows a 'pass'
		Track.AddRoll(p.name, tostring(random(0, 100)), "1", "100")
	end
	-- Now show the results
	Track.UpdateRollList()
end

function TitanPanelLootType.AddRollDebug(...) -- single roll
	Track.AddRoll(...)
end

--[[ TitanPanelLootType
NAME: TitanPanelLootTypeButton_OnLoad
DESC: On load of this addon:
- Get Titan registry values
- Get addon saved variable values
:DESC
VAR: None
OUT: None
--]]
function TitanPanelLootTypeButton_OnLoad(self)
	self.registry = {
		id = TITAN_LOOTTYPE_ID,
		category = "Built-ins",
		version = TITAN_VERSION,
		menuText = L["TITAN_LOOTTYPE_MENU_TEXT"],
		buttonTextFunction = "TitanPanelLootTypeButton_GetButtonText",
		tooltipTitle = L["TITAN_LOOTTYPE_TOOLTIP"],
		tooltipTextFunction = "TitanPanelLootTypeButton_GetTooltipText",
		icon = "Interface\\AddOns\\TitanLootType\\TitanLootType",
		iconWidth = 16,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowRegularText = false,
			ShowColoredText = false,
			DisplayOnRightSide = true,
		},
		savedVariables = {
			ShowIcon = 1,
			ShowLabelText = 1,
			RandomRoll = 100,
			DB = {},
			DisplayOnRightSide = false,
			--			ShowDungeonDiff = false,
			--			DungeonDiffType = "AUTO",
		}
	};

	self:RegisterEvent("PLAYER_ENTERING_WORLD", TitanPanelLootTypeButton_OnEvent)
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("RAID_ROSTER_UPDATE");
	self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED");
	self:RegisterEvent("CHAT_MSG_SYSTEM");
end

--[[ TitanPanelLootType
NAME: TitanPanelLootTypeButton_OnEvent
DESC: Parse events registered to plugin and act on them
VAR: None
OUT: None
--]]
function TitanPanelLootTypeButton_OnEvent(self, event, ...)
	LootDebug(event, "events") -- could generate a lot of messages...

	if (event == "CHAT_MSG_SYSTEM") then
		Track.Event_CHAT_MSG_SYSTEM(...)
	end

	if (event == "CHAT_MSG_PARTY") then
		Track.Event_Generic_CHAT_MSG(...)
	end

	if (event == "CHAT_MSG_PARTY_LEADER") then
		Track.Event_Generic_CHAT_MSG(...)
	end

	if (event == "CHAT_MSG_RAID") then
		Track.Event_Generic_CHAT_MSG(...)
	end

	if (event == "CHAT_MSG_RAID_LEADER") then
		Track.Event_Generic_CHAT_MSG(...)
	end

	if (event == "PLAYER_ENTERING_WORLD") then
		Track.Init()
	end

	TitanPanelPluginHandle_OnUpdate(updateTable)
end

--[[ TitanPanelLootType
NAME: TitanPanelLootTypeButton_GetButtonText
DESC: Determine loot type and then display on button
VAR: None
OUT: None
--]]
function TitanPanelLootTypeButton_GetButtonText(id)
	local lootTypeText, lootThreshold, color

	--	if (GetNumSubgroupMembers() > 0) or (GetNumGroupMembers() > 0) then

	if IsInRaid() or IsInGroup() then
		lootTypeText = TitanLootMethod[GetLootMethod()].text;
		lootThreshold = GetLootThreshold();
		color = _G["ITEM_QUALITY_COLORS"][lootThreshold];
	else
		lootTypeText = _G["SOLO"];
		color = _G["GRAY_FONT_COLOR"];
	end
	return L["TITAN_LOOTTYPE_BUTTON_LABEL"], TitanUtils_GetColoredText(lootTypeText, color);
end

--[[ TitanPanelLootType
NAME: TitanPanelLootTypeButton_GetTooltipText
DESC:
Prepare the tool tip text. The tool tip is determined by whether the player is in a group or not.
:DESC
VAR: None
OUT: None
--]]
function TitanPanelLootTypeButton_GetTooltipText()
	--	if (GetNumSubgroupMembers() > 0) or (GetNumGroupMembers() > 0) then
	if IsInRaid() or IsInGroup() then
		local lootTypeText = TitanLootMethod[GetLootMethod()].text;
		local lootThreshold = GetLootThreshold();
		local itemQualityDesc = _G["ITEM_QUALITY" .. lootThreshold .. "_DESC"];
		local color = _G["ITEM_QUALITY_COLORS"][lootThreshold];
		return "" ..
			_G["LOOT_METHOD"] .. ": \t" .. TitanUtils_GetHighlightText(lootTypeText) .. "\n" ..
			_G["LOOT_THRESHOLD"] .. ": \t" .. TitanUtils_GetColoredText(itemQualityDesc, color) .. "\n" ..
			TitanUtils_GetGreenText(L["TITAN_LOOTTYPE_TOOLTIP_HINT1"]) .. "\n"
		--			..TitanUtils_GetGreenText(L["TITAN_LOOTTYPE_TOOLTIP_HINT2"])
	else
		return --TitanUtils_GetNormalText(_G["ERR_NOT_IN_GROUP"]).."\n"..
			TitanUtils_GetGreenText(L["TITAN_LOOTTYPE_TOOLTIP_HINT1"]) .. "\n"
		--			TitanUtils_GetGreenText(L["TITAN_LOOTTYPE_TOOLTIP_HINT2"]);
	end
end

--[[ TitanPanelLootType
NAME: TitanPanelRightClickMenu_PrepareLootTypeMenu
DESC:
Display rightclick menu options.
:DESC
VAR: None
OUT: None
--]]
function TitanPanelRightClickMenu_PrepareLootTypeMenu()
	local info = {};

	TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_LOOTTYPE_ID].menuText);
	info = {};
	info.notCheckable = true

	TitanPanelRightClickMenu_AddToggleIcon(TITAN_LOOTTYPE_ID);
	TitanPanelRightClickMenu_AddToggleLabelText(TITAN_LOOTTYPE_ID);
	TitanPanelRightClickMenu_AddToggleRightSide(TITAN_LOOTTYPE_ID);
	TitanPanelRightClickMenu_AddSpacer();
	TitanPanelRightClickMenu_AddCommand(L["TITAN_PANEL_MENU_HIDE"], TITAN_LOOTTYPE_ID, TITAN_PANEL_MENU_FUNC_HIDE);
end

--[[ TitanPanelLootType
NAME: TitanPanelLootTypeButton_OnClick
DESC:
On left click:
If isLead then start a new roll
If not isLead then do a roll

:DESC
VAR: None
OUT: None
--]]
function TitanPanelLootTypeButton_OnClick(self, button)
	if button == "LeftButton" then
		if IsLead() then
			TitanPanelLootType.BtnClearRolls()
		else
			RandomRoll(1, 100)
		end
	end
end
