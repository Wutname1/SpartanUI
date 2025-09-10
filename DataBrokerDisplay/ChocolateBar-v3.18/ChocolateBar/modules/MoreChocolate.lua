﻿-- a LDB object that will show/hide the chocolatebar set in the chocolatebar options
local LibStub = LibStub
local counter = 0
local delay = 4
local Timer = CreateFrame("Frame")
local ChocolateBar = LibStub("AceAddon-3.0"):GetAddon("ChocolateBar")
local bar
local L = LibStub("AceLocale-3.0"):GetLocale("ChocolateBar")
local wipe, pairs = wipe, pairs

local moreChocolate

local debug = ChocolateBar and ChocolateBar.Debug or function() end


local function onEnter()
	counter = 0
	debug("onEnter", delay)
	if delay > 0 then
		Timer:SetScript("OnUpdate", Timer.OnUpdate)
	end
	if bar then
		bar:Show()
		--bar:ShowAll()
	end
end

local function setBar(self, db)
	bar = ChocolateBar:GetBar(db.moreBar)
	if bar and bar:IsShown() then
		bar:Hide()
	end
	delay = db.moreBarDelay
end


local function GetList()
	wipe(moreChocolate.barNames)
	moreChocolate.barNames.none = L["None"]
	for k,v in pairs(ChocolateBar:GetBars()) do
		moreChocolate.barNames[k] = k
	end
	return moreChocolate.barNames
end

function Timer:OnUpdate(elapsed)
	counter = counter + elapsed
	if counter >= delay and bar and not ChocolateBar.dragging then
		bar:Hide()
		counter = 0
		Timer:SetScript("OnUpdate", nil)
	end
end

local options = {
		inline = true,
		name="Module Options",
		type="group",
		order = 1,
		args={
			label = {
				order = 2,
				type = "description",
				name = L["A broker plugin to toggle a bar."],
			},
			selectBar = {
				type = 'select',
				values = GetList, 
				order = 3,
				name = L["Select Bar"],
				desc = L["Select Bar"],
				get = function()
					return ChocolateBar.db.profile.moreBar
				end,
				set = function(info, value)
					debug("selectBar", value)
					if bar then
						bar:Show()
					end
					ChocolateBar.db.profile.moreBar = value
					moreChocolate:SetBar(ChocolateBar.db.profile)
				end,
			},
			delay = {
				type = 'range',
				order = 4,
				name = L["Delay"],
				desc = L["Set seconds until bar will hide."],
				min = 0,
				max = 15,
				step = 1,
				get = function(name)
					return ChocolateBar.db.profile.moreBarDelay
				end,
				set = function(info, value)
					delay = value
					ChocolateBar.db.profile.moreBarDelay = value
				end,
			},
	},
}


local Module = ChocolateBar:NewModule("MoreChocolate", {
	description = "A broker plugin that can toggle the visibility of a specific chocolate bar.",
	defaults = {
		enabled = true,
	},
	options = options
})

function Module:DisableModule()
	debug("DisableModule")
	debug("DisableModule")
	if bar then
		bar:Show()
	end
	ChocolateBar.db.profile.moreBar = "none"
	setBar(moreChocolate, ChocolateBar.db.profile)
end

function Module:EnableModule()
	debug("EnableModule", self.name)
	if not moreChocolate then 
		moreChocolate = LibStub("LibDataBroker-1.1"):NewDataObject("MoreChocolate", {
			type = "launcher",
			icon = "Interface\\AddOns\\ChocolateBar\\pics\\ChocolatePiece",
			label = "MoreChocolate",
			text  = "MoreChocolate",
		
			OnClick = function(self, btn)
				if btn == "LeftButton" then
					if bar then
						if bar:IsShown() then
							bar:Hide()
							Timer:SetScript("OnUpdate", nil)
						else
							bar:Show()
							--bar:ShowAll()
							if delay > 0 then
								Timer:SetScript("OnUpdate", Timer.OnUpdate)
							end
						end
					end
				else
					InterfaceOptionsFrame_OpenToCategory("ChocolateBar");
				end
			end,
		})

		moreChocolate.barNames = {none = "none"}
		moreChocolate.SetBar = setBar
		moreChocolate.OnEnter = onEnter
	end
end