local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local module = spartan:NewModule("WhatsNew");

function spartan:WhatsNew()
	local PageData = {
		title = "What's new in SpartanUI 4.3",
		SubTitle = "",
		Desc1 = "Introducing a new Style: 'Fel' with the legions invasion Fel magic has infected SpartanUI, if you would like to try this new Skin you may click on the graphic below.",
		Display = function()
			--Container
			SUI_Win.WhatsNew = CreateFrame("Frame", nil)
			SUI_Win.WhatsNew:SetParent(SUI_Win.content)
			SUI_Win.WhatsNew:SetAllPoints(SUI_Win.content)
			local gui = LibStub("AceGUI-3.0")
			
			-- Fel Style
			local control = gui:Create("Icon")
			control:SetImage("interface\\addons\\SpartanUI\\media\\Style_Fel")
			control:SetImageSize(240, 120)
			control:SetPoint("TOP", SUI_Win.Desc1, "BOTTOM", 0, -15)
			control:SetCallback("OnClick", function()
				SUI.DBG.WhatsNew = (SUI_Win.WhatsNew.NeverEverAgain:GetChecked() ~= true or false)
				
				DBMod.Artwork.Style = "Fel"
				DBMod.PlayerFrames.Style = DBMod.Artwork.Style;
				DBMod.PartyFrames.Style = DBMod.Artwork.Style;
				DBMod.RaidFrames.Style = DBMod.Artwork.Style;
				DBMod.Artwork.FirstLoad = true;
				
				--Reset Moved bars
				if DB.Styles[DBMod.Artwork.Style].MovedBars == nil then DB.Styles[DBMod.Artwork.Style].MovedBars = {} end
				local FrameList = {BT4Bar1, BT4Bar2, BT4Bar3, BT4Bar4, BT4Bar5, BT4Bar6, BT4BarBagBar, BT4BarExtraActionBar, BT4BarStanceBar, BT4BarPetBar, BT4BarMicroMenu}
				for k,v in ipairs(FrameList) do
					DB.Styles[DBMod.Artwork.Style].MovedBars[v:GetName()] = false
				end;
				
				spartan:GetModule("Style_"..DBMod.Artwork.Style):SetupProfile();
				ReloadUI()
			end)
			control.frame:SetParent(SUI_Win.WhatsNew)
			control.frame:Show()
			SUI_Win.WhatsNew.Fel = control

			SUI_Win.WhatsNew.Buffs = SUI_Win.WhatsNew:CreateFontString(nil, "OVERLAY", "SUI_FontOutline13")
			SUI_Win.WhatsNew.Buffs:SetPoint("TOP",SUI_Win.WhatsNew.Fel.frame,"BOTTOM", 0, -15)
			SUI_Win.WhatsNew.Buffs:SetWidth(SUI_Win.WhatsNew:GetWidth()-40)
			SUI_Win.WhatsNew.Buffs:SetText("The buff system for player fames has been redesigned in 4.3. While it is still a work in progress all the options have been revamed. I strongly encourage you to preview the new Fel Unit frames to see some of the improvments that will be making their way to the other styles. If you have any questions or suggestions please let me know via the SpartanUI.net forums")
			
			-- Sad face
			SUI_Win.WhatsNew.NeverEverAgain = CreateFrame("CheckButton", "SUI_WhatsNew_NeverEverAgain", SUI_Win.WhatsNew, "OptionsCheckButtonTemplate")
			SUI_Win.WhatsNew.NeverEverAgain:SetPoint("BOTTOMLEFT", SUI_Win, "BOTTOMLEFT", 5, 5)
			SUI_WhatsNew_NeverEverAgainText:SetText("Never tell me about what's new ever again.")
		end,
		-- Nothing needs to be done just let the user go.
		Next = function()
			SUI.DBG.WhatsNew = (SUI_Win.WhatsNew.NeverEverAgain:GetChecked() ~= true or false)
			SUI_Win.WhatsNew:Hide();
			SUI_Win.WhatsNew = nil;
		end,
		Skip = function() end
	}
	
	local SetupWindow = spartan:GetModule("SetupWindow")
	
	SetupWindow:AddPage(PageData)
	SetupWindow:DisplayPage()
end

function module:OnInitialize()
	print(SUI.DBG.WhatsNew)
	if SUI.DBG.WhatsNew == nil then SUI.DBG.WhatsNew = true end
	--Only display if the setup has been done, and the DB version is lower than release build, AND the user has not told us to never tell them about new stuff
	
	print(SUI.DBG.WhatsNew)
	if SUI.DBG.Version and SUI.DBG.Version < "4.3.0" and DB.SetupDone and SUI.DBG.WhatsNew then
		spartan:WhatsNew()
	end
	-- Update DB Version
	DB.Version = spartan.SpartanVer;
	SUI.DBG.Version = spartan.SpartanVer;
end