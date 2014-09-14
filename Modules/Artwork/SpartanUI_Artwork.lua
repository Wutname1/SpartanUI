local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local Artwork_Core = spartan:NewModule("Artwork_Core");

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
	-- DBMod.Artwork.Theme = "SciFi"
	DBMod.Artwork.Theme = "Classic"
end
