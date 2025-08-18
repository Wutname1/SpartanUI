---@diagnostic disable: duplicate-set-field
-- **************************************************************************
-- * TitanPerformance.lua
-- *
-- * By: The Titan Panel Development Team
-- **************************************************************************

-- ******************************** Constants *******************************
local TITAN_PERFORMANCE_ID = "Performance";
local TITAN_BUTTON = "TitanPanel" .. TITAN_PERFORMANCE_ID .. "Button"

local TITAN_PERF_FRAME_SHOW_TIME = 0.5;
local updateTable = { TITAN_PERFORMANCE_ID, TITAN_PANEL_UPDATE_ALL };

local APP_MIN = 1
local APP_MAX = 40

---@diagnostic disable-next-line: deprecated, undefined-global
local NumAddons = C_AddOns.GetNumAddOns or GetNumAddOns
---@diagnostic disable-next-line: deprecated, undefined-global
local AddOnInfo = C_AddOns.GetAddOnInfo or GetAddOnInfo
---@diagnostic disable-next-line: deprecated, undefined-global
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded

local TITAN_FPS_THRESHOLD_TABLE = {
	Values = { 20, 30 },
	Colors = { RED_FONT_COLOR, NORMAL_FONT_COLOR, GREEN_FONT_COLOR },
}

-- #1369 - PERFORMANCEBAR_LOW_LATENCY, PERFORMANCEBAR_MEDIUM_LATENCY no longer defined by WoW
local TITAN_LATENCY_THRESHOLD_TABLE = {
	Values = { 300, 600 },
	Colors = { GREEN_FONT_COLOR, NORMAL_FONT_COLOR, RED_FONT_COLOR },
}

local TITAN_MEMORY_RATE_THRESHOLD_TABLE = {
	Values = { 1, 2 },
	Colors = { GREEN_FONT_COLOR, NORMAL_FONT_COLOR, RED_FONT_COLOR },
}

