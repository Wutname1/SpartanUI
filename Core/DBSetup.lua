local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local module = spartan:NewModule("DBSetup");
-----------------------------------
--	This File is being Phased out.
-----------------------------------
if (spartan.CurseVersion == nil) then spartan.CurseVersion = "" end

function module:OnInitialize()
	-- DB Updates
	spartan:DBUpdates()
end
local artdetup
function spartan:DBUpdates()
	if SUI.DBG.Version and DB.Version then
		if (DB.Version < "4.0.0") then
			if DBMod.PlayerFrames.ClassBar.scale == nil then DBMod.PlayerFrames.ClassBar.scale = 1 end
			if DB.MiniMap.northTag == nil then DB.MiniMap.northTag = false end
			if DB.MiniMap.SUIMapChangesActive == nil then DB.MiniMap.SUIMapChangesActive = false end
			if DB.MiniMap.Moved == nil then
				DB.MiniMap.Shape = "square"
				DB.MiniMap.Moved = false
				DB.MiniMap.Position = nil
			end
			if DB.Styles.Classic.Artwork == true then
				DB.Styles.Classic.Artwork = {}
				DB.Styles.Classic.PlayerFrames = {}
				DB.Styles.Classic.PartyFrames = {}
				DB.Styles.Classic.RaidFrames = {}
			end
			if DB.Styles.Classic.Movable == nil then
				DB.Styles.Classic.Movable = {
					Minimap = false,
					PlayerFrames = true,
					PartyFrames = true,
					RaidFrames = true,
				}
			end
			if DB.Styles.Classic.Minimap == nil then
				Minimap = {
					shape = "circle",
					size = {width = 140, height = 140}
				}
			end
			if DB.MiniMap.MouseIsOver == nil then DB.MiniMap.MouseIsOver = false; end
			if DB.EnabledComponents == nil then DB.EnabledComponents = {} end
			if DBMod.PlayerFrames.Style == nil then DBMod.PlayerFrames.Style = DBMod.Artwork.Style; end
			if DBMod.PartyFrames.Style == nil then DBMod.PartyFrames.Style = DBMod.Artwork.Style; end
			if DBMod.RaidFrames.Style == nil then DBMod.RaidFrames.Style = DBMod.Artwork.Style; end
			if DBMod.PlayerFrames.PetPortrait == nil then DBMod.PlayerFrames.PetPortrait = true end
			if DBMod.PlayerFrames.ClassBar.scale == nil then DBMod.PlayerFrames.ClassBar.scale = 1 end
			if DBMod.PlayerFrames.Style == "theme" then DBMod.PlayerFrames.Style = DBMod.Artwork.Style end
			if DBMod.PlayerFrames.pet.moved == nil then
				DBMod.PlayerFrames.pet.moved=false
				DBMod.PlayerFrames.target.moved=false
				DBMod.PlayerFrames.targettarget.moved=false
				DBMod.PlayerFrames.focus.moved=false
				DBMod.PlayerFrames.focustarget.moved=false
				DBMod.PlayerFrames.player.moved=false
			end
			if DBMod.PlayerFrames.boss == nil then DBMod.PlayerFrames.boss.moved=false end
			if DBMod.RaidFrames.mode == "group" then DBMod.RaidFrames.mode = "GROUP" end
			if DB.MiniMap.OtherStyle == nil then DB.MiniMap.OtherStyle = "mouseover" end
			if DB.MiniMap.BlizzStyle == nil then DB.MiniMap.BlizzStyle = "mouseover" end
			if DBMod.RaidFrames.mode == "group" then DBMod.RaidFrames.mode = "GROUP" end
			if DBMod.RaidFrames.mode == "role" then DBMod.RaidFrames.mode = "ASSIGNEDROLE" end
			if DB.Styles.Classic.TooltipLoc == nil then DB.Styles.Classic.TooltipLoc = true end
		end
	end
end

function module:OnEnable()
	-- Update DB Version
	DB.Version = spartan.SpartanVer;
	DB.HVer = (string.gsub(string.gsub(spartan.CurseVersion, "%.", ""), "[0-9]", ""))
	SUI.DBG.Version = spartan.SpartanVer;
end