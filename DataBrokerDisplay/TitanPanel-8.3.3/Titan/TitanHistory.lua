--[===[ File
This file contains Config 'recent changes' and notes.
It should be updated for each Titan release!

These are in a seperate file to
1) Increase the chance these strings get updated
2) Decrease the chance of breaking the code :).
--]===]

--[[ Var Release Notes
Detail changes for last 4 - 5 releases.
Format :
Gold - version & date
Green - 'header' - Titan or plugin
Highlight - notes. tips. and details
--]]
Titan_Global.recent_changes = ""
.. TitanUtils_GetGoldText("8.3.3 : 2025/08/12\n")
.. TitanUtils_GetGreenText("Titan : \n")
.. TitanUtils_GetHighlightText(""
.. "-  LootType : \n"
.. "-  - : Fix API change to GetLootMethod, retail only.\n"
.. "-  Location : \n"
.. "-  - : Fix map coords being off map in retail; Top and Bottom should now work in retail.\n"
.. "-  - : Fix rare error that shows error on button text.\n"
.. "-  Internally : \n"
.. "-  - : Fix profile not saving (#1439).\n"
.. "-  - : Expand GB widget adjust (allow 'up').\n"
.. "-  - : Make Classic TOC show as Classic to help avoid confusion.\n"
)
.. TitanUtils_GetGoldText("8.3.2 : 2025/08/01\n")
.. TitanUtils_GetGreenText("Titan : \n")
.. TitanUtils_GetHighlightText(""
.. "-  Ammo : \n"
.. "-  - : Fix missing icon.\n"
.. "-  Internally : \n"
.. "-  - : Several tweaks for MoP.\n"
)
.. TitanUtils_GetGoldText("8.3.0 : 2025/07/2\n")
.. TitanUtils_GetGreenText("Titan : \n")
.. TitanUtils_GetHighlightText(""
.. "-  Major change : \n"
.. "-  - : Titan users will have their Titan options reset.\n"
.. "-  - : Titan plugin options should be the same after update.\n"
.. "-  - : Titan 3rd party plugins for Classic must be updated.\n"
.. "-  Internally : \n"
.. "-  - : TitanClassic is no longer an ID.\n"
.. "-  - : Titan Classic 3rd party plugins must use Titan as the dependency in TOC, not TitanClassic.\n"
.. "-  - : Saved variables will be in Titan.lua rather than TitanCLassic.lua.\n"
)

.. "\n\n"

--[[ Var Notes
Use for important notes in the Titan Config About
--]]
Titan_Global.config_notes = ""
    .. TitanUtils_GetGoldText("Notes:\n")
    .. TitanUtils_GetHighlightText(""
        ..
        "- Changing Titan Scaling : Short bars will move on screen. They should not go off screen. If Short bars move then drag to desired location. You may have to Reset the Short bar or temporarily disable top or bottom bars to drag the Short bar.\n"
    )
    .. "\n"
    .. TitanUtils_GetGoldText("Known Issues:\n")
    .. TitanUtils_GetHighlightText(""
    .. "- Cata : Titan right-click menu may stay visible even if click elsewhere. Hit Esc twice. Investigating...\n"
)
