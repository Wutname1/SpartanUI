local SUI = SUI
local module = SUI:NewModule('WhatsNew')
local StdUi = LibStub('StdUi'):NewInstance()
-- DB or DBG - This allows us to change if the whats new should appear on every profile or once.
local db = 'DB'

function SUI:WhatsNew()
	module.window = StdUi:Window(nil, 650, 500)
	module.window.StdUi = StdUi
	module.window:SetPoint('CENTER', 0, 0)
	module.window:SetFrameStrata('DIALOG')
	module.window.Title = StdUi:Texture(module.window, 256, 64, 'Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
	module.window.Title:SetPoint('TOP')
	module.window.Title:SetAlpha(.8)

	-- Setup the Top text fields
	module.window.SubTitle = StdUi:Label(module.window, "What's new", 16, nil, module.window:GetWidth(), 20)
	module.window.SubTitle:SetPoint('TOP', module.window.titlePanel, 'BOTTOM', 0, -5)
	module.window.SubTitle:SetTextColor(.29, .18, .96, 1)
	module.window.SubTitle:SetJustifyH('CENTER')

	module.window.Desc1 = StdUi:Label(module.window, '', 13, nil, module.window:GetWidth())
	module.window.Desc1:SetPoint('TOP', module.window.SubTitle, 'BOTTOM', 0, -5)
	module.window.Desc1:SetTextColor(1, 1, 1, .8)
	module.window.Desc1:SetWidth(module.window:GetWidth() - 40)
	module.window.Desc1:SetJustifyH('CENTER')

	module.window.Desc2 = StdUi:Label(module.window, '', 13, nil, module.window:GetWidth())
	module.window.Desc2:SetPoint('TOP', module.window.Desc1, 'BOTTOM', 0, -3)
	module.window.Desc2:SetTextColor(1, 1, 1, .8)
	module.window.Desc2:SetWidth(module.window:GetWidth() - 40)
	module.window.Desc2:SetJustifyH('CENTER')

	-- Setup the Buttons
	module.window.Skip = StdUi:Button(module.window, 150, 20, 'SKIP')
	module.window.Next = StdUi:Button(module.window, 150, 20, 'CONTINUE')

	--Position the Buttons
	module.window.Skip:SetPoint('BOTTOMLEFT', module.window, 'BOTTOMLEFT', 5, 5)
	module.window.Next:SetPoint('BOTTOMRIGHT', module.window, 'BOTTOMRIGHT', -5, 5)

	module.window.Skip:SetScript(
		'OnClick',
		function(this)
			module.window:Hide()
		end
	)

	module.window.Next:SetScript(
		'OnClick',
		function(this)
			module.window:Hide()
		end
	)

	-- Display first page
	module.window.closeBtn:Hide()
	module.window:Hide()
end

function module:OnInitialize()
	if SUI[db].WhatsNew == nil then
		SUI[db].WhatsNew = true
	end
	--Only display if the setup has been done, and the SUI.DB version is lower than release build, AND the user has not told us to never tell them about new stuff

	if SUI[db].Version and SUI[db].Version < '6.0.0' and SUI[db].SetupDone and SUI[db].WhatsNew then
		SUI:WhatsNew()
	end

	-- Update SUI.DB Version
	SUI[db].Version = SUI.Version
end
