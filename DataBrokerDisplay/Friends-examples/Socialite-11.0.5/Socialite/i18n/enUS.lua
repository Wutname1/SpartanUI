-- @todo pull from localization
local
  ---@class string
  addonName,
  ---@class ns
  addon = ...

local L = {}

-- Configuration options

L["Battle.net Friends"] = "Battle.net Friends"
L["ShowRealID"] = "Show friends"
L["ShowRealIDDescription"] = "Show friends in the data text and tooltip."
L["ShowRealIDApp"] = "Show non-playing friends"
L["ShowRealIDAppDescription"] = "If enabled, show all Battle.net friends, regardless of in-game status."
L["ShowRealIDBroadcasts"] = "Show broadcasts/toasts"
L["ShowRealIDBroadcastsDescription"] = "Show Battle.net friend broadcasts in the tooltip."
L["ShowRealIDFactions"] = "Show friends faction"
L["ShowRealIDFactionsDescription"] = "Show the faction of your Battle.net friends"
L["ShowRealIDNotes"] = "Show friend note"
L["ShowRealIDNotesDescription"] = "Show your friends' note"
L["showInAddonCompartment"] = "Show in compartment"
L["showInAddonCompartmentDescription"] = "Toggles the display of Socialite within the addon compartment."
L["Data text"] = "Data text"
L["Tooltip Width"] = "Extra Tooltip Width"

L["Character Friends"] = "Character Friends"
L["ShowFriends"] = "Show friends"
L["ShowFriendsDescription"] = "Include character friends in the tooltip"
L["ShowFriendsNote"] = "Show friend note"
L["ShowFriendsNoteDescription"] = "Show your character friends' note"

L["Guild Members"] = "Guild Members"
L["ShowGuild"] = "Show guild members"
L["ShowGuildDescription"] = "If enabled, display guild members on the tooltip."
L["ShowGuildLabel"] = "Show guild label"
L["ShowGuildLabelDescription"] = "If enabled, the data text will be prefixed with the guild name."
L["ShowGuildNote"] = "Show guild note"
L["ShowGuildNoteDescription"] = "If enabled, the guild member's public note will be displayed in the tooltip."
L["ShowGuildONote"] = "Show officer note"
L["ShowGuildONoteDescription"] = "If enabled, the guild member's officer note will be displayed in the tooltip."
L["ShowSplitRemoteChat"] = "Separate remote chat"
L["ShowSplitRemoteChatDescription"] = "If enabled, guild members utilizing the remote chat feature will be displayed separately within the data text and tooltip."

L["Guild Sorting"] = "Guild Sorting"
L["GuildSort"] = "Custom Sort"
-- L["GuildSortDescription"] = "If enabled, the following options will be used to sort the guild members. If disabled, the most recently used guild sort options will be used instead."
-- L["GuildSortInverted"] = "Invert sort direction"
-- L["GuildSortInvertedDescription"] = "GuildSortInvertedDescription"
L["GuildSortKey"] = "GuildSortKey"
-- L["GuildSortKeyDescription"] = "GuildSortKeyDescription"

L["GuildSortAscending"] = "Ascending"
L["GuildSortAscendingDescription"] = "Sort in ascending (1..9 or A...Z) order"

L["Tooltip Settings"] = "Tooltip Settings"
L["ShowStatus"] = "ShowStatus"
L["ShowStatusDescription"] = "ShowStatusDescription"
L["TooltipInteraction"] = "TooltipInteraction"
L["TooltipInteractionDescription"] = "TooltipInteractionDescription"


-- Messages
-- L["No currencies can be displayed."] = "No currencies can be displayed.";
-- L["usageDescription"] = "Left-click to view currencies. Right-click to configure."
-- L["Settings have been reset to defaults."] = "Settings have been reset to defaults."

