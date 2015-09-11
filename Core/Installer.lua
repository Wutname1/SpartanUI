local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local module = spartan:NewModule("Installer");
---------------------------------------------------------------------------
local Page_Cur = 1
local Pages = 1
-- local module

function module:OnInitialize()
end

function module:OnEnable()
    -- if not OBJECT.RemoveTextures then META.RemoveTextures = RemoveTextures end
	-- module:CreateInstallWindow()
end

local RemoveTextures = function(self, option)
    if((not self.GetNumRegions) or (self.Panel and (not self.Panel.CanBeRemoved))) then return end
    local region, layer, texture
    for i = 1, self:GetNumRegions()do
        region = select(i, self:GetRegions())
        if(region and (region:GetObjectType() == "Texture")) then

            layer = region:GetDrawLayer()
            texture = region:GetTexture()
			region:SetTexture("")
        end
    end
end

function module:CreateInstallWindow()
	if DB.Installer == nil then
		local frame = CreateFrame("Button", "SUI_InstallerFrame", UIParent)
		frame:SetSize(550, 400)
		-- frame:SetStyle("Frame", "Window2")
		frame:SetPoint("TOP", UIParent, "TOP", 0, -150)
		frame:SetFrameStrata("TOOLTIP")
		-- frame:SetVertexColor(0,0,0,1)
		
		frame.bg = frame:CreateTexture(nil, "BORDER")
		-- frame.bg:SetSize(110, 75)
		frame.bg:SetAllPoints(frame)
		frame.bg:SetTexture([[Interface\AddOns\SpartanUI\media\smoke.tga]])
		frame.bg:SetVertexColor(0, 0, 0, 1)
		
		frame.border = frame:CreateTexture(nil, "BORDER")
		-- frame.bg:SetSize(110, 75)
		frame.border:SetPoint("TOP", 0, 10)
		frame.border:SetPoint("LEFT", -10, 0)
		frame.border:SetPoint("RIGHT", 10, 0)
		frame.border:SetPoint("BOTTOM", 0, -10)
		frame.border:SetTexture([[Interface\AddOns\SpartanUI\media\smoke.tga]])
		frame.border:SetVertexColor(0, 0, 0, .7)

		frame.SetPage = InstallerFrame_SetPage;
		
		--Create the text areas
		local statusFrame = CreateFrame("Frame", nil, frame)
		statusFrame:SetFrameLevel(statusFrame:GetFrameLevel() + 2)
		statusFrame:SetSize(150, 30)
		statusFrame:SetPoint("BOTTOM", frame, "TOP", 0, 2)

		frame.Status = statusFrame:CreateFontString(nil, "OVERLAY")
		frame.Status:SetFont(DB.font.Primary.Face, 22, "OUTLINE")
		frame.Status:SetPoint("CENTER")
		frame.Status:SetText(Page_Cur.."  /  ".. Pages)

		frame.titleHolder = frame:CreateFontString(nil, "OVERLAY")
		frame.titleHolder:SetFont(DB.font.Primary.Face, 22, "OUTLINE")
		frame.titleHolder:SetPoint("TOP", frame, "TOP", 0, -5)
		frame.titleHolder:SetSize(350, 20)
		frame.titleHolder:SetText("SpartanUI Installation")
		frame.titleHolder:SetTextColor(0, 0, 0, 1)

		frame.SubTitle = frame:CreateFontString(nil, "OVERLAY")
		frame.SubTitle:SetFont(DB.font.Primary.Face, 16, "OUTLINE")
		frame.SubTitle:SetPoint("TOP", frame, "TOP", 0, -40)

		frame.Desc1 = frame:CreateFontString(nil, "OVERLAY")
		frame.Desc1:SetFont(DB.font.Primary.Face, 14, "OUTLINE")
		frame.Desc1:SetPoint("TOPLEFT", 20, -75)
		frame.Desc1:SetWidth(frame:GetWidth()-40)

		--Make the Options
		
		
		--Buttons
		frame.Next = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		frame.Next.RemoveTextures = RemoveTextures
		frame.Next.RemoveTextures(frame.Next)
		-- frame.Next:RemoveTextures()
		frame.Next:SetSize(110, 25)
		frame.Next:SetPoint("BOTTOMRIGHT", 40, 5)
		frame.Next.Left:SetAlpha(0)
		frame.Next.Middle:SetAlpha(0)
		frame.Next.Right:SetAlpha(0)
		frame.Next:SetNormalTexture("")
		frame.Next:SetPushedTexture("")
		frame.Next:SetPushedTexture("")
		frame.Next:SetDisabledTexture("")
		frame.Next:SetFrameLevel(frame.Next:GetFrameLevel() + 1)
		
		frame.Next.texture = frame.Next:CreateTexture(nil, "BORDER")
		frame.Next.texture:SetSize(135, 100)
		frame.Next.texture:SetPoint("RIGHT")
		frame.Next.texture:SetTexture([[Interface\AddOns\SpartanUI\media\arrow.tga]])
		frame.Next.texture:SetVertexColor(0, 0.5, 1)
		frame.Next.text = frame.Next:CreateFontString(nil, "OVERLAY")
		frame.Next.text:SetFont(DB.font.Primary.Face, 18, "OUTLINE")
		frame.Next.text:SetPoint("CENTER")
		frame.Next.text:SetText(CONTINUE)
		-- frame.Next:Disable()
		frame.Next.parent = frame
		frame.Next:SetScript("OnClick", function(this)
			if Page_Cur == Pages then
				frame:Hide()
			end
		end)
		frame.Next:SetScript("OnEnter", function(this)
			this.texture:SetVertexColor(.7, .7, 1, 1)
		end)
		frame.Next:SetScript("OnLeave", function(this)
			this.texture:SetVertexColor(0, 0.5, 1)
		end)
	end
	if DB.Installer == nil then
		SUI_InstallerFrame:Show()
	end
end