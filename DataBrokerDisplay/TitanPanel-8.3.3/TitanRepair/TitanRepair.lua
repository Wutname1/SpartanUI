---@diagnostic disable: duplicate-set-field
--[[
-- **************************************************************************
-- * TitanRepair.lua
-- *
-- * By: The Titan Panel Development Team
-- **************************************************************************
--]]

-- ******************************** Constants *******************************
local TITAN_REPAIR_ID = "Repair";
local TITAN_BUTTON = "TitanPanel"..TITAN_REPAIR_ID.."Button"

local L = LibStub("AceLocale-3.0"):GetLocale(TITAN_ID, true)
local TitanRepair = {};
local _G = getfenv(0);
local TR = TitanRepair
TR.ITEM_STATUS = {};
TR.ITEM_BAG = {};

local AceTimer = LibStub("AceTimer-3.0")
local TR_Timer = {}
local TR_Timer_active = false

local parse_item = "";

---@diagnostic disable-next-line: deprecated
local GetItem = C_Item.GetItemInfo or GetItemInfo -- For Classic versions
---@diagnostic disable-next-line: deprecated
local GetQ = C_Item.GetItemQualityColor or GetItemQualityColor -- For Classic versions

-- locals
TR.repair_total = 0
TR.dur_total = 0

TR.repair_bags = {}
TR.repair_equip = {}

TR.money_total = 0
TR.bag_list = {}
TR.equip_list = {}
TR.equip_most_default = {
	name = UNKNOWN,
	quality = UNKNOWN,
	color = UNKNOWN,
	dur_max = 0,
	dur_cur = 0,
	dur_per = 100,
	cost = 0,
	}
TR.equip_most = {
	name = UNKNOWN,
	quality = UNKNOWN,
	color = UNKNOWN,
	dur_max = 0,
	dur_cur = 0,
	dur_per = 100,
	cost = 0,
	}

TR.last_scan = GetTime() -- seconds with milliseconds - sec.milli
TR.scan_time = 0
TR.scan_running = false
if Titan_Global.switch.game_ammo then
	TR.scan_start = 18
else
	TR.scan_start = 17
end
TR.scan_end = 1

local slots = {
	[1] = {name = "HEADSLOT"},
	[2] = {name = "NECKSLOT"},
	[3] = {name = "SHOULDERSLOT"},
	[4] = {name = "SHIRTSLOT"},
	[5] = {name = "CHESTSLOT"},
	[6] = {name = "WAISTSLOT"},
	[7] = {name = "LEGSSLOT"},
	[8] = {name = "FEETSLOT"},
	[9] = {name = "WRISTSLOT"},
	[10] = {name = "HANDSSLOT"},
	[11] = {name = "FINGER0SLOT"},
	[12] = {name = "FINGER1SLOT"},
	[13] = {name = "TRINKET0SLOT"},
	[14] = {name = "TRINKET1SLOT"},
	[15] = {name = "BACKSLOT"},
	[16] = {name = "MAINHANDSLOT"},
	[17] = {name = "SECONDARYHANDSLOT"},
	[18] = {name = "RANGEDSLOT"},
}

TR.guild_bank = Titan_Global.switch.guild_bank

-- WoW changed the parse string for items...
if Titan_Global.wowversion < 100000 then
    -- Not retail
    parse_item = 
        "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?"
else
    -- Retail
    parse_item = 
	    "|?cnIQ?(%x*):|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?"
end


--debug
TR.show_debug = false -- will tell you a lot about what's happening
TR.show_debug_scan = false -- shows items processed during scan
TR.show_debug_tooltip = false -- shows items processed during scan

-- ******************************** Functions *******************************

---local Debug function to print message to chat frame.
---@param Message string
local function debug_msg(Message)
	local msg = ""
	local stamp = date("%H:%M:%S") -- date("%m/%d/%y %H:%M:%S")
	local milli = GetTime() -- seconds with millisecond precision (float)
	local milli_str = string.format("%0.2F", milli - math.modf(milli))
	msg = msg..TitanUtils_GetGoldText(stamp..milli_str.." "..TITAN_REPAIR_ID..": ")
	msg = msg..TitanUtils_GetGreenText(Message)
	DEFAULT_CHAT_FRAME:AddMessage(msg)
--		DEFAULT_CHAT_FRAME:AddMessage(TITAN_REPAIR_ID..": " .. Message, 1.00, 0.49, 0.04)
end

---local Reset plugin tables and variables to default values
local function RepairInit()
	TR.repair_total = 0
	TR.repair_bags = { cur = 0, max = 0, dur = 0, total = 0 }
	TR.repair_equip = { cur = 0, max = 0, dur = 0, total = 0 }

	TR.dur_total = 0

	TR.grays = { total = 0 }

	TR.money_total = 0
	TR.bag_list = {}
	TR.equip_list = {}
	TR.equip_most = {}

	TR.equip_most = {
		name = TR.equip_most_default.name,
		quality = TR.equip_most_default.quality,
		color = TR.equip_most_default.color,
		dur_max = TR.equip_most_default.dur_max,
		dur_cur = TR.equip_most_default.dur_cur,
		dur_per = TR.equip_most_default.dur_per,
		cost = TR.equip_most_default.cost,
		}
end

--[[ local
-- **************************************************************************
-- NAME : GetRepairCostBag()
-- DESC : Assuming an item in a bag, get the repair cost
-- VARS : 
-- bag : int : bag to check
-- slot : int : bag slot
-- OUT : 
-- int : repair cost or 0
-- **************************************************************************
--]]
---local Assuming an equipped item, get repair cost
---@param slotName string For debug
---@param slot number
---@return boolean
---@return number
local function GetRepairCostEquip(slotName, slot)
	local equipped = false
	local res = 0
	local name = ""

	--Blizz changed SetInventoryItem for DragonFlight
	if C_TooltipInfo then 
		local data = C_TooltipInfo.GetInventoryItem("player", slot)
		if data then
--			TooltipUtil.SurfaceArgs(data) -- readable format
			res = (data.repairCost or 0)
			equipped = true
		end
	else -- Classic
		TitanRepairTooltip:SetOwner(UIParent, "ANCHOR_NONE");
		TitanRepairTooltip:ClearLines()

		local hasItem, _, repairCost = TitanRepairTooltip:SetInventoryItem("player", slot)
		res = repairCost

		equipped = hasItem -- debug

		TitanRepairTooltip:Hide()
	end

	if (TR.show_debug) then
		local msg = "TRepair eq cost"
		.." equipped : "..tostring(equipped)..""
		.." cost: "..tostring(res)..""
		.." slot : "..tostring(slot)..""
		.."["..tostring(slotName).."]"
		.." '"..tostring(name).."'"
		debug_msg(msg)
	end

	return equipped, res
end

---local Assuming an item in a bag, get the repair cost
---@param bag number
---@param slot number
---@return number
local function GetRepairCostBag(bag, slot)
	local res = 0

	--Blizz changed SetInventoryItem for DragonFlight
	if C_TooltipInfo then 
		local data = C_TooltipInfo.GetBagItem(bag, slot)
		if data then