-- ******************************** Variables *******************************
local _G = getfenv(0);
local topAddOns;
local memUsageSinceGC = {};
local counter = 1; --counter for active addons
local AceTimer = LibStub("AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(TITAN_ID, true)
local PerfTimer = {}
local PerfTimerRunning = false

local perf_stats = {}
-- ******************************** Functions *******************************

---local Use user selected with required min of 1
---@param val number
---@return number
local function CalcAppNum(val)
	local new_val = 1 -- always monitor at least one

	if val == nil or val < APP_MIN then
		-- keep the default min
	else
		-- return a value adjusted for the min
		new_val = (APP_MAX + APP_MIN) - TitanUtils_Round(val)
	end
	return new_val
end

---local Execute garbage collection for Leftclick on plugin
---@param self Button
---@param watchingCPU boolean
local function Stats_UpdateAddonsList(self, watchingCPU)
	if (watchingCPU) then
		UpdateAddOnCPUUsage()
	else
		UpdateAddOnMemoryUsage()
	end

	local total = 0
	local showAddonRate = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowAddonIncRate");
	for i = 1, NumAddons() do
		local value = (watchingCPU and GetAddOnCPUUsage(i)) or GetAddOnMemoryUsage(i)
		total = total + value

		for j, addon in ipairs(topAddOns) do
			if (value > addon.value) then
				for k = counter, 1, -1 do
					if (k == j) then
						topAddOns[k].value = value
						topAddOns[k].name = AddOnInfo(i)
						break
					elseif (k ~= 1) then
						topAddOns[k].value = topAddOns[k - 1].value
						topAddOns[k].name = topAddOns[k - 1].name
					end
				end
				break
			end
		end
	end

	GameTooltip:AddLine(' ')

	if (total > 0) then
		if (watchingCPU) then
			GameTooltip:AddLine(TitanUtils_GetHexText(L["TITAN_PERFORMANCE_ADDON_CPU_USAGE_LABEL"], Titan_Global.colors.white))
		else
			GameTooltip:AddLine(TitanUtils_GetHexText(L["TITAN_PERFORMANCE_ADDON_MEM_USAGE_LABEL"], Titan_Global.colors.white))
		end

		if not watchingCPU then
			if (showAddonRate == 1) then
				GameTooltip:AddDoubleLine(LIGHTYELLOW_FONT_COLOR_CODE .. L["TITAN_PERFORMANCE_ADDON_NAME_LABEL"],
					LIGHTYELLOW_FONT_COLOR_CODE ..
					L["TITAN_PERFORMANCE_ADDON_USAGE_LABEL"] .. "/" .. L["TITAN_PERFORMANCE_ADDON_RATE_LABEL"] .. ":")
			else
				GameTooltip:AddDoubleLine(LIGHTYELLOW_FONT_COLOR_CODE .. L["TITAN_PERFORMANCE_ADDON_NAME_LABEL"],
					LIGHTYELLOW_FONT_COLOR_CODE .. L["TITAN_PERFORMANCE_ADDON_USAGE_LABEL"] .. ":")
			end
		end

		if watchingCPU then
			GameTooltip:AddDoubleLine(LIGHTYELLOW_FONT_COLOR_CODE .. L["TITAN_PERFORMANCE_ADDON_NAME_LABEL"],
				LIGHTYELLOW_FONT_COLOR_CODE .. L["TITAN_PERFORMANCE_ADDON_USAGE_LABEL"] .. ":")
		end

		for _, addon in ipairs(topAddOns) do
			local wow_addon = TitanUtils_GetHexText(addon.name, Titan_Global.colors.yellow)
			if (watchingCPU) then
				local diff = addon.value / total * 100;
				local incrate = "";
				incrate = format("(%.2f%%)", diff);
				if (showAddonRate == 1) then
					local str = TitanUtils_GetHexText(format("%.3f", addon.value) 
							.. L["TITAN_PANEL_MILLISECOND"], Titan_Global.colors.white)
						.." "
						..TitanUtils_GetHexText(incrate, Titan_Global.colors.green)
					GameTooltip:AddDoubleLine(wow_addon, str)
				else
					local str = TitanUtils_GetHexText(format("%.3f", addon.value) 
						.. L["TITAN_PANEL_MILLISECOND"], Titan_Global.colors.white)
					GameTooltip:AddDoubleLine(wow_addon, str);
				end
			else
				local diff = addon.value - (memUsageSinceGC[addon.name])
				if diff < 0 or memUsageSinceGC[addon.name] == 0 then
					memUsageSinceGC[addon.name] = addon.value;
				end
				local incrate = "";
				if diff > 0 then
					incrate = format("(+%.2f) " .. L["TITAN_PANEL_PERFORMANCE_KILOBYTES_PER_SECOND"], diff);
				end
				local fmt = ""
				local div = 1
				local rate = ""
				if (showAddonRate == 1) then
					if TitanGetVar(TITAN_PERFORMANCE_ID, "AddonMemoryType") == 1 then
						fmt = L["TITAN_PANEL_PERFORMANCE_MEMORY_FORMAT"]
						div = 1000
						rate = TitanUtils_GetHexText(incrate, Titan_Global.colors.green)
					else
						if addon.value > 1000 then
							fmt = L["TITAN_PANEL_PERFORMANCE_MEMORY_FORMAT"]
							div = 1000
							rate = TitanUtils_GetHexText(incrate, Titan_Global.colors.green)
						else
							fmt = L["TITAN_PANEL_PERFORMANCE_MEMORY_FORMAT_KB"]
							rate = TitanUtils_GetHexText(incrate, Titan_Global.colors.green)
						end
					end
				else
					if TitanGetVar(TITAN_PERFORMANCE_ID, "AddonMemoryType") == 1 then
						fmt = L["TITAN_PANEL_PERFORMANCE_MEMORY_FORMAT"]
						div = 1000
					else
						if addon.value > 1000 then
							fmt = L["TITAN_PANEL_PERFORMANCE_MEMORY_FORMAT"]
							div = 1000
						else
							fmt = L["TITAN_PANEL_PERFORMANCE_MEMORY_FORMAT_KB"]
						end
					end
				end
				GameTooltip:AddDoubleLine(wow_addon,
				TitanUtils_GetHexText(format(fmt, addon.value / div), Titan_Global.colors.white)..rate)
			end
		end

		GameTooltip:AddLine(' ')

		if (watchingCPU) then
			GameTooltip:AddDoubleLine(LIGHTYELLOW_FONT_COLOR_CODE .. L["TITAN_PERFORMANCE_ADDON_TOTAL_CPU_USAGE_LABEL"],
				format("%.3f", total) .. L["TITAN_PANEL_MILLISECOND"])
		else
			if TitanGetVar(TITAN_PERFORMANCE_ID, "AddonMemoryType") == 1 then
				GameTooltip:AddDoubleLine(
				LIGHTYELLOW_FONT_COLOR_CODE .. L["TITAN_PERFORMANCE_ADDON_TOTAL_MEM_USAGE_LABEL"],
					format(L["TITAN_PANEL_PERFORMANCE_MEMORY_FORMAT"], total / 1000))
			else
				if total > 1000 then
					GameTooltip:AddDoubleLine(
					LIGHTYELLOW_FONT_COLOR_CODE .. L["TITAN_PERFORMANCE_ADDON_TOTAL_MEM_USAGE_LABEL"],
						format(L["TITAN_PANEL_PERFORMANCE_MEMORY_FORMAT"], total / 1000))
				else
					GameTooltip:AddDoubleLine(
					LIGHTYELLOW_FONT_COLOR_CODE .. L["TITAN_PERFORMANCE_ADDON_TOTAL_MEM_USAGE_LABEL"],
						format(L["TITAN_PANEL_PERFORMANCE_MEMORY_FORMAT_KB"], total))
				end
			end
		end
	end
end

---local Generate tootip text
---@param self Button
local function SetTooltip(self)
	local button = _G["TitanPanelPerformanceButton"];
	local showFPS = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowFPS");
	local showLatency = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowLatency");
	local showWorldLatency = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowWorldLatency")
	local showMemory = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowMemory");
	local showAddonMemory = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowAddonMemory");
	-- Tooltip title
	GameTooltip:SetText(L["TITAN_PERFORMANCE_TOOLTIP"], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g,
		HIGHLIGHT_FONT_COLOR.b);

	-- FPS tooltip
	if (showFPS) then
		local fpsText = format(L["TITAN_PANEL_PERFORMANCE_FPS_FORMAT"], perf_stats.fps);
		local avgFPSText = format(L["TITAN_PANEL_PERFORMANCE_FPS_FORMAT"], perf_stats.avgFPS);
		local minFPSText = format(L["TITAN_PANEL_PERFORMANCE_FPS_FORMAT"], perf_stats.minFPS);
		local maxFPSText = format(L["TITAN_PANEL_PERFORMANCE_FPS_FORMAT"], perf_stats.maxFPS);

		GameTooltip:AddLine("\n");
		GameTooltip:AddLine(TitanUtils_GetHighlightText(L["TITAN_PANEL_PERFORMANCE_FPS_TOOLTIP"]));
		GameTooltip:AddDoubleLine(L["TITAN_PANEL_PERFORMANCE_FPS_TOOLTIP_CURRENT_FPS"],
			TitanUtils_GetHighlightText(fpsText));
		GameTooltip:AddDoubleLine(L["TITAN_PANEL_PERFORMANCE_FPS_TOOLTIP_AVG_FPS"],
			TitanUtils_GetHighlightText(avgFPSText));
		GameTooltip:AddDoubleLine(L["TITAN_PANEL_PERFORMANCE_FPS_TOOLTIP_MIN_FPS"],
			TitanUtils_GetHighlightText(minFPSText));
		GameTooltip:AddDoubleLine(L["TITAN_PANEL_PERFORMANCE_FPS_TOOLTIP_MAX_FPS"],
			TitanUtils_GetHighlightText(maxFPSText));
	end

	-- Latency tooltip
	if (showLatency or showWorldLatency) then
		local latencyText = format(L["TITAN_PANEL_PERFORMANCE_LATENCY_FORMAT"], perf_stats.latencyHome);
		local latencyWorldText = format(L["TITAN_PANEL_PERFORMANCE_LATENCY_FORMAT"], perf_stats.latencyWorld);
		local bandwidthInText = format(L["TITAN_PANEL_PERFORMANCE_LATENCY_BANDWIDTH_FORMAT"], perf_stats.bandwidthIn);
		local bandwidthOutText = format(L["TITAN_PANEL_PERFORMANCE_LATENCY_BANDWIDTH_FORMAT"], perf_stats.bandwidthOut);

		GameTooltip:AddLine("\n");
		GameTooltip:AddLine(TitanUtils_GetHighlightText(L["TITAN_PANEL_PERFORMANCE_LATENCY_TOOLTIP"]));
		if showLatency then GameTooltip:AddDoubleLine(L["TITAN_PANEL_PERFORMANCE_LATENCY_TOOLTIP_LATENCY_HOME"],
				TitanUtils_GetHighlightText(latencyText)); end
		if showWorldLatency then GameTooltip:AddDoubleLine(L["TITAN_PANEL_PERFORMANCE_LATENCY_TOOLTIP_LATENCY_WORLD"],
				TitanUtils_GetHighlightText(latencyWorldText)); end
		GameTooltip:AddDoubleLine(L["TITAN_PANEL_PERFORMANCE_LATENCY_TOOLTIP_BANDWIDTH_IN"],
			TitanUtils_GetHighlightText(bandwidthInText));
		GameTooltip:AddDoubleLine(L["TITAN_PANEL_PERFORMANCE_LATENCY_TOOLTIP_BANDWIDTH_OUT"],
			TitanUtils_GetHighlightText(bandwidthOutText));
	end

	-- Memory tooltip
	if (showMemory) then
		local memoryText = format(L["TITAN_PANEL_PERFORMANCE_MEMORY_FORMAT"], perf_stats.memory / 1024);
		local initialMemoryText = format(L["TITAN_PANEL_PERFORMANCE_MEMORY_FORMAT"], perf_stats.initialMemory / 1024);
		local sessionTime = time() - perf_stats.startSessionTime;
		local rateRichText, timeToGCRichText, rate, timeToGC, color;
		if (sessionTime == 0) then
			rateRichText = TitanUtils_GetHighlightText("N/A");
		else
			rate = (perf_stats.memory - perf_stats.initialMemory) / sessionTime;
			color = TitanUtils_GetThresholdColor(TITAN_MEMORY_RATE_THRESHOLD_TABLE, rate);
			rateRichText = TitanUtils_GetColoredText(format(L["TITAN_PANEL_PERFORMANCE_MEMORY_RATE_FORMAT"], rate), color)
		end
		if (perf_stats.memory == perf_stats.initialMemory) then
			timeToGCRichText = TitanUtils_GetHighlightText("N/A");
		end

		GameTooltip:AddLine("\n");
		GameTooltip:AddLine(TitanUtils_GetHighlightText(L["TITAN_PANEL_PERFORMANCE_MEMORY_TOOLTIP"]));
		GameTooltip:AddDoubleLine(L["TITAN_PANEL_PERFORMANCE_MEMORY_TOOLTIP_CURRENT_MEMORY"],
			TitanUtils_GetHighlightText(memoryText));
		GameTooltip:AddDoubleLine(L["TITAN_PANEL_PERFORMANCE_MEMORY_TOOLTIP_INITIAL_MEMORY"],
			TitanUtils_GetHighlightText(initialMemoryText));
		GameTooltip:AddDoubleLine(L["TITAN_PANEL_PERFORMANCE_MEMORY_TOOLTIP_INCREASING_RATE"], rateRichText);
	end

	if (showAddonMemory == 1) then
		for _, i in pairs(topAddOns) do
			i.name = '';
			i.value = 0;
		end
		Stats_UpdateAddonsList(_G[TITAN_BUTTON], GetCVar('scriptProfile') == '1' and not IsModifierKeyDown())
	end

	GameTooltip:AddLine(TitanUtils_GetGreenText(L["TITAN_PERFORMANCE_TOOLTIP_HINT"]));
end

---local Update real-time data, placing it on the plugin frame
local function UpdateData()
	--	local button = _G["TitanPanelPerformanceButton"];
	local showFPS = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowFPS");
	local showLatency = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowLatency");
	local showWorldLatency = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowWorldLatency")
	local showMemory = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowMemory");
	local showAddonMemory = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowAddonMemory");

	-- FPS Data
	if (showFPS) then
		perf_stats.fps = GetFramerate();
		perf_stats.fpsSampleCount = perf_stats.fpsSampleCount + 1;
		if (perf_stats.fpsSampleCount == 1) then
			perf_stats.minFPS = perf_stats.fps;
			perf_stats.maxFPS = perf_stats.fps;
			perf_stats.avgFPS = perf_stats.fps;
		else
			if (perf_stats.fps < perf_stats.minFPS) then
				perf_stats.minFPS = perf_stats.fps;
			elseif (perf_stats.fps > perf_stats.maxFPS) then
				perf_stats.maxFPS = perf_stats.fps;
			end
			perf_stats.avgFPS = (perf_stats.avgFPS * (perf_stats.fpsSampleCount - 1) + perf_stats.fps) /
			perf_stats.fpsSampleCount;
		end
	end

	-- Latency Data
	if (showLatency or showWorldLatency) then
		-- bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats();
		perf_stats.bandwidthIn, perf_stats.bandwidthOut, perf_stats.latencyHome, perf_stats.latencyWorld = GetNetStats();
	end

	-- Memory data
	if (showMemory) or (showAddonMemory == 1) then
		local previousMemory = perf_stats.memory;
		perf_stats.memory, perf_stats.gcThreshold = gcinfo();
		if (not perf_stats.startSessionTime) then
			-- Initial data
			local i;
			perf_stats.startSessionTime = time();
			perf_stats.initialMemory = perf_stats.memory;

			for i = 1, NumAddons() do
				memUsageSinceGC[AddOnInfo(i)] = GetAddOnMemoryUsage(i)
			end
		elseif (previousMemory and perf_stats.memory and previousMemory > perf_stats.memory) then
			-- Reset data after garbage collection
			local k, i;
			perf_stats.startSessionTime = time();
			perf_stats.initialMemory = perf_stats.memory;

			for k in pairs(memUsageSinceGC) do
				memUsageSinceGC[k] = nil
			end

			for i = 1, NumAddons() do
				memUsageSinceGC[AddOnInfo(i)] = GetAddOnMemoryUsage(i)
			end
		end
	end
end

---local Generate button text using data on the plugin frame
---@param id string
---@return string label
---@return string plugin_text
---@return string | nil label2
---@return string | nil plugin_text2
---@return string | nil label3
---@return string | nil plugin_text3
local function GetButtonText(id)
	--	local button = _G["TitanPanelPerformanceButton"];
	local color, fpsRichText, latencyRichText, memoryRichText;
	local showFPS = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowFPS");
	local showLatency = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowLatency");
	local showWorldLatency = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowWorldLatency")
	local showMemory = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowMemory");

	-- Update real time data
	UpdateData()

	-- FPS text
	if (showFPS) then
		local fpsText = format(L["TITAN_PANEL_PERFORMANCE_FPS_FORMAT"], perf_stats.fps);
		if (TitanGetVar(TITAN_PERFORMANCE_ID, "ShowColoredText")) then
			color = TitanUtils_GetThresholdColor(TITAN_FPS_THRESHOLD_TABLE, perf_stats.fps);
			fpsRichText = TitanUtils_GetColoredText(fpsText, color);
		else
			fpsRichText = TitanUtils_GetHighlightText(fpsText);
		end
	end

	-- Latency text
	latencyRichText = ""
	if (showLatency) then
		local latencyText = format(L["TITAN_PANEL_PERFORMANCE_LATENCY_FORMAT"], perf_stats.latencyHome);
		if (TitanGetVar(TITAN_PERFORMANCE_ID, "ShowColoredText")) then
			color = TitanUtils_GetThresholdColor(TITAN_LATENCY_THRESHOLD_TABLE, perf_stats.latencyHome);
			latencyRichText = TitanUtils_GetColoredText(latencyText, color);
		else
			latencyRichText = TitanUtils_GetHighlightText(latencyText)
		end
	end

	if (showWorldLatency) then
		local latencyWorldText = format(L["TITAN_PANEL_PERFORMANCE_LATENCY_FORMAT"], perf_stats.latencyWorld);
		if (showLatency) then
			latencyRichText = latencyRichText .. "/"
		end
		if (TitanGetVar(TITAN_PERFORMANCE_ID, "ShowColoredText")) then
			color = TitanUtils_GetThresholdColor(TITAN_LATENCY_THRESHOLD_TABLE, perf_stats.latencyWorld);
			latencyRichText = latencyRichText .. TitanUtils_GetColoredText(latencyWorldText, color);
		else
			latencyRichText = latencyRichText .. TitanUtils_GetHighlightText(latencyWorldText);
		end
	end

	-- Memory text
	if (showMemory) then
		local memoryText = format(L["TITAN_PANEL_PERFORMANCE_MEMORY_FORMAT"], perf_stats.memory / 1024);
		memoryRichText = TitanUtils_GetHighlightText(memoryText);
	end

	if (showFPS) then
		if (showLatency or showWorldLatency) then
			if (showMemory) then
				return L["TITAN_PANEL_PERFORMANCE_FPS_BUTTON_LABEL"], fpsRichText,
					L["TITAN_PANEL_PERFORMANCE_LATENCY_BUTTON_LABEL"], latencyRichText,
					L["TITAN_PANEL_PERFORMANCE_MEMORY_BUTTON_LABEL"], memoryRichText;
			else
				return L["TITAN_PANEL_PERFORMANCE_FPS_BUTTON_LABEL"], fpsRichText,
					L["TITAN_PANEL_PERFORMANCE_LATENCY_BUTTON_LABEL"], latencyRichText;
			end
		else
			if (showMemory) then
				return L["TITAN_PANEL_PERFORMANCE_FPS_BUTTON_LABEL"], fpsRichText,
					L["TITAN_PANEL_PERFORMANCE_MEMORY_BUTTON_LABEL"], memoryRichText;
			else
				return L["TITAN_PANEL_PERFORMANCE_FPS_BUTTON_LABEL"], fpsRichText;
			end
		end
	else
		if (showLatency or showWorldLatency) then
			if (showMemory) then
				return L["TITAN_PANEL_PERFORMANCE_LATENCY_BUTTON_LABEL"], latencyRichText,
					L["TITAN_PANEL_PERFORMANCE_MEMORY_BUTTON_LABEL"], memoryRichText;
			else
				return L["TITAN_PANEL_PERFORMANCE_LATENCY_BUTTON_LABEL"], latencyRichText;
			end
		else
			if (showMemory) then
				return L["TITAN_PANEL_PERFORMANCE_MEMORY_BUTTON_LABEL"], memoryRichText;
			else
				return "", ""
			end
		end
	end
end

---local Display Right click menu options
local function CreateMenu()
	local info

	--[[
print("TPref"
.." "..tostring(TitanPanelRightClickMenu_GetDropdownLevel())..""
.." "..tostring(TitanPanelRightClickMenu_GetDropdMenuValue())..""
)
--]]
	-- level 3
	if TitanPanelRightClickMenu_GetDropdownLevel() == 3 and TitanPanelRightClickMenu_GetDropdMenuValue() == "AddonControlFrame" then
		TitanPanelPerfControlFrame:Show()
		return
	end

	-- level 2
	if TitanPanelRightClickMenu_GetDropdownLevel() == 2 then
		if TitanPanelRightClickMenu_GetDropdMenuValue() == "Options" then
			TitanPanelRightClickMenu_AddTitle(L["TITAN_PANEL_OPTIONS"], TitanPanelRightClickMenu_GetDropdownLevel());

			local temptable = { TITAN_PERFORMANCE_ID, "ShowFPS" };
			info = {};
			info.text = L["TITAN_PERFORMANCE_MENU_SHOW_FPS"];
			info.value = temptable;
			info.func = function()
				TitanPanelRightClickMenu_ToggleVar(temptable)
			end
			info.checked = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowFPS");
			info.keepShownOnClick = 1;
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			local temptable = { TITAN_PERFORMANCE_ID, "ShowLatency" };
			info = {};
			info.text = L["TITAN_PERFORMANCE_MENU_SHOW_LATENCY"];
			info.value = temptable;
			info.func = function()
				TitanPanelRightClickMenu_ToggleVar(temptable)
			end
			info.checked = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowLatency");
			info.keepShownOnClick = 1;
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			local temptable = { TITAN_PERFORMANCE_ID, "ShowWorldLatency" };
			info = {};
			info.text = L["TITAN_PERFORMANCE_MENU_SHOW_LATENCY_WORLD"];
			info.value = temptable;
			info.func = function()
				TitanPanelRightClickMenu_ToggleVar(temptable)
			end
			info.checked = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowWorldLatency");
			info.keepShownOnClick = 1;
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			local temptable = { TITAN_PERFORMANCE_ID, "ShowMemory" };
			info = {};
			info.text = L["TITAN_PERFORMANCE_MENU_SHOW_MEMORY"];
			info.value = temptable;
			info.func = function()
				TitanPanelRightClickMenu_ToggleVar(temptable)
			end
			info.checked = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowMemory");
			info.keepShownOnClick = 1;
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		end

		if TitanPanelRightClickMenu_GetDropdMenuValue() == "AddonUsage" then
			TitanPanelRightClickMenu_AddTitle(L["TITAN_PERFORMANCE_ADDONS"], TitanPanelRightClickMenu_GetDropdownLevel());

			local temptable = { TITAN_PERFORMANCE_ID, "ShowAddonMemory" };
			info = {};
			info.text = L["TITAN_PERFORMANCE_MENU_SHOW_ADDONS"];
			info.value = temptable;
			info.func = function()
				TitanPanelRightClickMenu_ToggleVar(temptable)
			end
			info.checked = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowAddonMemory");
			info.keepShownOnClick = 1;
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			local temptable = { TITAN_PERFORMANCE_ID, "ShowAddonIncRate" };
			info = {};
			info.text = L["TITAN_PERFORMANCE_MENU_SHOW_ADDON_RATE"];
			info.value = temptable;
			info.func = function()
				TitanPanelRightClickMenu_ToggleVar(temptable)
			end
			info.checked = TitanGetVar(TITAN_PERFORMANCE_ID, "ShowAddonIncRate");
			info.keepShownOnClick = 1;
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.notCheckable = true
			info.text = L["TITAN_PERFORMANCE_CONTROL_TOOLTIP"]
				.. LIGHTYELLOW_FONT_COLOR_CODE .. tostring(TitanGetVar(TITAN_PERFORMANCE_ID, "NumOfAddons"));
			info.value = "AddonControlFrame"
			info.hasArrow = 1;
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		end

		if TitanPanelRightClickMenu_GetDropdMenuValue() == "AddonMemoryFormat" then
			TitanPanelRightClickMenu_AddTitle(L["TITAN_PERFORMANCE_ADDON_MEM_FORMAT_LABEL"],
				TitanPanelRightClickMenu_GetDropdownLevel());
			info = {};
			info.text = L["TITAN_PANEL_MEGABYTE"];
			info.checked = function()
				if TitanGetVar(TITAN_PERFORMANCE_ID, "AddonMemoryType") == 1 then return true else return nil end
			end
			info.func = function() TitanSetVar(TITAN_PERFORMANCE_ID, "AddonMemoryType", 1) end
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
			info = {};
			info.text = L["TITAN_PANEL_PERFORMANCE_MEMORY_KBMB_LABEL"];
			info.checked = function()
				if TitanGetVar(TITAN_PERFORMANCE_ID, "AddonMemoryType") == 2 then return true else return nil end
			end
			info.func = function() TitanSetVar(TITAN_PERFORMANCE_ID, "AddonMemoryType", 2) end
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		end

		if TitanPanelRightClickMenu_GetDropdMenuValue() == "CPUProfiling" then
			if (GetCVar("scriptProfile") == "1") then
				TitanPanelRightClickMenu_AddTitle(
				L["TITAN_PERFORMANCE_MENU_CPUPROF_LABEL"] .. ": " .. GREEN_FONT_COLOR_CODE ..
				L["TITAN_PANEL_MENU_ENABLED"], TitanPanelRightClickMenu_GetDropdownLevel());
				info = {};
				info.text = L["TITAN_PERFORMANCE_MENU_CPUPROF_LABEL_OFF"] ..
				GREEN_FONT_COLOR_CODE .. L["TITAN_PANEL_MENU_RELOADUI"];
				info.func = function()
					SetCVar("scriptProfile", "0")
					ReloadUI()
				end
				TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
			else
				TitanPanelRightClickMenu_AddTitle(
				L["TITAN_PERFORMANCE_MENU_CPUPROF_LABEL"] .. ": " .. RED_FONT_COLOR_CODE ..
				L["TITAN_PANEL_MENU_DISABLED"], TitanPanelRightClickMenu_GetDropdownLevel());
				info = {};
				info.text = L["TITAN_PERFORMANCE_MENU_CPUPROF_LABEL_ON"] ..
				GREEN_FONT_COLOR_CODE .. L["TITAN_PANEL_MENU_RELOADUI"];
				info.func = function()
					SetCVar("scriptProfile", "1")
					ReloadUI()
				end
				TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
			end
		end
		return
	end

	-- level 1
	TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_PERFORMANCE_ID].menuText);

	info = {};
	info.notCheckable = true
	info.text = L["TITAN_PANEL_OPTIONS"];
	info.value = "Options"
	info.hasArrow = 1;
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.notCheckable = true
	info.text = L["TITAN_PERFORMANCE_ADDONS"];
	info.value = "AddonUsage"
	info.hasArrow = 1;
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.notCheckable = true
	info.text = L["TITAN_PERFORMANCE_ADDON_MEM_FORMAT_LABEL"];
	info.value = "AddonMemoryFormat"
	info.hasArrow = 1;
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.notCheckable = true
	info.text = L["TITAN_PERFORMANCE_MENU_CPUPROF_LABEL"];
	info.value = "CPUProfiling"
	info.hasArrow = 1;
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddControlVars(TITAN_PERFORMANCE_ID)
end

