--- @type StdUi
local StdUi = LibStub and LibStub('StdUi', true);
if not StdUi then
	return
end

local module, version = 'Label', 3;
if not StdUi:UpgradeNeeded(module, version) then return end;

----------------------------------------------------
--- FontString
----------------------------------------------------

local FontStringMethods = {
	SetFontSize = function(self, newSize)
		self:SetFont(self:GetFont(), newSize);
	end
}

--- @return FontString
function StdUi:FontString(parent, text, inherit)
	local fs = parent:CreateFontString(nil, self.config.font.strata, inherit or 'GameFontNormal');

	fs:SetText(text);
	fs:SetJustifyH('LEFT');
	fs:SetJustifyV('MIDDLE');

	for k, v in pairs(FontStringMethods) do
		fs[k] = v;
	end

	return fs;
end

----------------------------------------------------
--- Label
----------------------------------------------------

--- @return FontString
function StdUi:Label(parent, text, size, inherit, width, height)
	local fs = self:FontString(parent, text, inherit);
	if size then
		fs:SetFontSize(size);
	end

	self:SetTextColor(fs, 'normal');
	self:SetObjSize(fs, width, height);

	return fs;
end

----------------------------------------------------
--- Header
----------------------------------------------------

--- @return FontString
function StdUi:Header(parent, text, size, inherit, width, height)
	local fs = self:Label(parent, text, size, inherit or 'GameFontNormalLarge', width, height);

	self:SetTextColor(fs, 'header');

	return fs;
end

----------------------------------------------------
--- AddLabel
----------------------------------------------------

--- @return FontString
function StdUi:AddLabel(parent, object, text, labelPosition, labelWidth)
	local labelHeight = (self.config.font.size) + 4;
	local label = self:Label(parent, text, self.config.font.size, nil, labelWidth, labelHeight);

	if labelPosition == 'TOP' or labelPosition == nil then
		self:GlueAbove(label, object, 0, 4, 'LEFT');
	elseif labelPosition == 'RIGHT' then
		self:GlueRight(label, object, 4, 0);
	else -- labelPosition == 'LEFT'
		label:SetWidth(labelWidth or label:GetStringWidth())
		self:GlueLeft(label, object, -4, 0);
	end

	object.label = label;

	return label;
end

StdUi:RegisterModule(module, version);