--			TooltipUtil.SurfaceArgs(data) -- readable format
			res = (data.repairCost or 0)
		end
	else

		TitanRepairTooltip:SetOwner(UIParent, "ANCHOR_NONE");
		TitanRepairTooltip:ClearLines()
		local _, repairCost = TitanRepairTooltip:SetBagItem(bag, slot)
		res = repairCost
		TitanRepairTooltip:Hide()
	end

	return res
end

---local Scan all bags and equipment and set the 'scan in progress'. On a successful scan, the plugin button is updated.
---@param reason string For debug only - why was the scan requested?
---@param force boolean Force a scan if true otherwise use time since last scan
local function Scan(reason, force)
--[==[
local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, reforging, Name = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
print
--]==]
	local must_do = force or false
	local milli = GetTime() -- seconds with millisecond precision (float)
	local dmsg = ""
	local msg = "Scan "


	if (TR.show_debug or TR.show_debug_scan) then
		msg = msg
		.." '"..tostring(reason).."'"
		.." "..string.format("%0.2F",(milli - TR.last_scan)).." sec"
	end

	if must_do or (milli > TR.last_scan + 1) then -- no more than a scan per sec
		local calc_inv = TitanGetVar(TITAN_REPAIR_ID,"ShowInventory")
		local show_gray = TitanGetVar(TITAN_REPAIR_ID,"ShowGray")
		local sell_gray = TitanGetVar(TITAN_REPAIR_ID,"SellAllGray")
		local calc_gray = (show_gray or sell_gray) -- either needs a scan to calc
		
		if (TR.show_debug_scan) then
			msg = msg.." : running "
				.." force:"..tostring(force)..""
				.." inv:"..tostring(calc_inv)..""
				.." show grey:"..tostring(show_gray)..""
				.." sell grey:"..tostring(calc_gray)..""
			debug_msg(msg)
		end
		
		-- Init the repair tables - equip / bags / grays
		RepairInit()

		-- ++++++++++++++++++++++++++++++++++++++++++++++++++
		-- scan equipped items - only those with durability
		--
		if (TR.show_debug_scan) then
			dmsg = "Start equip scan"
				.." - "..(TitanGetVar(TITAN_REPAIR_ID,"ShowUndamaged") and "Include Undamaged" or "Only Damaged")
			debug_msg(dmsg)
		end

		-- Walk thru slots 'backward' to give weapons 'priority' if most damaged
		for slotID = TR.scan_start, TR.scan_end, -1 do  -- thru slots
			local slotName = slots[slotID].name
			local scan_slots = tostring(slotName)..":"..tostring(GetInventorySlotInfo(slotName))

			local _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, reforging, Name
			local itemName, itemQuality

			local itemLink = GetInventoryItemLink("player", slotID)
			
			scan_slots = scan_slots
				.." link:"..tostring((itemLink and true or false))..""

			if itemLink == nil then
				-- slot is empty
				scan_slots = scan_slots
					.." item: Empty"
			else
				_, _, Color, Ltype, Id, Enchant, 
				Gem1, Gem2, Gem3, Gem4, 
				Suffix, Unique, LinkLvl, reforging, Name = string.find(itemLink, parse_item)
				itemName, _, itemQuality = GetItem(Id)

				scan_slots = scan_slots
					.." id:"..tostring(Id)..""
					.." '"..tostring(itemName).."'"

				if Id == nil or itemName == nil then 
					-- likely entering world, server has not fully sent data to use
					-- Set a timer for 1 sec rather than waiting for some event
					if (TR.show_debug or TR.show_debug_scan) then
						scan_slots = scan_slots
							..TitanUtils_GetRedText(" scan: in 1 sec")
							.." on:"..tostring(TR_Timer_active)..""
						debug_msg(scan_slots)
					end
					TR_Timer_active = true
					TR_Timer = AceTimer:ScheduleTimer(TitanRepair_ScanShell, 1.0)
					return -- harsh but best...
				else
					-- item data should be good
					local minimum, maximum = GetInventoryItemDurability(slotID)
					if minimum and maximum then -- Only calc when item has durability
						local hasItem, repairCost = GetRepairCostEquip(slotName, slotID)
						local r, g, b, hex = GetQ(itemQuality or 1)

						scan_slots = scan_slots
							.." item:"..tostring(hasItem)..""
							.." $:"..tostring(repairCost)..""

						-- save item for tooltip and debug
						if ((repairCost and repairCost > 0) or TitanGetVar(TITAN_REPAIR_ID,"ShowUndamaged")) then
							TR.equip_list[slotName] = {
												name = (itemName or UNKNOWN),
												quality = (itemQuality or UNKNOWN),
												color = (hex or UNKNOWN),
												dur_max = (maximum or 0),
												dur_cur = (minimum or 0),
												dur_per = ((maximum > 0 and floor(minimum / maximum * 100)) or 100),
												cost = (repairCost or 0),
												}
							
							scan_slots = scan_slots
								.." %:"..tostring(TR.equip_list[slotName].dur_per)..""
								.." ["..tostring(minimum)..""
								..":"..tostring(maximum).."]"

							-- Get most damaged by finding least %
							if 	TR.equip_list[slotName].dur_per < TR.equip_most.dur_per
							then
								TR.equip_most = {
									name = TR.equip_list[slotName].name,
									quality = TR.equip_list[slotName].quality,
									color = TR.equip_list[slotName].color,
									dur_max = TR.equip_list[slotName].dur_max,
									dur_cur = TR.equip_list[slotName].dur_cur,
									dur_per = TR.equip_list[slotName].dur_per,
									cost = TR.equip_list[slotName].cost,
									}
								scan_slots = scan_slots
									..TitanUtils_GetNormalText(" <:"..tostring(TR.equip_most.dur_per))..""
							else
								-- not most damaged
							end
						else
							-- nothing
						end

						TR.repair_total = TR.repair_total + repairCost
						TR.repair_equip.total = TR.repair_equip.total + repairCost

						TR.repair_equip.cur = TR.repair_equip.cur + minimum
						TR.repair_equip.max = TR.repair_equip.max + maximum
					else
						-- some equipped items do not have durability
					end
				end
			end

			scan_slots = scan_slots
				.." total :"..tostring(TR.repair_equip.total)..""

			if TR.show_debug_scan then
				debug_msg(scan_slots)
			else
				-- not requested
			end
			
			
		end -- for
		TR.repair_equip.dur = (TR.repair_equip.max > 0 and floor(TR.repair_equip.cur / TR.repair_equip.max * 100)) or 100
		
		if (TR.show_debug or TR.show_debug_scan) then
			dmsg = "End equip scan "
				.." $"..tostring(TR.repair_equip.total)
				.." "..tostring(TR.repair_equip.dur).."%"
				.." = "..tostring(TR.repair_equip.cur)
				.." / "..tostring(TR.repair_equip.max)
			debug_msg(dmsg)
		end
		
		-- ++++++++++++++++++++++++++++++++++++++++++++++++++
		-- Check inventory for repair costs AND grays
		--
		for bag = 0, 4 do
			for slot = 1, C_Container.GetContainerNumSlots(bag) do
				if calc_inv then -- scan bags for 'damaged' items
					-- Inventory repair costs
					local repairCost = 0

					local minimum, maximum = C_Container.GetContainerItemDurability(bag, slot)
					if minimum and maximum then
						if TR.show_debug then
							print("TRepair inv dur"
								.." "..tostring(bag)..""
								.." "..tostring(slot)..""
								.." "..tostring(minimum)..""
								.." "..tostring(maximum)..""
							)
						end
						repairCost = GetRepairCostBag(bag, slot)
						if (repairCost and (repairCost > 0)) then
							TR.repair_total = TR.repair_total + repairCost
							TR.repair_bags.total = TR.repair_bags.total + repairCost
						end
						TR.repair_bags.cur = TR.repair_bags.cur + minimum
						TR.repair_bags.max = TR.repair_bags.max + maximum
					end
				else
					-- save a few cycles
				end
				if calc_gray then -- scan bags for 'gray' items
					local info = C_Container.GetContainerItemInfo(bag, slot)
					if info and info.quality == 0 then 
						-- gray / Poor quality
						TR.grays.total = TR.grays.total + (info.stackCount * select(11, GetItem(info.itemID)))
					else
						-- ignore - not gray
					end
				else
					-- save a few cycles
				end
			end
		end
		if calc_inv then -- calc total damage - if requested by user.
			TR.repair_bags.dur = (TR.repair_bags.max > 0 and floor(TR.repair_bags.cur / TR.repair_bags.max * 100)) or 100
			if (TR.show_debug) then
				dmsg = "Bags repair totals"
					.." "..tostring(TR.repair_bags.dur)
					.." $ "..tostring(TR.repair_bags.total)
				debug_msg(dmsg)
			end
		else
			if (TR.show_debug) then
				debug_msg("Bags repair totals None - User did not request")
			end
		end
		if (TR.show_debug) then
			if calc_gray then -- calc total grays - if requested by user.
				dmsg = "Bags gray scan End "
					.." $ "..tostring(TR.grays.total)
			else
				dmsg = "Bags gray totals None - User did not request"
			end
			if TR.show_debug then
				debug_msg(dmsg)
			end
		end

		-- ++++++++++++++++++++++++++++++++++++++++++++++++++
		-- Calc total durability %
		-- repair_equip - gear currently worn
		-- repair_bags - any dmaaged gear in bags
		TR.dur_total = ((TR.repair_bags.max + TR.repair_equip.max) > 0 
			and floor( (TR.repair_bags.cur + TR.repair_equip.cur) / (TR.repair_bags.max + TR.repair_equip.max) * 100)) 
			or 100
		
		-- cleanup
		TR.scan_time = GetTime() - milli
		TR.last_scan = GetTime()
		TR.scan_running = false
		
		-- update button text
		TitanPanelButton_UpdateButton(TITAN_REPAIR_ID)
		
		if (TR.show_debug) then
			dmsg = "Calc total durability"
				.." '"..tostring(TR.dur_total).."'"
				.." "..tostring(TR.repair_equip.max)
				.." "..tostring(TR.repair_equip.cur)
				.." "..tostring(TR.repair_bags.max)
				.." "..tostring(TR.repair_bags.cur)
			debug_msg(dmsg)
			dmsg = "...Scan complete"
			debug_msg(dmsg)
		end
	else
		if (TR.show_debug) then
			msg = msg.." : NOT running - too soon "
			debug_msg(msg)
		end
	end
