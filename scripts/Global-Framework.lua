local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local module = addon:NewModule("BottomBar");
local party -- for updateSpartanOffset use
----------------------------------------------------------------------------------------------------
local anchor, frame = SUI_AnchorFrame, SpartanUI;
local round = function(num) -- rounds a number to 2 decimal places
	return floor( (num*10^2)+0.5) / (10^2);
end;

local updateMinimumScale = function()
--	local minScale = floor(((UIParent:GetWidth()/2560)*10^2)+1) / (10^2);
--	if suiChar.scale < minScale then suiChar.scale = minScale; end
end;

local updateSpartanScale = function() -- scales SpartanUI based on setting or screen size
	suiChar = suiChar or {};
	if (not suiChar.scale) then -- make sure the variable exists, and auto-configured based on screen size
		local width, height = string.match(GetCVar("gxResolution"),"(%d+).-(%d+)");
		if (tonumber(width) / tonumber(height) > 4/3) then suiChar.scale = 0.92;
		else suiChar.scale = 0.78; end
	end
	updateMinimumScale();
	if (suiChar.scale ~= round(SpartanUI:GetScale())) then
		frame:SetScale(suiChar.scale);
	end
end;

local updateSpartanOffset = function() -- handles SpartanUI offset based on setting or fubar / titan
	local fubar,titan,offset = 0,0;
	if suiChar.offset then
		offset = max(suiChar.offset,1);
	else
		for i = 1,4 do
			if (_G["FuBarFrame"..i] and _G["FuBarFrame"..i]:IsVisible()) then
				local bar = _G["FuBarFrame"..i];
				local point = bar:GetPoint(1);
				if point == "BOTTOMLEFT" then fubar = fubar + bar:GetHeight(); end
			end
		end
		if (_G["Titan_Bar__Display_AuxBar"] and TitanPanelGetVar("AuxBar_Show")) then
			local PanelScale = TitanPanelGetVar("Scale") or 1
			local bar = _G["Titan_Bar__Display_AuxBar"]
			titan = titan + (PanelScale * bar:GetHeight());
		end
		if (_G["Titan_Bar__Display_AuxBar2"] and TitanPanelGetVar("AuxBar2_Show")) then
			local PanelScale = TitanPanelGetVar("Scale") or 1
			local bar = _G["Titan_Bar__Display_AuxBar2"]
			titan = titan + (PanelScale * bar:GetHeight());
		end
-- "old way" of adjusting bottom
--		if (_G["TitanPanelAuxBarButton"] and TitanPanelGetVar("BothBars")) then
--			local Double = TitanPanelGetVar("AuxDoubleBar")
--			local PanelScale = TitanPanelGetVar("Scale") or 1
--			local bar = _G["TitanPanelAuxBarButton"]
--			titan = titan + (PanelScale * bar:GetHeight());
--			if Double == 2 then titan = titan + (PanelScale * bar:GetHeight()); end
--		end
--		if (_G["TitanPanelBarButton"] and (TitanPanelGetVar("Position") == 2)) then
--			local Double = TitanPanelGetVar("DoubleBar")
--			local PanelScale = TitanPanelGetVar("Scale") or 1
--			local bar = _G["TitanPanelBarButton"]
--			titan = titan + (PanelScale * bar:GetHeight());
--			if Double == 2 then titan = titan + (PanelScale * bar:GetHeight()); end
--		end
		offset = max(fubar + titan,1);
	end
	if (round(offset) ~= round(anchor:GetHeight())) then anchor:SetHeight(offset); end
	if (party) then
		
		-- --------------------
		--    NEED TO REVISIT CODE BELOW
		-- --------------------
		--if party.offset ~= party:updatePartyOffset() then
		--	party:UpdatePartyPosition()
		--end
--		print("party")
	end
end;

local updateSpartanViewport = function(state) -- handles viewport offset based on settings
	if ( state ) then
		WorldFrame:ClearAllPoints(); WorldFrame:SetPoint("TOPLEFT", 0, 0); WorldFrame:SetPoint("BOTTOMRIGHT", 0, 0);
	else
		WorldFrame:SetPoint("BOTTOMRIGHT");
	end
end;

