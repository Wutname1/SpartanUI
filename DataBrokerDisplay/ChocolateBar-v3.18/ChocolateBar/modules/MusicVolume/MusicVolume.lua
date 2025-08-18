local LibStub = LibStub
local ChocolateBar = LibStub("AceAddon-3.0"):GetAddon("ChocolateBar")
local debug = ChocolateBar and ChocolateBar.debug or function() end
local L = LibStub("AceLocale-3.0"):GetLocale("ChocolateBar")

local addonName = "MusicVolume"
local dataobj

local volumeText = "Music: "..math.floor((_G.GetCVar("Sound_MusicVolume")*100)).."%"

local function OnMouseWheel(self, vector)
	local cVar = "Sound_MusicVolume" --Sound_MusicVolume  Sound_SFXVolume
	local vol = GetCVar(cVar)
	local step = IsAltKeyDown() and vector * .01 or vector * .1
	vol = vol + step
	if vol > 1 then vol = 1 end
	if vol < 0 then vol = 0 end
	SetCVar(cVar, vol);
	dataobj.text = "Music: "..math.floor((_G.GetCVar(cVar)*100)).."%"
end

local Module = ChocolateBar:NewModule(addonName, {
	description = L["Use your scroll wheel over this plugin to adjust the music volume."],
	defaults = {
		enabled = true,
	},
	options = options
})

function Module:DisableModule()
end

function Module:EnableModule()
	if not dataobj then 
		ChocolateBar:Debug("Creating Module: Music Volume")
		dataobj = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
			type = "data source",
			icon = "Interface\\AddOns\\ChocolateBar\\modules\\MusicVolume\\icon.tga",
			label = addonName,
			text  = volumeText,
			OnMouseWheel = OnMouseWheel,
		})
	end
end