local function Init()
	topAddOns = {}
	-- scan how many addons are active
	local count = NumAddons();
	local ActiveAddons = 0;
	local NumOfAddons = TitanGetVar(TITAN_PERFORMANCE_ID, "NumOfAddons");
	if NumOfAddons == nil then
		NumOfAddons = 5;
		TitanSetVar(TITAN_PERFORMANCE_ID, "NumOfAddons", 5);
	end
	for i = 1, count do
		if IsAddOnLoaded(i) then
			ActiveAddons = ActiveAddons + 1;
		end
	end

	if ActiveAddons < NumOfAddons then
		counter = ActiveAddons;
	else
		counter = NumOfAddons;
	end
	--set the counter to the proper number of active addons that are being monitored
	for i = 1, counter do
		topAddOns[i] = { name = '', value = 0 }
	end
end

---local Create plugin .registry and and init some variables and register for first events
---@param self Button
local function OnLoad(self)
	local notes = ""
		.. "Adds FPS (Frames Per Second) and Garbage collection information to Titan Panel.\n"
	--		.."- xxx.\n"
	self.registry = {
		id = TITAN_PERFORMANCE_ID,
		category = "Built-ins",
		version = TITAN_VERSION,
		menuText = L["TITAN_PERFORMANCE_MENU_TEXT"],
		menuTextFunction = CreateMenu,
		buttonTextFunction = GetButtonText,
		tooltipCustomFunction = SetTooltip,
		icon = "Interface\\AddOns\\TitanPerformance\\TitanPerformance",
		iconWidth = 16,
		notes = notes,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowRegularText = false,
			ShowColoredText = true,
			DisplayOnRightSide = true,
		},
		savedVariables = {
			ShowFPS = 1,
			ShowLatency = 1,
			ShowWorldLatency = 1,
			ShowMemory = 1,
			ShowAddonMemory = false,
			ShowAddonIncRate = false,
			NumOfAddons = 5,
			AddonMemoryType = 1,
			ShowIcon = 1,
			ShowLabelText = false,
			ShowColoredText = 1,
			DisplayOnRightSide = false,
		}
	};

	perf_stats.fpsSampleCount = 0
