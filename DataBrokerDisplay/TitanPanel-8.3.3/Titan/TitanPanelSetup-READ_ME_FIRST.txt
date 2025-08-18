TitanPanelSetup-READ_ME_FIRST File
==================================

****************************************************************************************************
****************************************************************************************************

1. Description

   Titan Panel adds a configurable interface bar/control panel to your WoW UI.


2. Installation

   Unzip the contents of the zip file into your ..\Interface\AddOns directory.

   Important Note for Mac Users:  When a zip file contains folders, the auto-unzip function built
   into Mac OSX will create a new folder to place them in.  If you unzip directly to the AddOns
   folder, this newly-created folder will prevent Titan from loading.  We recommend Mac users unzip
   to the desktop, open the Titan folder on the desktop, then select and drag the contents of it to
   your ../Interface/AddOns folder.  Verify WoW recognizes the addon.  After signing on to WoW,
   click the AddOns button on the Realm/Character Selection screen.  Titan Panel should be checked
   by default; if not, check it.  While there, check any unchecked addons, including Titan plugins,
   you want to display and uncheck any addons you don't want to display.  Now enter the game.


3. Setup

   Basic setup includes displaying the desired bars and configuring the plugins.

   - Bars:
   
      By default, Titan Panel displays the Main Bar (a single bar at the top of the screen). 
      You can, however, display up to 4 independent bars, 1 or 2 at the top of the screen and/or 1
      or 2 at the bottom.  To change the number and/or location of the bars, right-click a blank
      area of the Titan Panel and click the Configuration option.  Alternatively, you can click the
      Game Menu icon on the bottom action bar, select Interface, click the + next to Titan Panel in
      the Addons tab, and then click Bars.  Use the Bars option to configure the top bars and the
      Aux Bars option to configure the bottom bars.
      
         * Show Bar.  Displays the specified bar:  Main Bar is the top bar, Main Bar 2 is the 2nd
            top bar, Auxiliary Bar is the bottom bar, Auxiliary Bar 2 is the 2nd bottom bar.
         * Auto-hide.  Causes the bar to appear only when you move the cursor atop the bar;
            otherwise, the bar is hidden.
         * Center text.  Changes the location of display (left-side) plugins from left-justified to
            centered.
         * Disable screen adjust.  Titan Panel adjusts the Blizzard UI automatically so Titan Panel
            fits without overlapping frames, such as the minimap.  This allows you to disable this
            automatic adjustment.  Select this option if you previously selected Auto-hide.
         * Disable minimap adjust.  Disables the adjustment of the minimap. This is useful in cases
            you want to enable another addon to specifically handle that frame.
         * Automatic ticket frame adjust.  Moves the Blizzard Ticket Frame so it's not under the top
            bar(s).
         * Automatic log adjust.  Pins the chat log above your highest horizontal action bar, so the
            chat log doesn't overlap it.  This only works on Blizzard default bars (not custom
            bars). Because this option has created a lot of confusion, we recommend that you keep
            this off, manually move the chat log, and lock it.
         * Automatic bag adjust. Automatically adjusts your bag containers, so they don't overlap
            the horizontal action bar when you are using bottom bar(s). Unchecking this option is
            useful in cases you use another addon which specifically handles your container frames. 
   
   - Configuring Plugins using the Interface menu:
   
      Select the Plugins option and then click the Plugin you want to move or configure.  Not all of
      the options listed below apply to every plugin.
   
         * Show plugin.  Check to display the plugin, uncheck to hide.
         * Show icon.  Check to display the icon, uncheck to hide.
         * Show label text.  Check to display the name of the plugin, uncheck to hide.
         * Show colored text.  Check to show the information of display (left-side) plugins in
            color, uncheck to display the information in white.
         * Right-side plugin.  Check to move the plugin to the right side.  Applies to Clock and to
            LDB launchers that aren't coded as launchers.
         * < Shift Left.  Swaps the plugin with the one to it's immediate left.
         * > Shift Right.  Swaps the plugin with the one to it's immediate right.
         * Bar drop-down.  Specifies the bar on which you want the plugin to appear.  Only those
            bars you have enabled appear in the dropdown.
         
   - Configuring Plugins using the Titan Panel right-click menu:

         * Right-click a blank area of the Titan Panel bar on which you want to show, hide, or
            configure plugins.
         * Hover the cursor over a category of plugins.  Plugins that are displayed on the bar are
            selected.
         * Select additional plugins to display or deselect to hide by clicking the plugin's name on
            the secondary menu.
         * Select configuration options for individual plugins by clicking the option on the
            tertiary menu.

   - Configuring Plugins using individual plugin's right-click menu:  Most plugins have a
      right-click menu for configuring them.
   
   - Moving plugins using drag-and-drop:
   
         * To swap plugins, click-and-drag a plugin onto another one.  You can swap between
            different bars.
         * To move a plugin to another bar, click-and-drag it to an empty space on the desired bar.


