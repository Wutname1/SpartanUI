--[[ Titan Example with Explanation

This example will introduce Titan plugin essentials using a Titan plugin loosely based on Titan Bag. 
The intent is to clarify what may appear to be a daunting experience. 

We suggest you grab your favorite beverage, read this doc, and relax! 
Many of Titan mysteries will be explained. Helping you create a tool your audience will enjoy. 🙂

The Titan team and its users are available to answer questions.
The two most used ways are : 
- The Titan Discord community - https://discord.gg/e93sxuSPwC 
- Curse comments under Titan Panel addon

Using a text editor with code folding features will make this file easier to read and find information.
Notepad++ is a popular Windows code editor.
Visual Studio Code with a couple extensions can be used to develop WoW addons.
--]]

--[[ Titan Panel Notes:
- Use the current version of Titan to ensure no errors.
- You may freely use this example for addon development and publish it on WoW addon sites like Curseforge. If published, please add the Titan tag for users.
- The terms addon and plugin are essentially the same. Within this document, plugin is used when the addon is displayed by Titan.
- Titan includes several libraries under the Titan/libs folder. You are free to use these. 
If you require additional libraries, please include them within your addon.

=== Out of Scope Notes:
- A discussion on Lua syntax. A basic understanding of Lua is assumed.
- Timers are outside the scope of this example. See other Titan built-in plugins that use timers (AceTimer) such as TitanClock.
- Localization of strings presented to the user. Titan uses AceLocale; other addons use different schemes.
- Ace library information. Titan includes the Ace libraries it uses - not the entire library. (https://www.wowace.com)
- The API for LDB (LibDataBroker) : (https://github.com/tekkub/libdatabroker-1-1)
- WoW images : Some image type info (https://warcraft.wiki.gg/wiki/API_TextureBase_SetTexture)
--]]

--[[ “Best Practices” When Creating Your Addon/Plugin
=== Naming Convention
When publishing your addon/plugin please use this naming convention :

Titan Panel [Name]

Using this naming format, most Titan users will understand this plugin is intended for Titan Panel. 
They should know to contact you first instead of the Titan Panel team. 
The Titan team does receive comments and errors from time to time. We usually tell them to contact the plugin developer.

=== Additional Help For You
A good Lua resource is https://www.lua.org/docs.html
NOTE: WoW uses Lua version 5.1 as its base.
NOTE: WoW does restrict, add, or even remove some Lua features. For example the file routines and many OS routines are not available to an addon.

There are sites that have deeper explanations about addon development, such as
- Wowhead.com
- Warcraft wiki (Warcraft.Wiki.gg).
Please use these or other sites for more detailed addon and API information. The API information changes over time for several reasons.
--]]

--[[ Running right now!
The folder and .toc file prefix MUST be the same to be considered for loading into WoW!
See the .toc section under Example Folder Structure.

=== Steps needed to run this example:
- Unzip this example to your WoW installation: ../World of Warcraft/_retail_/Interface/AddOns
- Ensure the folder name is TitanPlugin
- Start or reload WoW

That is it!
You should see another Titan Bag icon in any version of WoW you are running. 
You are now ready to start changing code.
--]]

--[[ Example Folder Structure
Inside this folder you will notice :
- Artwork folder : with one .tga file - the icon used by the plugin
- libs : empty, ready for any library routines you may need
- three .toc files
- one .lua file – for your great idea
- a ReadMe file - This file

=== .toc

The folder and the .toc files MUST have the same name!
Sort of... the name prior to the underscore(_) must be the same as the folder name. 
The part after (postfix) has meaning to the WoW addon loader.
https://warcraft.wiki.gg/wiki/TOC_format : Contains the full list and A LOT more detail about .toc files

If your addon is only for Classic Era leave <addon>_Vanilla. Delete (or rename) the other .toc files.
Titan uses this TOC method. Notice TitanAmmo and TitanRegen.
This allows Titan to load differently so plugins (built-in or 3rd party) intended for Classic versions can run without change.

=== .toc internals
NOTE: The ## Interface value should match the current interface value of the corresponding WoW version.
In BattleNet this is typically shown below the 'Play' button.
DragonFlight 10.02.05 is represented without dots - 100207 - in the .toc.

If the interface value is higher or lower, WoW will complain that you are running 'out of date' addons.

== .lua

This is the code for the plugin.

Titan specific details will be noted and explained within the Lua file.
The comments will specify where names are important.

The plugin starts with local constants used throughout.
Then local variables; then functions.

Suggestion is start with Create_Frames routine at the bottom of the file. It is where the magic starts.

NOTES: 
- Titan locale strings (using AceLocale) were left in the code so the example will run as is. Please use your own strings - localized or not.
- Feel free to look at Titan code for Lua examples. 
- Any routine marked with ---API can be used by a plugin. 
Titan API routines will be maintained and the functionality expected to remain stable.
Any parameter or functionality changes to API will be 'broadcast' on delivery sites and our sites (Discord, our web page).

=== .tga

This file is the icon used by the plugin.
This file is also specified in the .registry of the Lua file – detailed later in this doc.
--]]

--[[ Start editing

Before you start changing this example, it is HIGHLY recommended to install the following WoW addons:
- BugGrabber : Grabs errors and stores them
- BugSack : The visual part of BugGrabber
- WowLua : This allows you to try Lua code directly in WoW.

Install a code / text editor. Notepad++ is a very popular editor.

Small changes are recommended; then test your coding.
When testing, just start or /reload WoW. All versions now check and load new files on reload.

First Routines to change:
- GetBagData will be replaced by your code. It uses the local function IsProfessionBagID.
- ToggleBags is called from OnClick. This will be replaced by your code that handles mouse clicks.
- CreateMenu will be changed to implement your right click menu, if one is needed.

Other routines may be modified to implement your idea.

--]]

--[[ Addon code flow

First step: ==== Starting WoW
Wow will load this addon after Titan is loaded.

NOTE: The .toc states Titan is required [## Dependencies: Titan].
WoW will load Titan BEFORE this addon.

Any code outside the Lua functions will be run.
Examples:
- local VERSION = GetAddOnMetadata(add_on, "Version") will run GetAddOnMetadata
- bag_info will be populated
- ...
- Create_Frames is called

Create_Frames will create the addon frame and name it the string in TITAN_BUTTON.
All created frames will be in the global namespace.
All created frames are forever – they are not touched by the Lua garbage collection.

Then local OnLoad is called when WoW loads the frame into memory.

OnLoad does two important things
1) Sets the .registry of the addon - See the .registry comment block
2) Registers for event PLAYER_ENTERING_WORLD

NOTE: OnLoad should :
- Be small
- NOT assume plugin saved variable data are ready / loaded yet

Then Create_frames sets the frame scripts for the addon. See Frame Scripts block.

Next: ==== Waiting for WoW
WoW fires a bunch of events as this and other addons are loaded.

Eventually the game and all addons are loaded and this plugin receives the PLAYER_ENTERING_WORLD event via the frame script OnEvent.
When processing PLAYER_ENTERING_WORLD, only register for events and access local data this plugin needs.
Do NOT assume saved variables from the registry or any server data are ready.

Titan also receives the PLAYER_ENTERING_WORLD event. 
It is best to assume there is NO guarantee this plugin receives the event before or after Titan!

Titan then processes its own data, creates Titan bars, registers Titan plugins and LDB addons, and syncs plugin saved variables.
Titan will process any saved variables specified in the .registry of this plugin!

Next: ==== Still waiting for WoW
Titan shows the user requested bars with the user requested plugins.
OnShow is called by Titan only if the user has requested the plugin to be shown.
It is best to assume any saved variables in .registry are NOT ready until OnShow!

OnShow now does the processing to set up this plugin and its data properly.
Lastly OnShow needs to call TitanPanelButton_UpdateButton to update the plugin text.
The plugin is now ready for the user.

Next: ==== Ready to play WoW, Yeah!
The plugin will be 'idle' until one of the following occur:
- Titan needs to (re)display this plugin -  TitanPanelButton_UpdateButton
- User selects to show this plugin via Titan Config or menu -  TitanPanelButton_UpdateButton
- User changes a plugin option using the Titan plugin menu :  TitanPanelButton_UpdateButton
- User clicks on this plugin - Right click .menuTextFunction; any other OnClick
- Any registered event is received - OnEvent
- User mouses over plugin - OnEnter
- User mouse leaves plugin - OnLeave
- A timer or callback calls a plugin routine – AceTimer

Next: ====
The above steps continue until:
- User hides the plugin - OnHide
- The user logs out the character or exits WoW or reloads UI - Onhide

On logout or exit the saved variables are saved to the local system - .registry.savedVariables .
No additional actions are required.

==== Using OnShow to set up this addon is good practice :
It should:
- Register any events the plugin will react to
- Process any saved variable data such as user options
- Create any timers
- Set the initial plugin - icon, label, text

This ensures:
- All saved variable data is set and ready
- Less processing if the user never selects the plugin

==== Using OnHide to clean up is good practice :
It should:
- Unregister any events the plugin registered for
- Cancel any timers
- Cleanup any plugin specific data or objects

This ensures:
- Less processing after the user clicks Hide

==== TitanPanelButton_UpdateButton(TITAN_PLUGIN) should be called by this plugin whenever the plugin text could change :
- On processing an event registered for
- On user left click – some action taken
- On user right click – plugin menu

NOTE: TitanPanelButton_UpdateButton expects label - value pairs (up to 4). 
TitanPerformance uses and shows multiple label - value pairs, based on user selection.

Titan uses ShowLabelText to control showing the label or not. This plugin only returns the expected label(s).

==== OnEnter and OnLeave
NOTE: The Titan template handles OnEnter and OnLeave to show or hide the tooltip.
Titan calls the specified routine to show the tooltip – .registry.tooltipTextFunction.
Titan expects a formatted string as the return from the function.

==== Additional saved variables specific to this addon must be handled by this addon and are outside the scope of this example.
Titan Gold is a Titan plugin that has its own saved variables.
--]]

--[[ Frame Scripts

The frame scripts are how WoW and Titan interact with this addon.
NOTE: The creation of the frame also creates scripts handlers. This is a bit hidden by the 'inherits' "TitanPanelComboTemplate" below.
	local window = CreateFrame("Button", TITAN_BUTTON, f, "TitanPanelComboTemplate")
TitanTemplate.xml defines TitanPanelButtonTemplate as the base for each of its plugin types - Combo / Text / Icon.
TitanPanelButtonTemplate sets OnLoad / OnShow / OnClick / OnEnter / OnLeave where each calls TitanPanelButton_On*.
If the script is overriden in the plugin, it should call the appropriate TitanPanelButton_On* routine as shown below. 
In a few cases, the default is not called because the plugin replaces what Titan would do.
TitanPerformance, for example overrides OnClick to create a custom right click menu.

==== OnShow script :
This is triggered when this plugin (frame) is shown.
Technically :
- WoW calls the now registered plugin frame - TITAN_BUTTON:OnShow() as set in Create_Frames
- Which calls the local OnShow to init the plugin
- Then calls TitanPanelButton_OnShow to update the plugin button text

==== OnClick script :
This is triggered when this plugin (frame) has been clicked by the mouse.
Technically :
- WoW calls the now registered plugin frame - TITAN_BUTTON:OnClick() as set in Create_Frames
- Which calls the local OnClick to handle left click (or any click / mod-click other than right click)
- Then calls TitanPanelButton_OnClick to handle right click (plugin menu) – see ‘Right Click’ below

== Right click: 
TitanPanelButton_OnClick is called to handle right click generically because it will
- Close any open control frame
- Close any tooltip
- Position the menu relative to the plugin on whatever Titan bar it is on
- Call the plugin routine to create the actual menu content

The plugin routine here is local CreateMenu.

The plugin can inform Titan of the routine in one of two ways:
1) Specify in .registry.menuTextFunction - preferred
2) Named routine in the global namespace with the expected name of - TitanPanelRightClickMenu_Prepare<id>Menu
- For this plugin the name would be TitanPanelRightClickMenu_PrepareStarterMenu
Titan will use the registry over the created routine. It will not use both.

==== OnEnter script :
OnEnter is handled by the Titan template to show the tooltip next to the plugin wherever it may be.
It calls the routine specified in .registry.tooltipTextFunction.
This routine is expected to return a formatted string to be shown inthe tooltip.

==== OnLeave script :
OnLeave is handled by the Titan template to hide the tooltip.

==== OnHide script :
This is triggered when this plugin (frame) has been hidden by the user :
- via the plugin menu
- via Titan config
- On exit or logout or /reload
Technically :
- WoW calls the now registered plugin frame - TITAN_BUTTON:OnHide() as set in Create_Frames
- Which calls the local OnHide 
The local OnHide should :
- Do any cleanup your plugin needs
- Stop any timers
- Unregister any events
These steps keep processing to a minimum and reduce the chance of errors to the user.

==== OnEvent script :
This is triggered when any event this plugin (frame) has registered for is fired.
Technically :
- WoW calls the now registered plugin frame - TITAN_BUTTON:OnEvent() as set in Create_Frames
- Which calls the local OnEvent to handle all registered events

Titan Bag uses PLAYER_ENTERING_WORLD to handle a difference between Retail and Classic versions when opening bags via the addon.

BAG_UPDATE just updates the text (count) whenever this event is fired.
NOTE: The event also fires when moving items within the bag...
--]]

