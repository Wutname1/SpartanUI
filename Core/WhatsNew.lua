local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local module = spartan:NewModule("WhatsNew");
local ArtifactWatcher, loginlevel

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
				
				spartan:GetModule("Style_"..DBMod.Artwork.Style):SetupProfile();
				
				--Reset Moved bars; Setting up profile triggers movment
				if DB.Styles[DBMod.Artwork.Style].MovedBars == nil then DB.Styles[DBMod.Artwork.Style].MovedBars = {} end
				local FrameList = {BT4Bar1, BT4Bar2, BT4Bar3, BT4Bar4, BT4Bar5, BT4Bar6, BT4BarBagBar, BT4BarExtraActionBar, BT4BarStanceBar, BT4BarPetBar, BT4BarMicroMenu}
				for k,v in ipairs(FrameList) do
					DB.Styles[DBMod.Artwork.Style].MovedBars[v:GetName()] = false
				end;
				
				ReloadUI()
			end)
			control.frame:SetParent(SUI_Win.WhatsNew)
			control.frame:Show()
			SUI_Win.WhatsNew.Fel = control

			SUI_Win.WhatsNew.Buffs = SUI_Win.WhatsNew:CreateFontString(nil, "OVERLAY", "SUI_FontOutline13")
			SUI_Win.WhatsNew.Buffs:SetPoint("TOP",SUI_Win.WhatsNew.Fel.frame,"BOTTOM", 0, -15)
			SUI_Win.WhatsNew.Buffs:SetWidth(SUI_Win.WhatsNew:GetWidth()-40)
			SUI_Win.WhatsNew.Buffs:SetText("The buff system for player fames has been redesigned in 4.3. While it is still a work in progress all the options have been revamped. I strongly encourage you to preview the new Fel Unit frames to see some of the improvements that will be making their way to the other styles. If you have any questions or suggestions please let me know via the SpartanUI.net forums")
			
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

function module:FirstArtifact()
	local PageData = {
		title = L["Congratulations"],
		SubTitle = L["You have equiped your first artifact weapon"],
		Desc1 = L["Your artifact weapon levels up just like your character through a resource called Artifact Power. Would you like to track your artifact power as a status bar?"].. "|r",
		Desc2 = L["This will replace your reputation bar and you can switch between the two at any time via the SpartanUI settings."],
		Display = function()
			-- Track have been displayed
			SUI.DBG.HasEquipedArtifact = true
			
			--Container
			SUI_Win.WhatsNew = CreateFrame("Frame", nil)
			SUI_Win.WhatsNew:SetParent(SUI_Win.content)
			SUI_Win.WhatsNew:SetAllPoints(SUI_Win.content)
			
			-- Buttons
			SUI_Win:SetSize(550, 170)
			SUI_Win:ClearAllPoints()
			SUI_Win:SetPoint("TOP", UIParent, "TOP", 0, -50)
			SUI_Win.Status:Hide()
			SUI_Win.Skip:SetSize(130, 25)
			SUI_Win.Skip:SetPoint("BOTTOMRIGHT", SUI_Win, "BOTTOM", -10, 5)
			SUI_Win.Skip:SetText("LEAVE IT AS IS")
			SUI_Win.Next:SetSize(130, 25)
			SUI_Win.Next:SetPoint("BOTTOMLEFT", SUI_Win, "BOTTOM", 10, 5)
			SUI_Win.Next:SetText("TRACK ARTIFACT POWER")
		end,
		Next = function()
			DB.StatusBars.RepBar.enabled = false
			DB.StatusBars.APBar.enabled = true
			spartan:GetModule("Style_"..SUI.DBMod.Artwork.Style):UpdateStatusBars()
		end,
		Skip = function() end
	}
	local SetupWindow = spartan:GetModule("SetupWindow")
	
	SetupWindow:AddPage(PageData)
	SetupWindow:DisplayPage()
end

function module:OnInitialize()
	if SUI.DBG.WhatsNew == nil then SUI.DBG.WhatsNew = true end
	if SUI.DBG.HasEquipedArtifact == nil then SUI.DBG.HasEquipedArtifact = false end
	--Only display if the setup has been done, and the DB version is lower than release build, AND the user has not told us to never tell them about new stuff
	
	if SUI.DBG.Version and SUI.DBG.Version < "4.3.0" and DB.SetupDone and SUI.DBG.WhatsNew then
		spartan:WhatsNew()
	end
	
	-- Update DB Version
	DB.Version = spartan.SpartanVer;
	SUI.DBG.Version = spartan.SpartanVer;
end

function module:FirstAtrifactNotice()
	loginlevel = UnitLevel("player")
	
	--Only process if we are not 110; allowed to show new featues; have never used an artifact; The style allows tracking
	if loginlevel ~= 110 and SUI.DBG.WhatsNew and not SUI.DBG.HasEquipedArtifact and SUI.DBP.Styles[DBMod.Artwork.Style].StatusBars.AP and not SUI.DBP.StatusBars.APBar.enabled then
		--Detect if user already has a artifact
		if HasArtifactEquipped() then
			SUI.DBG.HasEquipedArtifact = true
			return
		end
		
		--Create Watcher
		ArtifactWatcher = CreateFrame("Frame")
		ArtifactWatcher:SetScript("OnEvent", function(self, event)
			-- Add the hooks for inventory if player logged in sub 100
			if loginlevel < 100 and UnitLevel("player") >= 100 then
				if UnitLevel("player") >= 100 then
					ArtifactWatcher = CreateFrame("Frame")
					ArtifactWatcher:RegisterEvent("ARTIFACT_XP_UPDATE");
					ArtifactWatcher:RegisterEvent("UNIT_INVENTORY_CHANGED");
				end
			end
			if HasArtifactEquipped() and not SUI.DBP.StatusBars.APBar.enabled then
				module:FirstArtifact()
				ArtifactWatcher:UnregisterEvent("ARTIFACT_XP_UPDATE")
				ArtifactWatcher:UnregisterEvent("UNIT_INVENTORY_CHANGED")
				ArtifactWatcher:UnregisterEvent("PLAYER_LEVEL_UP")
				ArtifactWatcher = nil
			elseif SUI.DBP.StatusBars.APBar.enabled then
				ArtifactWatcher:UnregisterEvent("ARTIFACT_XP_UPDATE")
				ArtifactWatcher:UnregisterEvent("UNIT_INVENTORY_CHANGED")
				ArtifactWatcher:UnregisterEvent("PLAYER_LEVEL_UP")
			end
		end)
		
		--Setup update events
		if UnitLevel("player") >= 100 then
			ArtifactWatcher:RegisterEvent("ARTIFACT_XP_UPDATE");
			ArtifactWatcher:RegisterEvent("UNIT_INVENTORY_CHANGED");
		end
		ArtifactWatcher:RegisterEvent("PLAYER_LEVEL_UP");
	end
end

function module:OnEnable()
	module:FirstAtrifactNotice()
end