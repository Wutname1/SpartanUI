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
			SetupDone = false,
			Rule1 = {
				Status = "Raid",
				Combat = false
			},
			Rule2 = {
				Status = "Disabled",
				Combat = false
			},
			Rule3 = {
				Status = "Disabled",
				Combat = false
			}
		}
	end
	if DBMod.Artwork.SetupDone then DBMod.Objectives.SetupDone = true end
	if not DBMod.Objectives.SetupDone then module:FirstTimeSetup() end
end

function module:OnEnable()
	if not DB.EnabledComponents.Objectives then return end
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
	spartan.opt.args["ModSetting"].args["Objectives"] = {type="group",name=L["Objectives"],
		args = {}
	}
	for k,v in ipairs(RuleList) do
		spartan.opt.args["ModSetting"].args["Objectives"].args[v .. "Title"] = {name=v,type="header",order=k,width="full"}
		spartan.opt.args["ModSetting"].args["Objectives"].args[v .. "Status"] = {name ="When to hide", type="select",order=k + .2,
			values = {["Group"]="In a Group",["Raid"]="In a Raid Group",["Boss"]="Boss Fight",["Instance"]="In a instance",["All"]="All the time",["Disabled"]="Disabled"},
			get = function(info) return DBMod.Objectives[v].Status; end,
			set = function(info,val) DBMod.Objectives[v].Status = val; ObjTrackerUpdate() end
		}
		spartan.opt.args["ModSetting"].args["Objectives"].args[v .. "Text"] = {name="",type="description",order=k + .3,width="half"}
		spartan.opt.args["ModSetting"].args["Objectives"].args[v .. "Combat"] = {name="only if in combat",type="toggle",order=k + .4,
			get = function(info) return DBMod.Objectives[v].Combat end,
			set = function(info,val) DBMod.Objectives[v].Combat = val; ObjTrackerUpdate() end
		}
	end
end

function module:HideOptions()
	spartan.opt.args["ModSetting"].args["Objectives"].disabled = true
end

function module:FirstTimeSetup()
	local PageData = {
		SubTitle = "Objectives",
		Desc1 = "",
		Display = function()
			local gui = LibStub("AceGUI-3.0")
			--Container
			SUI_Win.Objectives = CreateFrame("Frame", nil)
			SUI_Win.Objectives:SetParent(SUI_Win.content)
			SUI_Win.Objectives:SetAllPoints(SUI_Win.content)

			--TurnInEnabled
			SUI_Win.Objectives.Enabled = CreateFrame("CheckButton", "SUI_Objectives_Enabled", SUI_Win.Objectives, "OptionsCheckButtonTemplate")
			SUI_Win.Objectives.Enabled:SetPoint("TOP", SUI_Win.Objectives, "TOP", -90, -10)
			SUI_Objectives_EnabledText:SetText("Auto Vendor Enabled")
			SUI_Win.Objectives.Enabled:HookScript("OnClick", function(this)
				if this:GetChecked() == true then
					SUI_Objectives_SellGray:Enable()
					SUI_Objectives_SellWhite:Enable()
					SUI_Objectives_SellGreen:Enable()
				else
					SUI_Objectives_SellGray:Disable()
					SUI_Objectives_SellWhite:Disable()
					SUI_Objectives_SellGreen:Disable()
				end
			end)
			
			--Profiles
			local control = gui:Create("Dropdown")
			control:SetLabel("Exsisting profiles")
			local tmpprofiles = {}
			local profiles = {}
			-- copy existing profiles into the table
			local currentProfile = SUI.DB:GetCurrentProfile()
			for i,v in pairs(SUI.DB:GetProfiles(tmpprofiles)) do 
				if not (nocurrent and v == currentProfile) then 
					profiles[v] = v 
				end 
			end
			control:SetList(profiles)
			control:SetPoint("TOP", SUI_Win.Core, "TOP", 0, -30)
			control.frame:SetParent(SUI_Win.Core)
			control.frame:Show()
			SUI_Win.Core.Profiles = control
			
			--SellGray
			SUI_Win.Objectives.SellGray = CreateFrame("CheckButton", "SUI_Objectives_SellGray", SUI_Win.Objectives, "OptionsCheckButtonTemplate")
			SUI_Win.Objectives.SellGray:SetPoint("TOP", SUI_Win.Objectives.Enabled, "TOP", -90, -40)
			SUI_Objectives_SellGrayText:SetText("Sell gray items")
			
			--Defaults
			SUI_Objectives_Enabled:SetChecked(true)
			SUI_Objectives_SellGray:SetChecked(true)
		end,
		Next = function()
			DB.Objectives.FirstLaunch = false
			
			DB.EnabledComponents.Objectives = (SUI_Win.Objectives.Enabled:GetChecked() == true or false)
			DB.Objectives.MaxILVL = SUI_Win.Objectives.iLVL:GetValue()
			
			SUI_Win.Objectives:Hide()
			SUI_Win.Objectives = nil
		end,
		Skip = function()
			DB.Objectives.FirstLaunch = true
		end
	}
	-- local SetupWindow = spartan:GetModule("SetupWindow")
	-- SetupWindow:AddPage(PageData)
	-- SetupWindow:DisplayPage()
end