end

---local Called from timer; used when entering world and data may not be ready.
function TitanRepair_ScanShell()
	Scan("Timer initiated", true)
	TR_Timer_active = false
end

---local Activate Repair - events, init, scan, etc.
---@param self Button
local function RepairShow(self)
	if TR.show_debug then
		debug_msg("RepairShow - starting")
	end
	RepairInit()
	
	self:RegisterEvent("MERCHANT_SHOW");
	self:RegisterEvent("MERCHANT_CLOSED");
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("UPDATE_INVENTORY_DURABILITY")

	-- Check everything on world enter (at init and after zoning)
	Scan("OnShow", true)

	if TR.show_debug then
		debug_msg("...RepairShow - complete")
	end
end

---local Deactivate Repair - events, init, etc.
---@param self Button
local function RepairHide(self)
	if TR.show_debug then
		debug_msg("RepairHide - shutting down")
	end
	RepairInit() -- cleanup footprint

	self:UnregisterEvent("MERCHANT_SHOW");
	self:UnregisterEvent("MERCHANT_CLOSED");
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("UNIT_INVENTORY_CHANGED");
	self:UnregisterEvent("UPDATE_INVENTORY_DURABILITY");

	if TR.show_debug then
		debug_msg("...RepairHide - complete")
	end
end

---local Get gold, silver, copper from the given money (in copper)
---@param money number Money in copper
---@return integer
---@return integer
---@return integer
---@return boolean
local function GetGSC(money)
	local neg = false;
	if (money == nil) then money = 0; end
	if (money < 0) then
		neg = true;
		money = money * -1;
	end
	local g = math.floor(money / 10000);
	local s = math.floor((money - (g * 10000)) / 100);
	local c = math.floor(money - (g * 10000) - (s * 100));
	return g, s, c, neg;
end

---local Get a formated string from the given money (in copper)
---@param money number Money in copper
---@return string readable_money
local function GetTextGSC(money)
--[===[
	local GSC_GOLD = "ffd100";
	local GSC_SILVER = "e6e6e6";
	local GSC_COPPER = "c8602c";
	local GSC_START = "|cff%s%d|r";
	local GSC_PART = ".|cff%s%02d|r";
	local GSC_NONE = "|cffa0a0a0" .. NONE .. "|r";
	local g, s, c, neg = GetGSC(money);
	local gsc = "";
	
	if TitanGetVar(TITAN_REPAIR_ID, "ShowCostGoldOnly") then
		if (g > 0) then
			gsc = format(GSC_START, GSC_GOLD, g);
		elseif (s > 0) or (c > 0) then
			gsc = format(GSC_START, GSC_GOLD, 0);
		else
			gsc = GSC_NONE;
		end
	else
		if (g > 0) then
			gsc = format(GSC_START, GSC_GOLD, g);
			gsc = gsc .. format(GSC_PART, GSC_SILVER, s);
			gsc = gsc .. format(GSC_PART, GSC_COPPER, c);
		elseif (s > 0) then
			gsc = format(GSC_START, GSC_SILVER, s);
			gsc = gsc .. format(GSC_PART, GSC_COPPER, c);
		elseif (c > 0) then
			gsc = gsc .. format(GSC_START, GSC_COPPER, c);
		else
			gsc = GSC_NONE;
		end
	end
	if (neg) then gsc = "(" .. gsc .. ")"; end
	return gsc;
--]===]

	local sep = ""
	local dec = ""
--	if (TitanGetVar(TITAN_REPAIR_ID, "UseSeperatorComma")) then
		sep = ","
		dec = "."
