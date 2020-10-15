local _G, SUI = _G, SUI
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:NewModule('Style_Classic')
local UnregisterStateDriver = _G.UnregisterStateDriver
----------------------------------------------------------------------------------------------------
local round = function(num) -- rounds a number to 2 decimal places
	if num then
		return floor((num * 10 ^ 2) + 0.5) / (10 ^ 2)
	end
end

function module:updateColor()
end

----------------------------------------------------------------------------------------------------

function module:SetColor()
	local r, b, g, a = 1, 1, 1, 1
	if SUI.DB.Styles.Classic.Color.Art then
		r, b, g, a = unpack(SUI.DB.Styles.Classic.Color.Art)
	end

	for i = 1, 10 do
		if _G['Classic_Bar' .. i].BG then
			_G['Classic_Bar' .. i].BG:SetVertexColor(r, b, g, a)
		end
	end
	SUI_Art_Classic.Center:SetVertexColor(r, b, g, a)
	SUI_Art_Classic.Left:SetVertexColor(r, b, g, a)
	SUI_Art_Classic.FarLeft:SetVertexColor(r, b, g, a)
	SUI_Art_Classic.Right:SetVertexColor(r, b, g, a)
	SUI_Art_Classic.FarRight:SetVertexColor(r, b, g, a)

	if _G['SUI_StatusBar_Left'] then
		_G['SUI_StatusBar_Left'].bg:SetVertexColor(r, b, g, a)
		_G['SUI_StatusBar_Left'].overlay:SetVertexColor(r, b, g, a)
	end
	if _G['SUI_StatusBar_Right'] then
		_G['SUI_StatusBar_Right'].bg:SetVertexColor(r, b, g, a)
		_G['SUI_StatusBar_Right'].overlay:SetVertexColor(r, b, g, a)
	end
end

function module:TooltipLoc(self, parent)
	if (parent == 'UIParent') then
		tooltip:ClearAllPoints()
		tooltip:SetPoint('BOTTOMRIGHT', 'SUI_Art_Classic', 'TOPRIGHT', 0, 10)
	end
end

function module:BuffLoc(self, parent)
	BuffFrame:ClearAllPoints()
	BuffFrame:SetPoint('TOPRIGHT', -13, -13 - (SUI.DB.BuffSettings.offset))
end

function module:SetupVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		RegisterStateDriver(SUI_Art_Classic, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if not SUI.DB.Artwork.VehicleUI then
		UnregisterStateDriver(SUI_Art_Classic, 'visibility')
	end
end
