local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI")
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true)
local AceHook = LibStub("AceHook-3.0")
local module = spartan:NewModule("Component_Tooltips")
----------------------------------------------------------------------------------------------------
local class, classFileName = UnitClass("player")
local targetList, inspectCache = {}, {}
local RuleList = {"Rule1", "Rule2", "Rule3"}
local tooltips = {
	GameTooltip, ItemRefTooltip, ItemRefShoppingTooltip1,ItemRefShoppingTooltip2, ItemRefShoppingTooltip3, AutoCompleteBox,FriendsTooltip, ConsolidatedBuffsTooltip, ShoppingTooltip1,
	ShoppingTooltip2, ShoppingTooltip3, WorldMapTooltip,WorldMapCompareTooltip1, WorldMapCompareTooltip2,WorldMapCompareTooltip3, DropDownList1MenuBackdrop,
	DropDownList2MenuBackdrop, DropDownList3MenuBackdrop, BNToastFrame,PetBattlePrimaryAbilityTooltip, PetBattlePrimaryUnitTooltip,BattlePetTooltip, FloatingBattlePetTooltip,
	FloatingPetBattleAbilityTooltip, FloatingGarrisonFollowerTooltip,GarrisonMissionMechanicTooltip, GarrisonFollowerTooltip,GarrisonMissionMechanicFollowerCounterTooltip, GarrisonFollowerAbilityTooltip,
	SmallTextTooltip, BrowserSettingsTooltip, QueueStatusFrame, EventTraceTooltip,ItemSocketingDescription
}
local whitebg = {bgFile = [[Interface\AddOns\SpartanUI\media\blank.tga]],tile=false,edgeSize=3}

function module:OnInitialize()
	if DB.Tooltips == nil then
		DB.Tooltips = 
		{
			Styles={
				metal = {
					bgFile = [[Interface\AddOns\SpartanUI\media\metal.tga]],tile=false
				},
				smooth = {
					bgFile = [[Interface\AddOns\SpartanUI\media\Smoothv2.tga]],tile=false
				},
				smoke = {
					bgFile = [[Interface\AddOns\SpartanUI\media\smoke.tga]],tile=false
				},
				none = {
					bgFile = [[Interface\AddOns\SpartanUI\media\blank.tga]],tile=false
				}
			},
			ActiveStyle="smoke",
			Override = {},
			ColorOverlay = true,
			Color = {0,0,0,0.4}
		}
	end
	
	if DB.Tooltips.Rule1 == nil then
		for k,v in ipairs(RuleList) do
			DB.Tooltips[v] = {
				Status = "Disabled",
				Combat = false,
				OverrideLoc=false,
				Anchor = {onMouse=false,Moved = false,AnchorPos = {}}
				}
		end
		if DB.Tooltips.OverrideLoc then
			DB.Tooltips.Rule1 = {
				Status = "All",
				Combat = false,
				OverrideLoc=DB.Tooltips.OverrideLoc,
				Anchor = {onMouse=DB.Tooltips.Anchor.onMouse,Moved = DB.Tooltips.Anchor.Moved,AnchorPos = DB.Tooltips.Anchor.AnchorPos}
			}
			DB.Tooltips.Anchor = nil
		else
			DB.Tooltips.Rule1 = {
				Status = "All",
				Combat = false,
				OverrideLoc=false,
				Anchor = {onMouse=false,Moved = false,AnchorPos = {}}
			}
		end
	end
	
	local a,b,c,d = unpack(DB.Tooltips.Color)
	if a == 0 and b==0 and c==0 and d==0.7 then DB.Tooltips.Color = {0,0,0,0.4} end
end

local function ActiveRule()
	for k,v in ipairs(RuleList) do
		
		if DB.Tooltips[v].Status ~= "Disabled" then
			local CombatRule = false
			if InCombatLockdown() and DB.Tooltips[v].Combat then
				CombatRule = true
			elseif not InCombatLockdown() and not DB.Tooltips[v].Combat then
				CombatRule = true
			end
			
			if DB.Tooltips[v].Status == "Group" and (IsInGroup() and not IsInRaid()) and CombatRule then
				return v
			elseif DB.Tooltips[v].Status == "Raid" and IsInRaid() and CombatRule then
				return v
			elseif DB.Tooltips[v].Status == "Instance" and IsInInstance() then
				return v
			elseif DB.Tooltips[v].Status == "All" and CombatRule then
				return v
			end
		end
	end
