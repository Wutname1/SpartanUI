local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
-- local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local AceHook = LibStub("AceHook-3.0")
local module = spartan:NewModule("Component_AutoSell", "AceTimer-3.0");
----------------------------------------------------------------------------------------------------
local frame = CreateFrame("FRAME");
local totalValue = 0
local iCount = 0
local iSellCount = 0
local Timer = nil
local bag = 0
local OnlyCount = true

function module:OnInitialize()
	if not DB.AutoSell then
		DB.AutoSell = {
			FirstLaunch = true,
			Gray = true,
			White = false,
			Green = false,
			Blue = false,
			Purple = false
		}
	end
end

function module:FirstTime()
	StaticPopupDialogs["AutoSell1"] = {
		text = '|cff33ff99SpartanUI Notice: |cffff3333AutoSell|n|r|n A new SpartanUI Module has been added that can automatically sell gray items. |n|r|n Would you like to enable this new Module?',
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			DB.AutoSell.FirstLaunch = false
		end,
		OnCancel = function()
			DB.EnabledComponents.AutoSell = false
			DB.AutoSell.FirstLaunch = false
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	StaticPopup_Show("AutoSell1")
end

-- Sell Items 5 at a time, sometimes it can sell stuff too fast for the game.
function module:SellTrashInBag()
    if GetContainerNumSlots(bag) == 0 then
		return 0;
	end
	
	local solditem = 0;
	for slot = 1, GetContainerNumSlots(bag) do
		local iLink = GetContainerItemLink(bag, slot);
		if module:IsGray(iLink) then
			if OnlyCount then
				iCount = iCount + 1
			elseif solditem ~= 5 then
				solditem = solditem + 1
				iSellCount = iSellCount + 1
				UseContainerItem(bag, slot);
				totalValue = totalValue + (select(11, GetItemInfo(iLink)) * select(2, GetContainerItemInfo(bag, slot)));
			end
		end
	end
	
	if OnlyCount then return end
	
	if solditem == 5 then
		--Process this bag again.
	elseif bag ~= 4 then
		--Next bag
		bag = bag+1
	else
		--Everything sold
		if (totalValue > 0) then
			spartan:Print("Sold items for " .. module:GetFormattedTrashValue(totalValue));
			totalValue = 0
		end
		module:CancelAllTimers()
	end
end

function module:IsGray(item)
	return item and select(3, GetItemInfo(item)) == 0;
end

function module:GetFormattedTrashValue(rawValue)
	local gold = math.floor(rawValue / 10000);
	local silver = math.floor((rawValue % 10000) / 100);
	local copper = (rawValue % 10000) % 100;
	
	return format(GOLD_AMOUNT_TEXTURE.." "..SILVER_AMOUNT_TEXTURE.." "..COPPER_AMOUNT_TEXTURE, gold, 0, 0, silver, 0, 0, copper, 0, 0);
end

function module:SellTrash()
	--Reset Locals
	totalValue = 0
	iCount = 0
	iSellCount = 0
	Timer = nil
	bag = 0
	
	--Count Items to sell
    OnlyCount=true
	for b = 0, 4 do
		bag = b
		module:SellTrashInBag();
    end
	if iCount == 0 then
		spartan:Print("No items are to be auto sold")
	else
		spartan:Print("Need to sell " .. iCount .. " item(s)")
	end
	
	--Start Loop to sell, reset locals
	OnlyCount=false
	bag = 0
	-- C_Timer.After(.2, SellTrashInBag)
	self.SellTimer = self:ScheduleRepeatingTimer("SellTrashInBag", .3)
end

function module:OnEnable()
	-- if not DB.EnabledComponents.AutoSell then return end
	frame:RegisterEvent("MERCHANT_SHOW");
	frame:RegisterEvent("MERCHANT_CLOSED");
	local function MerchantEventHandler(self, event, ...)
		if DB.AutoSell.FirstLaunch then module:FirstTime() return end
		if not DB.EnabledComponents.AutoSell then return end
		if event == "MERCHANT_SHOW" then
			module:SellTrash();
		else
			module:CancelAllTimers()
			if (totalValue > 0) then
				spartan:Print("Sold items for " .. module:GetFormattedTrashValue(totalValue));
				totalValue = 0
			end
		end
	end
	frame:SetScript("OnEvent", MerchantEventHandler);
end