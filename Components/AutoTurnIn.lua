local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local AceHook = LibStub("AceHook-3.0")
local module = spartan:NewModule("Component_AutoTurnIn");
----------------------------------------------------------------------------------------------------
local ATI_Container = CreateFrame("Frame")
local questCache = {}
local weapon = {GetAuctionItemSubClasses(1)}
local armor = {GetAuctionItemSubClasses(2)}
local ITEMS = {
	['One-Handed Axes'] = weapon[1],
	['Two-Handed Axes'] = weapon[2],
	['Bows'] = weapon[3],
	['Guns'] = weapon[4],
	['One-Handed Maces'] = weapon[5],
	['Two-Handed Maces'] = weapon[6],
	['Polearms'] = weapon[7],
	['One-Handed Swords'] = weapon[8],
	['Two-Handed Swords'] = weapon[9],
	['Staves'] = weapon[10],
	['Fist Weapons'] = weapon[11],
	--['Miscellaneous'] = select(12, weapon)
	['Daggers'] = weapon[13],
	['Thrown'] = weapon[14],
	['Crossbows'] = weapon[15],
	['Wands'] = weapon[16],
	--['Fishing Pole'] = select(17, weapon)
	-- armor
	--['Miscellaneous'] = armor[1]
	['Cloth'] = armor[2],
	['Leather'] = armor[3],
	['Mail'] = armor[4],
	['Plate'] = armor[5],
	['Shields'] = armor[7], -- from 5.4 '6' is a cosmetic
	--[[3rd slot
	['Librams'] = armor[7],
	['Idols'] = armor[8],
	['Totems'] = armor[9],
	]]--
}
local SLOTS = {
	["INVTYPE_AMMO"]={"AmmoSlot"},
	["INVTYPE_HEAD"]={"HeadSlot"},
	["INVTYPE_NECK"]={"NeckSlot"},
	["INVTYPE_SHOULDER"]={"ShoulderSlot"},
	["INVTYPE_CHEST"]={"ChestSlot"},
	["INVTYPE_WAIST"]={"WaistSlot"},
	["INVTYPE_LEGS"]={"LegsSlot"},
	["INVTYPE_FEET"]={"FeetSlot"},
	["INVTYPE_WRIST"]={"WristSlot"},
	["INVTYPE_HAND"]={"HandsSlot"}, 
	["INVTYPE_FINGER"]={"Finger0Slot", "Finger1Slot"}, 
	["INVTYPE_TRINKET"]={"Trinket0Slot", "Trinket1Slot"},
	["INVTYPE_CLOAK"]={"BackSlot"},

	["INVTYPE_WEAPON"]={"MainHandSlot", "SecondaryHandSlot"},
	["INVTYPE_2HWEAPON"]={"MainHandSlot"},
	["INVTYPE_RANGED"]={"MainHandSlot"},
	["INVTYPE_RANGEDRIGHT"]={"MainHandSlot"},
	["INVTYPE_WEAPONMAINHAND"]={"MainHandSlot"}, 
	["INVTYPE_SHIELD"]={"SecondaryHandSlot"},
	["INVTYPE_WEAPONOFFHAND"]={"SecondaryHandSlot"},
	["INVTYPE_HOLDABLE"]={"SecondaryHandSlot"}
}

local BlackList = {}

