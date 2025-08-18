--[===[ File
Starts the Titan developer documention.
--]===]

--[===[ Titan Documentation Beginning

This document will introduce Titan essentials for a Titan developer. 
The intent is simplify what may appear to be a daunting experience. 

We suggest you grab your favorite beverage, read this doc, and relax! 
Many of Titan mysteries will be explained. 🙂

The Titan team and its users are available to answer questions.
The two most used ways are : 
The Titan Discord community - https://discord.gg/e93sxuSPwC 
Curse comments under Titan Panel addon

=== IDE Tools used:
Visual Studio Code - https://code.visualstudio.com/
Other IDEs accept Lua Language Server, see if your prefered IDE will accept LLS

Lua Language Server (LLS) - https://marketplace.visualstudio.com/items?itemName=sumneko.lua
	https://github.com/LuaLS/lua-language-server
WoW API - LLS extension - https://marketplace.visualstudio.com/items?itemName=ketho.wow-api
	https://github.com/Ketho/vscode-wow-api

And a tiny Python parser to pull these comments.

Note: The WoW API is geared to Retail. 
There was no option to automatically include 'Classic' deprecated routines.
There are diagnostic annotations used to ignore some warnings. 
Ignore warning annotations were limited as much as practical to 'this line' to point out usage of Classic routines.

=== Documentation blocks
These are created from annotations in the Lua files.
API :
These are routines Titan will keep stable.
Changes to these varaibles and routines will be broadcast to developers via Discord at a minimum.

Dev : 
These are global routines Titan uses. These may change at any time per Titan needs and design.

File : 
Each file has a terse description of its contents.
--]===]

--[===[ Titan Start editing

Before you start changing this example, it is HIGHLY recommended to install the following WoW addons:
- BugGrabber : Grabs errors and stores them
- BugSack : The visual part of BugGrabber
- WowLua : This allows you to try Lua code directly in WoW.

Small changes are recommended; then test your coding.
When testing, just start or reload WoW. All versions now check and load new files on reload.

Reload is /reload in game chat.
Using a text editor with code folding features will make this file easier to read and find information.

For simple changes, install a code / text editor. NotepadPlusPlus is a very popular editor.

For more in delpth changes consider using an IDE (Integrated Development Environment).
The file TitanIDE contains details on tools and annotation.

Regardless of tools used, please update any annotations and comments as changes are made!!!

=== Additional Help For You
A good Lua resource is https://www.lua.org/docs.html
NOTE: WoW uses Lua version 5.1 as its base.
NOTE: WoW does restrict, add, or even remove some Lua features. For example the file routines and many OS routines are not available to an addon.

There are sites that have deeper explanations about addon development, such as
- Wowhead.com
- Wiki wow wiki (Warcraft.Wiki.gg).
Please use these or other sites for more detailed addon and API information. 
The API information changes as Blizzard adds features, changes API methods, or any other reason.

=== Folder Structure
Inside the Titan folder you will notice :
- Artwork folder : Contains skins used by Titan
- libs : Library routines Titan uses
- A .toc file
- Many .lua files including this file
- An XML file : Containing Titan templates mainly for plugins
- This file


=== .toc
NOTE: Summer 2025 Titan dropped TitanClassic as a method to make CE and other WoW versions distinct.

The folder and the .toc files MUST have the same name!
Sort of... the name prior to the underscore(_) must be the same as the folder name. 
The part after (postfix) has meaning to the WoW addon loader.
This list changes : https://warcraft.wiki.gg/wiki/TOC_format

Titan uses at least two postfix values.
_Mainline : current retail version
_Vanilla : Classic Era version

Titan uses this TOC method. Notice a couple built-ins use _Vanilla.toc.
This allows Titan to load plugins (built-in or 3rd party) intended for Classic only without change.

=== .toc internals
NOTE: The ## Interface value should match the current interface value of the corresponding WoW version.
In BattleNet this is typically shown below the 'Play' button.
DragonFlight 10.02.05 is represented without dots - 100207 - in the .toc.

If the interface value is higher or lower, WoW will complain that you are running 'out of date' addons.

See one of the referrenced sites for more detail.
- https://warcraft.wiki.gg/wiki/TOC_format contains more info than you will ever need on TOC format.

After the TOC directives, Titan lists the files in the order they are to be parsed.
This is important for Titan (or any addon) to load properly.

TitanGame.Lua specifies TITAN_ID which is the addon ID and is determines whether to use Retail or Classic versions of some routines.

Then the Ace libraries. Note Titan does not use all the Ace libraries.
_Titan_Lib_Notes shows a running change history of the libraries.

Then all the localization files.

Then the Titan code files.

=== Artwork

WoW tends to use .tga image files.
Lookup TextureBase:SetTexture for current accepted image types.
NOTE: All versions of WoW may not accept all image types.

Most graphic art software can save to these formats. We don’t recommend using an online source to convert options. 
They have a tendency to add additional code or info to the artwork.
--]===]

