--Cache global variables and Lua functions
local _G = _G
local unpack, select, pairs = unpack, select, pairs
local CreateFrame = CreateFrame
local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local module = spartan:NewModule("Skinning", 'AceTimer-3.0', 'AceHook-3.0', 'AceEvent-3.0');

--Global variables that we don't cache, list them here for mikk's FindGlobals script
-- GLOBALS: SquareButton_SetIcon, LibStub

local RegisterAsContainer

local function StripTextures(object, kill)
	for i=1, object:GetNumRegions() do
		local region = select(i, object:GetRegions())
		if region and region:GetObjectType() == "Texture" then
			if kill and type(kill) == 'boolean' then
				region:Kill()
			elseif region:GetDrawLayer() == kill then
				region:SetTexture([[Interface\AddOns\SpartanUI\media\smoke.tga]])
			elseif kill and type(kill) == 'string' and region:GetTexture() ~= kill then
				region:SetTexture([[Interface\AddOns\SpartanUI\media\smoke.tga]])
			else
				if region:GetTexture() == "Interface\\DialogFrame\\UI-DialogBox-Header" then
					-- region:SetTexture([[Interface\DialogFrame\UI-DialogBox-Background-Dark]])
					region:SetTexture(nil)
					region:SetScale(.2)
				end
				-- SUI.DBG.textures[SUI.DBG.textures.i] = region:GetTexture()
				-- SUI.DBG.textures.i = SUI.DBG.textures.i + 1
			end
		end
	end
end

function module:SkinAce3()
	local AceGUI = LibStub("AceGUI-3.0", true)
	if not AceGUI then return end

	--LibStub("AceGUI-3.0"):Create("Window")
	local oldRegisterAsContainer = AceGUI.RegisterAsContainer
	RegisterAsContainer = function(self, widget)
		local TYPE = widget.type
		if TYPE == "InlineGroup" or TYPE == "TreeGroup" or TYPE == "TabGroup" or TYPE == "Frame" or TYPE == "DropdownGroup" or TYPE == "Window" then
			local frame = widget.content:GetParent()
			if TYPE == "Frame" then
				StripTextures(frame)
				-- for i=1, frame:GetNumChildren() do
					-- local child = select(i, frame:GetChildren())
					-- if child:GetObjectType() == "Button" and child:GetText() then
						-- SkinButton(child)
					-- else
						-- child:StripTextures()
					-- end
				-- end
			elseif TYPE == "Window" then
				-- StripTextures(frame)
				-- S:HandleCloseButton(frame.obj.closebutton)
			end
			-- frame:SetBackdropColor(0,0,0,.7)
			frame:SetBackdropBorderColor(0,0,0,0)
		end
			if widget.treeframe then
				widget.treeframe:SetBackdropBorderColor(0,0,0,0)
				-- frame:Point("TOPLEFT", widget.treeframe, "TOPRIGHT", 1, 0)

				-- local oldCreateButton = widget.CreateButton
				-- widget.CreateButton = function(self)
					-- local button = oldCreateButton(self)
					-- button.toggle:StripTextures()
					-- button.toggle.SetNormalTexture = E.noop
					-- button.toggle.SetPushedTexture = E.noop
					-- button.toggleText = button.toggle:CreateFontString(nil, 'OVERLAY')
					-- button.toggleText:FontTemplate(nil, 19)
					-- button.toggleText:Point('CENTER')
					-- button.toggleText:SetText('+')
					-- return button
				-- end

				-- local oldRefreshTree = widget.RefreshTree
				-- widget.RefreshTree = function(self, scrollToSelection)
					-- oldRefreshTree(self, scrollToSelection)
					-- if not self.tree then return end
					-- local status = self.status or self.localstatus
					-- local groupstatus = status.groups
					-- local lines = self.lines
					-- local buttons = self.buttons

					-- for i, line in pairs(lines) do
						-- local button = buttons[i]
						-- if groupstatus[line.uniquevalue] and button then
							-- button.toggleText:SetText('-')
						-- elseif button then
							-- button.toggleText:SetText('+')
						-- end
					-- end
				-- end
			end

			-- if TYPE == "TabGroup" then
				-- local oldCreateTab = widget.CreateTab
				-- widget.CreateTab = function(self, id)
					-- local tab = oldCreateTab(self, id)
					-- tab:StripTextures()
					-- tab.backdrop = CreateFrame("Frame", nil, tab)
					-- tab.backdrop:SetTemplate("Transparent")
					-- tab.backdrop:SetFrameLevel(tab:GetFrameLevel() - 1)
					-- tab.backdrop:Point("TOPLEFT", 10, -3)
					-- tab.backdrop:Point("BOTTOMRIGHT", -10, 0)
					-- return tab
				-- end
			-- end

			-- if widget.scrollbar then
				-- SkinScrollBar(widget.scrollbar)
			-- end
		-- elseif TYPE == "SimpleGroup" then
			-- local frame = widget.content:GetParent()
			-- frame:SetTemplate("Transparent", nil, true) --ignore border updates
			-- frame:SetBackdropBorderColor(0,0,0,0) --Make border completely transparent
		-- end

		return oldRegisterAsContainer(self, widget)
	end
	AceGUI.RegisterAsContainer = RegisterAsContainer
end

local function attemptSkin()
	SUI.DBG.textures = { i = 0 }
	local AceGUI = LibStub("AceGUI-3.0", true)
	if AceGUI and (AceGUI.RegisterAsContainer ~= RegisterAsContainer or AceGUI.RegisterAsWidget ~= RegisterAsWidget) then
		module:SkinAce3()
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", attemptSkin)

spartan.callbacks = LibStub("CallbackHandler-1.0"):New(spartan)
spartan:RegisterCallback("Ace3", attemptSkin)
