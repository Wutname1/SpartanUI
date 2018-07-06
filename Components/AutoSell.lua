local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI")
local module = spartan:NewModule("Component_AutoSell", "AceTimer-3.0")
----------------------------------------------------------------------------------------------------
local frame = CreateFrame("FRAME")
local totalValue = 0
local iCount = 0
local iSellCount = 0
local bag = 0
local OnlyCount = true
local inSet = {}
local ExcludedItems = {
	137642, --Mark Of Honor
	141446 --Tome of the Tranquil Mind
}

function module:OnInitialize()
	local Defaults = {
		FirstLaunch = true,
		NotCrafting = true,
		NotConsumables = true,
		NotInGearset = true,
		MaxILVL = 200,
		Gray = true,
		White = false,
		Green = false,
		Blue = false,
		Purple = false,
		GearTokens = false
	}
	if not SUI.DB.AutoSell then
		SUI.DB.AutoSell = Defaults
	else
		SUI.DB.AutoSell = spartan:MergeData(SUI.DB.AutoSell, Defaults, false)
	end
	if SUI.DB.AutoSell.MaxILVL >= 501 then
		SUI.DB.AutoSell.MaxILVL = 200
	end
end

function module:FirstTime()
	local PageData = {
		SubTitle = "Auto Sell",
		Desc1 = "Automatically vendor items when you visit a merchant.",
		Desc2 = "Crafting, consumables, and gearset items will not be sold by default.",
		Display = function()
			local gui = LibStub("AceGUI-3.0")
			--Container
			SUI_Win.AutoSell = CreateFrame("Frame", nil)
			SUI_Win.AutoSell:SetParent(SUI_Win.content)
			SUI_Win.AutoSell:SetAllPoints(SUI_Win.content)

			--TurnInEnabled
			SUI_Win.AutoSell.Enabled =
				CreateFrame("CheckButton", "SUI_AutoSell_Enabled", SUI_Win.AutoSell, "OptionsCheckButtonTemplate")
			SUI_Win.AutoSell.Enabled:SetPoint("TOP", SUI_Win.AutoSell, "TOP", -90, -10)
			SUI_AutoSell_EnabledText:SetText("Auto Vendor Enabled")
			SUI_Win.AutoSell.Enabled:HookScript(
				"OnClick",
				function(this)
					if this:GetChecked() == true then
						SUI_AutoSell_SellGray:Enable()
						SUI_AutoSell_SellWhite:Enable()
						SUI_AutoSell_SellGreen:Enable()
					else
						SUI_AutoSell_SellGray:Disable()
						SUI_AutoSell_SellWhite:Disable()
						SUI_AutoSell_SellGreen:Disable()
					end
				end
			)

			--SellGray
			SUI_Win.AutoSell.SellGray =
				CreateFrame("CheckButton", "SUI_AutoSell_SellGray", SUI_Win.AutoSell, "OptionsCheckButtonTemplate")
			SUI_Win.AutoSell.SellGray:SetPoint("TOP", SUI_Win.AutoSell.Enabled, "TOP", -90, -40)
			SUI_AutoSell_SellGrayText:SetText("Sell gray items")

			--SellWhite
			SUI_Win.AutoSell.SellWhite =
				CreateFrame("CheckButton", "SUI_AutoSell_SellWhite", SUI_Win.AutoSell, "OptionsCheckButtonTemplate")
			SUI_Win.AutoSell.SellWhite:SetPoint("TOP", SUI_Win.AutoSell.SellGray, "BOTTOM", 0, -5)
			SUI_AutoSell_SellWhiteText:SetText("Sell white items")

			--SellGreen
			SUI_Win.AutoSell.SellGreen =
				CreateFrame("CheckButton", "SUI_AutoSell_SellGreen", SUI_Win.AutoSell, "OptionsCheckButtonTemplate")
			SUI_Win.AutoSell.SellGreen:SetPoint("TOP", SUI_Win.AutoSell.SellWhite, "BOTTOM", 0, -5)
			SUI_AutoSell_SellGreenText:SetText("Sell green items")

			--SellBlue
			SUI_Win.AutoSell.SellBlue =
				CreateFrame("CheckButton", "SUI_AutoSell_SellBlue", SUI_Win.AutoSell, "OptionsCheckButtonTemplate")
			SUI_Win.AutoSell.SellBlue:SetPoint("TOP", SUI_Win.AutoSell.SellGreen, "BOTTOM", 0, -5)
			SUI_AutoSell_SellBlueText:SetText("Sell blue items")

			--SellPurple
			SUI_Win.AutoSell.SellPurple =
				CreateFrame("CheckButton", "SUI_AutoSell_SellPurple", SUI_Win.AutoSell, "OptionsCheckButtonTemplate")
			SUI_Win.AutoSell.SellPurple:SetPoint("TOP", SUI_Win.AutoSell.SellBlue, "BOTTOM", 0, -5)
			SUI_AutoSell_SellPurpleText:SetText("Sell purple items")

			--Max iLVL
			control = gui:Create("Slider")
			control:SetLabel("Max iLVL to sell")
			control:SetSliderValues(1, 1100, 1)
			-- control:SetIsPercent(v.isPercent)
			control:SetValue(700)
			control:SetPoint("TOPLEFT", SUI_Win.AutoSell.SellPurple, "BOTTOMLEFT", 0, -15)
			control:SetWidth(SUI_Win:GetWidth() / 1.3)
			-- control:SetCallback("OnValueChanged",function(self) print(self:GetValue()) end)
			-- control:SetCallback("OnMouseUp",ActivateSlider)
			control.frame:SetParent(SUI_Win.AutoSell)
			control.frame:Show()
			SUI_Win.AutoSell.iLVL = control

			--Defaults
			SUI_AutoSell_Enabled:SetChecked(true)
			SUI_AutoSell_SellGray:SetChecked(true)
		end,
		Next = function()
			SUI.DB.AutoSell.FirstLaunch = false

			SUI.DB.EnabledComponents.AutoSell = (SUI_Win.AutoSell.Enabled:GetChecked() == true or false)
			SUI.DB.AutoSell.Gray = (SUI_Win.AutoSell.SellGray:GetChecked() == true or false)
			SUI.DB.AutoSell.White = (SUI_Win.AutoSell.SellWhite:GetChecked() == true or false)
			SUI.DB.AutoSell.Green = (SUI_Win.AutoSell.SellGreen:GetChecked() == true or false)
			SUI.DB.AutoSell.Blue = (SUI_Win.AutoSell.SellBlue:GetChecked() == true or false)
			SUI.DB.AutoSell.Purple = (SUI_Win.AutoSell.SellPurple:GetChecked() == true or false)
			SUI.DB.AutoSell.MaxILVL = SUI_Win.AutoSell.iLVL:GetValue()

			SUI_Win.AutoSell:Hide()
			SUI_Win.AutoSell = nil
		end,
		Skip = function()
			SUI.DB.AutoSell.FirstLaunch = true
		end
	}
	local SetupWindow = spartan:GetModule("SetupWindow")
	SetupWindow:AddPage(PageData)
	SetupWindow:DisplayPage()
