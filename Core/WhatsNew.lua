local SUI = SUI
local module = SUI:NewModule('WhatsNew')
local ArtifactWatcher, loginlevel

function SUI:WhatsNew()
	local PageData = {
		title = "What's new in SpartanUI 4.4",
		SubTitle = '',
		Desc1 = "Introducing a new style 'Digital' this is the first fan submitted style. Special thanks to Vargor of Stormrage, if you would like to try this new Skin you may click on the graphic below.",
		Display = function()
			--Container
			SUI_Win.WhatsNew = CreateFrame('Frame', nil)
			SUI_Win.WhatsNew:SetParent(SUI_Win.content)
			SUI_Win.WhatsNew:SetAllPoints(SUI_Win.content)
			local gui = LibStub('AceGUI-3.0')

			-- Fel Style
			local control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\media\\Style_Digital')
			control:SetImageSize(240, 120)
			control:SetPoint('TOP', SUI_Win.Desc1, 'BOTTOM', 0, -15)
			control:SetCallback(
				'OnClick',
				function()
					SUI.DBG.WhatsNew = (SUI_Win.WhatsNew.NeverEverAgain:GetChecked() ~= true or false)

					SUI.DBMod.Artwork.Style = 'Fel'
					SUI.DB.Styles.Fel.SubTheme = 'Digital'
					SUI.DBMod.PlayerFrames.Style = SUI.DBMod.Artwork.Style
					SUI.DBMod.PartyFrames.Style = SUI.DBMod.Artwork.Style
					SUI.DBMod.RaidFrames.Style = SUI.DBMod.Artwork.Style
					SUI.DBMod.BarManager.Style = SUI.DBMod.Artwork.Style
					SUI.DBMod.Artwork.FirstLoad = true

					SUI:GetModule('Style_' .. DBMod.Artwork.Style):SetupProfile()

					--Reset Moved bars; Setting up profile triggers movment
					SUI:GetModule('Artwork_Core'):ResetMovedBars()
					
					ReloadUI()
				end
			)
			control.frame:SetParent(SUI_Win.WhatsNew)
			control.frame:Show()
			SUI_Win.WhatsNew.Fel = control

			SUI_Win.WhatsNew.Buffs = SUI_Win.WhatsNew:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline13')
			SUI_Win.WhatsNew.Buffs:SetPoint('TOP', SUI_Win.WhatsNew.Fel.frame, 'BOTTOM', 0, -15)
			SUI_Win.WhatsNew.Buffs:SetWidth(SUI_Win.WhatsNew:GetWidth() - 40)
			SUI_Win.WhatsNew.Buffs:SetText(
				"A new component has been added called 'Open all mail' this Component adds a button to the top of the mailbox window that allows you to open all mail with 1 click."
			)

			-- Sad face
			SUI_Win.WhatsNew.NeverEverAgain =
				CreateFrame('CheckButton', 'SUI_WhatsNew_NeverEverAgain', SUI_Win.WhatsNew, 'OptionsCheckButtonTemplate')
			SUI_Win.WhatsNew.NeverEverAgain:SetPoint('BOTTOMLEFT', SUI_Win, 'BOTTOMLEFT', 5, 5)
			SUI_WhatsNew_NeverEverAgainText:SetText("Never tell me about what's new ever again.")
		end,
		-- Nothing needs to be done just let the user go.
		Next = function()
			SUI.DBG.WhatsNew = (SUI_Win.WhatsNew.NeverEverAgain:GetChecked() ~= true or false)
			SUI_Win.WhatsNew:Hide()
			SUI_Win.WhatsNew = nil
		end
	}

	local SetupWindow = SUI:GetModule('SetupWindow')

	SetupWindow:AddPage(PageData)
	SetupWindow:DisplayPage()
end