local Lquests = {
-- Steamwheedle Cartel
['Making Amends']={item="Runecloth", amount=40, currency=false},
['War at Sea']={item="Mageweave Cloth", amount=40, currency=false},
['Traitor to the Bloodsail']={item="Silk Cloth", amount=40, currency=false},
['Mending Old Wounds']={item="Linen Cloth", amount=40, currency=false},
-- AV both fractions
['Empty Stables']={donotaccept=true},
-- Alliance AV Quests
['Crystal Cluster']={donotaccept=true},
['Ivus the Forest Lord']={donotaccept=true},
["Call of Air - Ichman's Fleet"]={donotaccept=true},
["Call of Air - Slidore's Fleet"]={donotaccept=true},
["Call of Air - Vipore's Fleet"]={donotaccept=true},
['Armor Scraps']={donotaccept=true},
['More Armor Scraps']={donotaccept=true},
['Ram Riding Harnesses']={donotaccept=true},
-- Horde AV Quests
['A Gallon of Blood']={donotaccept=true},
['Lokholar the Ice Lord']={donotaccept=true},
["Call of Air - Guse's Fleet"]={donotaccept=true},
["Call of Air - Jeztor's Fleet"]={donotaccept=true},
["Call of Air - Mulverick's Fleet"]={donotaccept=true},
['Enemy Booty']={donotaccept=true},
['More Booty!']={donotaccept=true},
['Ram Hide Harnesses']={donotaccept=true},
-- Timbermaw Quests
['Feathers for Grazle']={item="Deadwood Headdress Feather", amount=5, currency=false},
['Feathers for Nafien']={item="Deadwood Headdress Feather", amount=5, currency=false},
['More Beads for Salfa']={item="Winterfall Spirit Beads", amount=5, currency=false},
-- Cenarion
['Encrypted Twilight Texts']={item="Encrypted Twilight Text", amount=10, currency=false},
['Still Believing']={item="Encrypted Twilight Text", amount=10, currency=false},
-- Thorium Brotherhood
['Favor Amongst the Brotherhood, Blood of the Mountain']={item="Blood of the Mountain", amount=1, currency=false},
['Favor Amongst the Brotherhood, Core Leather']={item="Core Leather", amount=2, currency=false},
['Favor Amongst the Brotherhood, Dark Iron Ore']={item="Dark Iron Ore", amount=10, currency=false},
['Favor Amongst the Brotherhood, Fiery Core']={item="Fiery Core", amount=1, currency=false},
['Favor Amongst the Brotherhood, Lava Core']={item="Lava Core", amount=1, currency=false},
['Gaining Acceptance']={item="Dark Iron Residue", amount=4, currency=false},
['Gaining Even More Acceptance']={item="Dark Iron Residue", amount=100, currency=false},

-- Fiona's Caravan
["Argus' Journal"]={donotaccept=true},
["Beezil's Cog"]={donotaccept=true},
["Fiona's Lucky Charm"]={donotaccept=true},
["Gidwin's Weapon Oil"]={donotaccept=true},
["Pamela's Doll"]={donotaccept=true},
["Rimblat's Stone"]={donotaccept=true},
["Tarenar's Talisman"]={donotaccept=true},
["Vex'tul's Armbands"]={donotaccept=true},

--[[Burning Crusade]]--
--Lower City
["More Feathers"]={item="Arakkoa Feather", amount=30, currency=false},
--Aldor
["More Marks of Kil'jaeden"]={item="Mark of Kil'jaeden", amount=10, currency=false},
["More Marks of Sargeras"]={item="Mark of Sargeras", amount=10, currency=false},
["Fel Armaments"]={item="Fel Armaments", amount=10, currency=false},
["Single Mark of Kil'jaeden"]={item="Mark of Kil'jaeden", amount=1, currency=false},
["Single Mark of Sargeras"]={item="Mark of Sargeras", amount=1, currency=false},
["More Venom Sacs"]={item="Dreadfang Venom Sac", amount=8, currency=false},
--Scryer
["More Firewing Signets"]={item="Firewing Signet", amount=10, currency=false},
["More Sunfury Signets"]={item="Sunfury Signet", amount=10, currency=false},
["Arcane Tomes"]={item="Arcane Tome", amount=1, currency=false},
["Single Firewing Signet"]={item="Firewing Signet", amount=1, currency=false},
["Single Sunfury Signet"]={item="Sunfury Signet", amount=1, currency=false},
["More Basilisk Eyes"]={item="Dampscale Basilisk Eye", amount=8, currency=false},
--Skettis
["More Shadow Dust"]={item="Shadow Dust", amount=6, currency=false},
--SporeGar
["Bring Me Another Shrubbery!"]={item="Sanguine Hibiscus", amount=5, currency=false},
["More Fertile Spores"]={item="Fertile Spores", amount=6, currency=false},
["More Glowcaps"]={item="Glowcap", amount=10, currency=false},
["More Spore Sacs"]={item="Mature Spore Sac", amount=10, currency=false},
["More Tendrils!"]={item="Bog Lord Tendril", amount=6, currency=false},
-- Halaa
["Oshu'gun Crystal Powder"]={item="Oshu'gun Crystal Powder Sample", amount=10, currency=false},

["Hodir's Tribute"]={item="Relic of Ulduar", amount=10, currency=false},
["Remember Everfrost!"]={item="Everfrost Chip", amount=1, currency=false},
["Additional Armaments"]={item=416, amount=125, currency=true},
["Calling the Ancients"]={item=416, amount=125, currency=true},
["Filling the Moonwell"]={item=416, amount=125, currency=true},
["Into the Fire"]={donotaccept=true},
["The Forlorn Spire"]={donotaccept=true},
["Fun for the Little Ones"] = {item=393, amount=15, currency=true},
--MoP
["Seeds of Fear"]={item="Dread Amber Shards", amount=5, currency=false},
["A Dish for Jogu"]={item="Sauteed Carrots", amount=5, currency=false},

["A Dish for Ella"]={item="Shrimp Dumplings", amount=5, currency=false},
["Valley Stir Fry"]={item="Valley Stir Fry", amount=5, currency=false},
["A Dish for Farmer Fung"]={item="Wildfowl Roast", amount=5, currency=false},
["A Dish for Fish"]={item="Twin Fish Platter", amount=5, currency=false},
["Swirling Mist Soup"]={item="Swirling Mist Soup", amount=5, currency=false},
["A Dish for Haohan"]={item="Charbroiled Tiger Steak", amount=5, currency=false},
["A Dish for Old Hillpaw"]={item="Braised Turtle", amount=5, currency=false},
["A Dish for Sho"]={item="Eternal Blossom Fish", amount=5, currency=false},
["A Dish for Tina"]={item="Fire Spirit Salmon", amount=5, currency=false},
["Replenishing the Pantry"]={item="Bundle of Groceries", amount=1, currency=false},
--MOP timeless Island
['Great Turtle Meat']={item="Great Turtle Meat", amount=1, currency=false},
['Heavy Yak Flank']={item="Heavy Yak Flank", amount=1, currency=false},
['Meaty Crane Leg']={item="Meaty Crane Leg", amount=1, currency=false},
['Pristine Firestorm Egg']={item="Pristine Firestorm Egg", amount=1, currency=false},
['Thick Tiger Haunch']={item="Thick Tiger Haunch", amount=1, currency=false},

}