end

-- Sell Items 5 at a time, sometimes it can sell stuff too fast for the game.
function module:SellTrashInBag()
	if GetContainerNumSlots(bag) == 0 then
		return 0
	end

	local solditem = 0
	for slot = 1, GetContainerNumSlots(bag) do
		local _, _, _, _, _, _, link, _, _, itemID =
			GetContainerItemInfo(bag, slot)
		if module:IsSellable(itemID, link) then
			if OnlyCount then
				iCount = iCount + 1
				totalValue = totalValue + (select(11, GetItemInfo(itemID)) * select(2, GetContainerItemInfo(bag, slot)))
			elseif solditem ~= 5 then
				solditem = solditem + 1
				iSellCount = iSellCount + 1
				UseContainerItem(bag, slot)
			end
		end
	end

	if OnlyCount then
		return
	end

	if bag ~= 4 then
		--Next bag
		bag = bag + 1
	else
		--Everything sold
		if (totalValue > 0) then
			spartan:Print("Sold item(s)")
			totalValue = 0
		end
		module:CancelAllTimers()
	end
end

function module:IsSellable(item, ilink)
	if not item then
		return false
	end
	local name,
		_,
		quality,
		iLevel,
		_,
		itemType,
		itemSubType,
		_,
		equipSlot,
		_,
		vendorPrice,
		_,
		_,
		_,
		_,
		itemSetID,
		isCraftingReagent = GetItemInfo(ilink)
	if vendorPrice == 0 or name == nil then
		return false
	end

	-- 0. Poor (gray): Broken I.W.I.N. Button
	-- 1. Common (white): Archmage Vargoth's Staff
	-- 2. Uncommon (green): X-52 Rocket Helmet
	-- 3. Rare / Superior (blue): Onyxia Scale Cloak
	-- 4. Epic (purple): Talisman of Ephemeral Power
	-- 5. Legendary (orange): Fragment of Val'anyr
	-- 6. Artifact (golden yellow): The Twin Blades of Azzinoth
	-- 7. Heirloom (light yellow): Bloodied Arcanite Reaper
	local ilvlsellable = false
	local qualitysellable = false
	local Craftablesellable = false
	local NotInGearset = true
	local NotConsumable = true
	local IsGearToken = false

	if quality == 0 and SUI.DB.AutoSell.Gray then
		qualitysellable = true
	end
	if quality == 1 and SUI.DB.AutoSell.White then
		qualitysellable = true
	end
	if quality == 2 and SUI.DB.AutoSell.Green then
		qualitysellable = true
	end
	if quality == 3 and SUI.DB.AutoSell.Blue then
		qualitysellable = true
	end
	if quality == 4 and SUI.DB.AutoSell.Purple then
		qualitysellable = true
	end

	if (not iLevel) or (iLevel <= SUI.DB.AutoSell.MaxILVL) then
		ilvlsellable = true
	end
	--Crafting Items
	if
		((itemType == "Gem" or itemType == "Reagent" or itemType == "Trade Goods" or itemType == "Tradeskill") or
			(itemType == "Miscellaneous" and itemSubType == "Reagent")) or
			(itemType == "Item Enhancement") or
			isCraftingReagent
	 then
		if not SUI.DB.AutoSell.NotCrafting then
			Craftablesellable = true
		end
	else
		Craftablesellable = true
	end

	--Gearset detection
	if (inSet[item] or itemSetID) and SUI.DB.AutoSell.NotInGearset then
		NotInGearset = false
	end

	--Consumable
	--Tome of the Tranquil Mind is consumable but is identified as Other.
	if SUI.DB.AutoSell.NotConsumables and itemType == "Consumable" then
		NotConsumable = false
	end

	-- Gear Tokens
	if
		quality == 4 and itemType == "Miscellaneous" and itemSubType == "Junk" and equipSlot == "" and
			not SUI.DB.AutoSell.GearTokens
	 then
		IsGearToken = true
	end

	if string.find(name, "Treasure Map") and quality == 1 then
		qualitysellable = false
	end

	if
		qualitysellable and ilvlsellable and Craftablesellable and NotInGearset and NotConsumable and not IsGearToken and
			not spartan:isInTable(ExcludedItems, item) and
			itemType ~= "Quest" and
			itemType ~= "Container" or
			(quality == 0 and SUI.DB.AutoSell.Gray)
	 then --Legion identified some junk as consumable
		if SUI.DB.AutoSell.debug then
			spartan:Print("--Selling--")
			spartan:Print(name)
			spartan:Print(ilink)
			spartan:Print("ilvl:     " .. iLevel)
			spartan:Print("type:     " .. itemType)
			spartan:Print("sub type: " .. itemSubType)
		end
		return true
	end

	return false
