---@diagnostic disable: duplicate-set-field
--[[
-- **************************************************************************
-- * TitanBag.lua
-- *
-- * By: The Titan Panel Development Team
-- **************************************************************************
--]]

local TITAN_VOLUME_ID = "Volume";
local TITAN_VOLUME_BUTTON = "TitanPanel" .. TITAN_VOLUME_ID .. "Button"

local cname = "TitanPanelVolumeControlFrame"

local TITAN_VOLUME_FRAME_SHOW_TIME = 0.5;
local TITAN_VOLUME_ARTWORK_PATH = "Interface\\AddOns\\TitanVolume\\Artwork\\";
local _G = getfenv(0);
local L = LibStub("AceLocale-3.0"):GetLocale(TITAN_ID, true)

local ALL_SOUND = "Sound_EnableAllSound"

-- The slider controls are nearly identical so set the data for them using the slider frame name
local sliders = {
	["TitanPanelMasterVolumeControlSlider"] = {
		short = "master",
		cvar = "Sound_MasterVolume",
		gtext = OPTION_TOOLTIP_MASTER_VOLUME,
		titan_var = "VolumeMaster",
		off_x = -160, off_y = -60,
	},
	["TitanPanelSoundVolumeControlSlider"] = {
		short = "sound",
		cvar = "Sound_SFXVolume",
		gtext = OPTION_TOOLTIP_FX_VOLUME,
		titan_var = "VolumeSFX",
		off_x = -90, off_y = -60,
	},
	["TitanPanelMusicVolumeControlSlider"] = {
		short = "music",
		cvar = "Sound_MusicVolume",
		gtext = OPTION_TOOLTIP_MUSIC_VOLUME,
		titan_var = "VolumeMusic",
		off_x = -20, off_y = -60,
	},
	["TitanPanelAmbienceVolumeControlSlider"] = {
		short = "ambience",
		cvar = "Sound_AmbienceVolume",
		gtext = OPTION_TOOLTIP_AMBIENCE_VOLUME,
		titan_var = "VolumeAmbience",
		off_x = 50, off_y = -60,
	},
	["TitanPanelDialogVolumeControlSlider"] = {
		short = "dialog",
		cvar = "Sound_DialogVolume",
		gtext = OPTION_TOOLTIP_DIALOG_VOLUME,
		titan_var = "VolumeDialog",
		off_x = 130, off_y = -60,
	},
}
--C_CVar.GetCVar("Sound_MusicVolume")
---local Get requested sound volume from Blizz C var API as a number.
---@param volume string
---@return number
local function GetCVolume(volume)
	-- Make explicit for clarity and IDE
	local vol = C_CVar.GetCVar(volume)
	-- If Blizz ever changes sound label strings, don't error
	if vol == nil then
		vol = "0"
	else
		-- accept value
	end
	return tonumber(vol)
end

---local Get volume as a % string.
---@param volume number | string
---@return string
local function GetVolumeText(volume)
	return tostring(floor(100 * tonumber(volume) + 0.5)) .. "%";
end

---local Get from WoW if 'all' sound is muted.
---@return boolean
local function IsMuted()
	local mute = false
	local setting = ALL_SOUND
	local value = GetCVolume(setting)
	if value == "0"
	or value == 0 then -- May have been a type change in 11.0.2
		mute = true
	elseif value == "1" then
		-- not muted
	else
		-- value is invalid - Blizz change??
	end
	return mute
end

---local Set plugin icon as off/low/med/high.
local function SetVolumeIcon()
	local plugin = TitanUtils_GetPlugin(TITAN_VOLUME_ID)

	local masterVolume = GetCVolume("Sound_MasterVolume")
	if (masterVolume <= 0)
	or IsMuted()
	then
		plugin.icon = TITAN_VOLUME_ARTWORK_PATH .. "TitanVolumeMute"
	elseif (masterVolume < 0.33) then
		plugin.icon = TITAN_VOLUME_ARTWORK_PATH .. "TitanVolumeLow"
	elseif (masterVolume < 0.66) then
		plugin.icon = TITAN_VOLUME_ARTWORK_PATH .. "TitanVolumeMedium"
	else
		plugin.icon = TITAN_VOLUME_ARTWORK_PATH .. "TitanVolumeHigh"
	end