end

---local Hide the plugin and stop timers
local function OnHide()
	AceTimer:CancelTimer(PerfTimer)
	PerfTimerRunning = false
end

---local Update button data
local function TitanPanelPerformanceButtonHandle_OnUpdate()
	TitanPanelPluginHandle_OnUpdate(updateTable);
	if not (TitanPanelRightClickMenu_IsVisible()) and _G["TitanPanelPerfControlFrame"]:IsVisible() and not (MouseIsOver(_G["TitanPanelPerfControlFrame"])) then
		_G["TitanPanelPerfControlFrame"]:Hide();
	end
end

---local Show the plugin and start timers
local function OnShow()
	Init()

	if PerfTimerRunning then
		-- Do not create a new one
	else
		PerfTimer = AceTimer:ScheduleRepeatingTimer(TitanPanelPerformanceButtonHandle_OnUpdate, 1.5)
		PerfTimerRunning = true
	end
end

---local Handle events registered to plugin
---@param self Button
---@param event string
---@param ... any
local function OnEvent(self, event, ...)
	-- No events to process
end

---local Handle mouse click events registered to plugin; Left click is garbage collection
---@param self Button
---@param button string
local function OnClick(self, button)
	if button == "LeftButton" then
		collectgarbage('collect');
	end
end

---local Position tooltip over slider control
---@param self Button
local function Slider_OnEnter(self)
	self.tooltipText = TitanOptionSlider_TooltipText(L["TITAN_PERFORMANCE_CONTROL_TOOLTIP"],
		TitanGetVar(TITAN_PERFORMANCE_ID, "NumOfAddons"));
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT");
	GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, 1);