end

function module:GetFormattedValue(rawValue)
	local gold = math.floor(rawValue / 10000)
	local silver = math.floor((rawValue % 10000) / 100)
	local copper = (rawValue % 10000) % 100

	return format(
		GOLD_AMOUNT_TEXTURE .. " " .. SILVER_AMOUNT_TEXTURE .. " " .. COPPER_AMOUNT_TEXTURE,
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

function module:SellTrash()
	--Reset Locals
	totalValue = 0
	iCount = 0
	iSellCount = 0
	Timer = nil
	bag = 0

	--Populate Gearsets so they are not sold
	for i = 1, C_EquipmentSet.GetNumEquipmentSets() do
		local name, _ = C_EquipmentSet.GetEquipmentSetInfo(i)
		local items = C_EquipmentSet.GetEquipmentSetItemIDs(name)
		for _, item in pairs(items) do
			inSet[item] = name
		end
	end

	--Count Items to sell
	OnlyCount = true
	for b = 0, 4 do
		bag = b
		module:SellTrashInBag()
	end
	if iCount == 0 then
		spartan:Print("No items are to be auto sold")
	else
		spartan:Print("Need to sell " .. iCount .. " item(s) for " .. module:GetFormattedValue(totalValue))
		--Start Loop to sell, reset locals
		OnlyCount = false
		bag = 0
		-- C_Timer.After(.2, SellTrashInBag)
		self.SellTimer = self:ScheduleRepeatingTimer("SellTrashInBag", .3)
	end
end

function module:OnEnable()
	if SUI.DB.AutoSell.FirstLaunch then
		module:FirstTime()
	end
	module:BuildOptions()
	if SUI.DB.EnabledComponents.AutoSell then
		module:Enable()
	else
		return
	end
end

function module:Enable()
	local function MerchantEventHandler(self, event, ...)
		if not SUI.DB.EnabledComponents.AutoSell then
			return
		end
		if event == "MERCHANT_SHOW" then
			module:SellTrash()
		else
			module:CancelAllTimers()
			if (totalValue > 0) then
				-- spartan:Print("Sold items for " .. module:GetFormattedValue(totalValue));
				totalValue = 0
			end
		end
	end
	frame:SetScript("OnEvent", MerchantEventHandler)
	frame:RegisterEvent("MERCHANT_SHOW")
	frame:RegisterEvent("MERCHANT_CLOSED")
end

function module:Disable()
	spartan:Print("Autosell disabled")
	frame:UnregisterEvent("MERCHANT_SHOW")
	frame:UnregisterEvent("MERCHANT_CLOSED")
end

function module:BuildOptions()
	spartan.opt.args["ModSetting"].args["AutoSell"] = {
		type = "group",
		name = "Auto Sell",
		args = {
			NotCrafting = {
				name = "Don't Sell crafting items",
				type = "toggle",
				order = 1,
				width = "full",
				get = function(info)
					return SUI.DB.AutoSell.NotCrafting
				end,
				set = function(info, val)
					SUI.DB.AutoSell.NotCrafting = val
				end
			},
			NotConsumables = {
				name = "Don't Sell Consumables",
				type = "toggle",
				order = 2,
				width = "full",
				get = function(info)
					return SUI.DB.AutoSell.NotConsumables
				end,
				set = function(info, val)
					SUI.DB.AutoSell.NotConsumables = val
				end
			},
			NotInGearset = {
				name = "Don't Sell items in a equipment set",
				type = "toggle",
				order = 3,
				width = "full",
				get = function(info)
					return SUI.DB.AutoSell.NotInGearset
				end,
				set = function(info, val)
					SUI.DB.AutoSell.NotInGearset = val
				end
			},
			GearTokens = {
				name = "Sell tier tokens",
				type = "toggle",
				order = 4,
				width = "full",
				get = function(info)
					return SUI.DB.AutoSell.GearTokens
				end,
				set = function(info, val)
					SUI.DB.AutoSell.GearTokens = val
				end
			},
			MaxILVL = {
				name = "Maximum iLVL to sell",
				type = "range",
				order = 10,
				width = "full",
				min = 1,
				max = 500,
				step = 1,
				set = function(info, val)
					SUI.DB.AutoSell.MaxILVL = val
				end,
				get = function(info)
					return SUI.DB.AutoSell.MaxILVL
				end
			},
			Gray = {
				name = "Sell Gray",
				type = "toggle",
				order = 20,
				width = "double",
				get = function(info)
					return SUI.DB.AutoSell.Gray
				end,
				set = function(info, val)
					SUI.DB.AutoSell.Gray = val
				end
			},
			White = {
				name = "Sell White",
				type = "toggle",
				order = 21,
				width = "double",
				get = function(info)
					return SUI.DB.AutoSell.White
				end,
				set = function(info, val)
					SUI.DB.AutoSell.White = val
				end
			},
			Green = {
				name = "Sell Green",
				type = "toggle",
				order = 22,
				width = "double",
				get = function(info)
					return SUI.DB.AutoSell.Green
				end,
				set = function(info, val)
					SUI.DB.AutoSell.Green = val
				end
			},
			Blue = {
				name = "Sell Blue",
				type = "toggle",
				order = 23,
				width = "double",
				get = function(info)
					return SUI.DB.AutoSell.Blue
				end,
				set = function(info, val)
					SUI.DB.AutoSell.Blue = val
				end
			},
			Purple = {
				name = "Sell Purple",
				type = "toggle",
				order = 24,
				width = "double",
				get = function(info)
					return SUI.DB.AutoSell.Purple
				end,
				set = function(info, val)
					SUI.DB.AutoSell.Purple = val
				end
			},
			debug = {
				name = "Enable debug messages",
				type = "toggle",
				order = 600,
				width = "full",
				get = function(info)
					return SUI.DB.AutoSell.debug
				end,
				set = function(info, val)
					SUI.DB.AutoSell.debug = val
				end
			}
		}
	}
end