end

---local Handle events registered to plugin
---@param self Button
---@param event string
local function OnEvent(self, event, a1, ...)
	-- No events to process
end

---local Set plugin icon and update plugin.
local function OnShow()
	if TitanGetVar(TITAN_VOLUME_ID, "OverrideBlizzSettings") then
		-- Override Blizzard's volume CVar settings
		if TitanGetVar(TITAN_VOLUME_ID, "VolumeMaster") then
			SetCVar("Sound_MasterVolume", TitanGetVar(TITAN_VOLUME_ID, "VolumeMaster"))
			SetVolumeIcon()
		end
		if TitanGetVar(TITAN_VOLUME_ID, "VolumeAmbience") then SetCVar("Sound_AmbienceVolume",
				TitanGetVar(TITAN_VOLUME_ID, "VolumeAmbience")) end
		if TitanGetVar(TITAN_VOLUME_ID, "VolumeDialog") then SetCVar("Sound_DialogVolume",
				TitanGetVar(TITAN_VOLUME_ID, "VolumeDialog")) end
		if TitanGetVar(TITAN_VOLUME_ID, "VolumeSFX") then SetCVar("Sound_SFXVolume",
				TitanGetVar(TITAN_VOLUME_ID, "VolumeSFX")) end
		if TitanGetVar(TITAN_VOLUME_ID, "VolumeMusic") then SetCVar("Sound_MusicVolume",
				TitanGetVar(TITAN_VOLUME_ID, "VolumeMusic")) end
		--		if TitanGetVar(TITAN_VOLUME_ID, "VolumeOutboundChat") then SetCVar("OutboundChatVolume", TitanGetVar(TITAN_VOLUME_ID, "VolumeOutboundChat")) end
		--		if TitanGetVar(TITAN_VOLUME_ID, "VolumeInboundChat") then SetCVar("InboundChatVolume", TitanGetVar(TITAN_VOLUME_ID, "VolumeInboundChat")) end
	end
	SetVolumeIcon();
	TitanPanelButton_UpdateButton(TITAN_VOLUME_ID);
end

---local On mouse over, set values for sliders in case of right click.
local function OnEnter()
	for idx, slider in pairs (sliders) do
		_G[idx]:SetValue(1 - GetCVolume(slider.cvar))
	end
end

-- ====== Slider helpers
---local On mouse over; set tooltip.
---@param self Slider
local function Slider_OnEnter(self)
	local slider = sliders[self:GetName()]
	local tooltipText = ""
	tooltipText = TitanOptionSlider_TooltipText(slider.gtext, GetVolumeText(GetCVolume(slider.cvar)));
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT");
	GameTooltip:SetText(tooltipText, nil, nil, nil, nil, 1);
	TitanUtils_StopFrameCounting(self:GetParent());
end

---local On mouse leaving; prep hide of tooltip.
---@param self Slider
local function Slider_OnLeave(self)
	GameTooltip:Hide();

	local slider = sliders[self:GetName()]
	if slider.short == "master" then
		local masterVolume = tonumber(GetCVolume(slider.cvar));
		if (masterVolume <= 0) then
			C_CVar.SetCVar(ALL_SOUND, "0")
		else
			C_CVar.SetCVar(ALL_SOUND, "1")
		end
	end

	TitanUtils_StartFrameCounting(self:GetParent(), TITAN_VOLUME_FRAME_SHOW_TIME);
end

---local On show; get and show current volume and bounds.
---@param self Slider
local function Slider_OnShow(self)
	local slider = sliders[self:GetName()]

	_G[self:GetName() .. "Text"]:SetText(GetVolumeText(GetCVolume(slider.cvar)));
	_G[self:GetName() .. "High"]:SetText(Titan_Global.literals.low);
	_G[self:GetName() .. "Low"]:SetText(Titan_Global.literals.high);
	self:SetMinMaxValues(0, 1);
	self:SetValueStep(0.01);
	self:SetObeyStepOnDrag(true) -- since 5.4.2 (Mists of Pandaria)
	self:SetValue(1 - GetCVolume(slider.cvar));
