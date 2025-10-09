---@class LibATErrorDisplay
local ErrorDisplay = _G.LibATErrorDisplay

-- Localization
local L = {
    ["Options"] = "Options",
    ["Auto popup on errors"] = "Auto popup on errors",
    ["Chat frame output"] = "Chat frame output",
    ["Font Size"] = "Font Size",
    ["Reset to Defaults"] = "Reset to Defaults",
    ["Show Minimap Icon"] = "Show Minimap Icon",
}

ErrorDisplay.Config = {}

-- Minimal defaults - only store overrides, use fallbacks for defaults
-- Note: We no longer store errors ourselves - BugGrabber handles that
local defaults = {
    profile = {
    },
    global = {
    }
}

-- Initialize using Ace3 DB pattern
function ErrorDisplay.Config:Initialize()
    -- Use LibStub to get AceDB if available, fallback to manual setup
    local AceDB = LibStub and LibStub("AceDB-3.0", true)

    if AceDB then
        ErrorDisplay.database = AceDB:New("LibATErrorDisplayDB", defaults, true)
        ErrorDisplay.db = ErrorDisplay.database.profile
        ErrorDisplay.gdb = ErrorDisplay.database.global
    else
        -- Fallback to manual setup
        if not LibATErrorDisplayDB then
            LibATErrorDisplayDB = CopyTable(defaults)
        end
        ErrorDisplay.database = LibATErrorDisplayDB
        ErrorDisplay.db = LibATErrorDisplayDB.profile or {}
        ErrorDisplay.gdb = LibATErrorDisplayDB.global or {}

        -- Ensure global defaults exist
        for k, v in pairs(defaults.global) do
            if ErrorDisplay.gdb[k] == nil then
                ErrorDisplay.gdb[k] = v
            end
        end
    end

    -- Remove old reference
    self.db = nil
end

