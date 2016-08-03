local _, SUI = ...
SUI = _G["SUI"]
local module = SUI:NewModule("ActionCamPlusPlus");

local SpinCamRunning = false
local userCameraYawMoveSpeed

function module:FirstLaunch()
	local PageData = {
		SubTitle = "Action Cam Plus",
		Desc1 = "New hidden legion camera view settings.",
		Display = function()
			local gui = LibStub("AceGUI-3.0")
			--Container
			SUI_Win.ActionCamPlus = CreateFrame("Frame", nil)
			SUI_Win.ActionCamPlus:SetParent(SUI_Win.content)
			SUI_Win.ActionCamPlus:SetAllPoints(SUI_Win.content)
			
			--cameraOverShoulder
			SUI_Win.ActionCamPlus.cameraOverShoulder = CreateFrame("CheckButton", "SUI_cameraOverShoulder", SUI_Win.ActionCamPlus, "OptionsCheckButtonTemplate")
			SUI_Win.ActionCamPlus.cameraOverShoulder:SetPoint("TOP", SUI_Win.ActionCamPlus, "TOP", -90, -90)
			SUI_cameraOverShoulderText:SetText("Camera over shoulder")
			
			--AcceptGeneralQuests
			SUI_Win.ActionCamPlus.cameraLockedTargetFocusing = CreateFrame("CheckButton", "SUI_cameraLockedTargetFocusing", SUI_Win.ActionCamPlus, "OptionsCheckButtonTemplate")
			SUI_Win.ActionCamPlus.cameraLockedTargetFocusing:SetPoint("TOP", SUI_Win.ActionCamPlus.cameraOverShoulder, "BOTTOM", 0, -15)
			SUI_cameraLockedTargetFocusingText:SetText("Focus camera on target")
			
			--Defaults
			if GetCVar("cameraOverShoulder") == "1" then SUI_cameraOverShoulder:SetChecked(true) end
			if GetCVar("cameraLockedTargetFocusing") == "1" then SUI_cameraLockedTargetFocusing:SetChecked(true) end
		end,
		Next = function()
			SUI.DBP.ActionCamPlus.FirstLaunch = false
	
			--cameraOverShoulder
			local i = 0
			if SUI_cameraOverShoulderText:GetChecked() then i = 1 end
			SetCVar("cameraOverShoulder", i, true)
			--cameraLockedTargetFocusing
			local i = 0
			if SUI_cameraLockedTargetFocusing:GetChecked() then i = 1 end
			SetCVar("cameraLockedTargetFocusing", i, true)
			
			SUI_Win.ActionCamPlus:Hide()
			SUI_Win.ActionCamPlus = nil
		end,
		Skip = function()
			SUI.DBP.ActionCamPlus.FirstLaunch = false
		end
	}
	local SetupWindow = SUI:GetModule("SetupWindow")
	SetupWindow:AddPage(PageData)
	SetupWindow:DisplayPage()
end

function module:OnInitialize()
	if SUI.DBP.ActionCamPlus == nil then
	SUI.DBP.ActionCamPlus = {
		FirstLaunch = true,
		SpinCam = SUI.DBMod.SpinCam -- TODO: These need to be moved out of defaults and to here.
	}
	end
	SUI.opt.args["ModSetting"].args["ActionCamPlus"] = {
		name = "ActionCamPlus",
		type = "group",
		args = {
			cameraOverShoulder = {
				name="Over shoulder",
				type="toggle",
				order=1,
				width="full",
				get = function(info)
					if GetCVar("cameraOverShoulder") == "1" then return true end
					return false
					end,
				set = function(info,val)
					local i = 0
					if val then i = 1 end
					SetCVar("cameraOverShoulder", i, true)
					end
			},
			cameraLockedTargetFocusing = {
				name="Focus on target",
				type="toggle",
				order=2,
				width="full",
				get = function(info)
					if GetCVar("cameraLockedTargetFocusing") == "1" then return true end
					return false
					end,
				set = function(info,val)
					local i = 0
					if val then i = 1 end
					SetCVar("cameraLockedTargetFocusing", i, true)
					end
			},
			SpinCam = {
			name = SUI.L["SpinCam"],
			type = "group",
			args = {
					enable = {name=SUI.L["Spin/AFKOn"],type="toggle",order=1,width="full",
						get = function(info) return SUI.DBP.ActionCamPlus.SpinCam.enable end,
						set = function(info,val) SUI.DBP.ActionCamPlus.SpinCam.enable = val end
					},
					speed = {name=SUI.L["Spin/Speed"],type="range",order=5,width="full",
						min=1,max=230,step=1,
						get = function(info) return SUI.DBP.ActionCamPlus.SpinCam.speed end,
						set = function(info,val) if SUI.DBP.ActionCamPlus.SpinCam.enable then SUI.DBP.ActionCamPlus.SpinCam.speed = val; end if SpinCamRunning then module:SpinToggle("update") end end
					},
					spin = {name=SUI.L["Spin/Toggle"],type="execute",order=15,width="double",
						desc = SUI.L["Spin/ToggleDesc"],
						func = function(info,val) module:SpinToggle(); end
					}
				}
			}
		}
	}
end

function module:OnEnable()
	if SUI.DBP.ActionCamPlus.FirstLaunch then module:FirstLaunch() end
	
	--Setup chat command
	SlashCmdList["SPINCAMTOGGLE"] = function(msg)
		if not SpinCamRunning then SUI:Print("|cff33ff99SpinCam|r- "..SUI.L["Spin/StopMSG"]); end
		module:SpinToggle()
	end;
	SLASH_SPINCAMTOGGLE1 = "/spin"
	
	--Log mouse speed
	SetCVar("cameraYawMoveSpeed",userCameraYawMoveSpeed);
	
	--watch for AFK
	local frame = CreateFrame("Frame");
	frame:RegisterEvent("CHAT_MSG_AFK");
	frame:SetScript("OnEvent",function(self, event, ...)
		if (... == format(MARKED_AFK_MESSAGE,DEFAULT_AFK_MESSAGE)) and (DBMod.SpinCam.enable) then
			addon:SpinToggle("start")
		elseif (... == CLEARED_AFK) and (SpinCamRunning) then
			addon:SpinToggle("stop")
		end
	end);
end

function module:SpinToggle(action)
	if (SpinCamRunning and action == nil) or (action=="stop") then
		MoveViewRightStop();
		SetCVar("cameraYawMoveSpeed",userCameraYawMoveSpeed);
		SpinCamRunning = false;
		SetView(1);
	elseif action == "update" then
		SetCVar("cameraYawMoveSpeed", DBMod.SpinCam.speed);
	elseif not SpinCamRunning then
		SaveView(1)
		userCameraYawMoveSpeed = (GetCVar("cameraYawMoveSpeed"))
		SetCVar("cameraYawMoveSpeed", DBMod.SpinCam.speed);
		MoveViewRightStart();
		SpinCamRunning = true;
		SetView(5);
	end
end
