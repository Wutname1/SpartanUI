local
  ---@class string
  addonName,
  ---@class ns
  addon = ...
local L = addon.L
local tooltip = addon.tooltip

-- Moved blizz functions
local BNGetFriendGameAccountInfo = C_BattleNet.GetFriendGameAccountInfo;
local BNGetFriendInfo = C_BattleNet.GetFriendAccountInfo;

local playerRealmName = GetRealmName()

local function tprint(tbl, indent)
  if not indent then indent = 0 end
  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2
  for k, v in pairs(tbl) do
    toprint = toprint .. string.rep(" ", indent)
    if (type(k) == "number") then
      toprint = toprint .. "[" .. k .. "] = "
    elseif (type(k) == "string") then
      toprint = toprint  .. k ..  "= "
    end
    if (type(v) == "number") then
      toprint = toprint .. v .. ",\r\n"
    elseif (type(v) == "string") then
      toprint = toprint .. "\"" .. v .. "\",\r\n"
    elseif (type(v) == "table") then
      toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
    else
      toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
    end
  end
  toprint = toprint .. string.rep(" ", indent-2) .. "}"
  return toprint
end

local MOBILE_HERE_ICON = "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat:0:0:0:0:16:16:0:16:0:16:73:177:73|t"
local MOBILE_BUSY_ICON = "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-BusyMobile:0:0:0:0:16:16:0:16:0:16|t"
local MOBILE_AWAY_ICON = "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-AwayMobile:0:0:0:0:16:16:0:16:0:16|t"
local CHECK_ICON = "|TInterface\\Buttons\\UI-CheckBox-Check:0:0|t"

local function ternary(cond, a, b)
	if cond then return a end
  return b
end

local function normal(text)
  if not text then return "" end
  return NORMAL_FONT_COLOR_CODE..text..FONT_COLOR_CODE_CLOSE;
end

local function highlight(text)
  if not text then return "" end
  return HIGHLIGHT_FONT_COLOR_CODE..text..FONT_COLOR_CODE_CLOSE;
end

local function muted(text)
  if not text then return "" end
  return DISABLED_FONT_COLOR_CODE..text..FONT_COLOR_CODE_CLOSE;
end

local function IsOfficerNoteVisible(...)
  if (not addon.db.ShowGuildONote) then return false end
  if (type(CanViewOfficerNote) == "function") then
    return CanViewOfficerNote(...)
  end
  return C_GuildInfo.CanViewOfficerNote(...)
end

-- Class support
local Classes = {}
for i = 1, _G.GetNumClasses() do
  local name, className, classId = _G.GetClassInfo(i)
  Classes[_G.LOCALIZED_CLASS_NAMES_MALE[className]] = className
  Classes[_G.LOCALIZED_CLASS_NAMES_FEMALE[className]] = className
end

local function addDoubleLine(indented, left, right)
	if indented then
		return tooltip:AddLine(nil, nil, left, right)
	else
		return tooltip:AddColspanLine(3, "LEFT", left, 1, "RIGHT", right)
	end
end

local function addHeader(header, color, online, total, collapsed, collapseVar)
	header = header..":"
	local left = normal(header)
	if collapsed then
		left = left.." |cff808080"..L.TOOLTIP_COLLAPSED.."|r"
	end
	if color then color = "|cff"..color end
	local right = (color or "")..(online or "")..(color and "|r")..normal("/"..total)
	local y = addDoubleLine(false, left, right)
	tooltip:SetLineScript(y, "OnMouseDown", clickHeader, collapseVar)
	return y
end

local function colorText(text, className)
	local classIndex, coloredText=nil

	local class = Classes[className]
	local color = nil
	if class == nil then
		color = "ffcccccc"
	else
		color = RAID_CLASS_COLORS[class].colorStr
	end
	return "|c"..color..text.."|r"
end

local function getStatusIcon(status)
	if addon.db.ShowStatus == "icon" then
		if status == CHAT_FLAG_AFK then
			return "|T"..FRIENDS_TEXTURE_AFK..":0|t"
		elseif status == CHAT_FLAG_DND then
			return "|T"..FRIENDS_TEXTURE_DND..":0|t"
		end
	end
	return ""