-- Create the options panel
function ErrorDisplay.Config:CreatePanel()
    local panel = CreateFrame('Frame')
    panel.name = "LibAT Error Display"

    local title = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
    title:SetPoint('TOPLEFT', 16, -16)
    title:SetText("LibAT Error Display " .. L['Options'])

    -- Auto Popup checkbox
    local autoPopup = CreateFrame('CheckButton', nil, panel, 'InterfaceOptionsCheckButtonTemplate')
    autoPopup:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -16)
    autoPopup.Text:SetText(L['Auto popup on errors'])
    autoPopup:SetChecked(ErrorDisplay.db.autoPopup or false) -- Default to false
    autoPopup:SetScript(
        'OnClick',
        function(self)
            ErrorDisplay.db.autoPopup = self:GetChecked() or nil -- Store nil if false to save space
        end
    )

    -- Chat Frame Output checkbox
    local chatFrame = CreateFrame('CheckButton', nil, panel, 'InterfaceOptionsCheckButtonTemplate')
    chatFrame:SetPoint('TOPLEFT', autoPopup, 'BOTTOMLEFT', 0, -8)
    chatFrame.Text:SetText(L['Chat frame output'])
    chatFrame:SetChecked(ErrorDisplay.db.chatframe ~= false) -- Default to true
    chatFrame:SetScript(
        'OnClick',
        function(self)
            ErrorDisplay.db.chatframe = self:GetChecked() and nil or false -- Store nil for true, false for false
        end
    )

    -- Font Size slider
    local fontSizeSlider = CreateFrame('Slider', nil, panel, 'OptionsSliderTemplate')
    fontSizeSlider:SetPoint('TOPLEFT', chatFrame, 'BOTTOMLEFT', 0, -24)
    fontSizeSlider:SetMinMaxValues(8, 24)
    fontSizeSlider:SetValueStep(1)
    fontSizeSlider:SetObeyStepOnDrag(true)
    fontSizeSlider:SetWidth(200)
    fontSizeSlider.Low:SetText('8')
    fontSizeSlider.High:SetText('24')
    fontSizeSlider.Text:SetText(L['Font Size'])
    fontSizeSlider:SetValue(ErrorDisplay.db.fontSize or 12) -- Default to 12
    fontSizeSlider:SetScript(
        'OnValueChanged',
        function(self, value)
            value = math.floor(value + 0.5)
            ErrorDisplay.db.fontSize = value ~= 12 and value or nil -- Store nil if default
            if ErrorDisplay.BugWindow.UpdateFontSize then
                ErrorDisplay.BugWindow:UpdateFontSize()
            end
        end
    )

    -- Add a "Reset to Defaults" button
    local defaultsButton = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
    defaultsButton:SetText(L['Reset to Defaults'])
    defaultsButton:SetWidth(150)
    defaultsButton:SetPoint('TOPLEFT', fontSizeSlider, 'BOTTOMLEFT', 0, -16)
    defaultsButton:SetScript(
        'OnClick',
        function()
            ErrorDisplay.Config:ResetToDefaults()
            autoPopup:SetChecked(ErrorDisplay.db.autoPopup or false)
            chatFrame:SetChecked(ErrorDisplay.db.chatframe ~= false)
            fontSizeSlider:SetValue(ErrorDisplay.db.fontSize or 12)
        end
    )

    local minimapIconCheckbox = CreateFrame('CheckButton', nil, panel, 'InterfaceOptionsCheckButtonTemplate')
    minimapIconCheckbox:SetPoint('TOPLEFT', defaultsButton, 'BOTTOMLEFT', 0, -16)
    minimapIconCheckbox.Text:SetText(L['Show Minimap Icon'])

    -- Check LibDBIcon state
    local isShown = true
    if ErrorDisplay.icon and ErrorDisplay.db.minimapIcon then
        isShown = not ErrorDisplay.db.minimapIcon.hide
    end
    minimapIconCheckbox:SetChecked(isShown)

    minimapIconCheckbox:SetScript(
        'OnClick',
        function(self)
            local shouldShow = self:GetChecked()
            if ErrorDisplay.icon then
                if shouldShow then
                    ErrorDisplay.icon:Show('Libs-AddonToolsErrorDisplay')
                else
                    ErrorDisplay.icon:Hide('Libs-AddonToolsErrorDisplay')
                end
            end
        end
    )

    panel.okay = function()
        -- This method is called when the player clicks "Okay" in the Interface Options
    end

    panel.cancel = function()
        -- This method is called when the player clicks "Cancel" in the Interface Options
        -- Reset to the previous values (not needed with direct access)
    end

    panel.refresh = function()
        -- This method is called when the panel is shown
        autoPopup:SetChecked(ErrorDisplay.db.autoPopup or false)
        chatFrame:SetChecked(ErrorDisplay.db.chatframe ~= false)
        fontSizeSlider:SetValue(ErrorDisplay.db.fontSize or 12)

        -- Update minimap icon checkbox state
        local isShown = true
        if ErrorDisplay.icon and ErrorDisplay.db.minimapIcon then
            isShown = not ErrorDisplay.db.minimapIcon.hide
        end
        minimapIconCheckbox:SetChecked(isShown)
    end

    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    else
        local category, layout = Settings.RegisterCanvasLayoutCategory(panel, 'LibAT Error Display')
        Settings.RegisterAddOnCategory(category)
        ErrorDisplay.settingsCategory = category
    end
end

function ErrorDisplay.Config:ResetToDefaults()
    -- Clear profile settings (let defaults kick in)
    if ErrorDisplay.database and ErrorDisplay.database.ResetProfile then
        ErrorDisplay.database:ResetProfile()
    else
        -- Manual reset
        wipe(ErrorDisplay.db)
    end

    if ErrorDisplay.BugWindow.UpdateFontSize then
        ErrorDisplay.BugWindow:UpdateFontSize()
    end
end

return ErrorDisplay.Config