--	else
--		sep = "."
--		dec = ","
--	end

	-- Not all parameters are Repair options so default.
	local outstr, gold, silver, copper =
		TitanUtils_CashToString(money,
			",", -- thousand seprator
			".", -- decimal seprator
			TitanGetVar(TITAN_REPAIR_ID, "ShowCostGoldOnly"),
			false, -- coin labels
			false, -- coin icons
			true -- color G / S / C
		)
	return outstr

end

---local Repair items per user settings to use Guild or own gold.
local function TitanRepair_RepairItems()
--[=[
Jul 2023 / 10.1.5 
- Button name change MerchantRepairAllIcon > MerchantRepairAllButton
- Button name change MerchantGuildBankRepairButtonIcon > MerchantGuildBankRepairButton
Realized the Disable also changes the button so the DeSat is redundent
--]=]
	if TR.show_debug then
		debug_msg("_RepairItems")
	end
	-- New RepairAll function
	local cost = GetRepairAllCost();
	local money = GetMoney();

	if cost == nil then -- for IDE...
		cost = 0
	else
		-- cost is reasonable
	end

	-- Use Guild Bank funds
	if TR.guild_bank and TitanGetVar(TITAN_REPAIR_ID,"UseGuildBank") then
		local withdrawLimit = GetGuildBankWithdrawMoney();
		local guildBankMoney = GetGuildBankMoney();

		if TR.show_debug then
			debug_msg("UseGuildBank"
				.." $"..tostring(cost)..""
				.." limit: "..tostring(withdrawLimit)
				.." guild $: "..tostring(guildBankMoney)
				)
		end
---[[
--]]
		if IsInGuild() and CanGuildBankRepair() then
			if withdrawLimit >= cost then
				RepairAllItems(true)
				if TitanGetVar(TITAN_REPAIR_ID,"AutoRepairReport") then
					-- report repair cost to chat (optional)
					DEFAULT_CHAT_FRAME:AddMessage(_G["GREEN_FONT_COLOR_CODE"]..L["TITAN_REPAIR"]..": ".."|r"
						..format(L["TITAN_REPAIR_REPORT_COST_CHAT_GUILD"], GetTextGSC(cost)).."\n")
				end
				-- disable repair all icon in merchant
				MerchantRepairAllButton:Disable();
				-- disable guild bank repair all icon in merchant
				MerchantGuildBankRepairButton:Disable();
			else
				DEFAULT_CHAT_FRAME:AddMessage(_G["GREEN_FONT_COLOR_CODE"]..L["TITAN_REPAIR"]..": ".."|r"
					..L["TITAN_REPAIR_GBANK_NOMONEY"])
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage(_G["GREEN_FONT_COLOR_CODE"]..L["TITAN_REPAIR"]..": ".."|r"
				..L["TITAN_REPAIR_GBANK_NORIGHTS"])
		end
	else -- Use own funds
		if TR.show_debug then
			debug_msg("Use own gold "
				.." $"..tostring(cost)..""
				.." gold: "..tostring(money)
				)
		end
		if money > cost then
			RepairAllItems()
			-- report repair cost to chat (optional)
			if TitanGetVar(TITAN_REPAIR_ID,"AutoRepairReport") then
				DEFAULT_CHAT_FRAME:AddMessage(_G["GREEN_FONT_COLOR_CODE"]..L["TITAN_REPAIR"]..": ".."|r"
					..format(L["TITAN_REPAIR_REPORT_COST_CHAT_YOU"], GetTextGSC(cost)).."\n")
			end
			-- disable repair all icon in merchant
			MerchantRepairAllButton:Disable();
			-- disable guild bank repair all icon in merchant
			MerchantGuildBankRepairButton:Disable();
		else
			DEFAULT_CHAT_FRAME:AddMessage(_G["GREEN_FONT_COLOR_CODE"]..L["TITAN_REPAIR"]..": ".."|r"..L["TITAN_REPAIR_CANNOT_AFFORD"])
		end
	end
end

---local Rummage through bags, selling any gray items.
local function TitanRepair_SellGrayItems()
	if TR.show_debug then
		debug_msg("Selling gray items")
	end

	for bag = 0, 4 do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local info = C_Container.GetContainerItemInfo(bag, slot)
			if info and info.quality == 0 then 
				if TR.show_debug then
					local name, _, value
						name,
						_, -- link
						_, -- quality
						_, -- level
						_, -- min level
						_, -- type
						_, -- sub type
						_, -- stack count
						_, -- loc
						_, -- texture
						value,
						_, -- class id
						_, -- sub class id
						_, -- bind type
						_, -- xpac id
						_, -- set id
						_ -- is crafting reagent
						= GetItem(info.itemID)
					local msg = "Selling"
					.." "..tostring(info.stackCount)..""
					.." "..tostring(name)..""
					.." $ "..tostring(GetGSC(info.stackCount * value))..""
					.." "..tostring(bag)..""
					.." "..tostring(slot)..""
					debug_msg(msg)
				end
				
				-- Sell item(s)
				for i = 1, info.stackCount do
					C_Container.UseContainerItem(bag, slot)
				end
			else
				-- ignore - not gray
			end
		end
	end
end

---local Color (green / white / red) the given string based on its durability % 
---@param item_frac number
---@param valueText string
---@return string
local function AutoHighlight (item_frac, valueText)
	-- Basic threshold coloring
	-- Do not check for <= 0.90 or <= 0.20 because fractional eguality test is not acurate...
	if (TitanGetVar(TITAN_REPAIR_ID, "ShowColoredText")) then
		if (item_frac < 21) then
			valueText = TitanUtils_GetRedText(valueText);
		elseif (item_frac < 91) then
			valueText = TitanUtils_GetHighlightText(valueText);
		else
			valueText = TitanUtils_GetGreenText(valueText);
		end
	else
		valueText = TitanUtils_GetHighlightText(valueText);
	end

	return valueText;
end

---local Handle events registered to plugin
---@param self Button
---@param event string
---@param ... any
local function OnEvent(self, event, a1, ...)

	if TR.show_debug then
		local msg = "Event"
			.." "..tostring(event)
			.." "..tostring(a1)
			.."..."
		debug_msg(msg)
	end

	if (event == "PLAYER_REGEN_ENABLED")
	or (event == "UNIT_INVENTORY_CHANGED" and a1 == "player")
	or (event == "UPDATE_INVENTORY_DURABILITY")
	then
		Scan(event, false)
	end