end

---local Hide tooltip after leaving slider
---@param self Button
local function Slider_OnLeave(self)
	self.tooltipText = nil;
	GameTooltip:Hide();
end

---local Generate tooltip over slider control
---@param self Slider plugin slider frame
local function Slider_OnShow(self)
	_G[self:GetName() .. "Text"]:SetText(TitanGetVar(TITAN_PERFORMANCE_ID, "NumOfAddons"));
	_G[self:GetName() .. "High"]:SetText(L["TITAN_PERFORMANCE_CONTROL_LOW"]);
	_G[self:GetName() .. "Low"]:SetText(L["TITAN_PERFORMANCE_CONTROL_HIGH"]);
	self:SetMinMaxValues(APP_MIN, APP_MAX);
	self:SetValueStep(1);
	self:SetObeyStepOnDrag(true) -- since 5.4.2 (Mists of Pandaria)
	self:SetValue(CalcAppNum(TitanGetVar(TITAN_PERFORMANCE_ID, "NumOfAddons")));

	local lev = TitanPanelRightClickMenu_GetDropdownLevel() - 1
	local dds = TitanPanelRightClickMenu_GetDropdownFrameBase() .. tostring(lev)
	local drop_down = _G[dds]
	--	local scale = TitanPanelPerfControlFrame:GetScale()
	TitanPanelPerfControlFrame:ClearAllPoints();
	TitanPanelPerfControlFrame:SetPoint("LEFT", drop_down, "RIGHT", 0, 0);
	local offscreenX, offscreenY = TitanUtils_GetOffscreen(TitanPanelPerfControlFrame);
	if offscreenX == -1 or offscreenX == 0 then
		TitanPanelPerfControlFrame:ClearAllPoints();
		TitanPanelPerfControlFrame:SetPoint("LEFT", drop_down, "RIGHT", 0, 0);
	else
		TitanPanelPerfControlFrame:ClearAllPoints();
		TitanPanelPerfControlFrame:SetPoint("RIGHT", drop_down, "LEFT", 0, 0);
	end

	--[[
	local top_point, top_rel_to, top_rel_point, top_x, top_y =
		TitanPanelPerfControlFrame:GetPoint(TitanPanelPerfControlFrame:GetNumPoints())
print("TPref"
.." "..tostring(drop_down:GetName())..""
.." "..tostring(offscreenX)..""
.." "..tostring(offscreenY)..""
)
print("TPref"
.." "..tostring(top_point)..""
.." "..tostring(top_rel_to:GetName())..""
.." "..tostring(top_rel_point)..""
.." "..tostring(top_x)..""
.." "..tostring(top_y)..""
)
--]]
end

