--[[ StarterLDB.lua
By: The Titan Panel Development Team
--]]


-- Intended for Intellisense if an IDE supports and is used
-- Lines starting with triple dash are usually Intellisense
---@class Frame WoW frame to get events
---@field obj table For LDB object

-- ******************************** Constants *******************************
local ADDON_NAME = ...
-- Set the name we want in the global name space. Ensure the name is unique across all addons.
StarterLDB = {}

-- NOTE: The 'id' and the 'addon' name are different! 
-- Typically they are the same to reduce user confusion but they do not need to be the same.
local id = "LDBStarter"; -- Name the user dhould see in the display addon
local addon = ADDON_NAME -- addon name / folder name / toc name

-- Localized strings are outside the scope of this example.

--[[
The artwork path must start with Interface\\AddOns
Then the name of the plugin
Then any additional folder(s) to your artwork / icons.
Double backslash will for for Windows; forward slash works fine.
--]]
local artwork_path = "Interface/AddOns/TitanLDB/Artwork/"
---@diagnostic disable-next-line: deprecated, undefined-global
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata or GetAddOnMetadata

--  Get data from the TOC file.
local version = tostring(GetAddOnMetadata(addon, "Version")) or "Unknown"
local author = GetAddOnMetadata(addon, "Author") or "Unknown"
-- NOTE: GetAddOnMetadata expects the addon name :
--       The addon folder name or .toc name needs to be the same.

-- ******************************** Variables *******************************
local trace = false -- toggle to show / hide debug statements in this addon

-- ******************************** Functions *******************************

---Output a debug statement to Chat with timestamp.
---@param debug_message string
---@param debug_type string
local function Debug(debug_message, debug_type)
	if trace then
		local dtype = ""
		local time_stamp = ""
		local msg = ""
		if debug_type == "error" then
			dtype = "Error: "
		elseif debug_type == "warning" then
			dtype = "Warning: "
		end
		time_stamp = date("%H:%M:%S") .. ": "

		msg =
			tostring(addon) .. ": "
			.. time_stamp
			.. dtype
			.. debug_message

		_G["DEFAULT_CHAT_FRAME"]:AddMessage(msg)
	else
		-- not requested
	end
	--date("%m/%d/%y %H:%M:%S")
end

--- Calculate bag space then return text and icon to display
---@return string bagText display text
---@return string icon path to
local function GetBagSlotInfo()
	local totalSlots, usedSlots, availableSlots, icon
	totalSlots = 0;
	usedSlots = 0;
	for bag = 0, 4 do
		local size = C_Container.GetContainerNumSlots(bag);
		if (size and size > 0) then
			totalSlots = totalSlots + size;
			local free = C_Container.GetContainerNumFreeSlots(bag)
			local used = size - free
			usedSlots = usedSlots + used;
		end
	end
	availableSlots = totalSlots - usedSlots;

	local i, r = math.modf(availableSlots / 2)
	-- Simple example of changing the icon : even blue - odd red
	-- wowhead.com/icons was searched and these selected
	-- The art was extracted : ../_retail_/BliizardInterfaceArt
	-- These were found in /Interface/ICONS of the extracted folder by the name used on wowhead
	-- Copied into /Artwork in case Blizz ever renames or removes these icons.
	if (r == 0) then
		icon = artwork_path .. "Bag_Blue.blp"
	else
		icon = artwork_path .. "Bag_Red.blp"
	end

	local bagText
	bagText = format("%d/%d", availableSlots, totalSlots);

	bagText = HIGHLIGHT_FONT_COLOR_CODE .. bagText .. FONT_COLOR_CODE_CLOSE

	return bagText, icon
end

--- Create the tooltip
---@param tooltip GameTooltip From display addon
local function LDB_OnTooltipShow(tooltip)
	tooltip = tooltip or GameTooltip  -- for safety
	local tt_str = ""

	tt_str =
		GREEN_FONT_COLOR_CODE
		.. id .. " Info"
		.. FONT_COLOR_CODE_CLOSE
	tooltip:AddLine(tt_str)

	local text, icon = GetBagSlotInfo()
	tt_str = "Available bag slots"
		.. " " .. text .. "\n"
		.. "\n" .. "Hint: Left-click to open all bags."

	tooltip:AddLine(tt_str)
end