end

---local On value changed; get and show current volume and bounds.
---@param self Slider
---@param a1 number
local function Slider_OnValueChanged(self, a1)
	local slider = sliders[self:GetName()]

	local vol = 1 - self:GetValue()
	_G[self:GetName() .. "Text"]:SetText(GetVolumeText(vol));

	C_CVar.SetCVar(slider.cvar, vol);
	TitanSetVar(TITAN_VOLUME_ID, slider.titan_var, vol)

	SetVolumeIcon();
	TitanPanelButton_UpdateButton(TITAN_VOLUME_ID);

	-- Update GameTooltip
	local tooltipText = TitanOptionSlider_TooltipText(slider.gtext, GetVolumeText(1 - self:GetValue()));
	GameTooltip:SetText(tooltipText, nil, nil, nil, nil, 1);
end

---local Any slider value changed via mouse wheel; update slider only; _OnValueChanged will update WoW and tooltip.
---@param self Slider
---@param a1 number
local function OnMouseWheel(self, a1)
	local tempval = self:GetValue();

	if a1 < 0 then
		self:SetValue(tempval + 0.01);
	end

	if a1 > 0 then
		self:SetValue(tempval - 0.01);
	end
end

---local Inititalize custom left click menu
---@param self Frame
local function ControlFrame_OnLoad(self)
	_G[self:GetName() .. "Title"]:SetText(L["TITAN_VOLUME_CONTROL_TITLE"]);         -- VOLUME
	_G[self:GetName() .. "MasterTitle"]:SetText(L["TITAN_VOLUME_MASTER_CONTROL_TITLE"]); --MASTER_VOLUME
	_G[self:GetName() .. "MusicTitle"]:SetText(L["TITAN_VOLUME_MUSIC_CONTROL_TITLE"]);
	_G[self:GetName() .. "SoundTitle"]:SetText(L["TITAN_VOLUME_SOUND_CONTROL_TITLE"]); -- FX_VOLUME
	_G[self:GetName() .. "AmbienceTitle"]:SetText(L["TITAN_VOLUME_AMBIENCE_CONTROL_TITLE"]);
	_G[self:GetName() .. "DialogTitle"]:SetText(L["TITAN_VOLUME_DIALOG_CONTROL_TITLE"]);
	--	_G[self:GetName().."MicrophoneTitle"]:SetText(L["TITAN_VOLUME_MICROPHONE_CONTROL_TITLE"]);
	--	_G[self:GetName().."SpeakerTitle"]:SetText(L["TITAN_VOLUME_SPEAKER_CONTROL_TITLE"]);
	TitanPanelRightClickMenu_SetCustomBackdrop(self)
end