function module:FirstArtifact()
	local PageData = {
		title = L['Congratulations'],
		SubTitle = L['You have equiped your first artifact weapon'],
		Desc1 = L[
			'Your artifact weapon levels up just like your character through a resource called Artifact Power. Would you like to track your artifact power as a status bar?'
		] .. '|r',
		Desc2 = L[
			'This will replace in the bottom right status bar and you can switch between the two at any time via the SpartanUI settings.'
		],
		Display = function()
			-- Track have been displayed
			SUI.DBG.HasEquipedArtifact = true

			--Container
			SUI_Win.WhatsNew = CreateFrame('Frame', nil)
			SUI_Win.WhatsNew:SetParent(SUI_Win.content)
			SUI_Win.WhatsNew:SetAllPoints(SUI_Win.content)

			-- Buttons
			SUI_Win:SetSize(550, 170)
			SUI_Win:ClearAllPoints()
			SUI_Win:SetPoint('TOP', UIParent, 'TOP', 0, -50)
			SUI_Win.Status:Hide()
			SUI_Win.Skip:SetSize(130, 25)
			SUI_Win.Skip:SetPoint('BOTTOMRIGHT', SUI_Win, 'BOTTOM', -10, 5)
			SUI_Win.Skip:SetText('LEAVE IT AS IS')
			SUI_Win.Next:SetSize(130, 25)
			SUI_Win.Next:SetPoint('BOTTOMLEFT', SUI_Win, 'BOTTOM', 10, 5)
			SUI_Win.Next:SetText('TRACK ARTIFACT POWER')
		end,
		Next = function()
			SUI.DBMod.StatusBars[2].display = 'ap'
			SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style):UpdateStatusBars()
		end,
		Skip = function()
		end
	}
	local SetupWindow = SUI:GetModule('SetupWindow')

	SetupWindow:AddPage(PageData)
	SetupWindow:DisplayPage()
end

function module:OnInitialize()
	if SUI.DBG.WhatsNew == nil then
		SUI.DBG.WhatsNew = true
	end
	if SUI.DBG.HasEquipedArtifact == nil then
		SUI.DBG.HasEquipedArtifact = false
	end
	--Only display if the setup has been done, and the SUI.DB version is lower than release build, AND the user has not told us to never tell them about new stuff

	if SUI.DBG.Version and SUI.DBG.Version < '4.4.0' and SUI.DB.SetupDone and SUI.DBG.WhatsNew then
		SUI:WhatsNew()
	end

	-- Update SUI.DB Version
	SUI.DB.Version = SUI.Version
	SUI.DBG.Version = SUI.Version
end

function module:FirstAtrifactNotice()
	--Only process if we are below 110; allowed to show new features; have never used an artifact; The style allows tracking
	local TrackingAP = false
	for _, v in ipairs(SUI.DBMod.StatusBars) do
		if v.display == 'ap' then
			TrackingAP = true
		end
	end

	if
		loginlevel < 110 and SUI.DBG.WhatsNew and not SUI.DBG.HasEquipedArtifact and
			not C_ArtifactUI.IsEquippedArtifactMaxed() and
			SUI.DB.Styles[SUI.DBMod.Artwork.Style].StatusBars.AP and
			not TrackingAP
	 then
		--Detect if user already has a artifact
		if HasArtifactEquipped() then
			SUI.DBG.HasEquipedArtifact = true
			return
		end

		--Create Watcher
		ArtifactWatcher = CreateFrame('Frame')
		ArtifactWatcher:SetScript(
			'OnEvent',
			function(self, event)
				-- Add the hooks for inventory if player logged in sub 100
				if loginlevel < 100 and UnitLevel('player') >= 100 then
					if UnitLevel('player') >= 100 then
						ArtifactWatcher = CreateFrame('Frame')
						ArtifactWatcher:RegisterEvent('ARTIFACT_XP_UPDATE')
						ArtifactWatcher:RegisterEvent('UNIT_INVENTORY_CHANGED')
					end
				end
				if
					HasArtifactEquipped() and not (SUI.DBMod.StatusBars[1].display == 'ap' or SUI.DBMod.StatusBars[2].display == 'ap')
				 then
					module:FirstArtifact()
					ArtifactWatcher:UnregisterEvent('ARTIFACT_XP_UPDATE')
					ArtifactWatcher:UnregisterEvent('UNIT_INVENTORY_CHANGED')
					ArtifactWatcher:UnregisterEvent('PLAYER_LEVEL_UP')
					ArtifactWatcher = nil
				elseif (SUI.DBMod.StatusBars[2].display == 'ap' or SUI.DBMod.StatusBars[2].display == 'ap') then
					ArtifactWatcher:UnregisterEvent('ARTIFACT_XP_UPDATE')
					ArtifactWatcher:UnregisterEvent('UNIT_INVENTORY_CHANGED')
					ArtifactWatcher:UnregisterEvent('PLAYER_LEVEL_UP')
				end
			end
		)

		--Setup update events
		if UnitLevel('player') >= 100 then
			ArtifactWatcher:RegisterEvent('ARTIFACT_XP_UPDATE')
			ArtifactWatcher:RegisterEvent('UNIT_INVENTORY_CHANGED')
		end
		ArtifactWatcher:RegisterEvent('PLAYER_LEVEL_UP')
	end
end

function module:FirstAzeriteItem()
end

function module:OnEnable()
	loginlevel = UnitLevel('player')

	module:FirstAtrifactNotice()
	module:FirstAzeriteItem()
end