---local Display slider tooltip text
---@param self Slider plugin slider frame
---@param a1 number positive or negative change to apply
local function Slider_OnValueChanged(self, a1)
	local val = CalcAppNum(self:GetValue()) -- grab new value

	_G[self:GetName() .. "Text"]:SetText(val);
	--[[
	if a1 == -1 then
		self:SetValue(self:GetValue() + 1);
	end

	if a1 == 1 then
		self:SetValue(self:GetValue() - 1);
	end
--]]
	TitanSetVar(TITAN_PERFORMANCE_ID, "NumOfAddons", val);

	topAddOns = {};
	-- scan how many addons are active
	local count = NumAddons();
	local ActiveAddons = 0;
	for i = 1, count do
		if IsAddOnLoaded(i) then
			ActiveAddons = ActiveAddons + 1;
		end
	end

	if ActiveAddons < TitanGetVar(TITAN_PERFORMANCE_ID, "NumOfAddons") then
		counter = ActiveAddons;
	else
		counter = TitanGetVar(TITAN_PERFORMANCE_ID, "NumOfAddons");
	end

	--set the counter to the proper number of active addons that are being monitored
	for idx = 1, counter do
		topAddOns[idx] = { name = '', value = 0 }
	end

	-- Update GameTooltip
	if (perf_stats.tooltipText) then
		perf_stats.tooltipText = TitanOptionSlider_TooltipText(L["TITAN_PERFORMANCE_CONTROL_TOOLTIP"], tostring(val))
		GameTooltip:SetText(perf_stats.tooltipText, nil, nil, nil, nil, 1);
	end