end

-- local setPoint = function(self,point,parent,rpoint)
local setPoint = function(self, parent)
	if parent then
		if(DB.Tooltips[ActiveRule()].Anchor.onMouse) then
			self:SetOwner(parent, "ANCHOR_CURSOR")
			return
		else
			self:SetOwner(parent, "ANCHOR_NONE")
		end
	
		--See If the theme has an anchor and if we are allowed to use it
		if DB.Styles[DBMod.Artwork.Style].TooltipLoc and not DB.Tooltips[ActiveRule()].OverrideLoc then
			spartan:GetModule("Style_" .. DBMod.Artwork.Style):TooltipLoc(self, parent);
		else
			self:ClearAllPoints();
			if DB.Tooltips[ActiveRule()].Anchor.Moved then
				local Anchors = {}
				for key,val in pairs(DB.Tooltips[ActiveRule()].Anchor.AnchorPos) do
					Anchors[key] = val
				end
				-- self:ClearAllPoints();
				if Anchors.point == nil then 
					--Error Catch
					self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 20)
					DB.Tooltips[ActiveRule()].Anchor.Moved = false
				else
					self:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
				end
			else
				self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 20)
			end
		end
	end
end

local onShow = function(self)
	self:SetBackdrop(whitebg)
	if DB.Styles[DBMod.Artwork.Style].Tooltip ~= nil and DB.Styles[DBMod.Artwork.Style].Tooltip.BG and not DB.Tooltip.Override[DBMod.Artwork.Style] then
		self.SUIBorder:SetBackdrop(DB.Styles[DBMod.Artwork.Style].Tooltip.BG)
	else
		self.SUIBorder:SetBackdrop(DB.Tooltips.Styles[DB.Tooltips.ActiveStyle])
	end
	
	if (DB.Tooltips.ActiveStyle == "none" or DB.Tooltips.ColorOverlay) or (not self.SUIBorder) then
		self:SetBackdropColor(unpack(DB.Tooltips.Color))
		self.SUIBorder:SetBackdropColor(1,1,1,1)
	else
		self.SUIBorder:SetBackdropColor(unpack(DB.Tooltips.Color))
		self:SetBackdropColor(0, 0, 0, 0)
	end
	
	if(self.SUIBorder) and (not GameTooltipStatusBar:IsShown()) then
		self.SUIBorder:ClearAllPoints()
		self.SUIBorder:SetPoint("TOPLEFT", self, "TOPLEFT", -1, 1)
		self.SUIBorder:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 1, -1)
	end
	--check if theme has a location
	if DB.Styles[DBMod.Artwork.Style].Tooltip ~= nil and DB.Styles[DBMod.Artwork.Style].Tooltip.Custom then
		spartan:GetModule("Style_" .. DBMod.Artwork.Style):Tooltip()
	end
end

local onHide = function(self)
	onShow(self)
	self.SUIBorder:ClearColors()
end

local TipCleared = function(self)
	onShow(self)
	self.SUIBorder:ClearColors()
	self.itemCleared = nil
end

local Override_Color = function(self, r, g, b, a)
	local r2,b2,g2,a2 = unpack(DB.Tooltips.Color)
	if((r ~= r2) and (g ~= g2) and (b ~= b2)) then
		if not DB.Tooltips.ColorOverlay then
			self.SUIBorder:SetBackdropColor(unpack(DB.Tooltips.Color))
		else
			self:SetBackdropColor(unpack(DB.Tooltips.Color))
		end
	end
end

local SetBorderColor = function(self, r, g, b, hasStatusBar)
	r,g,b = (r * 0.5),(g * 0.5),(b * 0.5)
	self[1]:SetTexture(r, g, b, 1)
	self[2]:SetTexture(r, g, b, 1)
	self[3]:SetTexture(r, g, b, 1)
	self[4]:SetTexture(r, g, b, 1)
end

local ClearColors = function(self)
	self[1]:SetTexture(0, 0, 0, 0)
	self[2]:SetTexture(0, 0, 0, 0)
	self[3]:SetTexture(0, 0, 0, 0)
	self[4]:SetTexture(0, 0, 0, 0)
end

