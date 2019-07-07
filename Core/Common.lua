local SUI, L = SUI, SUI.L
local type, pairs = type, pairs
----------------------------------------------------------------------------------------------------

function SUI:BT4ProfileAttach(msg)
	PageData = {
		title = 'SpartanUI',
		Desc1 = msg,
		-- Desc2 = Desc2,
		width = 400,
		height = 150,
		Display = function()
			SUI_Win:ClearAllPoints()
			SUI_Win:SetPoint('TOP', 0, -20)
			SUI_Win:SetSize(400, 150)
			SUI_Win.Status:Hide()

			SUI_Win.Skip:SetText('DO NOT ATTACH')
			SUI_Win.Skip:SetSize(110, 25)
			SUI_Win.Skip:ClearAllPoints()
			SUI_Win.Skip:SetPoint('BOTTOMRIGHT', SUI_Win, 'BOTTOM', -15, 15)

			SUI_Win.Next:SetText('ATTACH')
			SUI_Win.Next:ClearAllPoints()
			SUI_Win.Next:SetPoint('BOTTOMLEFT', SUI_Win, 'BOTTOM', 15, 15)
		end,
		Next = function()
			SUI.DBG.Bartender4[SUI.DB.BT4Profile] = {
				Style = SUI.DBMod.Artwork.Style
			}
			-- Catch if Movedbars is not initalized
			if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars then
				SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars = {}
			end
			--Setup profile
			SUI:GetModule('Artwork_Core'):SetupProfile(Bartender4.db:GetCurrentProfile())
			ReloadUI()
		end,
		Skip = function()
			-- ReloadUI()
		end
	}
	local SetupWindow = SUI:GetModule('SUIWindow')
	SetupWindow:DisplayPage(PageData)
end

function SUI:BT4RefreshConfig()
	if SUI.DBG.BartenderChangesActive or SUI.DBMod.Artwork.FirstLoad then
		return
	end
	-- if SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile == Bartender4.db:GetCurrentProfile() then return end -- Catch False positive)
	SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile = Bartender4.db:GetCurrentProfile()
	SUI.DB.BT4Profile = Bartender4.db:GetCurrentProfile()

	if SUI.DBG.Bartender4 == nil then
		SUI.DBG.Bartender4 = {}
	end

	if SUI.DBG.Bartender4[SUI.DB.BT4Profile] then
		-- We know this profile.
		if SUI.DBG.Bartender4[SUI.DB.BT4Profile].Style == SUI.DBMod.Artwork.Style then
			--Profile is for this style, prompt to ReloadUI; usually un needed can uncomment if needed latter
			-- SUI:reloadui("Your bartender profile has changed, a reload may be required for the bars to appear properly.")
			-- Catch if Movedbars is not initalized
			if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars then
				SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars = {}
			end
		else
			--Ask if we should change to the correct profile or if we should change the profile to be for this style
			SUI:BT4ProfileAttach(
				"This bartender profile is currently attached to the style '" ..
					SUI.DBG.Bartender4[SUI.DB.BT4Profile].Style ..
						"' you are currently using " ..
							SUI.DBMod.Artwork.Style .. ' would you like to reassign the profile to this art skin? '
			)
		end
	else
		-- We do not know this profile, ask if we should attach it to this style.
		SUI:BT4ProfileAttach(
			'This bartender profile is currently NOT attached to any style you are currently using the ' ..
				SUI.DBMod.Artwork.Style .. ' style would you like to assign the profile to this art skin? '
		)
	end

	SUI:Print('Bartender4 Profile changed to: ' .. Bartender4.db:GetCurrentProfile())
end

function SUI:UpdateModuleConfigs()
	if Bartender4 then
		if SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile then
			Bartender4.db:SetProfile(SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile)
		elseif SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderProfile then
			Bartender4.db:SetProfile(SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderProfile)
		else
			Bartender4.db:SetProfile(SUI.DB.BT4Profile)
		end
	end

	SUI:reloadui()
