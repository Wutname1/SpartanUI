local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local AceHook = LibStub("AceHook-3.0")
local module = spartan:NewModule("Component_Objectives");
----------------------------------------------------------------------------------------------------
local ObjectiveTrackerWatcher = CreateFrame("Frame")
local RuleList = {"Rule1", "Rule2", "Rule3"}

local HideFrame = function()
	if ObjectiveTrackerFrame.BlocksFrame:GetAlpha() == 0 then
		ObjectiveTrackerFrame.HeaderMenu.MinimizeButton:Hide()
	end
end

local ObjTrackerUpdate = function()
	local FadeIn = false
	local FadeOut = false

	--Figure out if we need to hide objectives
	for k,v in ipairs(RuleList) do
		if DBMod.Objectives[v].Status ~= "Disabled" then
			local CombatRule = false
			if InCombatLockdown() and DBMod.Objectives[v].Combat then
				CombatRule = true
			elseif not InCombatLockdown() and not DBMod.Objectives[v].Combat then
				CombatRule = true
			end
			
			if DBMod.Objectives[v].Status == "Group" and (IsInGroup() and not IsInRaid()) and CombatRule then
				FadeOut = true
			elseif DBMod.Objectives[v].Status == "Raid" and IsInRaid() and CombatRule then
				FadeOut = true
			elseif DBMod.Objectives[v].Status == "Boss" and event == "ENCOUNTER_START" then
				FadeOut = true
			elseif DBMod.Objectives[v].Status == "Instance" and IsInInstance() then
				FadeOut = true
			elseif DBMod.Objectives[v].Status == "All" and CombatRule then
				FadeOut = true
			else
				FadeIn = true
			end
		end
	end
	
	if FadeOut and ObjectiveTrackerFrame.BlocksFrame:GetAlpha() == 1 then
		ObjectiveTrackerFrame.BlocksFrame.FadeOut:Play();
		C_Timer.After(1, HideFrame)
	elseif FadeIn and ObjectiveTrackerFrame.BlocksFrame:GetAlpha() == 0 and not FadeOut then
		ObjectiveTrackerFrame.HeaderMenu.MinimizeButton:Show()
		ObjectiveTrackerFrame.BlocksFrame.FadeOut:Stop();
		ObjectiveTrackerFrame.BlocksFrame.FadeIn:Play();
	end
end

function module:OnInitialize()
	if DBMod.Objectives == nil then
		DBMod.Objectives = {
			Rule1 = {
				Status = "All",
				Combat = true
			},
			Rule2 = {
				Status = "Raid",
				Combat = false
			},
			Rule3 = {
				Status = "Disabled",
				Combat = false
			}
		}
	end
end

function module:OnEnable()
	-- Add Fade in and out
	ObjectiveTrackerFrame.BlocksFrame.FadeIn = ObjectiveTrackerFrame.BlocksFrame:CreateAnimationGroup()
	local FadeIn = ObjectiveTrackerFrame.BlocksFrame.FadeIn:CreateAnimation("Alpha")
	FadeIn:SetOrder(1)
	FadeIn:SetDuration(0.2)
	FadeIn:SetFromAlpha(0)
	FadeIn:SetToAlpha(1)
	ObjectiveTrackerFrame.BlocksFrame.FadeIn:SetToFinalAlpha(true)

	ObjectiveTrackerFrame.BlocksFrame.FadeOut = ObjectiveTrackerFrame.BlocksFrame:CreateAnimationGroup()
	local FadeOut = ObjectiveTrackerFrame.BlocksFrame.FadeOut:CreateAnimation("Alpha")
	FadeOut:SetOrder(1)
	FadeOut:SetDuration(0.3)
	FadeOut:SetFromAlpha(1)
	FadeOut:SetToAlpha(0)
	FadeOut:SetStartDelay(.5)
	ObjectiveTrackerFrame.BlocksFrame.FadeOut:SetToFinalAlpha(true)
	
	--Event Manager
	ObjectiveTrackerWatcher:SetScript("OnEvent", ObjTrackerUpdate)
	
	
	ObjectiveTrackerWatcher:RegisterEvent("ZONE_CHANGED")
	ObjectiveTrackerWatcher:RegisterEvent("ZONE_CHANGED_INDOORS")
	ObjectiveTrackerWatcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	ObjectiveTrackerWatcher:RegisterEvent("PLAYER_REGEN_DISABLED")
	ObjectiveTrackerWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
	ObjectiveTrackerWatcher:RegisterEvent("COMBAT_LOG_EVENT")
	ObjectiveTrackerWatcher:RegisterEvent("GROUP_JOINED")
	ObjectiveTrackerWatcher:RegisterEvent("GROUP_ROSTER_UPDATE")
	ObjectiveTrackerWatcher:RegisterEvent("RAID_INSTANCE_WELCOME")
	ObjectiveTrackerWatcher:RegisterEvent("PARTY_CONVERTED_TO_RAID")
	ObjectiveTrackerWatcher:RegisterEvent("RAID_INSTANCE_WELCOME")
	ObjectiveTrackerWatcher:RegisterEvent("ENCOUNTER_START")
	ObjectiveTrackerWatcher:RegisterEvent("ENCOUNTER_END")
	
	module:BuildOptions()
end

function module:BuildOptions()
	spartan.opt.args["General"].args["ModSetting"].args["Objectives"] = {type="group",name=L["Objectives"],
		args = {}
	}
	for k,v in ipairs(RuleList) do
		spartan.opt.args["General"].args["ModSetting"].args["Objectives"].args[v .. "Title"] = {name=v,type="header",order=k,width="full"}
		spartan.opt.args["General"].args["ModSetting"].args["Objectives"].args[v .. "Status"] = {name ="When to hide", type="select",order=k + .2,
			values = {["Group"]="In a Group",["Raid"]="In a Raid Group",["Boss"]="Boss Fight",["Instance"]="In a instance",["All"]="All the time",["Disabled"]="Disabled"},
			get = function(info) return DBMod.Objectives[v].Status; end,
			set = function(info,val) DBMod.Objectives[v].Status = val; ObjTrackerUpdate() end
		}
		spartan.opt.args["General"].args["ModSetting"].args["Objectives"].args[v .. "Text"] = {name="",type="description",order=k + .3,width="half"}
		spartan.opt.args["General"].args["ModSetting"].args["Objectives"].args[v .. "Combat"] = {name="only if in combat",type="toggle",order=k + .4,
			get = function(info) return DBMod.Objectives[v].Combat end,
			set = function(info,val) DBMod.Objectives[v].Combat = val; ObjTrackerUpdate() end
		}
	end
end

function module:HideOptions()
	spartan.opt.args["General"].args["ModSetting"].args["Objectives"].disabled = true
end