4. Customization

   You have numerous ways to customize Titan Panel.  One way is through core functions.  The
   following core functions appear on the right side of the main bar:

   - AutoHide (Push Pin icon):  Left-clicking this icon causes the bar to only appear when you move
      the cursor atop the bar.  Otherwise, the bar is hidden.  There is a separate push pin for each
      bar.

   - Volume Control (speaker icon):  This allows you to override Blizzard's default sound settings.

      * Right-click this icon to display the following Volume Control options:
         + Show Sound/Voice options.  Displays the Sound & Voice window.  Here you can control
            volume using Blizzard's interface.
         + Override Blizzard Volume Settings.  Select this to control volume using Titan Panel's
            interface.
         + Hide.  Removes the plugin from the bar.
      * Left-click this icon to display 6 slider bars with which you can control specific volume
         levels.  You MUST select Override Blizzard Volume Settings from the right-click options
         menu if you want to control the volume with these sliders.

   - Clock:

      * In addition to the options in the Interface menu, right-clicking the Clock gives access to
         the following options: Show Local Time, Show Server Time, Show Server Adjusted Time, Hide
         Time button, and Hide Calendar Button.
      * Left-clicking allows you to adjust the server time and change the time to 24-hour format.
   
   The following core functions appear in Blizzard's Interface Addons frame:
      
   - Tooltips and Frames:

      * Hide tooltips in combat.  Turns off tooltips in combat so you're not distracted while
         fighting.
      * Show tooltips.  Displays a tooltip when you hover the cursor over a button/icon.
      * Lock buttons.  Locks the buttons in place, keeping you from inadvertently moving them.
      * Show plugin versions.  Displays the version number when a plugin is selected from the
         Interface menu.
      * Force LDB launchers to right-side.  Use when LDB launchers are not coded as such.
      * Refresh plugins.  Use when a plugin does not update.  If you need to use this, and it fixes
         the display, contact the developer.
      * Reset Titan Panel to Default.  For emergency use only.

   - Scale and Font:

      * UI Scale.  Controls the scale of the User Interface from 64% to 100%.
      * Titan Panel Scale.  Controls the size of Titan Panel from 75% to 125%.
      * Button Spacing.  Controls the separation between left-side plugins from 5 pixels to 80
         pixels.
      * Tooltip Font Scale.  Controls the size of the plugins' Tooltip Fonts from 50% to 130%.
      * Disable Tooltip Font Scale.  Overrides the setting on the Tooltip Font Scale slider.
      * Panel Font drop-down.  Changes the font type used.
      * Font Size.  Changes the size of the specified font.
      * Titan Panel Frame Strata drop-down.  Changes the depth you want the bars to be relative to
         other frames.

   - Transparency:  Controls the transparency of each of the bars and the tooltips.


   All the built-ins, and many third-party plugins, give you the option to disable them individually
   by right-clicking the icon and selecting Hide.  Another way to customize Titan Panel is by
   changing skins.  Titan comes with a large selection of skins.  You control skins from the
   Interface Addon menu.
   
   - Skins:  Here you can select a skin from the Skin List drop-down or Reset to Defaults.

   - Skins-Custom:  Use this screen to add a custom skin to the Skin List or remove one.


5. Profiles

   Profiles allow you to have different configurations for individual characters.  The
   first time you configure Titan Panel, it automatically saves the settings in a profile, using the
   character's name.  It will continue to use that profile for other characters until you change
   your configuration and save it.  There are two ways to manage profiles:
   
   - Titan Panel Right-Click Menu:
   
      * Profiles Manage.  Allows you to replace the current character's profile with another another
         character's profile.  Also allows you to delete a profile.
      * Profiles Save.  Allows you to save the current character's settings under a user-specified
         name.
   
   - Interface Addons Menu:  Gives you the same options to manage and save profiles as the
      right-click menu does.


6. Bug Reporting

   If you encounter a bug, open an Issue at our SourceForge site:
   
      https://sourceforge.net/p/titanpanel/tickets/?source=navbar
   
   Please include as many details as possible, including a complete list of addons.  It is helpful
   to use a bug capturing addon, such as !Swatter (part of Gatherer addon); copy and paste the
   entire text into the Issue screen.  We will post our troubleshooting results and recommendations
   there, so check back often.  Before opening the Issue, please Search All Issues to see if the bug
   has already been reported and fixed.  Also, check the download sites for information on the
   download page, such as:
   
      http://www.wowinterface.com/downloads/fileinfo.php?id=8092
      http://www.curse.com/addons/wow/titan-panel