end

local function getStatusText(status)
	if addon.db.ShowStatus == "text" then
		if status ~= "" then
			return "|cffFFFFFF"..tostring(status).."|r "
		end
	end
	return ""
end

local rightClickFrame
local function getRightClickFrame()
	if not rightClickFrame then
		rightClickFrame = CreateFrame("Frame", addonName.."TooltipContextualMenu", _G.UIParent, "UIDropDownMenuTemplate")
	end
	return rightClickFrame
end

local function showGuildRightClick(player, isMobile)
  local frame = getRightClickFrame()
  frame.initialize = function()
    print("Guild member right click temporarily disabled, sorry!")
    -- UnitPopup_OpenMenu(_G.UIDROPDOWNMENU_OPEN_MENU, "FRIEND", nil, player)
  end -- COMMUNITIES_WOW_MEMBER
  frame.displayMode = "MENU";
  frame.friendsList = false
  frame.bnetAccountID = nil
  frame.isMobile = isMobile
  ToggleDropDownMenu(1, nil, frame, "cursor")
end

local function clickPlayer(frame, info, button)
  local player, isGuild, isMobile = unpack(info)
  if player ~= "" then
    if button == "LeftButton" then
      if IsAltKeyDown() then
        C_PartyInfo.InviteUnit(player)
      else
        ChatFrame_SendTell(player)
      end
    elseif button == "RightButton" then
      if isGuild then
        showGuildRightClick(player, isMobile)
      else
        local info = C_FriendList.GetFriendInfo(player);
        FriendsFrame_ShowDropdown(info.name, info.connected, nil, nil, nil, 1);
      end
    end
  end
end

local function sendBattleNetInvite(bnetAccountID)
	local playerFactionGroup = UnitFactionGroup("player")
	local index = BNGetFriendIndex(bnetAccountID)
	if index then
		local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(index)
		if numGameAccounts > 1 then
			-- See if there's only one game account we can invite
			local validGameAccountID = nil
			for i = 1, numGameAccounts do
				local _, _, client, _, realmID, faction, _, _, _, _, _, _, _, _, _, bnetIDGameAccount = BNGetFriendGameAccountInfo(index, i)
				if client == BNET_CLIENT_WOW and faction == playerFactionGroup and realmID ~= 0 then
					-- Valid account
					if validGameAccountID and validGameAccountID ~= bnetIDGameAccount then
						-- Found two accounts. Bail out.
						validGameAccountID = nil
						break
					else
						validGameAccountID = bnetIDGameAccount
					end
				end
			end
			if validGameAccountID then
				BNInviteFriend(validGameAccountID)
				return
			end
			-- More than one account, show the dropdown
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			local dropDown = TravelPassDropDown
			if dropDown.index ~= index then
				Lib_CloseDropDownMenus()
			end
			dropDown.index = index
			Lib_ToggleDropDownMenu(1, nil, dropDown, "cursor", 1, -1)
		else
			local bnetIDGameAccount = select(6, BNGetFriendInfo(index))
			if bnetIDGameAccount then
				BNInviteFriend(bnetIDGameAccount)
			end
		end
	end
end

local function clickRealID(frame, info, button)
  local accountName, bnetAccountID = unpack(info)
  if button == "LeftButton" then
    if IsAltKeyDown() then
      if CanGroupWithAccount(bnetAccountID) then
        sendBattleNetInvite(bnetAccountID)
      end
    else
      ChatFrame_SendBNetTell(accountName)
    end
  elseif button == "RightButton" then
    FriendsFrame_ShowBNDropdown(accountName, true, nil, nil, nil, 1, bnetAccountID);
  end
end

--[[
spacer(width, count)
PARAMETERS:
  width - number - width of the space. Defaults to TextHeight
  count - number - number of spacers. Defaults to 1
RETURNS:
string - the spacer
--]]
local function spacer(width, count)
	if not width then width = 0 end
	if not count then count = 1 end
	local height = (width == 0) and 0 or 1
	return ("|T:"..height..":"..width.."|t"):rep(count)
end

