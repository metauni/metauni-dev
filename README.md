# Metauni development

This repository hosts demonstration Roblox levels and common code snippets used within these nodes, as well as (eventually) open source tools.

## metauni-node-template

- Workspace -> **Spawn Location**: where players spawn into your place (move this down into the ground to make it invisible)
- Workspace -> **Zones**: translucent zones which will correspond to voice channels within your discord channel
  - Each zone in this folder is a `Model` with a primary `Part` (the physical object), with `Transparency: 0.9` and `CanCollide` disabled so players can see and walk through it.
- Workspace -> **metauniPortal**: teleports players to the metauni hub.
  - This can be duplicated and customised to teleport to any other place (i.e. another metauni node).
  - To make a portal to, for example, [The Rising Sea](https://www.roblox.com/games/6224932973/The-Rising-Sea), duplicate the portal and take the placeID `6224932973` from the game url https://www.roblox.com/games/6224932973/The-Rising-Sea. Then double-click the `teleportScript` inside your new portal and modify the place ID in the line `local placeID_1 = 6233302798`.
  - If you'd like your node to be accessible from the metauni hub, send your place ID to <admin@metauni.org>. 
- ServerScriptService -> **ZonesScript**: adds triggers to each zone in the `Zones` folder, which tell the discord bot which voice channel to move each player into, according to the current zone they are touching