local TooltipSetItem = function(self)
	local key,itemLink = self:GetItem()
	if(key and (not self.itemCleared)) then
		local itemName, _, quality, _, _, _, _, _, equipSlot, icon = GetItemInfo(key)
		if(quality) then
			local r,g,b = GetItemQualityColor(quality)
			self.SUIBorder:SetBorderColor(r, g, b)
		end
		self.itemCleared = true
	end
end

local TooltipSetUnit = function(self)
	if(not self) then return end
	-- tipbackground(self)
	local unit = select(2, self:GetUnit())
	if not unit then
		local mFocus = GetMouseFocus()
		if mFocus and mFocus:GetAttribute("unit") then
			unit = mFocus:GetAttribute("unit")
		end
		if not unit or not UnitExists(unit) then return end
	end
	
	local unitLevel = UnitLevel(unit)
	local colors, burst, qColor, totColor, lvlLine
	local line = 2
	local sex = {"", "Male ", "Female "}
	local creatureClassColors = {
		worldboss = format("|cffAF5050World Boss%s|r", BOSS),
		rareelite = format("|cffAF5050RARE-ELITE%s|r", ITEM_QUALITY3_DESC),
		elite = "|cffAF5050ELITE|r",
		rare = format("|cffAF5050RARE%s|r", ITEM_QUALITY3_DESC)
	}

	if UnitIsPlayer(unit) then
		local className, classToken = UnitClass(unit)
		local uName, uRealm = UnitName(unit)
		local gName, _, _, gRealm = GetGuildInfo(unit)
		local gender = sex[UnitSex(unit)]
		local realmRelation = UnitRealmRelationship(unit)
		colors = _G.RAID_CLASS_COLORS[classToken]
		local nameString = UnitPVPName(unit) or uName
			
		if uRealm and uRealm ~= "" then
			local tmp = ""
			if gRealm ~= uRealm then tmp = " " .. uRealm end
			
			if (realmRelation == LE_REALM_RELATION_COALESCED) then
				nameString = nameString..FOREIGN_SERVER_LABEL..tmp
			elseif (realmRelation == LE_REALM_RELATION_VIRTUAL) then
				nameString = nameString..INTERACTIVE_SERVER_LABEL..tmp
			elseif gRealm ~= uRealm then
				nameString = nameString.."-"..uRealm
			end
		end

		if(UnitIsAFK(unit)) then
			GameTooltipTextLeft1:SetFormattedText("|cffFF0000%s|r |c%s%s|r", L["AFK"], colors.colorStr, nameString)
		elseif(UnitIsDND(unit)) then
			GameTooltipTextLeft1:SetFormattedText("|cffFFA500%s|r |c%s%s|r", L["DND"], colors.colorStr, nameString)
		else
			GameTooltipTextLeft1:SetFormattedText("|c%s%s|r", colors.colorStr, nameString)
		end

		if(gName) then
			if gRealm then
				gName = gName.."-"..gRealm
			end
			GameTooltipTextLeft2:SetText(("|cff008000%s|r"):format(gName))
			line = line + 1
		end
		
		for i = line, self:NumLines() do
			local tip = _G["GameTooltipTextLeft"..i]
			if tip:GetText() and tip:GetText():find(LEVEL) then
				lvlLine = tip
			end
		end

		if(lvlLine) then
			qColor = GetQuestDifficultyColor(unitLevel)
			local race, englishRace = UnitRace(unit)
			local _, factionGroup = UnitFactionGroup(unit)

			if(factionGroup and englishRace == "Pandaren") then
				race = factionGroup.." "..race
			end

			if(GENDER_INFO) then
				local gender = GENDER[UnitSex(unit)]
				if(gender) then race = race .. " " .. gender end
			end
			lvlLine:SetFormattedText("|cff%02x%02x%02x%s|r %s |c%s%s|r", qColor.r * 255, qColor.g * 255, qColor.b * 255, unitLevel > 0 and unitLevel or SKULL_ICON, race or "", colors.colorStr, className)
		end

	else
		if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
			colors = TAPPED_COLOR
		else
			colors = FACTION_BAR_COLORS[UnitReaction(unit, "player")]
		end
		
		for i = 2, self:NumLines() do
			local tip = _G["GameTooltipTextLeft"..i]
			if tip:GetText() and tip:GetText():find(LEVEL) then
				lvlLine = tip
			end
		end

		if(lvlLine) then
			local creatureClassification = UnitClassification(unit)
			local creatureType = UnitCreatureType(unit)
			if(UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
				unitLevel = UnitBattlePetLevel(unit)
				local ab = C_PetJournal.GetPetTeamAverageLevel()
				if ab then
					qColor = GetRelativeDifficultyColor(ab, unitLevel)
				else
					qColor = GetQuestDifficultyColor(unitLevel)
				end
			else
				qColor = GetQuestDifficultyColor(unitLevel)
			end


			lvlLine:SetFormattedText("|cff%02x%02x%02x%s|r %s %s", qColor.r * 255, qColor.g * 255, qColor.b * 255, unitLevel > 0 and unitLevel or "??", creatureClassColors[creatureClassification] or "", creatureType)
		end
	end
	
	local unitTarget = unit.."target"
	if unit ~= "player" and UnitExists(unitTarget) then
		if UnitIsPlayer(unitTarget) and not UnitHasVehicleUI(unitTarget) then
			totColor = RAID_CLASS_COLORS[select(2, UnitClass(unitTarget))]
		else
			totColor = FACTION_BAR_COLORS[UnitReaction(unitTarget, "player")]
		end
		self:AddDoubleLine(TARGET .. ":", format("|cff%02x%02x%02x%s|r", totColor.r * 255, totColor.g * 255, totColor.b * 255, UnitName(unitTarget)))
	end
	
	if IsInGroup() then
		for i = 1, GetNumGroupMembers() do
			local groupedUnit = IsInRaid() and "raid"..i or "party"..i
			if UnitIsUnit(groupedUnit.."target", unit) and not UnitIsUnit(groupedUnit, "player") then
				local _, classToken = UnitClass(groupedUnit)
				_G.tinsert(targetList, format("|c%s%s|r", RAID_CLASS_COLORS[classToken].colorStr, UnitName(groupedUnit)))
			end
		end
		local maxTargets = #targetList
		if maxTargets > 0 and targetList ~= nil then
			self:AddLine(format("%s (|cffffffff%d|r): %s", L["Targeted By"], maxTargets, table.concat(targetList, ", ")), nil, nil, nil, true)
			wipe(targetList)
		end
	end
end

local function ApplyTooltipSkins()
	for i, tooltip in pairs(tooltips) do
		if(not tooltip) then return end
		
		if(not tooltip.SUIBorder) then
			local Offset = 0
		    if(tooltip == GameTooltip) then
		        Offset = (GameTooltipStatusBar:GetHeight() + 6) * -1
		    end

		    local tmp = CreateFrame("Frame", nil, tooltip)
		    tmp:SetPoint("TOPLEFT", tooltip, "TOPLEFT", -1, 1)
		    tmp:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", 1, Offset)
		    tmp:SetFrameLevel(0)
			
		    --TOP
		    tmp[1] = tmp:CreateTexture(nil, "OVERLAY")
		    tmp[1]:SetPoint("BOTTOMLEFT", tmp, "TOPLEFT", -3, 0)
		    tmp[1]:SetPoint("BOTTOMRIGHT", tmp, "TOPRIGHT", 3, 0)
		    tmp[1]:SetHeight(3)
		    tmp[1]:SetTexture(0,0,0)
		    --BOTTOM
		    tmp[2] = tmp:CreateTexture(nil, "OVERLAY")
		    tmp[2]:SetPoint("TOPLEFT", tmp, "BOTTOMLEFT", -3, 0)
		    tmp[2]:SetPoint("TOPRIGHT", tmp, "BOTTOMRIGHT", 3, 0)
		    tmp[2]:SetHeight(3)
		    tmp[2]:SetTexture(0,0,0)
		    --RIGHT
		    tmp[3] = tmp:CreateTexture(nil, "OVERLAY")
		    tmp[3]:SetPoint("TOPLEFT", tmp, "TOPRIGHT", 0, 3)
		    tmp[3]:SetPoint("BOTTOMLEFT", tmp, "BOTTOMRIGHT", 0, -3)
		    tmp[3]:SetWidth(3)
		    tmp[3]:SetTexture(0,0,0)
		    --LEFT
		    tmp[4] = tmp:CreateTexture(nil, "OVERLAY")
		    tmp[4]:SetPoint("TOPRIGHT", tmp, "TOPLEFT", 0, 3)
		    tmp[4]:SetPoint("BOTTOMRIGHT", tmp, "BOTTOMLEFT", 0, -3)
		    tmp[4]:SetWidth(3)
		    tmp[4]:SetTexture(0,0,0)

		    if (DB.Styles[DBMod.Artwork.Style].Tooltip ~= nil) and DB.Styles[DBMod.Artwork.Style].Tooltip.BG and not DB.Tooltip.Override[DBMod.Artwork.Style] then
				tmp:SetBackdrop(DB.Styles[DBMod.Artwork.Style].Tooltip.BG)
			else
				tmp:SetBackdrop(DB.Tooltips.Styles[DB.Tooltips.ActiveStyle])
			end

		    tmp.SetBorderColor = SetBorderColor
			tmp.ClearColors = ClearColors

			tooltip.SUIBorder = tmp
			tooltip:SetBackdrop(nil)
			
			hooksecurefunc(tooltip, "SetBackdropColor", Override_Color)
			tooltip:HookScript("OnShow", onShow)
			tooltip:HookScript("OnHide", onHide)
			_G.tremove(tooltips, i)			
		end
	end
end

function module:UpdateBG()
	for i, tooltip in pairs(tooltips) do
		if (tooltip.SUIBorder) then
		    -- if DB.Styles[DBMod.Artwork.Style].Tooltip ~= nil and DB.Styles[DBMod.Artwork.Style].Tooltip.BG and not DB.Tooltip.Override[DBMod.Artwork.Style] then
				-- tooltip.SUIBorder:SetBackdrop(DB.Styles[DBMod.Artwork.Style].Tooltip.BG)
			-- else
				-- tooltip.SUIBorder:SetBackdrop(DB.Tooltips.Styles[DB.Tooltips.ActiveStyle])
			-- end
			if not DB.Tooltips.ColorOverlay then
				if DB.Tooltips.ActiveStyle ~= "none" then
					tooltip.SUIBorder:SetBackdropColor(unpack(DB.Tooltips.Color))
				else
					tooltip.SUIBorder:SetBackdropColor(0,0,0,0)
					tooltip:SetBackdropColor(unpack(DB.Tooltips.Color))
				end
			end
		end
	end
end

local function ReStyle()
	if(#tooltips > 0) then ApplyTooltipSkins() end
end

function module:OnEnable()
	if not DB.EnabledComponents.Tooltips then return end
	--Create Anchor point
	for k,v in ipairs(RuleList) do
		local anchor = CreateFrame("Frame",nil)
		anchor:SetSize(150, 20)
		anchor:EnableMouse(enable)
		anchor.bg = anchor:CreateTexture(nil, "OVERLAY")
		anchor.bg:SetAllPoints(anchor)
		anchor.bg:SetTexture(0,0,0)
		anchor.lbl = anchor:CreateFontString(nil,"OVERLAY", "SUI_Font10")
		anchor.lbl:SetText("Anchor for Rule " .. k);
		anchor.lbl:SetAllPoints(anchor)
		
		anchor:SetScript("OnMouseDown",function(self,button)
			if button == "LeftButton" then
				DB.Tooltips[v].Anchor.Moved = true;
				module[v].anchor:SetMovable(true);
				module[v].anchor:StartMoving();
			end
		end);
		
		anchor:SetScript("OnMouseUp",function(self,button)
			module[v].anchor:Hide();
			module[v].anchor:StopMovingOrSizing();
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = module[v].anchor:GetPoint()
			for k,val in pairs(Anchors) do
				DB.Tooltips[v].Anchor.AnchorPos[k] = val
			end
		end);
		
		anchor:SetScript("OnShow", function(self)
			if DB.Tooltips[v].Anchor.Moved then
				local Anchors = {}
				for key,val in pairs(DB.Tooltips[v].Anchor.AnchorPos) do
					Anchors[key] = val
				end
				self:ClearAllPoints();
				self:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
			else
				self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 20)
			end
		end)
		
		anchor:SetScript("OnEvent",function(self, event, ...)
			module[v].anchor:Hide();
		end);
		anchor:RegisterEvent("PLAYER_REGEN_DISABLED");
		
		module[v] = {anchor = anchor}
		module[v].anchor:Hide()
	end
	
	--Do Setup
	ApplyTooltipSkins()
	
	GameTooltip:HookScript("OnTooltipCleared", TipCleared)
	GameTooltip:HookScript("OnTooltipSetItem", TooltipSetItem)
	GameTooltip:HookScript("OnTooltipSetUnit", TooltipSetUnit)
	hooksecurefunc("GameTooltip_SetDefaultAnchor", setPoint)
	hooksecurefunc("GameTooltip_ShowCompareItem", ReStyle)
	
	-- GameTooltip:HookScript("SetPoint", setPoint)
	-- hooksecurefunc(GameTooltip,"SetPoint",setPoint);
	
	module:BuildOptions()
end

local UpdateOverrideThemeLoc = function(v)
	if DB.Tooltips[v].Anchor.onMouse or not DB.Styles[DBMod.Artwork.Style].TooltipLoc then
		spartan.opt.args["General"].args["ModSetting"].args["Tooltips"].args["DisplayLocation"..v].args["OverrideTheme"].disabled = true
	else
		spartan.opt.args["General"].args["ModSetting"].args["Tooltips"].args["DisplayLocation"..v].args["OverrideTheme"].disabled = false
	end
end

function module:BuildOptions()
	spartan.opt.args["General"].args["ModSetting"].args["Tooltips"] = {type="group",name="Tooltips",
		args = {
			Background = {name=L["Background"],type="select",order=1,
				values = {
				["metal"]="metal",
				["smooth"]="smooth",
				["smoke"]="smoke",
				["none"]=L["none"]},
				get = function(info) return DB.Tooltips.ActiveStyle end,
				set = function(info,val) DB.Tooltips.ActiveStyle = val end
			},
			OverrideTheme = {name=L["OverrideTheme"],type="toggle",order=2,desc=L["TooltipOverrideDesc"],
					get = function(info) return DB.Tooltips.Override[DBMod.Artwork.Style] end,
					set = function(info,val) DB.Tooltips.Override[DBMod.Artwork.Style] = val end
			},
			color = {name=L["Color"],type="color",hasAlpha=true,order=10,width="full",
				get = function(info) return unpack(DB.Tooltips.Color) end,
				set = function(info,r,g,b,a) DB.Tooltips.Color = {r,g,b,a} module:UpdateBG() end
			},
			ColorOverlay = {name=L["Color Overlay"],type="toggle",order=11,desc=L["ColorOverlayDesc"],
					get = function(info) return DB.Tooltips.ColorOverlay end,
					set = function(info,val) DB.Tooltips.ColorOverlay = val module:UpdateBG()end
			}
		}
	}
	
	for k,v in ipairs(RuleList) do
		spartan.opt.args["General"].args["ModSetting"].args["Tooltips"].args["DisplayLocation"..v] = {
			name="Display Location " .. v,type="group",inline=true,order=k + 20.1,width="full", args = {
			Condition = {name ="Condition", type="select",order=k + 20.2,
				values = {["Group"]="In a Group",["Raid"]="In a Raid Group",["Instance"]="In a instance",["All"]="All the time",["Disabled"]="Disabled"},
				get = function(info) return DB.Tooltips[v].Status; end,
				set = function(info,val) DB.Tooltips[v].Status = val; ObjTrackerUpdate() end
			},
			Combat = {name="only if in combat",type="toggle",order=k + 20.3,
			get = function(info) return DB.Tooltips[v].Combat end,
			set = function(info,val) DB.Tooltips[v].Combat = val; ObjTrackerUpdate() end
			},
			OnMouse = {name="Display on mouse?",type="toggle",order=k + 20.4,desc=L["TooltipOverrideDesc"],
					get = function(info) UpdateOverrideThemeLoc(v); return DB.Tooltips[v].Anchor.onMouse end,
					set = function(info,val) DB.Tooltips[v].Anchor.onMouse = val; UpdateOverrideThemeLoc(v); end
			},
			OverrideTheme = {name=L["OverrideTheme"],type="toggle",order=k + 20.5,
					get = function(info) UpdateOverrideThemeLoc(v); return DB.Tooltips[v].OverrideLoc end,
					set = function(info,val) DB.Tooltips[v].OverrideLoc = val; end
			},
			MoveAnchor = {name="Move anchor",type="execute",order=k + 20.6,width="half",func = function(info,val) module[v].anchor:Show() end},
			ResetAnchor = {name="Reset anchor",type="execute",order=k + 20.7,width="half",func = function(info,val) DB.Tooltips[v].Anchor.Moved = false end}
		}
		}
	end
end

function module:HideOptions()
	spartan.opt.args["General"].args["ModSetting"].args["Tooltips"].disabled = true
end