local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");

---------------		Math and Comparison FUNCTIONS		-------------------------------

function addon:isPartialMatch(frameName, tab)
	local result = false

	for k,v in ipairs(tab) do
		startpos, endpos = strfind(strlower(frameName), strlower(v))
		if (startpos == 1) then
			result = true;
		end
	end

	return result;
end

function addon:isInTable(tab, frameName)
	for k,v in ipairs(tab) do
		if (strlower(v) == strlower(frameName)) then
			return true;
		end
	end
	return false;
end

function addon:round(num) -- rounds a number to 2 decimal places
	if num then return floor( (num*10^2)+0.5) / (10^2); end
end;

function addon:comma_value(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1' .. _G.LARGE_NUMBER_SEPERATOR):reverse())..right
end

---------------		FONT FUNCTIONS		---------------------------------------------


function addon:FontSetup()
	local OutlineSizes = {22, 18, 13, 12,11,10,9,8}
	local Sizes = {10}
	for i,v in ipairs(OutlineSizes) do
		local filename, fontHeight, flags = _G["SUI_FontOutline" .. v]:GetFont()
		if filename ~= addon:GetFontFace("Primary") then
			_G["SUI_FontOutline" .. v] = _G["SUI_FontOutline" .. v]:SetFont(addon:GetFontFace("Primary"), v)
		end
	end	
	
	for i,v in ipairs(Sizes) do
		local filename, fontHeight, flags = _G["SUI_Font" .. v]:GetFont()
		if filename ~= addon:GetFontFace("Primary") then
			_G["SUI_Font" .. v] = _G["SUI_Font" .. v]:SetFont(addon:GetFontFace("Primary"), v)
		end
	end
end

function addon:GetFontFace(Module)
	if Module then
		if DB.font[Module].Face == "SpartanUI" then
			return "Interface\\AddOns\\SpartanUI\\media\\font-cognosis.ttf"
		elseif DB.font[Module].Face == "SUI4" then
			return "Interface\\AddOns\\SpartanUI\\media\\NotoSans-Bold.ttf"
		elseif DB.font[Module].Face == "FrizQuadrata" then
			return "Fonts\\FRIZQT__.TTF"
		elseif DB.font[Module].Face == "ArialNarrow" then
			return "Fonts\\ARIALN.TTF"
		elseif DB.font[Module].Face == "Skurri" then
			return "Fonts\\skurri.TTF"
		elseif DB.font[Module].Face == "Morpheus" then
			return "Fonts\\MORPHEUS.TTF"
		elseif DB.font[Module].Face == "Custom" and DB.font.Path ~= "" then
			return DB.font.Path
		end
	end
	
	return "Interface\\AddOns\\SpartanUI\\media\\NotoSans-Bold.ttf"
end

function addon:FormatFont(element, size, Module)
	--Adaptive Modules
	if DB.font[Module] == nil then
		DB.font[Module] = fontdefault;
	end
	--Set Font Outline
	local flags,sizeFinal
	if DB.font[Module].Type == "monochrome" then flags = flags.."monochrome " end
	
	-- Outline was deemed to thick, it is not a slight drop shadow done below
	--if DB.font[Module].Type == "outline" then flags = flags.."outline " end
	
	if DB.font[Module].Type == "thickoutline" then flags = flags.."thickoutline " end
	--Set Size
	sizeFinal = size + DB.font[Module].Size;
	--Create Font
	element:SetFont(addon:GetFontFace(Module), sizeFinal, flags)
	
	if DB.font[Module].Type == "outline" then
		element:SetShadowColor(0,0,0,.9)
		element:SetShadowOffset(1,-1)
	end
	--Add Item to the Array
	local count = 0
	for _ in pairs(FontItems[Module]) do count = count + 1 end
	FontItems[Module][count+1]=element
	FontItemsSize[Module][count+1]=size
end

function addon:FontRefresh(Module)
	for a,b in pairs(FontItems[Module]) do
		--Set Font Outline
		local flag,size
		if DB.font[Module].Type == "monochrome" then flags = flags.."monochrome " end
		if DB.font[Module].Type == "outline" then flags = flags.."outline " end
		if DB.font[Module].Type == "thickoutline" then flags = flags.."thickoutline " end
		--Set Size
		size = FontItemsSize[Module][a] + DB.font[Module].Size;
		--Update Font
		b:SetFont(addon:GetFontFace(Module), size, flags)
	end
end

