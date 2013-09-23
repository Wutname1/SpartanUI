local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local AceHook = LibStub("AceHook-3.0")
local module = addon:NewModule("BottomBar");
local party -- for updateSpartanOffset use
----------------------------------------------------------------------------------------------------
local anchor, frame = SUI_AnchorFrame, SpartanUI;

local round = function(num) -- rounds a number to 2 decimal places
	if num then return floor( (num*10^2)+0.5) / (10^2); end
end;

local updateMinimumScale = function()
--	local minScale = floor(((UIParent:GetWidth()/2560)*10^2)+1) / (10^2);
--	if DB.scale < minScale then DB.scale = minScale; end
end;

local updateSpartanScale = function() -- scales SpartanUI based on setting or screen size
	if (not DB.scale) then -- make sure the variable exists, and auto-configured based on screen size
		local width, height = string.match(GetCVar("gxResolution"),"(%d+).-(%d+)");
		if (tonumber(width) / tonumber(height) > 4/3) then DB.scale = 0.92;
		else DB.scale = 0.78; end
	end
	updateMinimumScale();
	if (DB.scale ~= round(SpartanUI:GetScale())) then
		frame:SetScale(DB.scale);
	end
	if DB.scale <= .75 then
		SpartanUI_Base3:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT");
		SpartanUI_Base5:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT");
	else
		SpartanUI_Base3:ClearAllPoints();
		SpartanUI_Base5:ClearAllPoints();
		SpartanUI_Base3:SetPoint("RIGHT", SpartanUI_Base2, "LEFT");
		SpartanUI_Base5:SetPoint("LEFT", SpartanUI_Base4, "RIGHT");
	end
end;

local updateSpartanAlpha = function() -- scales SpartanUI based on setting or screen size
	if DB.alpha then
		SpartanUI_Base1:SetAlpha(DB.alpha);
		SpartanUI_Base2:SetAlpha(DB.alpha);
		SpartanUI_Base3:SetAlpha(DB.alpha);
		SpartanUI_Base4:SetAlpha(DB.alpha);
		SpartanUI_Base5:SetAlpha(DB.alpha);
		SUI_Popup1Mask:SetAlpha(DB.alpha);
		SUI_Popup2Mask:SetAlpha(DB.alpha);
	end
end;

local updateSpartanOffset = function() -- handles SpartanUI offset based on setting or fubar / titan
	local fubar,ChocolateBar,titan,offset = 0,0,0;

	if not DB.yoffsetAuto then
		offset = max(DB.yoffset,1);
	else
		for i = 1,4 do -- FuBar Offset
			if (_G["FuBarFrame"..i] and _G["FuBarFrame"..i]:IsVisible()) then
				local bar = _G["FuBarFrame"..i];
				local point = bar:GetPoint(1);
				if point == "BOTTOMLEFT" then fubar = fubar + bar:GetHeight(); end
			end
		end
		for i = 1,100 do -- Chocolate Bar Offset
			if (_G["ChocolateBar"..i] and _G["ChocolateBar"..i]:IsVisible()) then
				local bar = _G["ChocolateBar"..i];
				local point = bar:GetPoint(1);
				--if point == "TOPLEFT" then ChocolateBar = ChocolateBar + bar:GetHeight(); 	end--top bars
				if point == "RIGHT" then ChocolateBar = ChocolateBar + bar:GetHeight(); 	end-- bottom bars
			end
		end
		TitanBarOrder = {[1]="AuxBar2", [2]="AuxBar"} -- Bottom 2 Bar names
		for i=1,2 do -- Titan Bar Offset
			if (_G["Titan_Bar__Display_"..TitanBarOrder[i]] and TitanPanelGetVar(TitanBarOrder[i].."_Show")) then
				local PanelScale = TitanPanelGetVar("Scale") or 1
				local bar = _G["Titan_Bar__Display_"..TitanBarOrder[i]]
				titan = titan + (PanelScale * bar:GetHeight());
			end
		end
		
		offset = max(fubar + titan + ChocolateBar,1);
	end
	if (round(offset) ~= round(anchor:GetHeight())) then anchor:SetHeight(offset); end
	DB.yoffset = offset
