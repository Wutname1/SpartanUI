# Frenemy

## [10.0.7.3](https://github.com/Torhal/Frenemy/tree/10.0.7.3) (2023-04-05)
[Full Changelog](https://github.com/Torhal/Frenemy/compare/10.0.7.2...10.0.7.3) [Previous Releases](https://github.com/Torhal/Frenemy/releases)

- Add a MapName field to MapHandler.Data, and set its value at the same time as the MapID field so HereBeDragons:GetLocalizedMap is only called when absolutely necessary.  
- Trigger mapID updates from the HereBeDragons callback, instead of listening to the events directly. Remove unused PLAYER\_REGEN_* event handlers.  
- Add "Section Header" and "Section Body" separator comments to the BattleNet, Guild, and WowFriends tooltip code.  
- Index the correct portion of the tooltipIcon table so guild members' Class icons will show.  
- Remove AceAddon-3.0 from the Frenemy object's types; that's for the library itself, whereas the AceAddon type is for the actual AddOn.  
- Swap all repository URIs from "wowace" to "curseforge"  