---local Generate tooltip text
---@return string
local function GetTooltipText()
	local mute = Titan_Global.literals.muted

	if IsMuted() then
		mute = mute .. "\t" .. TitanUtils_GetRedText(Titan_Global.literals.yes) .. "\n\n"
	else
		mute = mute .. "\t" .. TitanUtils_GetGreenText(Titan_Global.literals.no) .. "\n\n"
	end
	local text = ""

	local volumeMasterText = GetVolumeText(GetCVolume("Sound_MasterVolume"));
	local volumeSoundText = GetVolumeText(GetCVolume("Sound_SFXVolume"));
	local volumeMusicText = GetVolumeText(GetCVolume("Sound_MusicVolume"));
	local volumeAmbienceText = GetVolumeText(GetCVolume("Sound_AmbienceVolume"));
	local volumeDialogText = GetVolumeText(GetCVolume("Sound_DialogVolume"));
	--	local volumeMicrophoneText = GetVolumeText(GetCVolume("OutboundChatVolume"));
	--	local volumeSpeakerText = GetVolumeText(GetCVolume("InboundChatVolume"));

	text = ""..
	mute ..
	L["TITAN_VOLUME_MASTER_TOOLTIP_VALUE"] .. "\t" .. TitanUtils_GetHighlightText(volumeMasterText) .. "\n" ..
	L["TITAN_VOLUME_SOUND_TOOLTIP_VALUE"] .. "\t" .. TitanUtils_GetHighlightText(volumeSoundText) .. "\n" ..
	L["TITAN_VOLUME_MUSIC_TOOLTIP_VALUE"] .. "\t" .. TitanUtils_GetHighlightText(volumeMusicText) .. "\n" ..
	L["TITAN_VOLUME_AMBIENCE_TOOLTIP_VALUE"] .. "\t" .. TitanUtils_GetHighlightText(volumeAmbienceText) .. "\n" ..
	L["TITAN_VOLUME_DIALOG_TOOLTIP_VALUE"] .. "\t" .. TitanUtils_GetHighlightText(volumeDialogText) .. "\n" ..
	--		L["TITAN_VOLUME_MICROPHONE_TOOLTIP_VALUE"].."\t"..TitanUtils_GetHighlightText(volumeMicrophoneText).."\n"..
	--		L["TITAN_VOLUME_SPEAKER_TOOLTIP_VALUE"].."\t"..TitanUtils_GetHighlightText(volumeSpeakerText).."\n"..
	TitanUtils_GetGreenText(L["TITAN_VOLUME_TOOLTIP_HINT1"]) .. "\n" ..
	TitanUtils_GetGreenText(L["TITAN_VOLUME_TOOLTIP_HINT2"]) .. "\n" ..
	""
	
	return text
end

---local Generate the right click menu
local function CreateMenu()
	TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_VOLUME_ID].menuText);

	local info = {};
	info.notCheckable = true
	info.text = L["TITAN_VOLUME_MENU_AUDIO_OPTIONS_LABEL"];
	info.func = function()
		ShowUIPanel(VideoOptionsFrame);
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info.text = L["TITAN_VOLUME_MENU_OVERRIDE_BLIZZ_SETTINGS"];
	info.notCheckable = false
	info.func = function()
		TitanToggleVar(TITAN_VOLUME_ID, "OverrideBlizzSettings");
	end
	info.checked = TitanGetVar(TITAN_VOLUME_ID, "OverrideBlizzSettings");
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddControlVars(TITAN_VOLUME_ID)
end

---local On double click toggle the all sound mute; will flash the slider frame...
---@param self Button
---@param button string
local function OnDoubleClick(self, button)
	if button == "LeftButton" then
		-- Toggle mute value
		if IsMuted() then
			SetCVar(ALL_SOUND,"1")
		else
			SetCVar(ALL_SOUND,"0")
		end
		SetVolumeIcon()
		_G[cname]:Hide()
		TitanPanelButton_UpdateButton(TITAN_VOLUME_ID);
	else
		-- No action
	end
end

---local Create plugin .registry and and register for first events
---@param self Button
local function OnLoad(self)
	local notes = ""
	.. "Adds a volume control icon on your Titan Bar.\n"
	.. L["TITAN_VOLUME_TOOLTIP_HINT1"] .. "\n"
	.. L["TITAN_VOLUME_TOOLTIP_HINT2"] .. "\n"
	--		.."- xxx.\n"
	self.registry = {
		id = TITAN_VOLUME_ID,
		category = "Built-ins",
		version = TITAN_VERSION,
		menuText = L["TITAN_VOLUME_MENU_TEXT"],
		menuTextFunction = CreateMenu,
		tooltipTitle = VOLUME, --L["TITAN_VOLUME_TOOLTIP"],
		tooltipTextFunction = GetTooltipText,
		iconWidth = 32,
		iconButtonWidth = 18,
		notes = notes,
		controlVariables = {
			ShowIcon = false,
			ShowLabelText = false,
			ShowColoredText = false,
			DisplayOnRightSide = true,
		},
		savedVariables = {
			OverrideBlizzSettings = false,
			VolumeMaster = 1,
			VolumeAmbience = 0.5,
			VolumeDialog = 0.5,
			VolumeSFX = 0.5,
			VolumeMusic = 0.5,
			--			VolumeOutboundChat = 1,
			--			VolumeInboundChat = 1,
			DisplayOnRightSide = 1,
		}
	};
