--[[ Example
This example is intended to introduce LDB (LibDataBroker) essentials by using an example loosely based on Titan Bag.
A display addon is needed to show this addon. Titan is recommended :).

This example is intended to be small and light for easy understanding and editting.

Important notes are denoted with ***:
*** The 'official' LDB spec is here : https://github.com/tekkub/libdatabroker-1-1 .
*** This example is provided as is and without restrictions.
*** Timers are outside the scope of this example. 
- Titan built-in addons use timers (AceTimer).
*** Localized strings are outside the scope of this example. 
- Titan and built-in plugins use localized strings (AceLocale).

There are sites that have deeper explanations about addon development such as wowhead or wow wiki (warcraft.wiki.gg).
Please use these or other sites for more detailed addon information.
--]]

--[[ Folder Structure
This addon folder must be added to the Addon folder to be considered for loading into WoW.
Inside this folder you will notice :
- Artwork folder : icon(s) used by the addon
- libs folder 
- .toc files
- one .lua file : for your great idea
- This read me file

=== .toc
The folder and the .toc files MUST have the same name!
Sort of... the name prior to the underscore(_) must be the same as the folder name. 
The name after that (postfix) has meaning to the WoW addon loader.
https://warcraft.wiki.gg/wiki/TOC_format : Contains the full list and A LOT more detail about .toc files

If your addon is only for Classic Era leave <addon>_Vanilla. Delete (or rename) the other .toc files.

*** The ## Interface value should match the current interface value of the corresponding WoW version.
If the interface value is higher or lower, WoW will complain that you are running 'out of date' addons.
In the BattleNet app this typically shown below the 'Play' button.
- DragonFlight 10.2.7 is represented without dots - 100207 - in the .toc file.
- Cataclysm 4.4.0 is represented without dots - 40401 - in the .toc file.

=== Artwork folder: icons and artwork
Anyone can extract the Blizzard UI code and art from WoW. This can be handy to get code examples.
My understanding is any WoW icon can be used within an addon without violating the ToS (Terms of Service).
Wowhead has a searchable list of WoW icons : https://www.wowhead.com/icons

WoW icons tend to be .blp files. These files are NOT easy to look at or manipulate!!
BLPView (Windows only) from wowinterface is light and easy to view blp files as thumbnails in File Explorer.
You will need to research third party tools to manipulate .blp files. My advice is convert .blp to another format.

=== libs folder
*** The libraries required for a LDB addon are in the LDB/libs folder.
- WoW does not guarentee the load order of addons. 
- If the LDB addon were loaded before the display addon, the loader would throw errors if the libs were not found.
- If the LDB addon requires additional libraries, please include them in libs folder and update the .toc appropriately.

--]]

--[[ LDB attributes
The list of required attributes depend on the type of LDB being created.

Attributes used in this addon:
.type : Required : data source | launcher
.icon : Path to the icon to be used. Place the icon in the addon folder, even if copied from WoW folder.
.label : The label for the addon text
.text : The addon text to display
.OnTooltipShow : The function to use for the tool tip, if any
.OnClick : The function to to handle mouse clicks, if any


Available Titan extensions:
.category : The general grouping this addon is in.
- Titan attempts to grab X-Category from the addon TOC first.
- The complete category list is in 
- TITAN_PANEL_BUTTONS_PLUGIN_CATEGORY (TitanGlobal.lua) "Built-ins" is reserved for addons that Titan releases!
.version : Addon version shown in Titan menus and config.
- Titan attempts to grab Version from the addon TOC first.
.OnDoubleClick : Implemented by orig dev, not sure this is used by any addon.

The three data elements are:
- icon
- label
- text

When any of these are changed, the LDB lib initiates a callback to the display addon.
The display addon registers for these callbacks and creates any frame(s) it needs to display the LDB addon data.
--]]

--[[ Editing
Before you start changing this example it is HIGHLY recommended to install the following addons:
- BugGrabber : Grabs errors and stores them
- BugSack : The visual part of BugGrabber
- WowLua : Allows you to try Lua code directly in WoW.

It is recommended you make small changes then check your coding.
When testing just start or /reload WoW. All versions now check and load new files on reload.

Routines:
GetBagSlotInfo will be replaced by your code.

Button_OnEvent will be changed to react to any events your addon needs.
- All events registered for should be handled here.
- The display addon is not directly involved in any event handling of this addon.
--]]

--[[ Code flow within WoW
First step: ==== Starting WoW
Wow will load addons in the Addons folder.
Order is not guaranteed, however dependencies (## Dependencies) are honored.

When this addon is loaded any code outside the Lua functions will be run.
Examples:
- local VERSION = GetAddOnMetadata(add_on, "Version")   will set VERSION
- ...
- Create_Frames is called

Create_Frames will create the addon frame StarterLDBExample.
- All created frames will be in the global namespace.
- All created frames are forever – they are not touched by the Lua garbage collection.

Then Create_frames sets the frame OnEvent script handler. This is the only handler required in this addon.

Then local LDB_Init will initialize the required LDB object.
This routine should be small :
- Set the LDB object
- Set required local variables
- Register for PLAYER_ENTERING_WORLD
- *** DO NOT rely on any saved variables (## SavedVariables) being ready here

Next: ==== Waiting for WoW
WoW fires a bunch of events as addons are loaded.

Eventually the game and all addons are loaded and addons receive the PLAYER_ENTERING_WORLD event via the frame script OnEvent.
When processing PLAYER_ENTERING_WORLD, register for additional events your addon requires.
Any saved variables should be ready.

Next: ==== Still waiting for WoW
The display addon (such as Titan) shows the user requested bars with the user requested addons.

The addon is now ready for the user.

Next: ==== Ready to play WoW! Yeah!
The addon is 'idle' until one of the following occur:
- Any registered event is received - OnEvent
- User clicks on this addon - OnClick via display addon
- User mouses over addon - OnTooltipShow via display addon
- User mouse leaves addon - OnLeave via display addon

Next: ====
The above steps continues until:
- The user logs out the character or exits WoW or reloads UI - Onhide

On logout or exit any saved variables are saved to the local system.
No additional actions are required.

--]]