end;

local updateSpartanXOffset = function() -- handles SpartanUI offset based on setting or fubar / titan
	if not DB.xOffset then return 0; end
	local offset = DB.xOffset
	if round(offset) <= -300 then
		SpartanUI_Base5:ClearAllPoints();
		SpartanUI_Base5:SetPoint("LEFT", SpartanUI_Base4, "RIGHT");
		SpartanUI_Base5:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT");
	elseif round(offset) >= 300 then
		SpartanUI_Base3:ClearAllPoints();
		SpartanUI_Base3:SetPoint("RIGHT", SpartanUI_Base2, "LEFT");
		SpartanUI_Base3:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT");
	end
	SpartanUI:SetPoint("LEFT", SUI_AnchorFrame, "LEFT", offset, 0)
	if (round(offset) ~= round(anchor:GetWidth())) then anchor:SetWidth(offset); end
	DB.xOffset = offset
end;

local updateSpartanViewport = function(state) -- handles viewport offset based on settings
	if ( state ) and not InCombatLockdown() then
		WorldFrame:ClearAllPoints(); WorldFrame:SetPoint("TOPLEFT", 0, 0); WorldFrame:SetPoint("BOTTOMRIGHT", 0, 0);
	else
		if not InCombatLockdown() then WorldFrame:SetPoint("BOTTOMRIGHT"); end
	end
end;