end

---local Create needed frames
local function Create_Frames()
	if _G[TITAN_VOLUME_BUTTON] then
		return -- if already created
	end

	-- general container frame
	local f = CreateFrame("Frame", nil, UIParent)
	--	f:Hide()

	-- Titan plugin button
	local window = CreateFrame("Button", TITAN_VOLUME_BUTTON, f, "TitanPanelIconTemplate")
	window:SetFrameStrata("FULLSCREEN")
	-- Using SetScript("OnLoad",   does not work
	OnLoad(window);
	--	TitanPanelButton_OnLoad(window); -- Titan XML template calls this...w

	window:SetScript("OnShow", function(self)
		OnShow()
		TitanPanelButton_OnShow(self)
	end)
	window:SetScript("OnEnter", function(self)
		OnEnter()
		TitanPanelButton_OnEnter(self)
	end)
	window:SetScript("OnEvent", function(self, event, ...)
		OnEvent(self, event, ...)
	end)


	---[===[
	-- Config screen
	local config = CreateFrame("Frame", cname, f, BackdropTemplateMixin and "BackdropTemplate")
	config:SetFrameStrata("FULLSCREEN") --
	config:Hide()
	config:SetWidth(400)
	config:SetHeight(200)

	config:SetScript("OnEnter", function(self)
		TitanUtils_StopFrameCounting(self)
	end)
	config:SetScript("OnLeave", function(self)
		TitanUtils_StartFrameCounting(self, 0.5)
	end)
	config:SetScript("OnUpdate", function(self, elapsed)
		TitanUtils_CheckFrameCounting(self, elapsed)
	end)
	window:SetScript("OnDoubleClick", function(self, button)
		OnDoubleClick(self, button)
--		TitanPanelButton_OnClick(self, button)
	end)

	-- Config font sections
	local str = nil
	local style = "GameFontNormalSmall"
	str = config:CreateFontString(cname .. "Title", "ARTWORK", style)
	str:SetPoint("TOP", config, 0, -10)

	str = config:CreateFontString(cname .. "MasterTitle", "ARTWORK", style)
	str:SetPoint("TOP", config, -160, -30)

	str = config:CreateFontString(cname .. "SoundTitle", "ARTWORK", style)
	str:SetPoint("TOP", config, -90, -30)

	str = config:CreateFontString(cname .. "MusicTitle", "ARTWORK", style)
	str:SetPoint("TOP", config, -20, -30)

	str = config:CreateFontString(cname .. "AmbienceTitle", "ARTWORK", style)
	str:SetPoint("TOP", config, 50, -30)

	str = config:CreateFontString(cname .. "DialogTitle", "ARTWORK", style)
	str:SetPoint("TOP", config, 130, -30)

	-- ====== Config slider sections

	local inherit = "TitanOptionsSliderTemplate"
	for idx, slider in pairs (sliders) do
		local s = CreateFrame("Slider", idx, config, inherit)
		s:SetPoint("TOP", config, slider.off_x, slider.off_y)
		s:SetScript("OnShow", function(self)
			Slider_OnShow(self)
		end)
		s:SetScript("OnValueChanged", function(self, value)
			Slider_OnValueChanged(self, value)
		end)
		s:SetScript("OnMouseWheel", function(self, delta)
			OnMouseWheel(self, delta)
		end)
		s:SetScript("OnEnter", function(self)
			Slider_OnEnter(self)
		end)
		s:SetScript("OnLeave", function(self)
			Slider_OnLeave(self)
		end)
	end

	-- Now that the parts exist, initialize
	ControlFrame_OnLoad(config)

	--]===]
end

Create_Frames() -- do the work