--[[
	if (event == "PLAYER_MONEY" and TR.MerchantisOpen == true and CanMerchantRepair())
	then
		Scan(event, true)
	end
--]]
	if (event == "MERCHANT_SHOW") then
		TR.MerchantisOpen = true;
		local canRepair = CanMerchantRepair();
		-- handle sell ALL grays
		if (TitanGetVar(TITAN_REPAIR_ID,"SellAllGray") == 1) then
			if (TR.grays.total > 0) then
				TitanRepair_SellGrayItems()
				Scan("MERCHANT_SHOW - auto SellAllGray", true)
			end
		end
		
		if canRepair then
			-- keep going
		else
			return -- save a few cycles
		end
		self:RegisterEvent("PLAYER_MONEY") -- this prevents extra scan requests on looting...
		if TitanGetVar(TITAN_REPAIR_ID,"ShowPopup") == 1 then
			if (TR.repair_total > 0) then
				TR.MONEY = TR.repair_total;
				StaticPopup_Show("REPAIR_CONFIRMATION");
			end
		end
		-- handle auto-repair
		if (TitanGetVar(TITAN_REPAIR_ID,"AutoRepair") == 1) then
			if (TR.repair_total > 0) then
				TitanRepair_RepairItems();
				Scan("MERCHANT_SHOW - AutoRepair", true)
			end
		end
	end

	if ( event == "MERCHANT_CLOSED" ) then
		TR.MerchantisOpen = false;

		StaticPopup_Hide("REPAIR_CONFIRMATION");
		-- When an object is repaired in a bag, the BAG_UPDATE event is not sent so we rescan all
		Scan("MERCHANT_CLOSED",  true)
		self:UnregisterEvent("PLAYER_MONEY");
	end

	if TR.show_debug then
		local msg = "...Event"
			.." "..tostring(event)
			.." ".."complete"
		debug_msg(msg)
	end
end

local function OnClick(self, button)
	if button == "LeftButton" and IsShiftKeyDown() then
		TitanUtils_CloseAllControlFrames();
		if (TitanPanelRightClickMenu_IsVisible()) then
			TitanPanelRightClickMenu_Close();
		end
		Scan("User Sh+L click", true)
	elseif button == "LeftButton" then
		if TR.MerchantisOpen == true  then
			TitanRepair_SellGrayItems()
			Scan("MERCHANT_SHOW - user intiated SellAllGray", true)
		end
	else
		TitanPanelButton_OnClick(self, button);
	end
end

local function GetDiscountCost(sum)
		local costStr = ""
		local discountlabel = ""
		-- show cost per the user choice

		if (sum > 0 and TitanGetVar(TITAN_REPAIR_ID,"ShowRepairCost")) then
			-- if a discount was requested by user
			if TitanGetVar(TITAN_REPAIR_ID, "DiscountFriendly") then
				sum = sum * 0.95;
				discountlabel = FACTION_STANDING_LABEL5;
			elseif TitanGetVar(TITAN_REPAIR_ID, "DiscountHonored") then
				sum = sum * 0.90;
				discountlabel = FACTION_STANDING_LABEL6;
			elseif TitanGetVar(TITAN_REPAIR_ID, "DiscountRevered") then
				sum = sum * 0.85;
				discountlabel = FACTION_STANDING_LABEL7;
			elseif TitanGetVar(TITAN_REPAIR_ID, "DiscountExalted") then
				sum = sum * 0.80;
				discountlabel = FACTION_STANDING_LABEL8;
			end
			costStr = "(".. GetTextGSC(sum)..")";
			discountlabel = " "..GREEN_FONT_COLOR_CODE..discountlabel..FONT_COLOR_CODE_CLOSE
		else
			-- user does not want to see cost; clear the reputation also
			costStr = ""
			discountlabel = ""
		end
		
		return costStr, discountlabel
end

---local Determine the plugin button text based on last scan values and user preferences.
---@param id string
---@return string text_label
---@return string text
---@return string | nil most_label
---@return string | nil most
---@return string | nil gray_header
---@return string | nil gray_total
local function GetButtonText(id)
	local itemNamesToShow = ""
	local itemPercent = 0
	local itemCost = 0
	local res = ""
	local msg = "Repair _text"

	local totals = TitanGetVar(TITAN_REPAIR_ID,"ShowTotals")
	local dmg = TitanGetVar(TITAN_REPAIR_ID,"ShowMostDamaged")
	local gray = TitanGetVar(TITAN_REPAIR_ID,"ShowGray")
	
	if (TR.show_debug) then
		msg = msg.." : running "
			.." totals:"..tostring(totals)..""
			.." dmg:"..tostring(dmg)..""
			.." gray:"..tostring(gray)..""
		debug_msg(msg)
	end

	-- supports turning off labels

	local text = ""
	if TR.scan_running then
		res = text.." ("..L["TITAN_REPAIR_LOCALE_WHOLESCANINPROGRESS"]..")"

		if (TR.show_debug) then
			debug_msg(res)
		end

		return L["TITAN_REPAIR_LOCALE_BUTTON"], res
	else
		-- ======
		-- Get repair totals
		local text_label = ""
		if (TitanGetVar(TITAN_REPAIR_ID,"ShowTotals")) then
			text_label = L["TITAN_REPAIR_LOCALE_BUTTON"]
			local dura_total = TR.dur_total
			text = string.format("%d%%", dura_total)
			text = AutoHighlight(dura_total, text)
			text = text.." " -- total %

			-- show cost per the user choice
			local costStr, discountlabel = GetDiscountCost(TR.repair_total)
			text = text..costStr..discountlabel
		else
			-- not requested
		end

		-- ======
		-- Get most damaged
		local most_label = ""
		local most = ""
		if (TitanGetVar(TITAN_REPAIR_ID,"ShowMostDamaged")) then
			most_label = L["TITAN_REPAIR_LOCALE_MOSTDAMAGED"]..": "
			if TR.equip_most.name == UNKNOWN then
				-- nothing damaged
				most = TitanUtils_GetNormalText((NONE or "None"))
			else
				most = string.format("%d%%", TR.equip_most.dur_per)
				most = AutoHighlight (TR.equip_most.dur_per, most)

				-- name with color
				most = most.." ".."|c"..TR.equip_most.color..TR.equip_most.name.._G["FONT_COLOR_CODE_CLOSE"]
			end
		else
			-- not requested
		end

		-- ======
		-- calculate gray totals
		local gray_header = ""
		local gray_total = ""
		if (TitanGetVar(TITAN_REPAIR_ID,"ShowGray")) then
			gray_header = ITEM_QUALITY0_DESC..": " -- Poor / gray
			gray_total = GetTextGSC(TR.grays.total)
		else
		end

		if (TR.show_debug) then
			msg = text.." "..most.." "..gray_total
			debug_msg(msg)
		end

		-- Now that the pieces have been created, return the whole string
		return text_label, text,
			most_label, most,
			gray_header, gray_total
	end
end

---local Create the Repair tool tip based on last scan and user preferences.
---@return string tooltip_text
local function GetTooltipText()
	local out = "";
	local cost = 0;
	local sum = TR.repair_total

	if TR.show_debug_tooltip then
		local msg = "Tooltip Start "
			.." items:"..tostring(TitanGetVar(TITAN_REPAIR_ID,"ShowItems"))
			.." discounts:"..tostring(TitanGetVar(TITAN_REPAIR_ID,"ShowDiscounts"))
			.." costs:"..tostring(TitanGetVar(TITAN_REPAIR_ID,"ShowCosts"))
			.." guild:"..tostring(TitanGetVar(TITAN_REPAIR_ID,"UseGuildBank"))
			.." show gray:"..tostring(TitanGetVar(TITAN_REPAIR_ID,"ShowGray"))
			.." sell gray:"..tostring(TitanGetVar(TITAN_REPAIR_ID,"SellAllGray"))
		debug_msg(msg)
	end

	if (TitanGetVar(TITAN_REPAIR_ID,"ShowItems")) then
		out = out..TitanUtils_GetGoldText(L["TITAN_REPAIR_LOCALE_ITEMS"]).."\n"

		local num_items = 0
		-- walk items saved from the scan