----------------------------------------------------------------------------------------------------
function module:OnInitialize()
	do -- default interface modifications
		FramerateLabel:ClearAllPoints(); FramerateLabel:SetPoint("TOP", "WorldFrame", "TOP", -15, -50);
		MainMenuBar:Hide();
		hooksecurefunc(UIParent,"Hide",function() updateSpartanViewport(false); end);
		hooksecurefunc(UIParent,"Show",function() updateSpartanViewport(true); end);
		hooksecurefunc("UpdateContainerFrameAnchors",function() -- fix bag offsets
			local frame, xOffset, yOffset, screenHeight, freeScreenHeight, leftMostPoint, column
			local screenWidth = GetScreenWidth()
			local containerScale = 1
			local leftLimit = 0
			if ( BankFrame:IsShown() ) then
				leftLimit = BankFrame:GetRight() - 25
			end
			while ( containerScale > CONTAINER_SCALE ) do
				screenHeight = GetScreenHeight() / containerScale
				-- Adjust the start anchor for bags depending on the multibars
				xOffset = 1 / containerScale
				yOffset = 155;
				-- freeScreenHeight determines when to start a new column of bags
				freeScreenHeight = screenHeight - yOffset
				leftMostPoint = screenWidth - xOffset
				column = 1
				local frameHeight
				for index, frameName in ipairs(ContainerFrame1.bags) do
					frameHeight = getglobal(frameName):GetHeight()
					if ( freeScreenHeight < frameHeight ) then
						-- Start a new column
						column = column + 1
						leftMostPoint = screenWidth - ( column * CONTAINER_WIDTH * containerScale ) - xOffset
						freeScreenHeight = screenHeight - yOffset
					end
					freeScreenHeight = freeScreenHeight - frameHeight - VISIBLE_CONTAINER_SPACING
				end
				if ( leftMostPoint < leftLimit ) then
					containerScale = containerScale - 0.01
				else
					break
				end
			end
			if ( containerScale < CONTAINER_SCALE ) then
				containerScale = CONTAINER_SCALE
			end
			screenHeight = GetScreenHeight() / containerScale
			-- Adjust the start anchor for bags depending on the multibars
			xOffset = 1 / containerScale
			yOffset = 154
			-- freeScreenHeight determines when to start a new column of bags
			freeScreenHeight = screenHeight - yOffset
			column = 0
			for index, frameName in ipairs(ContainerFrame1.bags) do
				frame = getglobal(frameName)
				frame:SetScale(containerScale)
				if ( index == 1 ) then
					-- First bag
					frame:SetPoint("BOTTOMRIGHT", frame:GetParent(), "BOTTOMRIGHT", -xOffset, (yOffset + (DB.yoffset or 1)) * (DB.scale or 1) )
				elseif ( freeScreenHeight < frame:GetHeight() ) then
					-- Start a new column
					column = column + 1
					freeScreenHeight = screenHeight - yOffset
					frame:SetPoint("BOTTOMRIGHT", frame:GetParent(), "BOTTOMRIGHT", -(column * CONTAINER_WIDTH) - xOffset, yOffset )
				else
					-- Anchor to the previous bag
					frame:SetPoint("BOTTOMRIGHT", ContainerFrame1.bags[index - 1], "TOPRIGHT", 0, CONTAINER_SPACING)
				end
				freeScreenHeight = freeScreenHeight - frame:GetHeight() - VISIBLE_CONTAINER_SPACING
			end
		end);
		hooksecurefunc(GameTooltip,"SetPoint",function(tooltip,point,parent,rpoint) -- fix GameTooltip offset
			if (point == "BOTTOMRIGHT" and parent == "UIParent" and rpoint == "BOTTOMRIGHT") then
				tooltip:ClearAllPoints();
				tooltip:SetPoint("BOTTOMRIGHT","SpartanUI","TOPRIGHT",0,10);
			end
		end);
	end
	addon.optionsGeneral.args["DefaultScales"] = {name = L["DefScales"],type = "execute",order = 2,
		desc = L["DefScalesDesc"],
		func = function()
			if (InCombatLockdown()) then 
				addon:Print(ERR_NOT_IN_COMBAT);
			else
				if (DB.scale >= 0.92) or (DB.scale < 0.78) then
					DB.scale = 0.78;
				else
					DB.scale = 0.92;
				end
			end
		end
	};
	addon.optionsGeneral.args["scale"] = {name = L["ConfScale"],type = "range",order = 1,width = "double",
		desc = L["ConfScaleDesc"],min = 0,max = 1,
		set = function(info,val)
			if (InCombatLockdown()) then 
				addon:Print(ERR_NOT_IN_COMBAT);
			else
				DB.scale = min(1,round(val));
				updateMinimumScale();
			end
		end,
		get = function(info) return DB.scale; end
	};
	addon.optionsGeneral.args["offset"] = {name = L["ConfOffset"],type = "range",order = 3,width="double",
		desc = L["ConfOffsetDesc"],
		min=0,max=200,step=.1,
		get = function(info) return DB.yoffset end,
		set = function(info,val)
			if (InCombatLockdown()) then 
				addon:Print(ERR_NOT_IN_COMBAT);
			else
				if DB.yoffsetAuto then
					addon:Print(L["confOffsetAuto"]);
				else
					val = tonumber(val);
					DB.yoffset = val;
				end
			end
		end,
		get = function(info) return DB.yoffset; end
	};
	addon.optionsGeneral.args["offsetauto"] = {name = L["AutoOffset"],type = "toggle",order = 4,
		desc = L["AutoOffsetDesc"],
		get = function(info) return DB.yoffsetAuto end,
		set = function(info,val) DB.yoffsetAuto = val end,
	};
	addon.optionsGeneral.args["Artwork"] = {name = "Artwork Options",type="group",order=10,
		args = {
			alpha = {name=L["Transparency"],type="range",order=1,width="full",
				min=0,max=100,step=1,desc=L["TransparencyDesc"],
				get = function(info) return (DB.alpha*100); end,
				set = function(info,val) DB.alpha = (val/100); updateSpartanAlpha(); end
			},
			xOffset = {name = L["MoveSideways"],type = "range",order = 3,width="full",
				desc = L["MoveSidewaysDesc"],
				min=-200,max=200,step=.1,
				get = function(info) return DB.xOffset/6.25 end,
				set = function(info,val) DB.xOffset = val*6.25; updateSpartanXOffset(); end,
			}
		}
	}
end

