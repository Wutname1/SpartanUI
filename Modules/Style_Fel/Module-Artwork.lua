local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Fel");
----------------------------------------------------------------------------------------------------
local CurScale

-- Misc Framework stuff
function module:updateScale()
	if (not DB.scale) then -- make sure the variable exists, and auto-configured based on screen size
		local width, height = string.match(GetCVar("gxResolution"),"(%d+).-(%d+)");
		if (tonumber(width) / tonumber(height) > 4/3) then DB.scale = 0.92;
		else DB.scale = 0.78; end
	end
	if DB.scale ~= CurScale then
		if (DB.scale ~= Artwork_Core:round(Fel_SpartanUI:GetScale())) then
			Fel_SpartanUI:SetScale(DB.scale);
		end
		CurScale = DB.scale
	end
end;

function module:updateAlpha()
	if DB.alpha then
		Transparent_SpartanUI_Base1:SetAlpha(DB.alpha);
		Transparent_SpartanUI_Base2:SetAlpha(DB.alpha);
	end
end;

--	Module Calls
function module:TooltipLoc(self, parent)
	if (parent == "UIParent") then
		tooltip:ClearAllPoints();
		tooltip:SetPoint("BOTTOMRIGHT","Fel_SpartanUI","TOPRIGHT",0,10);
	end
end

function module:BuffLoc(self, parent)
	BuffFrame:ClearAllPoints();
	BuffFrame:SetPoint("TOPRIGHT",-13,-13-(DB.BuffSettings.offset));
end

function module:SetupVehicleUI()
	if DBMod.Artwork.VehicleUI then
		RegisterStateDriver(Fel_SpartanUI, "visibility", "[petbattle][overridebar][vehicleui] hide; show");
	end
end

function module:RemoveVehicleUI()
	if DBMod.Artwork.VehicleUI then
		UnRegisterStateDriver(Fel_SpartanUI, "visibility");
	end
end

function module:InitArtwork()
	--if (Bartender4.db:GetCurrentProfile() == DB.Styles.Transparent.BartenderProfile or not Artwork_Core:BartenderProfileCheck(DB.Styles.Transparent.BartenderProfile,true)) then
	Artwork_Core:ActionBarPlates("Fel_ActionBarPlate");
	--end

	do -- create bar anchor
		plate = CreateFrame("Frame","Fel_ActionBarPlate",Fel_SpartanUI,"Fel_ActionBarsTemplate");
		plate:SetFrameStrata("BACKGROUND");
		plate:SetFrameLevel(1);
		plate:SetPoint("BOTTOM");
	end
end

function module:EnableArtwork()
	Fel_SpartanUI:SetFrameStrata("BACKGROUND");
	Fel_SpartanUI:SetFrameLevel(1);
	-- module:SetupProfile()
	
	-- local Win = CreateFrame("Frame", "SUI_Win", UIParent)
	-- Win:SetSize(550, 400)
	-- Win:SetPoint("TOP", UIParent, "TOP", 0, -150)
	-- Win:SetFrameStrata("TOOLTIP")
	
	Fel_SpartanUI.Left = Fel_SpartanUI:CreateTexture("Fel_SpartanUI_Left", "BORDER")
	Fel_SpartanUI.Left:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", 0, 0)
	Fel_SpartanUI.Left:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Base_Bar_Left]])
	
	Fel_SpartanUI.Right = Fel_SpartanUI:CreateTexture("Fel_SpartanUI_Right", "BORDER")
	Fel_SpartanUI.Right:SetPoint("LEFT", Fel_SpartanUI.Left, "RIGHT", 0, 0)
	Fel_SpartanUI.Right:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Base_Bar_Right]])
	-- Win.bg:SetVertexColor(0, 0, 0, .7)
	
	hooksecurefunc("UIParent_ManageFramePositions",function()
		TutorialFrameAlertButton:SetParent(Minimap);
		TutorialFrameAlertButton:ClearAllPoints();
		TutorialFrameAlertButton:SetPoint("CENTER",Minimap,"TOP",-2,30);
		CastingBarFrame:ClearAllPoints();
		CastingBarFrame:SetPoint("BOTTOM",Fel_SpartanUI,"TOP",0,90);
	end);
	
	module:SetupVehicleUI();
	
	if (DB.MiniMap.AutoDetectAllowUse) or (DB.MiniMap.ManualAllowUse) then module:MiniMap() end

	module:updateScale();
	module:updateAlpha();
