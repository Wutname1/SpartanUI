local SUI = SUI
local module = SUI:NewModule('WhatsNew')

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
			control:SetImage('interface\\addons\\SpartanUI\\images\\setup\\Style_Digital')
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
					SUI.DBMod.Artwork.FirstLoad = true

					SUI:GetModule('Style_' .. DBMod.Artwork.Style):SetupProfile()

					--Reset Moved bars; Setting up profile triggers movment
					if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars == nil then
						SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars = {}
					end
					local FrameList = {
						BT4Bar1,
						BT4Bar2,
						BT4Bar3,
						BT4Bar4,
						BT4Bar5,
						BT4Bar6,
						BT4BarBagBar,
						BT4BarExtraActionBar,
						BT4BarStanceBar,
						BT4BarPetBar,
						BT4BarMicroMenu
					}
					for _, v in ipairs(FrameList) do
						SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] = false
					end

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

	local SetupWindow = SUI:GetModule('SUIWindow')

	SetupWindow:AddPage(PageData)
	SetupWindow:DisplayPage()
end

function module:OnInitialize()
	-- if SUI.DBG.WhatsNew == nil then
	-- 	SUI.DBG.WhatsNew = true
	-- end
	--Only display if the setup has been done, and the SUI.DB version is lower than release build, AND the user has not told us to never tell them about new stuff

	-- if SUI.DBG.Version and SUI.DBG.Version < '5.0.0' and SUI.DB.SetupDone and SUI.DBG.WhatsNew then
	-- SUI:WhatsNew()
	-- end

	-- Update SUI.DB Version
	-- SUI.DB.Version = SUI.Version
	SUI.DBG.Version = SUI.Version
end
