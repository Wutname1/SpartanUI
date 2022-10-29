--- @class StdUi
local StdUi = LibStub and LibStub('StdUi', true);
if not StdUi then
	return
end

local module, version = 'Basic', 3;
if not StdUi:UpgradeNeeded(module, version) then return end;

---@return StdUi.Frame
function StdUi:Frame(parent, width, height, inherits)
	---@class StdUi.Frame : Frame
	local frame = CreateFrame('Frame', nil, parent, inherits);
	self:InitWidget(frame);
	self:SetObjSize(frame, width, height);

	return frame;
end

---@return StdUi.Panel
function StdUi:Panel(parent, width, height, inherits)
	---@class StdUi.Panel : StdUi.Frame,. BackdropTemplate
	local frame = self:Frame(parent, width, height, inherits);
	self:ApplyBackdrop(frame, 'panel');

	return frame;
end

---@return StdUi.PanelWithLabel
function StdUi:PanelWithLabel(parent, width, height, inherits, text)
	---@class StdUi.PanelWithLabel : StdUi.Panel
	local frame = self:Panel(parent, width, height, inherits);

	frame.label = self:Header(frame, text);
	frame.label:SetAllPoints();
	frame.label:SetJustifyH('MIDDLE');

	return frame;
end

---@return StdUi.PanelWithTitle
function StdUi:PanelWithTitle(parent, width, height, text)
	---@class StdUi.PanelWithTitle : StdUi.Panel
	local frame = self:Panel(parent, width, height);

	frame.titlePanel = self:PanelWithLabel(frame, 100, 20, nil, text);
	frame.titlePanel:SetPoint('TOP', 0, -10);
	frame.titlePanel:SetPoint('LEFT', 30, 0);
	frame.titlePanel:SetPoint('RIGHT', -30, 0);
	frame.titlePanel:SetBackdrop(nil);

	return frame;
end

--- @return Texture
function StdUi:Texture(parent, width, height, texture)
	local tex = parent:CreateTexture(nil, 'ARTWORK');

	self:SetObjSize(tex, width, height);
	if texture then
		tex:SetTexture(texture);
	end

	return tex;
end

--- @return Texture
function StdUi:ArrowTexture(parent, direction)
	local texture = self:Texture(parent, 16, 8, [[Interface\Buttons\Arrow-Up-Down]]);

	if direction == 'UP' then
		texture:SetTexCoord(0, 1, 0.5, 1);
	else
		texture:SetTexCoord(0, 1, 1, 0.5);
	end

	return texture;
end

StdUi:RegisterModule(module, version);