end

function SUI:reloadui(Desc2)
	-- SUI.DB.OpenOptions = true;
	PageData = {
		title = 'SpartanUI',
		Desc1 = 'A reload of your UI is required.',
		Desc2 = Desc2,
		width = 400,
		height = 150,
		WipePage = true,
		Display = function()
			SUI_Win:ClearAllPoints()
			SUI_Win:SetPoint('TOP', 0, -20)
			SUI_Win:SetSize(400, 150)
			SUI_Win.Status:Hide()
			SUI_Win.Next:SetText('RELOADUI')
			SUI_Win.Next:ClearAllPoints()
			SUI_Win.Next:SetPoint('BOTTOM', 0, 30)
		end,
		Next = function()
			ReloadUI()
		end
	}
	local SetupWindow = SUI:GetModule('SUIWindow')
	SetupWindow:DisplayPage(PageData)
end

--[[
	Takes a target table and injects data from the source
	override allows the source to be put into the target
	even if its already populated
]]
function SUI:MergeData(target, source, override)
	if type(target) ~= 'table' then
		target = {}
	end
	for k, v in pairs(source) do
		if type(v) == 'table' then
			target[k] = self:MergeData(target[k], v, override)
		else
			if override then
				target[k] = v
			elseif target[k] == nil then
				target[k] = v
			end
		end
	end
	return target
end

function SUI:isPartialMatch(frameName, tab)
	local result = false

	for _, v in ipairs(tab) do
		startpos, endpos = strfind(strlower(frameName), strlower(v))
		if (startpos == 1) then
			result = true
		end
	end

	return result
end

function SUI:isInTable(tab, frameName)
	-- local Count = 0
	-- for Index, Value in pairs( tab ) do
	-- Count = Count + 1
	-- end
	-- print (Count)
	if tab == nil or frameName == nil then
		return false
	end
	for _, v in ipairs(tab) do
		if v ~= nil and frameName ~= nil then
			if (strlower(v) == strlower(frameName)) then
				return true
			end
		end
	end
	return false
end

function SUI:round(val, decimal)
	if (decimal) then
		return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
	else
		return math.floor(val + 0.5)
	end
end

function SUI:GetiLVL(itemLink)
	if not itemLink then
		return 0
	end

	local scanningTooltip = CreateFrame('GameTooltip', 'AutoTurnInTooltip', nil, 'GameTooltipTemplate')
	local itemLevelPattern = _G.ITEM_LEVEL:gsub('%%d', '(%%d+)')
	local itemQuality = select(3, GetItemInfo(itemLink))

	-- if a heirloom return a huge number so we dont replace it.
	if (itemQuality == 7) then
		return math.huge
	end

	-- Scan the tooltip
	-- Setup the scanning tooltip
	-- Why do this here and not in OnEnable? If the player is not questing there is no need for this to exsist.
	scanningTooltip:SetOwner(UIParent, 'ANCHOR_NONE')

	-- If the item is not in the cache populate it.
	-- if not ilevel then
	-- Load tooltip
	scanningTooltip:SetHyperlink(itemLink)

	-- Find the iLVL inthe tooltip
	for i = 2, scanningTooltip:NumLines() do
		local line = _G['AutoTurnInTooltipTextLeft' .. i]
		if line:GetText():match(itemLevelPattern) then
			return tonumber(line:GetText():match(itemLevelPattern))
		end
	end
	return 0
end

function SUI:GoldFormattedValue(rawValue)
	local gold = math.floor(rawValue / 10000)
	local silver = math.floor((rawValue % 10000) / 100)
	local copper = (rawValue % 10000) % 100

	return format(
		GOLD_AMOUNT_TEXTURE .. ' ' .. SILVER_AMOUNT_TEXTURE .. ' ' .. COPPER_AMOUNT_TEXTURE,
		gold,
		0,
		0,
		silver,
		0,
		0,
		copper,
		0,
		0
	)
end