--		for slotName, sID in pairs(Enum.InventoryType) do
		for slotID = TR.scan_end, TR.scan_start, 1 do  -- thru slots
			local slotName = slots[slotID].name
			if TR.equip_list[slotName] then
				-- determine the percent or value per user request
				local valueText = ""
---[[
				if TR.show_debug_tooltip then
					local msg = ""
						.." '"..tostring(slotName).."'"
						.." '"..tostring(TR.equip_list[slotName].name).."'"
						.." "..tostring(TR.equip_list[slotName].quality)
						.." "..tostring(TR.equip_list[slotName].cost)
						.." "..tostring(TR.equip_list[slotName].dur_per).."%"
						.." "..tostring(TR.equip_list[slotName].dur_cur)
						.."/"..tostring(TR.equip_list[slotName].dur_max)
					debug_msg(msg)
				end
--]]
				if (TitanGetVar(TITAN_REPAIR_ID,"ShowPercentage")) then
					valueText = string.format("%d%%", TR.equip_list[slotName].dur_per)
				else
					valueText = string.format("%d/%d", TR.equip_list[slotName].dur_cur, TR.equip_list[slotName].dur_max)
				end
				-- % color
				out = out..AutoHighlight(TR.equip_list[slotName].dur_per, valueText).."  "
				-- name with color
				out = out.."|c"..TR.equip_list[slotName].color..TR.equip_list[slotName].name.._G["FONT_COLOR_CODE_CLOSE"]
				-- add column
				out = out.."\t"
				-- add cost
				out = out..GetTextGSC(TR.equip_list[slotName].cost)
				out = out.."\n"
				
				num_items = num_items + 1
			else
				-- slot is empty or not 'damaged'
			end
		end
		
		if num_items == 0 then
			-- All items are at 100%
			out = out..TitanUtils_GetHighlightText("No items damaged").."\n"
		end
		if TR.show_debug_tooltip then
			debug_msg(tostring("Items shown : "..num_items))
		end
	end

	out = out.."\n" -- spacer
	if (TitanGetVar(TITAN_REPAIR_ID,"ShowDiscounts")) then
		if (sum > 0) then
			out = out..TitanUtils_GetGoldText(L["TITAN_REPAIR_LOCALE_DISCOUNTS"])..TitanUtils_GetHighlightText("").."\n"
			out = out.. TitanUtils_GetHighlightText(L["TITAN_REPAIR_LOCALE_NORMAL"]) .. "\t" .. GetTextGSC(sum).."\n"
			out = out.. TitanUtils_GetHighlightText(L["TITAN_REPAIR_LOCALE_FRIENDLY"]) .. "\t" .. GetTextGSC(sum * 0.95).."\n"
			out = out.. TitanUtils_GetHighlightText(L["TITAN_REPAIR_LOCALE_HONORED"]) .. "\t" .. GetTextGSC(sum * 0.90).."\n"
			out = out.. TitanUtils_GetHighlightText(L["TITAN_REPAIR_LOCALE_REVERED"]) .. "\t" .. GetTextGSC(sum * 0.85).."\n"
			out = out.. TitanUtils_GetHighlightText(L["TITAN_REPAIR_LOCALE_EXALTED"]) .. "\t" .. GetTextGSC(sum * 0.80).."\n"
		else
			out = out..TitanUtils_GetGoldText(L["TITAN_REPAIR_LOCALE_DISCOUNTS"]).."\t".."|cffa0a0a0"..NONE.."|r".."\n"
		end
		out = out.."\n"
	end

	if (TitanGetVar(TITAN_REPAIR_ID,"ShowCosts")) then
		if (sum > 0) then
			out = out..TitanUtils_GetGoldText(L["TITAN_REPAIR_LOCALE_COSTS"]).." ".."\n"
			out = out.. TitanUtils_GetHighlightText(L["TITAN_REPAIR_LOCALE_COSTEQUIP"]).." : ".. "\t" .. GetTextGSC(TR.repair_equip.total).."\n"
			out = out.. TitanUtils_GetHighlightText(L["TITAN_REPAIR_LOCALE_COSTBAG"]).." : ".. "\t" .. GetTextGSC(TR.repair_bags.total).."\n"
			out = out.. "---".. "\t" .. "---".."\n"
			out = out.. TitanUtils_GetHighlightText(REPAIR_COST).. "\t" .. GetTextGSC(TR.repair_total).."\n"
		else
			out = out..TitanUtils_GetGoldText(L["TITAN_REPAIR_LOCALE_COSTS"]).."\t".."|cffa0a0a0"..NONE.."|r".."\n"
		end
		out = out .. "\n"
	end

	if (TitanGetVar(TITAN_REPAIR_ID,"ShowGray")) 
	or (TitanGetVar(TITAN_REPAIR_ID,"SellAllGray")) then
		if (TR.grays.total > 0) then
			out = out..TitanUtils_GetGoldText(ITEM_QUALITY0_DESC).." : ".. "\t" .. GetTextGSC(TR.grays.total).."\n"
		else
			out = out..TitanUtils_GetGoldText(ITEM_QUALITY0_DESC).."\t".."|cffa0a0a0"..NONE.."|r".."\n"
		end
		out = out .. "\n"
	end

	-- Show the guild - if player is in one
	--GUILDBANK_REPAIR
	if TR.guild_bank and IsInGuild() then
		out = out..TitanUtils_GetGoldText(GUILD).."\n"
		local name, rank, index, realm = GetGuildInfo("player")
		out = out..TitanUtils_GetHighlightText(name).." : ".."\t"..TitanUtils_GetHighlightText(rank).."\n"

		if TitanGetVar(TITAN_REPAIR_ID, "UseGuildBank") then
			if CanGuildBankRepair() then
				if IsGuildLeader() then
				-- Can use the whole bank amount...
					out = out..TitanUtils_GetHighlightText(WITHDRAW.." "..AVAILABLE).."\t" ..UNLIMITED.."\n"
				else
					local withdrawLimit = GetGuildBankWithdrawMoney()
					if withdrawLimit == nil then
						withdrawLimit = 0
					else
						-- limit is known
					end
					out = out..TitanUtils_GetHighlightText(WITHDRAW.." "..AVAILABLE).."\t"..GetTextGSC(withdrawLimit).."\n"
					if (withdrawLimit >= sum) then
						-- funds available
					else
						out = out.. TitanUtils_GetRedText(GUILDBANK_REPAIR_INSUFFICIENT_FUNDS).."\n"
					end
				end
			else
				out = out..TitanUtils_GetHighlightText(WITHDRAW.." "..AVAILABLE).."\t".."|cffa0a0a0"..NONE.."|r".."\n"
			end
		else
			out = out..TitanUtils_GetHighlightText(L["TITAN_REPAIR_GBANK_USEFUNDS"]).." : ".."\t"..TitanUtils_GetHighlightText(tostring(false)).."\n"
		end
		out = out .. "\n"
	else
	-- skip
	end

	out = out..L["TITAN_REPAIR_LOCALE_AUTOREPLABEL"].." : ".."\t"
		..TitanUtils_GetHighlightText(tostring(TitanGetVar(TITAN_REPAIR_ID, "AutoRepair") and true or false)).."\n"
	out = out..L["TITAN_REPAIR_LOCALE_SHOWINVENTORY"].." : ".."\t"
		..TitanUtils_GetHighlightText(tostring(TitanGetVar(TITAN_REPAIR_ID, "ShowInventory") and true or false)).."\n"
	out = out.."Sell ALL "..ITEM_QUALITY0_DESC.." : ".."\t"
		..TitanUtils_GetHighlightText(tostring(TitanGetVar(TITAN_REPAIR_ID, "SellAllGray") and true or false)).."\n"
	out = out.."\n"

	out = out..TitanUtils_GetGreenText("Hint: Left click to sell ALL "..ITEM_QUALITY0_DESC.." items - CAUTION\n")
	out = out.."\t"..TitanUtils_GetGreenText("Only while merchant is open ".."\n")
	out = out..TitanUtils_GetGreenText("Hint: Shift + Left click to force a scan of repair info.")

	return out
