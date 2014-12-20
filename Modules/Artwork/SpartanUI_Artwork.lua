local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:NewModule("Artwork_Core");

function Artwork_Core:isPartialMatch(frameName, tab)
	local result = false

	for k,v in ipairs(tab) do
		startpos, endpos = strfind(strlower(frameName), strlower(v))
		if (startpos == 1) then
			result = true;
		end
	end

	return result;
end

function Artwork_Core:isInTable(tab, frameName)
	for k,v in ipairs(tab) do
		if (strlower(v) == strlower(frameName)) then
			return true;
		end
	end
	return false;
end

function Artwork_Core:round(num) -- rounds a number to 2 decimal places
	if num then return floor( (num*10^2)+0.5) / (10^2); end
end;

function Artwork_Core:ActionBarPlates(plate)
	local lib = LibStub("LibWindow-1.1",true);
	if not lib then return; end
	function lib.RegisterConfig(frame, storage, names)
		if not lib.windowData[frame] then
			lib.windowData[frame] = {}
		end
		lib.windowData[frame].names = names
		lib.windowData[frame].storage = storage
		local parent = frame:GetParent();
		if (storage.parent) then
			frame:SetParent(storage.parent);
			if storage.parent == plate then
				frame:SetFrameStrata("LOW");
			end
		elseif (parent and parent:GetName() == plate) then
			frame:SetParent(UIParent);
		end
	end
end

function Artwork_Core:OnInitialize()
	Artwork_Core:CheckMiniMap();
end

function Artwork_Core:OnEnable()
	Artwork_Core:SetupOptions();
end

function Artwork_Core:CheckMiniMap()
	-- Check for Carbonite dinking with the minimap.
	if (NXTITLELOW) then
		spartan:Print(NXTITLELOW..' is loaded ...Checking settings ...');
		if (Nx.db.profile.MiniMap.Own == true) then
			spartan:Print(NXTITLELOW..' is controlling the Minimap');
			spartan:Print("SpartanUI Will not modify or move the minimap unless Carbonite is a separate minimap");
			DB.MiniMap.AutoDetectAllowUse = false;
		end
	end
	
	if select(4, GetAddOnInfo("SexyMap")) then
		spartan:Print(L["SexyMapLoaded"])
		DB.MiniMap.AutoDetectAllowUse = false;
	end
	
	local point, relativeTo, relativePoint, x, y = MinimapCluster:GetPoint();
	if (relativeTo ~= UIParent) then
		spartan:Print('A unknown addon is controlling the Minimap');
		spartan:Print("SpartanUI Will not modify or move the minimap until the addon modifying the minimap is no longer enabled.");
		DB.MiniMap.AutoDetectAllowUse = false;
	end
end