local LignoreList = {
--MOP Tillers
["A Marsh Lily for"]="",
["A Lovely Apple for"]="",
["A Jade Cat for"]="",
["A Blue Feather for"]="",
["A Ruby Shard for"]="",
}
-- Available check requires cache
-- Active check query API function Returns true if quest matches options
-- function module:isAppropriate(questname, byCache)
    -- local daily
    -- if byCache then
        -- daily = (not not questCache[questname])
    -- else
        -- daily = (QuestIsDaily() or QuestIsWeekly())
    -- end
    -- return daily
-- end

-- turns quest in printing reward text if `showrewardtext` option is set.
-- prints appropriate message if item is taken by greed
-- equips received reward if such option selected
function module:TurnInQuest(rewardIndex)
	if (DB.AutoTurnIn.showrewardtext) then
		spartan:Print((UnitName("target") and  UnitName("target") or '')..'\n', GetRewardText())
	end

	if (self.forceGreed) then
		if  (GetNumQuestChoices() > 1) then
			-- spartan:Print(L["gogreedy"])
		end
	else
		local name = GetQuestItemInfo("choice", (GetNumQuestChoices() == 1) and 1 or rewardIndex)
		if (DB.AutoTurnIn.autoequip and (strlen(name) > 0)) then
			local lootLevel, _, _, _, _, equipSlot = select(4, GetItemInfo(GetQuestItemLink("choice", rewardIndex)))

			-- Compares reward and already equipped item levels. If reward level is greater than equipped item, auto equip reward
			local slot = C.SLOTS[equipSlot]
			if (slot) then
				local firstSlot = GetInventorySlotInfo(slot[1])
				local invLink = GetInventoryItemLink("player", firstSlot)
				local eqLevel = self:ItemLevel(invLink)

				-- If reward is a ring  trinket or one-handed weapons all slots must be checked in order to swap one with a lesser item-level
				if (#slot > 1) then
					local secondSlot = GetInventorySlotInfo(slot[2])
					invLink = GetInventoryItemLink("player", secondSlot)
					if (invLink) then
						local eq2Level = self:ItemLevel(invLink)
						firstSlot = (eqLevel > eq2Level) and secondSlot or firstSlot
						eqLevel = (eqLevel > eq2Level) and eq2Level or eqLevel
					end
				end

				-- comparing lowest equipped item level with reward's item level
				if (lootLevel > eqLevel) then
					self.autoEquipList[name] = firstSlot
					self.delayFrame.delay = time() + 2
					self.delayFrame:Show()
				end
			end
		end
	end

	-- if (DB.AutoTurnIn.debug) then
		local link = GetQuestItemLink("choice", rewardIndex)
		if (link) then
			spartan:Print("Debug: item to loot=", link)
		elseif (GetNumQuestChoices() == 0) then
			-- spartan:Print("Debug: turning quest in, no choice required")
		end
    -- else
		GetQuestReward(rewardIndex)
	-- end
end

function module:CacheAsDaily(questname)
	questCache[questname] = true
end

function module.QUEST_DETAIL()
	if (QuestIsDaily() or QuestIsWeekly()) then
		module:CacheAsDaily(name)
	end

	if (DB.AutoTurnIn.AcceptGeneralQuests) then
		QuestInfoDescriptionText:SetAlphaGradient(0, -1)
		QuestInfoDescriptionText:SetAlpha(1)
		AcceptQuest()
	end
end

function module.QUEST_ACCEPTED(event, index)
	if DB.AutoTurnIn.questshare and GetQuestLogPushable() and GetNumGroupMembers() >= 1 then
		SelectQuestLogEntry(index);
		QuestLogPushQuest();
	end
end

function module.QUEST_COMPLETE()
	if not DB.AutoTurnIn.TurnInEnabled then return end
	--/script faction = (GameTooltip:NumLines() > 2 and not UnitIsPlayer(select(2,GameTooltip:GetUnit()))) and
    -- getglobal("GameTooltipTextLeft"..GameTooltip:NumLines()):GetText() DEFAULT_CHAT_FRAME:AddMessage(faction or "NIL")
	local name = GetTitleText()
    -- if module:isAppropriate(name) then
		local questname = GetTitleText()
		-- local quest = L.quests[questname]

		if GetNumQuestChoices() > 1 then
			local function getItemId(typeStr)
				local link = GetQuestItemLink(typeStr, 1) --first item is enough
				return link and link:match("%b::"):gsub(":", "") or ERRORVALUE
			end

			local itemID = getItemId("choice")
			if (not itemID) then
				spartan:Print("Can't read reward link from server. Close NPC dialog and open it again.");
				return
			end
			-- Tournament quest found
			if (itemID == "46114" or itemID == "45724") then 
				-- module:TurnInQuest(DB.AutoTurnIn.tournament)
				return
			end

			-- if (DB.AutoTurnIn.lootreward > 1) then -- Auto Loot enabled!
				-- self.forceGreed = false
				-- if (DB.AutoTurnIn.lootreward == 3) then -- 3 == Need
					-- self.forceGreed = (not self:Need() ) and DB.AutoTurnIn.greedifnothingfound
				-- end
				-- if (DB.AutoTurnIn.lootreward == 2 or self.forceGreed) then -- 2 == Greed
					-- self:Greed()
				-- end
			-- end
		else
			module:TurnInQuest(1) -- for autoequip to work index must be greater that 0. That's required by Blizzard API
		end
    -- end
end

function module:GetItemAmount(isCurrency, item)
	local amount = isCurrency and select(2, GetCurrencyInfo(item)) or GetItemCount(item, nil, true)
	return amount and amount or 0
end

function module.QUEST_LOG_UPDATE()
	if ( GetNumQuestLogEntries() > 0 ) then
		for index=1, GetNumQuestLogEntries() do
			local title, _, _, _, isHeader , _, _, isDaily = GetQuestLogTitle(index)
			if not isHeader and isDaily then
				questCache[title] = true
			end
		end
		-- self:UnregisterEvent("QUEST_LOG_UPDATE")
	end
end

-- (gaq[i+3]) equals "1" if quest is complete, "nil" otherwise
-- why not 	gaq={GetGossipAvailableQuests()}? Well, tables in lua are truncated for values
-- with ending `nil`. So: '#' for {1,nil, "b", nil} returns 1
function module:VarArgForActiveQuests(...)
    local INDEX_CONST = 6

	for i=1, select("#", ...), INDEX_CONST do
		local isComplete = select(i+3, ...) -- complete status
		if ( isComplete ) then
			local questname = select(i, ...)
			-- if self:isAppropriate(questname, true) then
				local quest = Lquests[questname]
				if quest and quest.amount then
					if module:GetItemAmount(quest.currency, quest.item) >= quest.amount then
						SelectGossipActiveQuest(math.floor(i/INDEX_CONST)+1)
						-- self.DarkmoonAllowToProceed = false
					end
				else
					SelectGossipActiveQuest(math.floor(i/INDEX_CONST)+1)
					-- self.DarkmoonAllowToProceed = false
				end
			-- end
		end
	end
end

-- like previous function this one works around `nil` values in a list.
function module:VarArgForAvailableQuests(...)
	local INDEX_CONST = 6 -- was '5' in Cataclysm
	for i=1, select("#", ...), INDEX_CONST do
		local title = select(i, ...)
		local isTrivial = select(i+2, ...)		
		local isDaily  = select(i+3, ...)		
		-- local triviaAndAllowedOrNotTrivia = (not isTrivial) or AutoTurnInCharacterDB.trivial
		
		local quest = Lquests[title] -- this quest exists in addons quest DB. There are mostly daily quests
		-- local notBlackListed = not (quest and (quest.donotaccept or AutoTurnIn:IsIgnoredQuest(title)))

		-- Quest is appropriate if: (it is trivial and trivial are accepted) and (any quest accepted or (it is daily quest that is not in ignore list))
		-- if (triviaAndAllowedOrNotTrivia and notBlackListed and self:_isAppropriate(isDaily)) then
			if quest and quest.amount then
				if self:GetItemAmount(quest.currency, quest.item) >= quest.amount then
					SelectGossipAvailableQuest(math.floor(i/INDEX_CONST)+1)
				end
			else
				SelectGossipAvailableQuest(math.floor(i/INDEX_CONST)+1)
			end
		-- end
	end
end

function module:FirstLaunch()
	local PageData = {
		SubTitle = "Auto Turn In",
		Desc1 = "Automatically accept and turn in quests.",
		Display = function()
			--Container
			SUI_Win.ATI = CreateFrame("Frame", nil)
			SUI_Win.ATI:SetParent(SUI_Win.content)
			SUI_Win.ATI:SetAllPoints(SUI_Win.content)
			
			--TurnInEnabled
			SUI_Win.ATI.TurnInEnabled = CreateFrame("CheckButton", "SUI_ATI_TurnInEnabled", SUI_Win.ATI, "OptionsCheckButtonTemplate")
			SUI_Win.ATI.TurnInEnabled:SetPoint("TOP", SUI_Win.ATI, "TOP", -90, -90)
			SUI_ATI_TurnInEnabledText:SetText("Enable turning in quests")
			
			--AcceptGeneralQuests
			SUI_Win.ATI.AcceptGeneralQuests = CreateFrame("CheckButton", "SUI_ATI_AcceptGeneralQuests", SUI_Win.ATI, "OptionsCheckButtonTemplate")
			SUI_Win.ATI.AcceptGeneralQuests:SetPoint("TOP", SUI_Win.ATI.TurnInEnabled, "BOTTOM", 0, -15)
			SUI_ATI_AcceptGeneralQuestsText:SetText("Enable accepting quests")
		end,
		Next = function()
			DB.AutoTurnIn.FirstLaunch = false
			
			DB.AutoTurnIn.TurnInEnabled = (SUI_ATI_TurnInEnabled:GetChecked() == true or false)
			DB.AutoTurnIn.AcceptGeneralQuests = (SUI_ATI_AcceptGeneralQuests:GetChecked() == true or false)
			
			SUI_Win.ATI:Hide()
			SUI_Win.ATI = nil
		end
	}
	local SetupWindow = spartan:GetModule("SetupWindow")
	SetupWindow:AddPage(PageData)
	SetupWindow:DisplayPage()
end

function module.GOSSIP_SHOW()
	if not DB.AutoTurnIn.AutoGossip then
		return
	end
	
	local questCount = GetNumGossipActiveQuests() > 0
	if DB.AutoTurnIn.debug then print(questCount) end
	if questCount then
		local options = {GetGossipOptions()}
		for k, v in pairs(options) do
			if (v ~= "gossip") and (not BlackList[v]) then
				local opcount = GetNumGossipOptions()
				-- SelectGossipOption((opcount == 1) and 1 or  math.floor(k / GetNumGossipOptions()) + 1)
				BlackList[v] = true
				if DB.AutoTurnIn.debug then print(v .. "---BLACKLISTED") end
			end
		end
	end
	-- SelectGossipOption(1)
	-- module:VarArgForActiveQuests(GetGossipActiveQuests())
	-- module:VarArgForAvailableQuests(GetGossipAvailableQuests())
	
end

function module.QUEST_PROGRESS()
    if IsQuestCompletable() then
        CompleteQuest()
    end
end

function module:OnInitialize()
	if not DB.AutoTurnIn then
		DB.AutoTurnIn = {
			FirstLaunch = true,
			debug = false,
			TurnInEnabled = true,
			AutoGossip = true,
			AcceptGeneralQuests = true,
			AcceptDaily = false,
			trivial = false, --Low Level
			lootreward = 1,
			tournament = 2,
			darkmoonteleport=true,
			todarkmoon=true,
			darkmoonautostart=true,
			showrewardtext=true,
			autoequip = false,
			questlevel=true,
			watchlevel=true,
			questshare=false,
			armor = {}, weapon = {}, stat = {}, secondary = {}
		}
	end
end

function module:OnEnable()
	module:BuildOptions()
	-- if not DB.EnabledComponents.AutoTurnIn then module:HideOptions() return end
	if DB.AutoTurnIn.FirstLaunch then module:FirstLaunch() end
		
	ATI_Container:SetScript("OnEvent", function(_, event)
		if not DB.EnabledComponents.AutoTurnIn then return end
		if DB.AutoTurnIn.debug then print(event) end
		
		if module[event] then 
			module[event]()
		end
	end)
	ATI_Container:RegisterEvent("QUEST_GREETING")
	ATI_Container:RegisterEvent("GOSSIP_SHOW") -- multiple quests, and NPC chat screen
	ATI_Container:RegisterEvent("QUEST_DETAIL") -- new quest screen
	ATI_Container:RegisterEvent("QUEST_PROGRESS")
	ATI_Container:RegisterEvent("QUEST_LOG_UPDATE") -- quest progress
	ATI_Container:RegisterEvent("QUEST_ACCEPTED")
	ATI_Container:RegisterEvent("QUEST_COMPLETE") -- quest turn in screen
	-- hooksecurefunc("QuestLogQuests_Update", ATI_Container.ShowQuestLevelInLog)
	-- hooksecurefunc(QuestFrame, "Hide", function() DB.allowed = nil end)
end

function module:BuildOptions()
	spartan.opt.args["ModSetting"].args["AutoTurnIn"] = {type="group",name="Auto TurnIn",
		args = {
			debugMode = {name="Debug Mode",type="toggle",order=1,
					get = function(info) return DB.AutoTurnIn.debug end,
					set = function(info,val) DB.AutoTurnIn.debug = val end
			},
			TurnInEnabled = {name="Turn in Quests",type="toggle",order=10,
					get = function(info) return DB.AutoTurnIn.TurnInEnabled end,
					set = function(info,val) DB.AutoTurnIn.TurnInEnabled = val end
			},
			AutoGossip = {name="Auto Gossip",type="toggle",order=15,
					get = function(info) return DB.AutoTurnIn.AutoGossip end,
					set = function(info,val) DB.AutoTurnIn.AutoGossip = val end
			},
			AcceptGeneralQuests = {name="Accept Quests",type="toggle",order=20,
					get = function(info) return DB.AutoTurnIn.AcceptGeneralQuests end,
					set = function(info,val) DB.AutoTurnIn.AcceptGeneralQuests = val end
			},
			AcceptDaily = {name="Accept Daily",type="toggle",order=30,disabled=true,
					get = function(info) return DB.AutoTurnIn.AcceptDaily end,
					set = function(info,val) DB.AutoTurnIn.AcceptDaily = val end
			},
			AcceptLowLevel = {name="Accept Low Level",type="toggle",order=40,disabled=true,
					get = function(info) return DB.AutoTurnIn.trivial end,
					set = function(info,val) DB.AutoTurnIn.trivial = val end
			}
		}
	}
end

function module:HideOptions()
	spartan.opt.args["ModSetting"].args["AutoTurnIn"].disabled = true
end