--[===[ Titan Addon code flow

First step: ==== Starting WoW
Wow will load load Titan along with other addons installed. There is no guarantee of order the addons are installed!

The files will be loaded / run per the order in the TOC.
TitanTemplate.xml : Creates the Titan frame - TitanPanelBarButton - along with Titan Templates. This is used to receive events.

Any code outside the Lua functions will be run per the order in the TOC.
Examples:
- TitanGlobal.lua sets up constants and variables used by Titan
- Titan.lua local variables and registering for some events such as ADDON_LOADED
- Creation of functions
- TitanLDB.lua creates LDBToTitan frome to handle LDB objects

When ADDON_LOADED event is received, 
- Titan registers for event PLAYER_ENTERING_WORLD
- Titan ensures its saved variables are whole and known player profiles are read.

NOTE: On ADDON_LOADED is the first time addon saved variables should be considered loaded and safe!!
Using addon saved variables before ADDON_LOADED is likely to result in nil(s). Such as when WoW parses the addon code as it is loading.
NOTE: The addon saved vars are NOT the Titan plugin saved vars via the registry (.savedVariables)! The registry is processed later!

Next: ==== Waiting for WoW
WoW fires a bunch of events as this and other addons are loaded.
Eventually the game and all addons are loaded and PLAYER_ENTERING_WORLD event is sent

Next: ==== Entering world - PLAYER_ENTERING_WORLD (PEW) event
When PLAYER_ENTERING_WORLD event is received via OnEvent, the real work begins.
The PEW events do NOT guarantee order! Titan plugins (addons) could receive a PEW before Titan - See NOTE below.

The local routine - TitanPanel_PlayerEnteringWorld - is called using pcall.
This ensures Titan reacts to errors rather than forcing an error to the user.
TitanPanel_PlayerEnteringWorld does all the variable and profile setup for the character entering the world.

On login PLAYER_ENTERING_WORLD - not reload - Titan
- Sets character profiles - TitanVariables_InitTitanSettings
- Sets TitanPanel*Anchor for other addons to adjust for Titan
- Creates all Titan bars including right click menu and auto hide frames. See Frames below.
- Registers for events Titan uses - RegisterForEvents

On login and reload Titan
- Set THIS character profile () - TitanVariables_UseSettings - 
   See TitanVariables (File) for more details on saved variables; this is a simple concept but touchy to implement.
   The user chosen profile sets the user chosen plugin saved vars for both Titan and any plugins - see NOTE below.
   TitanVariables_UseSettings uses
   - TitanPanel_InitPanelBarButton to set the bars the user wants.
   - TitanPanel_InitPanelButtons to set the plugins the user wants on the user selected bars via OnShow.
- Update the Titan config tables - TitanUpdateConfig
- Set Titan font and strata
- Sync any LDB plugins with the cooresponding Titan plugin- TitanLDBRefreshButton
If the above was successful then all is good
If the above failed with an error then 
- tell user some bad happened with error they can pass to dev team
- attempt to hide all bars as cleanup
- nuke the Titan config tables as cleanup

NOTE: The PEW event is an important but subtle distinction for Titan plugins!
Titan plugins should be very careful if they use the PEW event to run code. The PEW events do NOT guarantee order! 
Meaning the plugin PEW could be processed BEFORE Titan has set saved vars for itself or plugins.
Titan plugins should not assume ANY saved vars are available until their OnShow.
Only at the OnShow are the 'right' plugin saved vars guaranteed to be set.
We have seen bugs occur on some user systems due to the order addons get and process the PEW event.
--]===]

--[[ Frames and Frame Scripts
Here we detour into XML. TitanTemplate.xml contains the frames used by Titan.
- TitanPanelBarButton : This "is" Titan in the sense that it has all events attached to it and all the code.
- Titan_Bar__Display_Template : The template (Button) for a Titan bar.
- TitanPanelBarButtonHiderTemplate : The template (Button) paired a full width Titan bar to allow hiding and unhiding the paired Titan Bar.
- TitanPanelTooltip : This or GameTooltip is used for tool tips.

TitanPanelButton_CreateBar in Titan.lua creates the full width bars and short bars by looping through TitanBarData.
TitanBarData in TitanVariables.lua holds creation data for each bar.
TitanBarDataVars holds the Titan and user settings for each bar. An initial setup (fresh / another install) uses TitanBarVarsDefaults.

The frame scripts are how WoW and Titan interact with this addon.

==== OnEnter and OnLeave
Titan sets these scripts on a Bar for future use . Currently Titan does no work.

For Titan Hider Bars these are used to show / hide the Titan Bar.
Note: Hider Bars are only for the full width bars - NOT Short Bars.

==== OnClick script :
Right click is to open the Titan menu.
Left click closes any tooltip and any menu.

On Short Bars Titan registers for 
- OnDragStart and OnDragStop (left mouse button) for moving Short Bars
- OnMouseWheel to size a Short Bar

==== OnShow script :
Not used by Titan bars.

==== OnHide script :
Not used by Titan bars.

==== OnEvent script :
Titan.lua sets the OnEvent stript for TitanPanelBarButton to redirect events to TitanPanelBarButton:<registered event> 
See local function RegisterForEvents for the list of eventsand their usage.
--]]

--[[ Plugin .registry

=== Titan plugins
The routine - TitanUtils_RegisterPluginList - starts the plugin registry process.

=== LDB objects : See LDBTitan.lua for many more details.

The OnEvent script of LDBToTitan frame processes the PLAYER_LOGIN event.
This starts the process to convert all known LDB objects into Titan plugins.
Note: PLAYER_LOGIN occurs same time or very close to PLAYER_ENTERING_WORLD.
This event was chosen by the orignal developer.

Each object found calls TitanLDBCreateObject using pcall to protect Titan.

Before Titan is initialized (first PLAYER_ENTERING_WORLD) the LDB object will be added to the plugin list.
After, TitanUtils_RegisterPluginList will be used iteratively to register each found LDB object.
Most LDB objects are created on loading by addons. There should only an issue for addons that create
many LDB objects on demand.

The Titan plugin example has a lot more detail from the plugin view that would be helpful to a Titan dev.
--]]

--[[ Saved Variables

See TitanVariables.lua (File) for additional detail.

Much of the info below is included in the Titan plugin example.

NOTE: Titan routines have used 1 as true since inception so be careful on 'true checks'. 
As an example
if ShowUsedSlots then 
*should* work fine if ShowUsedSlots is true or 1

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

Say we want to find a character named Embic on Staghelm which you are using for testing.
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

--]]