--[[ .registry attributes
This is the GUTS of a Titan plugin. The .registry table on the frame contains all the information to register the plugin for display.

Every plugin registry with an id should appear in Titan > Configuration > Attempts.
Information about the plugin is shown there along with pass / fail.
If the plugin failed to register, the error is shown there.

NOTE: Titan looks for 3 routines. See .registry Routines.

Attributes:
.id : Required : must be unique across Titan plugins. If there are duplicates, the first one 'wins'.
.category : The general grouping this plugin is in.
	The complete category list is in 	TITAN_PANEL_BUTTONS_PLUGIN_CATEGORY (TitanGlobal.lua)
	"Built-ins" is reserved for plugins that Titan releases.
.version : plugin version shown in menus and config.
.menuText : Used as the title for the right click menu.
.menuTextFunction : See .registry Routines.
.buttonTextFunction : See .registry Routines.
.tooltipTitle : Used as the title for the tool tip
.tooltipTextFunction : See .registry Routines.
.icon : Allowed path to the icon to be used. 
	It is recommended to store the icon in the plugin folder, even if exists within WoW.
.iconWidth : Best left at 16...
.notes : This is shown in Titan > Config > Plugins when this plugin is selected.
.controlVariables : This list is controls whether the variable is shown. See below.
.savedVariables : These are the variables stored in Titan saved variables.
	The initial values are used only if that particular entry is 'new' to 
	that character (new Titan install, new character, character new to Titan).
	If a value is removed then it is removed from the saved variables as Titan is run for each character.

== .controlVariables
These are used to show or hide 'controls' in the Titan config or Titan right click menu.
- ShowIcon
- ShowLabelText
- ShowColoredText
- DisplayOnRightSide
- ShowRegularText (LDB only)
If true, the control is shown to the user.
If false, the control is not shown to the user.
--]]