end

-- Bartender Stuff
function module:SetupProfile()
	Artwork_Core:SetupProfile()
end;

function module:CreateProfile()
	Artwork_Core:CreateProfile()
end

-- Minimap


function module:MiniMap()
	Minimap:SetSize(156, 156);
	
	Minimap:ClearAllPoints();
	Minimap:SetPoint("CENTER",Fel_SpartanUI.Left,"RIGHT",0,-10);
	Minimap:SetParent(Fel_SpartanUI);
	
	if Minimap.ZoneText ~= nil then
		Minimap.ZoneText:ClearAllPoints();
		Minimap.ZoneText:SetPoint("TOPLEFT",Minimap,"BOTTOMLEFT",0,-5);
		Minimap.ZoneText:SetPoint("TOPRIGHT",Minimap,"BOTTOMRIGHT",0,-5);
		Minimap.ZoneText:Hide();
		MinimapZoneText:Show();
		
		Minimap.coords:SetTextColor(1,.82,0,1);
	end
	
	-- Minimap.coords:Hide()
	
	QueueStatusFrame:ClearAllPoints();
	QueueStatusFrame:SetPoint("BOTTOM",Fel_SpartanUI,"TOP",0,100);

	Minimap.FelBG = Minimap:CreateTexture(nil, "BACKGROUND")
	if DB.Styles.Fel.Minimap.Engulfed then
		Minimap.FelBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Minimap-Engulfed]])
		Minimap.FelBG:SetPoint("CENTER", Minimap, "CENTER", 7, 37)
		Minimap.FelBG:SetSize(330, 330)
		Minimap.FelBG:SetBlendMode("ADD");
	else
		Minimap.FelBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Minimap-Calmed]])
		Minimap.FelBG:SetPoint("CENTER", Minimap, "CENTER", 5, -1)
		Minimap.FelBG:SetSize(256, 256)
		Minimap.FelBG:SetBlendMode("ADD");
	end
	
	--Shape Change
	local shapechange = function(shape)
		if shape == "square" then
			Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
			
			Minimap.overlay = Minimap:CreateTexture(nil,"OVERLAY");
			Minimap.overlay:SetTexture("Interface\\AddOns\\SpartanUI\\Media\\map-square-overlay");
			Minimap.overlay:SetAllPoints(Minimap);
			Minimap.overlay:SetBlendMode("ADD");
			
			MiniMapTracking:ClearAllPoints();
			MiniMapTracking:SetPoint("TOPLEFT",Minimap,"TOPLEFT",0,0)
			Minimap.FelBG:Hide()
		else
			Minimap:SetMaskTexture("Interface\\AddOns\\SpartanUI\\media\\map-circle-overlay")
			MiniMapTracking:ClearAllPoints();
			MiniMapTracking:SetPoint("TOPLEFT",Minimap,"TOPLEFT",-5,-5)
			if Minimap.overlay then Minimap.overlay:Hide() end
			Minimap.FelBG:Show()
		end
	end

	Fel_SpartanUI:HookScript("OnHide", function(this, event)
		Minimap:ClearAllPoints();
		Minimap:SetParent(UIParent);
		Minimap:SetPoint("TOP",UIParent,"TOP",0,-20);
		shapechange("square")
	end)
	
	Fel_SpartanUI:HookScript("OnShow", function(this, event)
		Minimap:ClearAllPoints();
		Minimap:SetPoint("CENTER",Fel_SpartanUI,"CENTER",0,54);
		Minimap:SetParent(Fel_SpartanUI);
		shapechange("circle")
	end)
	
end