end

---local Create the Repair right click menu
local function CreateMenu()
	local info;

	-- level 2
	if TitanPanelRightClickMenu_GetDropdownLevel() == 2 then
		if TitanPanelRightClickMenu_GetDropdMenuValue() == "Discount" then
			TitanPanelRightClickMenu_AddTitle(L["TITAN_REPAIR_LOCALE_DISCOUNT"], TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_BUTTONNORMAL"];
			info.checked = not TitanGetVar(TITAN_REPAIR_ID,"DiscountFriendly") and not TitanGetVar(TITAN_REPAIR_ID,"DiscountHonored") and not TitanGetVar(TITAN_REPAIR_ID,"DiscountRevered") and not TitanGetVar(TITAN_REPAIR_ID,"DiscountExalted");
			info.disabled = TR.MerchantisOpen;
			info.func = function()
				TitanSetVar(TITAN_REPAIR_ID,"DiscountFriendly", nil)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountHonored", nil)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountRevered", nil)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountExalted", nil)
				TitanPanelButton_UpdateButton(TITAN_REPAIR_ID)
			end
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_BUTTONFRIENDLY"];
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"DiscountFriendly");
			info.disabled = TR.MerchantisOpen;
			info.func = function()
				TitanSetVar(TITAN_REPAIR_ID,"DiscountFriendly", 1)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountHonored", nil)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountRevered", nil)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountExalted", nil)
				TitanPanelButton_UpdateButton(TITAN_REPAIR_ID)
			end
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_BUTTONHONORED"];
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"DiscountHonored");
			info.disabled = TR.MerchantisOpen;
			info.func = function()
				TitanSetVar(TITAN_REPAIR_ID,"DiscountFriendly", nil)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountHonored", 1)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountRevered", nil)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountExalted", nil)
				TitanPanelButton_UpdateButton(TITAN_REPAIR_ID)
			end
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_BUTTONREVERED"];
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"DiscountRevered");
			info.disabled = TR.MerchantisOpen;
			info.func = function()
				TitanSetVar(TITAN_REPAIR_ID,"DiscountFriendly", nil)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountHonored", nil)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountRevered", 1)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountExalted", nil)
				TitanPanelButton_UpdateButton(TITAN_REPAIR_ID)
			end
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_BUTTONEXALTED"];
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"DiscountExalted");
			info.disabled = TR.MerchantisOpen;
			info.func = function()
				TitanSetVar(TITAN_REPAIR_ID,"DiscountFriendly", nil)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountHonored", nil)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountRevered", nil)
				TitanSetVar(TITAN_REPAIR_ID,"DiscountExalted", 1)
				TitanPanelButton_UpdateButton(TITAN_REPAIR_ID)
			end
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		end

		if TitanPanelRightClickMenu_GetDropdMenuValue() == "Options" then
			TitanPanelRightClickMenu_AddTitle(L["TITAN_PANEL_OPTIONS"], TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_SHOW_TOTAL"];
			info.func = function() 
				TitanToggleVar(TITAN_REPAIR_ID, "ShowTotals")
				TitanPanelButton_UpdateButton(TITAN_REPAIR_ID)
				end
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"ShowTotals")
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel())

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_MOSTDAMAGED"]
			info.func = function() 
				TitanToggleVar(TITAN_REPAIR_ID, "ShowMostDamaged")
				TitanPanelButton_UpdateButton(TITAN_REPAIR_ID)
				end
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"ShowMostDamaged")
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel())

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_SHOWINVENTORY"];
			info.func = function() 
				TitanToggleVar(TITAN_REPAIR_ID, "ShowInventory");
				Scan("Calc inventory durability", true)
				end
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"ShowInventory");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_SHOWREPAIRCOST"];  --"Show Repair Cost"
			info.func = function() 
				TitanToggleVar(TITAN_REPAIR_ID, "ShowRepairCost");
				TitanPanelButton_UpdateButton(TITAN_REPAIR_ID);
				end
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"ShowRepairCost");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_SHOWREPAIRCOST"].." Gold Only"  
			info.func = function() 
				TitanToggleVar(TITAN_REPAIR_ID, "ShowCostGoldOnly")
				TitanPanelButton_UpdateButton(TITAN_REPAIR_ID);
				end
			info.checked = TitanGetVar(TITAN_REPAIR_ID, "ShowCostGoldOnly");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = "Show "..ITEM_QUALITY0_DESC.." Total"
			info.func = function() 
				TitanToggleVar(TITAN_REPAIR_ID, "ShowGray");
				Scan("Calc inventory gray", true)
				TitanPanelButton_UpdateButton(TITAN_REPAIR_ID);
				end
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"ShowGray");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = "Sell ALL "..ITEM_QUALITY0_DESC.." Items - CAUTION"
			info.func = function() 
				TitanToggleVar(TITAN_REPAIR_ID, "SellAllGray");
				end
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"SellAllGray");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		end

		if TitanPanelRightClickMenu_GetDropdMenuValue() == "AutoRepair" then
			TitanPanelRightClickMenu_AddTitle(L["TITAN_REPAIR_LOCALE_AUTOREPLABEL"], TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_POPUP"];
			info.func = function()
				TitanToggleVar(TITAN_REPAIR_ID, "ShowPopup");
				if TitanGetVar(TITAN_REPAIR_ID,"ShowPopup") and TitanGetVar(TITAN_REPAIR_ID,"AutoRepair") then
					TitanSetVar(TITAN_REPAIR_ID,"AutoRepair",nil);
				end
				end
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"ShowPopup");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_AUTOREPITEMLABEL"];
			info.func = function()
				TitanToggleVar(TITAN_REPAIR_ID, "AutoRepair");
				if TitanGetVar(TITAN_REPAIR_ID,"AutoRepair") and TitanGetVar(TITAN_REPAIR_ID,"ShowPopup") then
					TitanSetVar(TITAN_REPAIR_ID,"ShowPopup",nil);
				end
				end
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"AutoRepair");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_REPORT_COST_MENU"]
			info.func = function() TitanToggleVar(TITAN_REPAIR_ID, "AutoRepairReport"); end
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"AutoRepairReport");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			if TR.guild_bank then
				info = {}
				info.text = L["TITAN_REPAIR_GBANK_USEFUNDS"]
				info.func = function() TitanToggleVar(TITAN_REPAIR_ID, "UseGuildBank"); end
				info.checked = TitanGetVar(TITAN_REPAIR_ID,"UseGuildBank");
				TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
			else
				-- skip
			end
		end

		if TitanPanelRightClickMenu_GetDropdMenuValue() == "TooltipOptions" then
			TitanPanelRightClickMenu_AddTitle(L["TITAN_REPAIR_LOCALE_TOOLTIPOPTIONS"], TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_SHOWITEMS"];
			info.func = function() TitanToggleVar(TITAN_REPAIR_ID, "ShowItems"); end
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"ShowItems");
			info.keepShownOnClick = 1
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_UNDAMAGED"];
			info.func = function() 
				TitanToggleVar(TITAN_REPAIR_ID, "ShowUndamaged");
				end
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"ShowUndamaged");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_PERCENTAGE"];
			info.func = function()
				TitanToggleVar(TITAN_REPAIR_ID, "ShowPercentage");
				TitanPanelButton_UpdateButton(TITAN_REPAIR_ID);
			end
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"ShowPercentage");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_SHOWDISCOUNTS"];
			info.func = function() TitanToggleVar(TITAN_REPAIR_ID, "ShowDiscounts"); end
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"ShowDiscounts");
			info.keepShownOnClick = 1
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_REPAIR_LOCALE_SHOWCOSTS"];
			info.func = function() TitanToggleVar(TITAN_REPAIR_ID, "ShowCosts"); end
			info.checked = TitanGetVar(TITAN_REPAIR_ID,"ShowCosts");
			info.keepShownOnClick = 1
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		end

		return
	end

	-- level 1
	TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_REPAIR_ID].menuText);

	info = {};
	info.notCheckable = true
	info.text = L["TITAN_PANEL_OPTIONS"];
	info.value = "Options"
	info.hasArrow = 1;
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.notCheckable = true
	info.text = L["TITAN_REPAIR_LOCALE_AUTOREPLABEL"];
	info.value = "AutoRepair"
	info.hasArrow = 1;
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.notCheckable = true
	info.text = L["TITAN_REPAIR_LOCALE_DISCOUNT"];
	info.value = "Discount"
	info.hasArrow = 1;
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.notCheckable = true
	info.text = L["TITAN_REPAIR_LOCALE_TOOLTIPOPTIONS"];
	info.value = "TooltipOptions"
	info.hasArrow = 1;
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddControlVars(TITAN_REPAIR_ID)
end