--[[ .registry Saved Variables

All saved variables for this plugin are listed within savedVariables
- ShowUsedSlots = 1,
- ShowDetailedInfo = false,
- CountProfBagSlots = false,
- ShowIcon = 1,
- ShowLabelText = 1,
- ShowColoredText = 1,
- DisplayOnRightSide = false,
- OpenBags = false,
- OpenBagsClassic = "new_install",

Plugin variables :
- ShowUsedSlots : Show used versus available slots
- ShowDetailedInfo : Show bag details in the tooltip
- CountProfBagSlots : Whether to include, or not, profession bags in the counts
- OpenBags : Whether to open bags on left click or not. Included due to a taint issue introduced by WoW
- OpenBagsClassic : Used to determine a new install / new character (to Titan or just created)

Titan uses the below to control display of the plugin :
- ShowIcon : Whether the icon,if specified is shown
- ShowLabelText : Whether the labels returned by buttonTextFunction are shown
- ShowColoredText : Whether the text is 'colored' or not
- DisplayOnRightSide : Put this plugin in the right side of the Titan bar

ShowColoredText is plugin specific. Generally used to indicate a range such as your bags are empty (green) to nearly full (red).
If the plugin does not need this then please set controlVariables > ShowColoredText to false to prevent the user from seeing 
the option and potentially getting confused.

NOTE: Titan routines have used 1 as true since inception so be careful on 'true checks'. 
"if ShowUsedSlots then " *should* work fine if ShowUsedSlots is true or 1

=== Where are these saved variables?????
The saved variables are specified in the Titan toc :
## SavedVariables: TitanAll, TitanSettings, TitanSkins, ServerTimeOffsets, ServerHourFormat

TitanSettings contains all the plugin saved variables.
Titan uses the single table structure to store the saved variables across a user account.
This makes the setup code rather cumbersome and not straight forward - just warning...

The saved variables can be found here: .../World of Warcraft/_retail_/WTF/Account/(account name>/SavedVariables/Titan.lua
There is a Titan.lua.bak which is the prior save (logout / exit / reload).

It is HIGHLY recommended opening the saved variables file in an editor with code folding features! 
This file could be quite large with many lines.
I have 20+ characters on one server. Even though I do not use many addons, I do test with addons on some characters.
A plugin such as Titan Panel [Reputation] can create 100+ plugins. My file is nearly 90,000 lines long!

Say we want to find a character named Embic on Staghelm being used for testing to examine the saved variables.
This would under
TitanSettings = {
	["Players"] = {
		["Embic@Staghelm"] = {
			["Panel"] = {
				-- Holds all the Titan settings for this character
				}
			["BarVars"] = {
				-- Holds all the Titan bar settings for this character
				}
			["Plugins"] = {
				-- Each registered plugin will be here
					["Starter"] = { 
						["notes"] = "Adds bag and free slot information to Titan Panel.\n",
						["menuTextFunction"] = nil,
						["id"] = "Starter",
						["menuText"] = "Bag",
						["iconWidth"] = 16,
						["savedVariables"] = {
							["ShowColoredText"] = 1,
							["CustomLabel3Text"] = "",
							["ShowIcon"] = 1,
							["OpenBags"] = false,
							["CustomLabel3TextShow"] = false,
							["CustomLabelTextShow"] = false,
							["CustomLabel4Text"] = "",
							["CustomLabel2Text"] = "",
							["OpenBagsClassic"] = "new_install",
							["ShowLabelText"] = 1,
							["CustomLabel4TextShow"] = false,
							["CountProfBagSlots"] = false,
							["ShowUsedSlots"] = 1,
							["DisplayOnRightSide"] = false,
							["ShowDetailedInfo"] = false,
							["CustomLabel2TextShow"] = false,
							["CustomLabelText"] = "",
						},
						["controlVariables"] = {
							["DisplayOnRightSide"] = true,
							["ShowColoredText"] = true,
							["ShowIcon"] = true,
							["ShowLabelText"] = true,
						},
						["version"] = "1.0.0",
						["category"] = "Information",
						["buttonTextFunction"] = nil ,
						["tooltipTextFunction"] = nil ,
						["icon"] = "Interface\\AddOns\\TitanPlugin\\Artwork\\TitanStarter",
						["tooltipTitle"] = "Bags Info",
					},
				}
			["Adjust"] = {
				-- Holds offsets for frames the user may adjust - Retail and Classic have different list of frames
				}
			["Register"] = {
				-- Holds data as each plugin and LDB is attempted to be registered. 
				-- There may be helpful debug data here under your plugin name if the plugin is not shown as expected. 
				-- Titan > Configuration > Attempts shows some of this data, including errors.
				}

NOTES:
- "Starter" index under Plugins is also .registry.id !!
- This lists the last saved contents of .registry - NOT what is in memory!
- This file contains all the tables specified in the Titan .toc file.

--]]
--[[ .registry Routines

Titan looks for 3 routines specified in the .registry :
- .buttonTextFunction : Routine that updates the plugin text.
- .tooltipTextFunction : Routine that generates the tool tip text.
- .menuTextFunction : Routine that creates the options for the menu (right click) OR "TitanPanelRightClickMenu_Prepare"<id>"Menu"

.menuTextFunction : This is the routine called by Titan on right click so the plugin can create its menu.
	1) This is the newer, preferred method which makes the options menu routine explicit (changed 2024 Feb).
	If found, this will be used over the older method - both will not be used.
	NOTE: Routine can be specified :
	--- As a string, it MUST be in the global namespace. Strings were the only method for a long time.
	--- As a function, it may be in the global namespace but could be local. This example uses a local routine which is preferred.

	2) The older method is still supported!
	Titan builds the expected routine name as "TitanPanelRightClickMenu_Prepare"<id>"Menu".
	In this example it would be : TitanPanelRightClickMenu_PrepareStarterMenu

.buttonTextFunction : This is called whenever the button is to be updated.
	This is called from within the plugin and from Titan by calling TitanPanelButton_UpdateButton(TITAN_PLUGIN) .
	Titan will usually return "<?>" if the routine dies.
	If you need to see the error, search for this attribute in the Titan folder and uncomment the print of the error message.
	This may generate a LOT of messages!
.tooltipTextFunction : This is called when the mouse enters the plugin frame is triggered.
	The Titan templates set the OnEnter script for the plugin frame.
	On a tooltip error, Titan will usually show part of the error in the tool tip.
	If you need to see the full error, search for this attribute in the Titan folder and uncomment the print of the error message.

NOTE: The .registry routines are called securely using pcall to protect Titan.
These routines are expected to have NO parameters. Handling parameters was not implemented in any version of Titan.
--]]
--[[ Special Icons and Artwork

Anyone can extract the Blizzard UI code and art from WoW. This can be handy to get code examples.
And to grab icons to use for a plugin. My understanding is any icon can be used within WoW without violating the ToS.
WoW icons tend to be .blp files. These files are NOT easy to look at or manipulate!!
You will need to research third party tools to manipulate .blp files. 
BLPView (Windows only) from wowinterface is light and easy to view blp files as thumbnail pics in File Explorer.

==== Extracting art and code
Add the switch -console when starting WoW. 
In BattleNet click the Settings (next to Play) then Game Settintgs. Add as an additional command line argument.

Start WoW but stay on the character screen.
Hit the ~ (tilde) key to open a text console which will appear from the top of the screen.
Type exportInterfaceFiles (can tab to auto fill) with parameter code or art
exportInterfaceFiles code
exportInterfaceFiles art

These must be run separately. Code should take a second or so; art may take some time and appear to hang the game.

For retail, the result will be here : 
.../World of Warcraft/_retail_/BlizzardInterfaceCode
.../World of Warcraft/_retail_/BlizzardInterfaceArt
--]]

