local SUI = SUI
local module = SUI:NewModule('LibsToolkit') ---@type SUI.Module
local L = SUI.L
module.DisplayName = "Lib's Toolkit"
module.HideModule = true
----------------------------------------------------------------------------------------------------

local function SetupTweaks()
	if SUI.IsClassic then
		return
	end

	-- Access LibAT from global namespace (not LibStub)
	local LibAT = _G.LibAT

	local LibsToolkit = {
		ID = 'LibsToolkit',
		Name = "Lib's Toolkit",
		SubTitle = "Lib's Toolkit",
		Desc1 = 'Below are a collection of tweaks I find myself making often, so I decided to add them in here.',
		Display = function()
			local SUI_Win = SUI.Setup.window.content

			local CheckboxItem = {}
			SetCVar('nameplateShowSelf', 0)
			SetCVar('autoLootDefault', 1)
			SetCVar('nameplateShowAll', 1)
			SetCVar('nameplateMotion', 0)

			--Container
			local LibsToolkit = CreateFrame('Frame', nil)
			LibsToolkit:SetParent(SUI_Win)
			LibsToolkit:SetAllPoints(SUI_Win)
			if SUI:IsModuleEnabled('LibsToolkit') then
				local LDBIcon = LibStub('LibDBIcon-1.0')
				local Nameplate = LibAT.UI.CreateCheckbox(LibsToolkit, 'Disable ' .. DISPLAY_PERSONAL_RESOURCE)
				local AutoLoot = LibAT.UI.CreateCheckbox(LibsToolkit, 'Enable AutoLoot')
				local ShowNameplates = LibAT.UI.CreateCheckbox(LibsToolkit, 'Enable ' .. UNIT_NAMEPLATES_AUTOMODE)
				local DisableTutorials = LibAT.UI.CreateCheckbox(LibsToolkit, 'Disable ALL tutorials')
				local DisableTutorialsWarning = LibAT.UI.CreateLabel(LibsToolkit, 'For experienced players only')
				DisableTutorialsWarning:SetTextColor(1, 0, 0, 0.7)

				Nameplate:SetChecked(true)
				AutoLoot:SetChecked(true)
				ShowNameplates:SetChecked(true)
				-- If the user has more than 2 SUI Profile they should be 'experienced' so check this by default
				local tmpprofiles = {}
				if #SUI.SpartanUIDB:GetProfiles(tmpprofiles) >= 2 then
					DisableTutorials:SetChecked(true)
				end

				Nameplate:HookScript(
					'OnClick',
					function()
						if Nameplate:GetValue() or false then
							SetCVar('nameplateShowSelf', 0)
						else
							SetCVar('nameplateShowSelf', 1)
						end
					end
				)
				AutoLoot:HookScript(
					'OnClick',
					function()
						if AutoLoot:GetValue() or false then
							SetCVar('autoLootDefault', 1)
						else
							SetCVar('autoLootDefault', 0)
						end
					end
				)
				ShowNameplates:HookScript(
					'OnClick',
					function()
						if ShowNameplates:GetValue() or false then
							SetCVar('nameplateShowAll', 1)
						else
							SetCVar('nameplateShowAll', 0)
						end
					end
				)

				CheckboxItem['tut'] = DisableTutorials
				CheckboxItem['prd'] = Nameplate
				CheckboxItem['autoloot'] = AutoLoot
				CheckboxItem['nameplate'] = ShowNameplates

				if DBM_MinimapIcon then
					DBM_MinimapIcon.hide = true
					local DBMMinimap = LibAT.UI.CreateCheckbox(LibsToolkit, 'Hide DBM Minimap Icon')
					DBMMinimap:SetChecked(true)
					DBMMinimap:HookScript(
						'OnClick',
						function()
							DBM_MinimapIcon.hide = (not DBMMinimap:GetChecked() or false)
							if DBMMinimap:GetChecked() or false then
								LDBIcon:Hide('DBM')
							else
								LDBIcon:Show('DBM')
							end
						end
					)
					CheckboxItem['dbm'] = DBMMinimap
				end

				if Bartender4 then
					Bartender4.db.profile.minimapIcon.hide = true
					LDBIcon:Hide('Bartender4')

					local BT4MiniMap = LibAT.UI.CreateCheckbox(LibsToolkit, 'Hide Bartender4 Minimap Icon')
					BT4MiniMap:SetChecked(true)
					BT4MiniMap:HookScript(
						'OnClick',
						function()
							Bartender4.db.profile.minimapIcon.hide = (not BT4MiniMap:GetChecked() or false)
							if BT4MiniMap:GetChecked() or false then
								LDBIcon:Hide('Bartender4')
							else
								LDBIcon:Show('Bartender4')
							end
						end
					)
					CheckboxItem['bt4'] = BT4MiniMap
				end

				if WeakAurasSaved then
					WeakAurasSaved.minimap.hide = true
					LDBIcon:Hide('WeakAuras')

					local WAMiniMap = LibAT.UI.CreateCheckbox(LibsToolkit, 'Hide WeakAuras Minimap Icon')
					WAMiniMap:SetChecked(true)
					WAMiniMap:HookScript(
						'OnClick',
						function()
							Bartender4.db.profile.minimapIcon.hide = (not WAMiniMap:GetChecked() or false)
							if WAMiniMap:GetChecked() or false then
								LDBIcon:Hide('WeakAuras')
							else
								LDBIcon:Show('WeakAuras')
							end
						end
					)
					CheckboxItem['wa'] = WAMiniMap
				end

				local lastItem = false
				for k, v in pairs(CheckboxItem) do
					if not lastItem then
						SUI.UI.GlueTop(v, LibsToolkit, 0, -30)
					else
						SUI.UI.GlueBelow(v, lastItem, 0, -10)
					end
					lastItem = v
				end

				SUI.UI.GlueRight(DisableTutorialsWarning, DisableTutorials, -85, 0)

				LibsToolkit.DisableTutorials = DisableTutorials
			else
				LibsToolkit.lblDisabled = LibAT.UI.CreateLabel(LibsToolkit, 'Disabled', 'GameFontNormalLarge')
				LibsToolkit.lblDisabled:SetPoint('CENTER', LibsToolkit)
			end

			SUI_Win.LibsToolkit = LibsToolkit
		end,
		Next = function()
			if SUI:IsModuleEnabled('LibsToolkit') then
				local LibsToolkit = SUI.Setup.window.content.LibsToolkit
				if LibsToolkit.DisableTutorials:GetValue() or false then
					local bitfieldListing = {
						LE_FRAME_TUTORIAL_ACCCOUNT_RAF_INTRO,
						LE_FRAME_TUTORIAL_ACCCOUNT_CLUB_FINDER_NEW_FEATURE,
						LE_FRAME_TUTORIAL_ACCOUNT_CLUB_FINDER_NEW_COMMUNITY_JOINED,
						LE_FRAME_TUTORIAL_ARTIFACT_APPEARANCE_TAB,
						LE_FRAME_TUTORIAL_ARTIFACT_RELIC_MATCH,
						LE_FRAME_TUTORIAL_AZERITE_FIRST_POWER_LOCKED_IN,
						LE_FRAME_TUTORIAL_AZERITE_ITEM_IN_BAG,
						LE_FRAME_TUTORIAL_AZERITE_ITEM_IN_SLOT,
						LE_FRAME_TUTORIAL_AZERITE_RESPEC,
						LE_FRAME_TUTORIAL_BONUS_ROLL_ENCOUNTER_JOURNAL_LINK,
						LE_FRAME_TUTORIAL_BOOSTED_SPELL_BOOK,
						LE_FRAME_TUTORIAL_BOUNTY_FINISHED,
						LE_FRAME_TUTORIAL_BOUNTY_INTRO,
						LE_FRAME_TUTORIAL_BRAWL,
						LE_FRAME_TUTORIAL_CHAT_CHANNELS,
						LE_FRAME_TUTORIAL_CLUB_FINDER_LINKING,
						LE_FRAME_TUTORIAL_CORRUPTION_CLEANSER,
						LE_FRAME_TUTORIAL_FRIENDS_LIST_QUICK_JOIN,
						LE_FRAME_TUTORIAL_GAME_TIME_AUCTION_HOUSE,
						LE_FRAME_TUTORIAL_GARRISON_BUILDING,
						LE_FRAME_TUTORIAL_GARRISON_LANDING,
						LE_FRAME_TUTORIAL_GARRISON_ZONE_ABILITY,
						LE_FRAME_TUTORIAL_HEIRLOOM_JOURNAL,
						LE_FRAME_TUTORIAL_HEIRLOOM_JOURNAL_LEVEL,
						LE_FRAME_TUTORIAL_HEIRLOOM_JOURNAL_TAB,
						LE_FRAME_TUTORIAL_INVENTORY_FIXUP_CHECK_EXPANSION_LEGION,
						LE_FRAME_TUTORIAL_INVENTORY_FIXUP_EXPANSION_LEGION,
						LE_FRAME_TUTORIAL_ISLANDS_QUEUE_BUTTON,
						LE_FRAME_TUTORIAL_ISLANDS_QUEUE_INFO_FRAME,
						LE_FRAME_TUTORIAL_LFG_LIST,
						LE_FRAME_TUTORIAL_MOUNT_EQUIPMENT_SLOT_FRAME,
						LE_FRAME_TUTORIAL_PET_JOURNAL,
						LE_FRAME_TUTORIAL_PROFESSIONS,
						LE_FRAME_TUTORIAL_PVP_SPECIAL_EVENT,
						LE_FRAME_TUTORIAL_PVP_TALENTS_FIRST_UNLOCK,
						LE_FRAME_TUTORIAL_PVP_WARMODE_UNLOCK,
						LE_FRAME_TUTORIAL_REAGENT_BANK_UNLOCK,
						LE_FRAME_TUTORIAL_REPUTATION_EXALTED_PLUS,
						LE_FRAME_TUTORIAL_SPEC,
						LE_FRAME_TUTORIAL_SPELLBOOK,
						LE_FRAME_TUTORIAL_TALENT,
						LE_FRAME_TUTORIAL_TOYBOX,
						LE_FRAME_TUTORIAL_TOYBOX_FAVORITE,
						LE_FRAME_TUTORIAL_TOYBOX_MOUSEWHEEL_PAGING,
						LE_FRAME_TUTORIAL_TRADESKILL_RANK_STAR,
						LE_FRAME_TUTORIAL_TRADESKILL_UNLEARNED_TAB,
						LE_FRAME_TUTORIAL_TRANSMOG_JOURNAL_TAB,
						LE_FRAME_TUTORIAL_TRANSMOG_MODEL_CLICK,
						LE_FRAME_TUTORIAL_TRANSMOG_MODEL_CLICK,
						LE_FRAME_TUTORIAL_TRANSMOG_OUTFIT_DROPDOWN,
						LE_FRAME_TUTORIAL_TRANSMOG_SETS_TAB,
						LE_FRAME_TUTORIAL_TRANSMOG_SETS_VENDOR_TAB,
						LE_FRAME_TUTORIAL_TRANSMOG_SPECS_BUTTON,
						LE_FRAME_TUTORIAL_TRIAL_BANKED_XP,
						LE_FRAME_TUTORIAL_WARFRONT_RESOURCES,
						LE_FRAME_TUTORIAL_WARFRONT_CONSTRUCTION,
						LE_FRAME_TUTORIAL_WORLD_MAP_FRAME,
						LE_FRAME_TUTORIAL_WORLD_MAP_THREAT_ICON,
						LE_FRAME_TUTORIAL_QUEST_SESSION,
						LE_FRAME_TUTORIAL_CLUB_FINDER_NEW_GUILD_LEADER,
						LE_FRAME_TUTORIAL_CLUB_FINDER_NEW_COMMUNITY_LEADER,
						LE_FRAME_TUTORIAL_CLUB_FINDER_NEW_APPLICANTS_GUILD_LEADER,
						LE_FRAME_TUTORIAL_CLUB_FINDER_LINKING
					}
					for i, v in ipairs(bitfieldListing) do
						if v then
							SetCVarBitfield('closedInfoFrames', v, true)
						end
					end
					SetCVar('showTutorials', 0)
				end
			end
		end
	}
	SUI.Setup:AddPage(LibsToolkit)
end

function module:OnInitialize()
	SetupTweaks()
end

function module:OnEnable()
end

function module:Options()
end