---local Create the .registry for the plugin.
---@param self Button
local function OnLoad(self)
	local notes = ""
		.."Provides a configurable durability display. Adds the ability to auto repair items and inventory at vendors.\n"
		.."- Shift + Left - Click forces a scan.\n"
		.."- Left - Click now sells ALL gray items - use with CAUTION!\n"
		.."- Option to auto sell ALL gray items - use with CAUTION!\n"
	self.registry = {
		id = TITAN_REPAIR_ID,
		category = "Built-ins",
		version = TITAN_VERSION,
		menuText = L["TITAN_REPAIR_LOCALE_MENU"],
		menuTextFunction = CreateMenu,
		buttonTextFunction = GetButtonText,
		tooltipTitle = L["TITAN_REPAIR_LOCALE_TOOLTIP"],
		tooltipTextFunction = GetTooltipText,
		icon = "Interface\\AddOns\\TitanRepair\\TitanRepair",
		iconWidth = 16,
		notes = notes,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowColoredText = true,
			DisplayOnRightSide = true,
		},
		savedVariables = {
			ShowIcon = 1,
			ShowLabelText = 1,
			ShowMostDamaged = false,
			ShowTotals = true,
			ShowUndamaged = false,
			ShowPopup = false,
			AutoRepair = false,
			DiscountFriendly = false,
			DiscountHonored = false,
			DiscountRevered = false,
			DiscountExalted = false,
			ShowPercentage = false,
			ShowColoredText = false,
			ShowInventory = false,
			ShowRepairCost = 1,
			ShowMostDmgPer = 1,
			UseGuildBank = false,
			AutoRepairReport = false,
			ShowItems = true,
			ShowDiscounts = true,
			ShowCosts = true,
			DisplayOnRightSide = false,
			ShowGray = false,
			SellAllGray = false,
			ShowCostGoldOnly = false,
		}
	};
end

---local Create plugin, tooltip, and pop up frames; set frame scripts.
local function Create_Frames()
	if _G[TITAN_BUTTON] then
		return -- if already created
	end
	
	if C_TooltipInfo then -- use a proxy for retail (true) versus classic (false)
		-- Not needed for retail
	else
		local tool_tip = CreateFrame("GameTooltip", "TitanRepairTooltip", UIParent, "GameTooltipTemplate")
--		<GameTooltip name="TitanRepairTooltip" inherits="GameTooltipTemplate" parent="UIParent" hidden="true"/>
	end

	-- general container frame
	local f = CreateFrame("Frame", nil, UIParent)
--	f:Hide()

	-- Titan plugin button
	local window = CreateFrame("Button", TITAN_BUTTON, f, "TitanPanelComboTemplate")
	window:SetFrameStrata("FULLSCREEN")
	-- Using SetScript("OnLoad",   does not work
	OnLoad(window);
--	TitanPanelButton_OnLoad(window); -- Titan XML template calls this...
	
	window:SetScript("OnEvent", function(self, event, ...)
		OnEvent(self, event, ...) 
	end)
	window:SetScript("OnClick", function(self, button)
		OnClick(self, button)
		TitanPanelButton_OnClick(self, button)
	end)
	window:SetScript("OnShow", function(self, button)
		RepairShow(self)
	end)
	window:SetScript("OnHide", function(self, button)
		RepairHide(self)
	end)

	StaticPopupDialogs["REPAIR_CONFIRMATION"] = {
		text = L["TITAN_REPAIR_LOCALE_CONFIRMATION"],
		button1 = YES,
		button2 = NO,
		OnAccept = function(self)
			TitanRepair_RepairItems();
		end,
		OnShow = function(self)
			MoneyFrame_Update(self.moneyFrame, TR.repair_total);
		end,
		hasMoneyFrame = 1,
		timeout = 0,
		hideOnEscape = 1
	};


end

Create_Frames()