function module:OnEnable()
	anchor:SetFrameStrata("BACKGROUND"); anchor:SetFrameLevel(1);
	frame:SetFrameStrata("BACKGROUND"); frame:SetFrameLevel(1);
	
	hooksecurefunc("AchievementAlertFrame_ShowAlert",function() -- achivement alerts
		if (AchievementAlertFrame1) then AchievementAlertFrame1:SetPoint("BOTTOM",SpartanUI,"TOP",0,100); end
	end);
	hooksecurefunc("UIParent_ManageFramePositions",function()
		TutorialFrameAlertButton:SetParent(Minimap);
		TutorialFrameAlertButton:ClearAllPoints();
		TutorialFrameAlertButton:SetPoint("CENTER",Minimap,"TOP",-2,30);
		CastingBarFrame:ClearAllPoints();
		CastingBarFrame:SetPoint("BOTTOM",frame,"TOP",0,90);
	end);
	
	RegisterStateDriver(frame, "visibility", "[petbattle] hide; show")

	updateSpartanScale();
	updateSpartanOffset();
	updateSpartanXOffset();
	updateSpartanViewport();
	updateSpartanAlpha();
	
	party = addon:GetModule("PartyFrames","PartyFrames",true);
	-- Fix CPU leak, use UpdateInterval
	anchor.UpdateInterval = 2
	anchor.TimeSinceLastUpdate = 0
	anchor:SetScript("OnUpdate",function(self,...)
		local elapsed = select(1,...)
		self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed; 
		if (self.TimeSinceLastUpdate > self.UpdateInterval) then
			-- Debug
--			print(self.TimeSinceLastUpdate)
			if (InCombatLockdown()) then return; end
			-- Count this be hooked in another way ... event CVar_UPDATE
			updateSpartanScale();
			updateSpartanOffset();
			updateSpartanXOffset();
			self.TimeSinceLastUpdate = 0
		end
	end);
	do
		function My_VehicleSeatIndicatorButton_OnClick(self, button)
			local seatIndex = self.virtualID;
			local controlType, occupantName = UnitVehicleSeatInfo("player", seatIndex);
			if ( button == "RightButton" and ( CanEjectPassengerFromSeat(seatIndex) or (CanExitVehicle() and ( occupantName == UnitName("player") )))) then
				ToggleDropDownMenu(1, seatIndex, VehicleSeatIndicatorDropDown, self:GetName(), 0, -5);
				if ( CanEjectPassengerFromSeat(seatIndex) ) then
					UIDropDownMenu_DisableButton(1,2);
					UIDropDownMenu_EnableButton(1,1);
				else
					UIDropDownMenu_DisableButton(1,1);
					UIDropDownMenu_EnableButton(1,2);
				end
			else
				UnitSwitchToVehicleSeat("player", seatIndex);
			end
		end
		
		local old_VehicleSeatIndicatorButton_OnClick = VehicleSeatIndicatorButton_OnClick
		VehicleSeatIndicatorButton_OnClick = My_VehicleSeatIndicatorButton_OnClick
		
		function My_VehicleSeatIndicatorDropDown_Initialize()
			local info = UIDropDownMenu_CreateInfo();
			info.text = EJECT_PASSENGER;
			info.disabled = nil;
			info.func = VehicleSeatIndicatorDropDown_OnClick;
			UIDropDownMenu_AddButton(info);
			info.text = VEHICLE_LEAVE;
			info.disabled = nil;
			info.func = VehicleSeatLeaveVehicleDropDown_OnClick;
			UIDropDownMenu_AddButton(info);
		end
		
		function VehicleSeatLeaveVehicleDropDown_OnClick()
			VehicleExit();
			PlaySound("UChatScrollButton");
		end
		
		local old_VehicleSeatIndicatorDropDown_Initialize = VehicleSeatIndicatorDropDown_Initialize()
		VehicleSeatIndicatorDropDown_Initialize = My_VehicleSeatIndicatorDropDown_Initialize
		
		UIDropDownMenu_Initialize( VehicleSeatIndicatorDropDown, VehicleSeatIndicatorDropDown_Initialize, "MENU");
	end
	
end