end

---local Create performance menu / control frame
---@param self Frame
local function Control_OnLoad(self)
	_G[self:GetName() .. "Title"]:SetText(L["TITAN_PERFORMANCE_CONTROL_TITLE"]);
	TitanPanelRightClickMenu_SetCustomBackdrop(self)
end

---local If dropdown is visible, see if its timer has expired.  If expired, hide frame.
---@param self Frame
---@param elapsed number
local function Control_OnUpdate(self, elapsed)
	--	local drop_down = TitanPanelRightClickMenu_GetDropdownFrame()

	if not MouseIsOver(_G["TitanPanelPerfControlFrame"])
	then
		TitanUtils_CheckFrameCounting(self, elapsed);
	end
end

---local Create needed frames
local function Create_Frames()
	if _G[TITAN_BUTTON] then
		return -- if already created
	end

	-- general container frame
	local f = CreateFrame("Frame", nil, UIParent)
	--	f:Hide()

	-- Titan plugin button
	local window = CreateFrame("Button", TITAN_BUTTON, f, "TitanPanelComboTemplate")
	window:SetFrameStrata("FULLSCREEN")
	-- Using SetScript("OnLoad",   does not work
	OnLoad(window);
	--	TitanPanelButton_OnLoad(window); -- Titan XML template calls this...

	window:SetScript("OnShow", function(self)
		OnShow()
		TitanPanelButton_OnShow(self)
	end)
	window:SetScript("OnHide", function(self)
		OnHide()
	end)
	window:SetScript("OnEvent", function(self, event, ...)
		OnEvent(self, event, ...)
	end)
	window:SetScript("OnClick", function(self, button)
		OnClick(self, button)
		TitanPanelButton_OnClick(self, button)
	end)


	---[===[
	-- Config screen
	local cname = "TitanPanelPerfControlFrame"
	local config = CreateFrame("Frame", cname, f, BackdropTemplateMixin and "BackdropTemplate")
	config:SetFrameStrata("FULLSCREEN")
	config:Hide()
	config:SetWidth(120)
	config:SetHeight(170)

	config:SetScript("OnEnter", function(self)
		TitanUtils_StopFrameCounting(self)
	end)
	config:SetScript("OnLeave", function(self)
		TitanUtils_StartFrameCounting(self, 0.5)
	end)
	config:SetScript("OnUpdate", function(self, elapsed)
		Control_OnUpdate(self, elapsed)
	end)

	-- Config Title
	local str = nil
	local style = "GameFontNormalSmall"
	str = config:CreateFontString(cname .. "Title", "ARTWORK", style)
	str:SetPoint("TOP", config, 0, -10)

	-- Config slider sections
	local slider = nil

	-- Hours offset
	local inherit = "TitanOptionsSliderTemplate"
	local offset = CreateFrame("Slider", "TitanPanelPerfControlSlider", config, inherit)
	offset:SetPoint("TOP", config, 0, -40)
	offset:SetScript("OnShow", function(self)
		Slider_OnShow(self)
	end)
	offset:SetScript("OnValueChanged", function(self, value)
		Slider_OnValueChanged(self, value)
	end)
	offset:SetScript("OnMouseWheel", function(self, delta)
		Slider_OnValueChanged(self, delta)
	end)
	offset:SetScript("OnEnter", function(self)
		Slider_OnEnter(self)
	end)
	offset:SetScript("OnLeave", function(self)
		Slider_OnLeave(self)
	end)

	-- Now that the parts exist, initialize
	Control_OnLoad(config)

	--]===]
end


if TITAN_ID then -- it exists
	Create_Frames() -- do the work
end