--[[
  If enabled, returns an icon if the friend is currently in your group or raid.
  @param table info
--]]
local function getGroupIndicator(info)
  if not addon.db.ShowGroupMembers or not IsInGroup() then return "" end
  local name
  if info.focus then
    if info.focus.realmName and info.focus.realmName ~= playerRealmName then
      name = info.focus.name.."-"..info.focus.realmName
    else
      name = info.focus.name
    end
  elseif info.realmName then
    name = info.name.."-"..info.realmName
  else
    name = info.name
  end

  if UnitInParty(name) or UnitInRaid(name) then return CHECK_ICON end
  return spacer()
end

--[[
  Parses and returns character and battle.net friend & character information
  @see https://wow.gamepedia.com/API_C_BattleNet.GetFriendAccountInfo
  @see https://wow.gamepedia.com/API_C_BattleNet.GetFriendGameAccountInfo

  Returns two tables, first is for friends and second is for bnet. Both are arrays of identically
  -formatted tables. "friends" is all the normal RealID friends and "bnet" is all the friends in
  the Battle.Net app. Any friends in the app and elsewhere are considered to only be elsewhere.

  The individual player tables are formatted as follows: {
      bnetAccountID,
      accountName,
      battleTag: nil if not isBattleTagFriend,
      isAFK,
      isDND,
      broadcastText,
      note,
      focus: {
          name,
          client,
          realmName,
          realmID,
          faction,
          race,
          class,
          zone,
          level,
          gameText,
          location -- zone, or gameText if zone is "" or nil
      },
      alts: nil or non-empty array of tables identical to focus,
      bnet: nil or table identical to focus
  }
  filterClients indicates whether friends with both bnet and non-bnet should
  be filtered out of the bnet list

  @param Boolean filterClients  A flag indicating if the non-WoW clients should be filtered out
  @returns {table friends, table bnetFriends}
]]
function addon:parseRealID(filterClients)
  --[[
    Returns the rich location information for a character

    @param struct BNetGameAccountInfo
    @returns String
  ]]
  local function getLocation(ai)
    if ai.clientProgram == BNET_CLIENT_WOW and ai.realmName == playerRealmName then
      return ai.areaName
    end
    return ai.richPresence
  end

  local _, numOnline = BNGetNumFriends()

  local friends, bnets = {}, {}
  for i=1, numOnline do
    local accountInfo = C_BattleNet.GetFriendAccountInfo(i);
    local toons, focus, bnet = {}, nil, nil

    for j=1, C_BattleNet.GetFriendNumGameAccounts(i) do
      local ai = C_BattleNet.GetFriendGameAccountInfo(i, j)

      local toon = {
        name = ai.characterName,
        client = ai.clientProgram,
        realmName = ai.realmName,
        realmID = ai.realmID,
        faction = ai.factionName,
        race = ai.raceName,
        class = ai.className,
        zone = ai.areaName,
        level = ai.characterLevel,
        location = getLocation(ai),
      }

      if ai.clientProgram == BNET_CLIENT_APP or ai.clientProgram == "BSAp" then
        -- assume no more than 1 bnet toon, but check anyway
        if not bnet then bnet = toon end
      elseif ai.hasFocus then
        if focus ~= nil then table.insert(toons, 1, focus) end
        focus = toon
      else
        table.insert(toons, toon)
      end
    end

    if focus == nil and #toons > 0 then
      focus = toons[1]
      table.remove(toons, 1)
    end

    if focus ~= nil or bnet ~= nil then
      local friend = {
        bnetAccountID = accountInfo.bnetAccountID,
        accountName = accountInfo.accountName,
        battleTag = ternary(accountInfo.isBattleTagFriend, accountInfo.battleTag, accountInfo.accountName),
        isAFK = accountInfo.gameAccountInfo.isAFK,
        isDND = accountInfo.gameAccountInfo.isDND,
        broadcastText = accountInfo.broadcastText,
        note = accountInfo.note,
        focus = focus,
        alts = toons,
        bnet = bnet
      }
      if focus ~= nil then table.insert(friends, friend) end
      if bnet ~= nil and (not filterClients or focus == nil) then table.insert(bnets, friend) end
    end
  end

  return friends, bnets
end