--- Initialize the LDB obj and initial set up
---@param LDB_frame Frame Addon frame
local function LDB_Init(LDB_frame)
	Debug(id .. " Init ...", "normal");
	--[[
	Initialize the Data Broker 'button'.
	This is the heart of a LDB plugin. It determines how the display addon is to treat this addon.

	Setting the type is required so the LDB lib and display addon know what to do. See the LDB spec.

	id will be the name Titan uses for the plugin. You can find it in the Titan Config or Titan right click menu.
	--]]

	LDB_frame.obj =
		LibStub("LibDataBroker-1.1"):NewDataObject(id, -- Name used within Titan
		{
			type          = "data source", -- required
			-- LDB spec: The two options are:
			--      "data source" - Expected to show some type of info
			--      "launcher" - Expected to open another window or perform some action
			icon          = artwork_path .. "Starter.tga", -- The icon to display on the display addon
			label         = id,        -- label for the text
			text          = "nyl",     -- will be updated as needed by this plugin
			OnTooltipShow = function(tooltip)
				LDB_OnTooltipShow(tooltip)
			end,
			OnClick       = function(self, button)
				if (button == "LeftButton") then
					-- Just a simple action to illustrate an LDB addon.
					ToggleAllBags();
				elseif (button == "RightButton") then
					-- There is no action to take in this example.
					--[[ Add code here if your addon needs to do something on right click.
						Typically an options menu which is outside the scope of this example.
					--]]
				end
			end,
			-- Titan specific!!
			category = "Information", -- Otherwise defaults to General : TITAN_PANEL_BUTTONS_PLUGIN_CATEGORY
		})

	-- After player entering world it is safe 
	-- - to look at any saved variables 
	-- - register for more events; registering here may cause errors if data is not ready
	LDB_frame:RegisterEvent("PLAYER_ENTERING_WORLD");

	Debug(id .. " Init fini.", "normal");
end

--- Update the Bags Data Broker 'button'
---@param LDB_frame Frame
local function LDB_Update(LDB_frame)
	local text, icon = GetBagSlotInfo()
	LDB_frame.obj.text = text
	LDB_frame.obj.icon = icon
end

--- Parse events registered events and act on them
---@param self Button
---@param event string
---@param ... any
local function Button_OnEvent(self, event, ...)
	-- https://warcraft.wiki.gg/wiki/UIHANDLER_OnEvent

	Debug("OnEvent"
		.. " " .. tostring(event) .. ""
	, "normal")
	if (event == "PLAYER_ENTERING_WORLD") then
		-- Do any additional set up needed
		--
		-- Now that events have settled, register the one(s) we really want.
		-- Registering here may reduce churn and possible timing issues wrt data being ready
		self:RegisterEvent("BAG_UPDATE");

		-- Unregister events no longer needed.
		-- Good practice to avoid init again - this is fired on /reload
		self:UnregisterEvent("PLAYER_ENTERING_WORLD");

		-- Update the text (bag numbers)
		LDB_Update(self)

	end
	if event == "BAG_UPDATE" then
		LDB_Update(self)
	end
end

--- Create needed frames
local function Create_Frames()
	-- general container frame to get events from WoW.
	-- The display addon will create frame(s) needed to display data set by this addon.
	local window = CreateFrame("Frame", "StarterLDBExample", UIParent)
	--	window:Hide()

	-- Set strata as desired
	window:SetFrameStrata("FULLSCREEN") 
	-- https://warcraft.wiki.gg/wiki/Frame_Strata

	window:SetScript("OnEvent", function(self, event, ...) 
		Button_OnEvent(self, event, ...)
	end)
	-- https://warcraft.wiki.gg/wiki/API_ScriptObject_SetScript

	-- Using SetScript("OnLoad",   does not work
	LDB_Init(window)

	-- shamelessly print a load message to chat window
	DEFAULT_CHAT_FRAME:AddMessage(
		GREEN_FONT_COLOR_CODE
		.. addon .. id .. " " .. version
		.. " by "
		.. FONT_COLOR_CODE_CLOSE
		.. "|cFFFFFF00" .. author .. FONT_COLOR_CODE_CLOSE);
end

Create_Frames() -- Create WoW frames to get events

--[[
print(""
	.." "..tostring(id)..""
	.." "..tostring(version)..""
	.." by "..tostring(author)..""
	)
--]]
