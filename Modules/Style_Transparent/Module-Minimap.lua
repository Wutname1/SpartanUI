local _G, SUI = _G, SUI
local Artwork_Core = SUI:GetModule("Artwork_Core")
local module = SUI:GetModule("Style_Transparent")
---------------------------------------------------------------------------
local Minimap_Conflict_msg = true
local BlizzButtons = {
	"MiniMapTracking",
	"MiniMapVoiceChatFrame",
	"MiniMapWorldMapButton",
	"QueueStatusMinimapButton",
	"MinimapZoomIn",
	"MinimapZoomOut",
	"MiniMapMailFrame",
	"MiniMapBattlefieldFrame",
	"GameTimeFrame",
	"FeedbackUIButton"
}
local BlizzUI = {
	"ActionBar",
	"BonusActionButton",
	"MainMenu",
	"ShapeshiftButton",
	"MultiBar",
	"KeyRingButton",
	"PlayerFrame",
	"TargetFrame",
	"PartyMemberFrame",
	"ChatFrame",
	"ExhaustionTick",
	"TargetofTargetFrame",
	"WorldFrame",
	"ActionButton",
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"TalentMicroButton",
	"QuestLogMicroButton",
	"SocialsMicroButton",
	"LFGMicroButton",
	"HelpMicroButton",
	"CharacterBag",
	"PetFrame",
	"MinimapCluster",
	"MinimapBackdrop",
	"UIParent",
	"WorldFrame",
	"Minimap",
	"BuffButton",
	"BuffFrame",
	"TimeManagerClockButton",
	"CharacterFrame"
}
local BlizzParentStop = {"WorldFrame", "Minimap", "MinimapBackdrop", "UIParent", "MinimapCluster"}
local SUIMapChangesActive = false
local SkinProtect = {
	"TutorialFrameAlertButton",
	"MiniMapMailFrame",
	"MinimapBackdrop",
	"MiniMapVoiceChatFrame",
	"TimeManagerClockButton",
	"MinimapButtonFrameDragButton",
	"GameTimeFrame",
	"MiniMapTracking",
	"MiniMapVoiceChatFrame",
	"MiniMapWorldMapButton",
	"QueueStatusMinimapButton",
	"MinimapZoomIn",
	"MinimapZoomOut",
	"MiniMapMailFrame",
	"MiniMapBattlefieldFrame",
	"GameTimeFrame",
	"FeedbackUIButton"
}

function Transparent_MiniMapCreate()
	Minimap:SetSize(130, 130)
	Minimap:ClearAllPoints()
	Minimap:SetPoint("CENTER", "Transparent_SpartanUI", "CENTER", 0, -5)

	Transparent_SpartanUI:HookScript(
		"OnHide",
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetPoint("TOP", UIParent, "TOP", 0, -15)
		end
	)

	Transparent_SpartanUI:HookScript(
		"OnShow",
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetPoint("CENTER", "Transparent_SpartanUI", "CENTER", 0, -5)
		end
	)

	module.handleBuff = true
end

function module:InitMinimap()
end

function module:EnableMinimap()
	if (SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse) then
		Transparent_MiniMapCreate()
	end
end
