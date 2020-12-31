--Cache global variables and Lua functions
local _G, SUI = _G, SUI
local module = SUI:NewModule('Handler_Skinning')

local RegisterAsContainer

local function StripTextures(object)
	for i = 1, object:GetNumRegions() do
		local region = select(i, object:GetRegions())
		if region and region:GetObjectType() == 'Texture' then
			if region:GetTexture() == 'Interface\\DialogFrame\\UI-DialogBox-Header' then
				-- region:SetTexture(nil)
				region:SetScale(.2)
			end
		end
	end
end

function module:SkinAce3()
	local AceGUI = LibStub('AceGUI-3.0', true)
	if not AceGUI then
		return
	end

	--LibStub("AceGUI-3.0"):Create("Window")
	local oldRegisterAsContainer = AceGUI.RegisterAsContainer
	RegisterAsContainer = function(self, widget)
		local TYPE = widget.type
		if
			TYPE == 'InlineGroup' or TYPE == 'TreeGroup' or TYPE == 'TabGroup' or TYPE == 'Frame' or TYPE == 'DropdownGroup' or
				TYPE == 'Window'
		 then
			local frame = widget.content:GetParent()
			if TYPE == 'Frame' then
				StripTextures(frame)
			end
			if not frame.SetBackdropBorderColor then
				Mixin(frame, BackdropTemplateMixin)
			end

			frame:SetBackdropBorderColor(0, 0, 0, 0)
		end
		return oldRegisterAsContainer(self, widget)
	end
	AceGUI.RegisterAsContainer = RegisterAsContainer
end

local function attemptSkin()
	SUI.DBG.textures = {i = 0}
	local AceGUI = LibStub('AceGUI-3.0', true)
	if AceGUI and (AceGUI.RegisterAsContainer ~= RegisterAsContainer or AceGUI.RegisterAsWidget ~= RegisterAsWidget) then
		if select(4, GetAddOnInfo('ElvUI')) then
			return
		end
		module:SkinAce3()
	end
end

local f = CreateFrame('Frame')
f:RegisterEvent('ADDON_LOADED')
f:SetScript('OnEvent', attemptSkin)

SUI.callbacks = LibStub('CallbackHandler-1.0'):New(SUI)
SUI:RegisterCallback('Ace3', attemptSkin)
