local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local PartyFrames = spartan:NewModule("PartyFrames");
----------------------------------------------------------------------------------------------------

--	Formatting functions
function PartyFrames:TextFormat(text)
	local textstyle = DBMod.PartyFrames.bars[text].textstyle
	local textmode = DBMod.PartyFrames.bars[text].textmode
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

function PartyFrames:PostUpdateText(self,unit)
	self:Untag(self.Health.value)
	self:Tag(self.Health.value, PartyFrames:TextFormat("health"))
	if self.Power then self:Untag(self.Power.value) end
	if self.Power then self:Tag(self.Power.value, PartyFrames:TextFormat("mana")) end
end

function PartyFrames:menu(self)
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

function PartyFrames:CreatePortrait(self)
	if DBMod.PartyFrames.Portrait3D then
		local Portrait = CreateFrame('PlayerModel', nil, self)
		Portrait:SetScript("OnShow", function(self) self:SetCamera(0) end)
		Portrait.type = "3D"
		return Portrait;
	else
		return self.artwork:CreateTexture(nil,"BORDER");
	end
end

function PartyFrames:PostUpdateAura(self,unit)
	if DBMod.PartyFrames.showAuras then
		self:Show();
		self.size = DBMod.PartyFrames.Auras.size;
		self.spacing = DBMod.PartyFrames.Auras.spacing;
		self.showType = DBMod.PartyFrames.Auras.showType;
		self.numBuffs = DBMod.PartyFrames.Auras.NumBuffs;
		self.numDebuffs = DBMod.PartyFrames.Auras.NumDebuffs;
	else
		self:Hide();
	end
end
