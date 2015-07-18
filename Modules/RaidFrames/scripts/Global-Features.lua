local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local RaidFrames = spartan:NewModule("RaidFrames");
----------------------------------------------------------------------------------------------------

--	Formatting functions
function RaidFrames:TextFormat(text)
	local textstyle = DBMod.RaidFrames.bars[text].textstyle
	local textmode = DBMod.RaidFrames.bars[text].textmode
	local a,m,t,z
	if text == "mana" then z = "pp" else z = "hp" end
	
	-- textstyle
	-- "Long: 			 Displays all numbers."
	-- "Long Formatted: Displays all numbers with commas."
	-- "Dynamic: 		 Abbriviates and formats as needed"
	if textstyle == "long" then
		a = "[cur"..z.."]";
		m = "[missing"..z.."]";
		t = "[max"..z.."]";
	elseif textstyle == "longfor" then
		a = "[cur"..z.."formatted]";
		m = "[missing"..z.."formatted]";
		t = "[max"..z.."formatted]";
	elseif textstyle == "disabled" then
		return "";
	else
		a = "[cur"..z.."dynamic]";
		m = "[missing"..z.."dynamic]";
		t = "[max"..z.."dynamic]";
	end
	-- textmode
	-- [1]="Avaliable / Total",
	-- [2]="(Missing) Avaliable / Total",
	-- [3]="(Missing) Avaliable"
	
	if textmode == 1 then
		return a .. " / " .. t
	elseif textmode == 2 then
		return "("..m..") "..a.." / "..t
	elseif textmode == 3 then
		return "("..m..") "..a
	end
end

function RaidFrames:PostUpdateText(self,unit)
	self:Untag(self.Health.value)
	self:Tag(self.Health.value, RaidFrames:TextFormat("health"))
	if self.Power then self:Untag(self.Power.value); self:Tag(self.Power.value, RaidFrames:TextFormat("mana")); end
end

function RaidFrames:menu(self)
	if (not self.id) then self.id = self.unit:match"^.-(%d+)" end
	local unit = string.gsub(self.unit,"(.)",string.upper,1);
	if (_G[unit..'FrameDropDown']) then
		ToggleDropDownMenu(1, nil, _G[unit..'FrameDropDown'], 'cursor')
	elseif ( (self.unit:match('party')) and (not self.unit:match('partypet')) ) then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor")
	else
		FriendsDropDown.unit = self.unit
		FriendsDropDown.id = self.id
		FriendsDropDown.initialize = RaidFrameDropDown_Initialize
		ToggleDropDownMenu(1, nil, FriendsDropDown, 'cursor')
	end
end

function RaidFrames:PostUpdateDebuffs(self,unit)
	if DBMod.RaidFrames.showDebuffs then
		self:Show();
		self.size = DBMod.RaidFrames.Auras.size;
		self.spacing = DBMod.RaidFrames.Auras.spacing;
		self.showType = DBMod.RaidFrames.Auras.showType;
	else
		self:Hide();
	end
end

function RaidFrames:UpdateAura()
	for i = 1,40 do
		local unit = _G["SUI_RaidFrameHeaderUnitButton"..i];
		if unit and unit.Auras then unit.Auras:PostUpdateDebuffs(); end
	end
end

function RaidFrames:UpdateText()
	for i = 1,40 do
		local unit = _G["SUI_RaidFrameHeaderUnitButton"..i];
		if unit then unit:TextUpdate(); end
	end
end