local updateBattlefieldMinimap = function()
	if ( BattlefieldMinimapTab and not BattlefieldMinimapTab:IsUserPlaced() ) then
		BattlefieldMinimapTab:ClearAllPoints()
		BattlefieldMinimapTab:SetPoint("RIGHT", "UIParent", "RIGHT",-144,150);
	end
end
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
					frame:SetPoint("BOTTOMRIGHT", frame:GetParent(), "BOTTOMRIGHT", -xOffset, (yOffset + (suiChar.offset or 1)) * (suiChar.scale or 1) )
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
	addon.options.args["maxres"] = {
		type = "execute", name = "Toggle Default Scales",
		desc = "toggles between widescreen and standard scales",
		func = function()
			if (InCombatLockdown()) then 
				addon:Print(ERR_NOT_IN_COMBAT);
			else
				if (suiChar.scale >= 0.92) or (suiChar.scale < 0.78) then
					suiChar.scale = 0.78;
				else
					suiChar.scale = 0.92;
				end
				addon:Print("Relative Scale set to "..suiChar.scale);
			end
		end
	};
	addon.options.args["scale"] = {
		type = "range", name = "Configure Scale",
		desc = "sets a specific scale for SpartanUI",
		set = function(info,val)
			if (InCombatLockdown()) then 
				addon:Print(ERR_NOT_IN_COMBAT);
			else
				suiChar.scale = min(1,round(val));
				updateMinimumScale();
				addon:Print("Relative Scale set to "..suiChar.scale);
			end
		end,
		get = function(info) return suiChar.scale; end
	};
	addon.options.args["offset"] = {
		type = "input",
		name = "Configure Offset",
		desc = "offsets the bottom bar automatically, or on a set value",
		set = function(info,val)
			if (InCombatLockdown()) then 
				addon:Print(ERR_NOT_IN_COMBAT);
			else
				if (val == "") or (val == "auto") then
					suiChar.offset = nil;
					addon:Print("Panel Offset set to AUTO");
				else
					val = tonumber(val);
					if (type(val) == "number") then
						val = max(0,val);
						suiChar.offset = max(val+1,1);
						addon:Print("Panel Offset set to "..val);
					end
				end
			end
		end,
		get = function(info) return suiChar.offset; end
	};
end

function module:OnEnable()
	anchor:SetFrameStrata("BACKGROUND"); anchor:SetFrameLevel(1);
	frame:SetFrameStrata("BACKGROUND"); frame:SetFrameLevel(1);
	
	-- Problem is due to Outfitter
	-- local FrameLevel = LFDQueueFrameRandom:GetFrameLevel();
	-- LFDQueueFrameCooldownFrame:SetFrameLevel(FrameLevel + 1)
	
	hooksecurefunc("AchievementAlertFrame_ShowAlert",function() -- achivement alerts
		if (AchievementAlertFrame1) then AchievementAlertFrame1:SetPoint("BOTTOM",UIParent,"CENTER"); end
	end);
	hooksecurefunc("UIParent_ManageFramePositions",function()
		updateBattlefieldMinimap();
		if ( ArenaEnemyFrames ) then
			ArenaEnemyFrames:ClearAllPoints();
			ArenaEnemyFrames:SetPoint("RIGHT", UIParent, "RIGHT",0,40);
		end
		TutorialFrameAlertButton:SetParent(Minimap);
		TutorialFrameAlertButton:ClearAllPoints();
		TutorialFrameAlertButton:SetPoint("CENTER",Minimap,"TOP",-2,30);
		CastingBarFrame:ClearAllPoints();
		CastingBarFrame:SetPoint("BOTTOM",frame,"TOP",0,90);
	end);
	hooksecurefunc("ToggleBattlefieldMinimap",updateBattlefieldMinimap);
	
	updateSpartanScale();
	updateSpartanOffset();
	updateSpartanViewport();
	
	party = addon:GetModule("PartyFrames","PartyFrames",true);
	-- Fix CPU leak, use UpdateInterval
	anchor.UpdateInterval = 0.5
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
	-- VEHICLE Exit button will need this
--	if (event == "UNIT_EXITED_VEHICLE") then
--		print(event)
--	end
--	self:RegisterEvent("UNIT_EXITED_VEHICLE", Update);
--	VehicleExit();
end