-- Labels
L["Socialite"] = "Socialite";
L["TOOLTIP"] = "Social"
L["TOOLTIP_REALID"] = "Battle.net Friends Online"
L["TOOLTIP_REALID_APP"] = "Battle.net Friends in App"
L["TOOLTIP_FRIENDS"] = "Friends Online"
L["TOOLTIP_GUILD"] = "Guild Members Online"
L["TOOLTIP_REMOTE_CHAT"] = "Remote Chat"
L["TOOLTIP_COLLAPSED"] = "(collapsed, click to expand)"

L["MENU_STATUS"] = "Show status as";
L["MENU_STATUS_DESCRIPTION"] = "Show friend's online presence as...";
L["MENU_STATUS_ICON"] = "Icon";
L["MENU_STATUS_TEXT"] = "Text";
L["MENU_STATUS_NONE"] = "None";
L["MENU_STATUS_ICON_DESCRIPTION"] = "When selected, the friend's status will be displayed by an icon, such as |T"..FRIENDS_TEXTURE_DND..":0|t";
L["MENU_STATUS_TEXT_DESCRIPTION"] = "When selected, the friend's status will be indicated by a text string, such as <Away>";
L["MENU_STATUS_NONE_DESCRIPTION"] = "When selected, the friend's status will not be displayed.";

L["MENU_INTERACTION"] = "Tooltip interaction"
L["MENU_INTERACTION_DESCRIPTION"] = "When should the tooltip be interactable?"
L["MENU_INTERACTION_ALWAYS"] = "Always"
L["MENU_INTERACTION_OOC"] = "Out Of Combat"
L["MENU_INTERACTION_NEVER"] = "Never"
L["MENU_INTERACTION_ALWAYS_DESCRIPTION"] = "MENU_INTERACTION_ALWAYS_DESCRIPTION"
L["MENU_INTERACTION_OOC_DESCRIPTION"] = "MENU_INTERACTION_OOC_DESCRIPTION"
L["MENU_INTERACTION_NEVER_DESCRIPTION"] = "MENU_INTERACTION_NEVER_DESCRIPTION"

L["MENU_GUILD_SORT"] = "Sort by"
-- L["MENU_GUILD_SORT_DEFAULT"] = "Use Guild Roster Sort"
L["MENU_GUILD_SORT_NAME"] = "Name"
L["MENU_GUILD_SORT_NAME_DESCRIPTION"] = "Sort by guild member name"
L["MENU_GUILD_SORT_RANK"] = "Rank"
L["MENU_GUILD_SORT_RANK_DESCRIPTION"] = "Sort by guild member rank"
L["MENU_GUILD_SORT_CLASS"] = "Class"
L["MENU_GUILD_SORT_CLASS_DESCRIPTION"] = "Sort by guild member class"
L["MENU_GUILD_SORT_NOTE"] = "Note"
L["MENU_GUILD_SORT_NOTE_DESCRIPTION"] = "Sort by guild member note"
L["MENU_GUILD_SORT_LEVEL"] = "Level"
L["MENU_GUILD_SORT_LEVEL_DESCRIPTION"] = "Sort by guild member level"
L["MENU_GUILD_SORT_ZONE"] = "Zone"
L["MENU_GUILD_SORT_ZONE_DESCRIPTION"] = "Sort by guild member zone/login date"
-- L["MENU_GUILD_SORT_ASCENDING"] = "Ascending"
-- L["MENU_GUILD_SORT_DESCENDING"] = "Descending"

L['Display Settings'] = 'Display Settings'
L['Show minimap button'] = 'Show minimap button'
L['Show the Scoreboard minimap button'] = 'Show the Scoreboard minimap button'
L["usageDescription"] = "Left-click to view social panes. Alt+Click to invite. Right-click to configure."

L['ShowGroupMembers'] = "Show Group Members"
L['ShowGroupMembersDescription'] = "Show an indicator icon next to a friend when in the same group"

L["ShowLabel"] = "Show label"
L["ShowLabelDescription"] = "If enabled, the addon label (or guild name, if enabled) will be shown in the data text."

L["DisableUsageText"] = "Disable usage text"
L["DisableUsageTextDescription"] = "If checked, the usage instructions will not be shown on the tooltip."

addon.L = L