-- Returns two counts, first is for friends and second is for bnet.
-- Identical to counting the tables from parseRealID() but cheaper
-- filterClients indicates if bnet should be filtered out of friends
-- and vice versa.
function addon:countRealID(filterClients)
  local friends, bnet = 0, 0
  local _, numOnline = BNGetNumFriends()
  for i=1, numOnline do
    local ai = C_BattleNet.GetFriendAccountInfo(i);
    local ga = ai.gameAccountInfo
    if ga.clientProgram == BNET_CLIENT_APP or ga.clientProgram == "BSAp" then
      bnet = bnet + 1
    else
      if (ga.clientProgram ~= "") then
        friends = friends + 1
      end
    end
  end
  return friends, bnet
end

function addon:renderBattleNet(tooltip, friends, isBnetClient, collapseVar)
  local function getFactionIndicator(faction, client)
    if addon.db.ShowRealIDFactions then
      if client == BNET_CLIENT_WOW then
        if faction == "Horde" or faction == "Alliance" then
          return "|TInterface\\PVPFrame\\PVP-Currency-"..faction..":0|t"
        elseif faction == "Neutral" then
          return "|TInterface\\FriendsFrame\\Battlenet-WoWicon:0|t"
        end
      elseif client and client ~= "" then
        return BNet_GetClientEmbeddedAtlas(client)
      end
      return spacer()
    end
    return ""
  end

  addon.tooltip:AddLine()
  local numTotal = BNGetNumFriends()

  local header
  if (isBnetClient) then
    header = L.TOOLTIP_REALID_APP
  else
    header = L.TOOLTIP_REALID
  end
  local collapsed = addon.db[collapseVar]
  addHeader(header, "00A2E8", #friends, numTotal, collapsed, collapseVar)

  if collapsed then return end

  for _, friend in ipairs(friends) do
    local left = ""

    local focus = isBnetClient and friend.bnet or friend.focus

    -- group member indicator
    local check = getGroupIndicator(friend)

    -- player status
    local playerStatus = ""
    if friend.isAFK then
      playerStatus = CHAT_FLAG_AFK
    elseif friend.isDND then
      playerStatus = CHAT_FLAG_DND
    end

    -- Character (and faction)
    local level = friend.level
    do
      local name
      if focus.client == BNET_CLIENT_WOW then
        level = "|cffFFFFFF"..focus.level.."|r"
        name = focus.name and colorText(focus.name, focus.class) or "|cffFFFFFFUnknown|r"
      else
        local clientname = focus.client
        if clientname == BNET_CLIENT_WTCG then
          clientname = "HS"
        elseif clientname == "App" then
          clientname = "BN"
        end
        level = "|cffFFFFFF"..(clientname or "??").."|r"
        name = "|cffCCCCCC"..(focus.name or "").."|r"
      end
      left = left..getFactionIndicator(focus.faction, focus.client).." "
      left = left..getStatusIcon(playerStatus)
      left = left..name.." "
    end

    -- Full name
    left = left.."[|cff00A2E8"..friend.battleTag.."|r] "

    -- Status
    left = left..getStatusText(playerStatus).." "

    local broadcastText = friend.broadcastText

    -- Note
    if addon.db.ShowRealIDNotes then
      local note = friend.note
      if note and note ~= "" then
        left = left.."|cffFFFFFF"..note.."|r"
        -- prepend "\n" onto broadcast to put it onto next line
        if broadcastText and broadcastText ~= "" then
          broadcastText = "\n"..broadcastText
        end
      end
    end

    -- Broadcast
    local extraLines
    if addon.db.ShowRealIDBroadcasts then
      if broadcastText and broadcastText ~= "" then
        -- watch out for newlines in the broadcast text
        local color = "|cff00A2E8"
        local firstLine = broadcastText:match("^([^\n]*)\n")
        if firstLine then
          extraLines = {}
          for line in broadcastText:gmatch("\n([^\n]*)") do
            extraLines[#extraLines+1] = color..line.."|r"
          end
          broadcastText = firstLine
        end
        if broadcastText ~= "" then
          left = left..color..broadcastText.."|r"
        end
      end
    end

    -- Location
    local right = focus.location and focus.location ~= "" and ("|cffFFFFFF"..focus.location.."|r") or ""

    local y = addon.tooltip:AddLine(check, level, left, right)
    addon.tooltip:SetLineScript(y, "OnMouseDown", clickRealID, { friend.accountName, friend.bnetAccountID })

    -- Extra lines
    if extraLines then
      for _, line in ipairs(extraLines) do
        addDoubleLine(true, line)
      end
    end

    -- Additional toons
    if friend.alts ~= nil then
      local playerFactionGroup = UnitFactionGroup("player")
      for _, toon in ipairs(friend.alts) do
        local left, right
        if toon.client == BNET_CLIENT_WOW then
          local cooperateLabel = ""
          if toon.realmName ~= playerRealmName or toon.faction ~= playerFactionGroup then
            cooperateLabel = _G.CANNOT_COOPERATE_LABEL
          end
          left = _G.FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE:format(tostring(toon.name)..cooperateLabel, tostring(toon.level), tostring(toon.race), tostring(toon.class))
        else
          left = toon.name
        end
        left = getFactionIndicator(toon.faction, toon.client).."|cffFEE15C"..FRIENDS_LIST_PLAYING.."|cffFFFFFF "..(left or "Unknown").."|r"
        right = "|cffFFFFFF"..(toon.location or "").."|r"
        addDoubleLine(true, left, right)
      end
    end
  end
end


function addon:renderFriends(tooltip, collapseVar)
	addon.tooltip:AddLine()
  local numTotal = C_FriendList.GetNumFriends()
  local numOnline = C_FriendList.GetNumOnlineFriends()

	local collapsed = addon.db[collapseVar]
	addHeader(L.TOOLTIP_FRIENDS, "FFFFFF", numOnline, numTotal, collapsed, collapseVar)

	if collapsed then return end

	for i=1, numOnline do
		local left = ""

		local info = C_FriendList.GetFriendInfoByIndex(i)
		local playerStatus = nil
		if info.afk == true then
			playerStatus = _G.CHAT_FLAG_AFK
		elseif info.dnd == true then
			playerStatus = _G.CHAT_FLAG_DND
		end
		-- Group indicator
    local check = getGroupIndicator(info)

		-- Level
		local level = "|cffFFFFFF"..info.level.."|r"

		-- Status icon
		left = left..getStatusIcon(playerStatus)

		-- Name
		left = left..colorText(info.name, info.className).." "

		-- Status
		left = left..getStatusText(playerStatus).." "

		-- Notes
		if addon.db.ShowFriendsNote then
			if info.notes and info.notes ~= "" then
				left = left.."|cffFFFFFF"..info.notes.."|r "
			end
		end
		local right = ""
		if info.area ~= nil then
			right = "|cffFFFFFF"..info.area.."|r"
		end

		local y = addon.tooltip:AddLine(check, level, left, right)
		addon.tooltip:SetLineScript(y, "OnMouseDown", clickPlayer, { info.name, false, false, false })
	end
end


function addon:renderGuild(tooltip, collapseGuildVar)
  local function processGuildMember(i, tooltip)
    local left = ""

    local name, rank, rankIndex, level, class, zone, note, officerNote, online, playerStatus, classFileName, achievementPoints, achievementRank, isMobile = GetGuildRosterInfo(i)

    local origname = name
    name = Ambiguate(name, "guild")

    local check = getGroupIndicator({ name = name })

    -- fix name
    -- local origname = name
    if name == "" then
      name = "Unknown"
    end

    -- fix playerStatus
    if playerStatus == 1 then
      playerStatus = CHAT_FLAG_AFK
    elseif playerStatus == 2 then
      playerStatus = CHAT_FLAG_DND
    else
      playerStatus = ""
    end

    if isMobile then
      if playerStatus == CHAT_FLAG_DND then
        name = MOBILE_BUSY_ICON..name
      elseif playerStatus == CHAT_FLAG_AFK then
        name = MOBILE_AWAY_ICON..name
      else
        name = MOBILE_HERE_ICON..name
      end
    end

    -- Level
    local level = "|cffFFFFFF"..level.."|r"

    -- Status icon
    if not isMobile then
      -- Mobile icon already shows status
      left = left..getStatusIcon(playerStatus)
    end

    -- Name
    left = left..colorText(name, class).." "

    -- Status
    left = left..getStatusText(playerStatus).." "

    -- Rank
    left = left..rank.."  "

    -- Notes
    if addon.db.ShowGuildNote then
      if note and note ~= "" then
        left = left.."|cffFFFFFF"..note.."|r  "
      end
    end

    -- Officer Notes
    if IsOfficerNoteVisible() then
      if officerNote and officerNote ~= "" then
        left = left.."|cffAAFFAA"..officerNote.."|r  "
      end
    end

    -- Location
    local right = ""
    if zone and zone ~= "" then
      right = "|cffFFFFFF"..zone.."|r"
    end

    local y = addon.tooltip:AddLine(check, level, left, right)
    addon.tooltip:SetLineScript(y, "OnMouseDown", clickPlayer, { origname, true, isMobile })
  end

  -- collectGuildRosterInfo(split, sortKey, sortAscending)
  -- collects and sorts the guild roster
  -- PARAMETERS:
  --   split - boolean - whether to split the remote chat
  --   sortKey - string - the key to sort by. nil means no sort
  --   sortAscending - boolean - whether the sort is ascending
  -- RETURNS:
  --   table - array of guild roster indices
  --   number - total guild members
  --   number - online guild members
  --
  -- If `split` is true, the online and remote sections of the roster are
  -- sorted independently. If false, they're sorted into the same table.
  -- Every entry in the roster is an index suitable for GetGuildRosterInfo()
  local function collectGuildRosterInfo(sortKey, sortAscending)
    SetGuildRosterShowOffline(false)

    local guildTotal, guildOnline = GetNumGuildMembers()

    local onlineTable = {}
    for i = 1, guildOnline do
      onlineTable[i] = i
    end

    if sortKey then
      local function sortFunc(a, b)
        local aname, _, arankIndex, alevel, aclass, azone, anote = GetGuildRosterInfo(a)
        local bname, _, brankIndex, blevel, bclass, bzone, bnote = GetGuildRosterInfo(b)
        if sortKey == "rank" and arankIndex ~= brankIndex then
          -- rank indices are reversed from what you'd expect, so flip the meaning of ascending
          return ternary(sortAscending, arankIndex > brankIndex, arankIndex < brankIndex)
        end
        if sortKey == "level" and alevel ~= blevel then
          return ternary(sortAscending, alevel < blevel, alevel > blevel)
        end
        if sortKey == "class" and aclass ~= bclass then
          return ternary(sortAscending, aclass < bclass, aclass > bclass)
        end
        if sortKey == "zone" and azone ~= bzone then
          -- zones are sometimes nil when enough players are online
          if azone == nil then azone = "" end
          if bzone == nil then bzone = "" end
          return ternary(sortAscending, azone < bzone, azone > bzone)
        end
        if sortKey == "note" and anote ~= bnote then
          return ternary(sortAscending, anote < bnote, anote > bnote)
        end
        aname = string.lower(aname or "Unknown")
        bname = string.lower(bname or "Unknown")
        -- if name is the secondary sort, it's always ascending
        if sortAscending or sortKey ~= "name" then
          return aname < bname
        else
          return aname > bname
        end
      end

      table.sort(onlineTable, sortFunc)
    end

    return onlineTable, guildTotal, guildOnline
  end

	addon.tooltip:AddLine()
	local wasOffline = GetGuildRosterShowOffline()
	if wasOffline then
		-- SetGuildRosterShowOffline() seems to sometimes trigger GUILD_ROSTER_UPDATE
		SetGuildRosterShowOffline(false)
	end

	local sortKey = addon.db.GuildSort and addon.db.GuildSortKey or nil
	local roster, numTotal, numOnline = collectGuildRosterInfo(sortKey, addon.db.GuildSortAscending or false)
	local collapseGuild = addon.db[collapseGuildVar]
	addHeader(L.TOOLTIP_GUILD, "00FF00", numOnline, numTotal, collapseGuild, collapseGuildVar)

	for i, guildIndex in ipairs(roster) do
    processGuildMember(guildIndex, tooltip)
	end

	if wasOffline then
		SetGuildRosterShowOffline(wasOffline)
	end
end
