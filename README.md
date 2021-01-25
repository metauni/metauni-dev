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


## Building tips

Be careful with the select tool, it does not have a distance filter! So if you drag to select a bunch of objects, be vigilant that you haven't selected parts halfway across the world (often this will manifest as trees or other objects being moved, or unanchored, so they fall over). To avoid problems like this you should get into the habit of using the Lock tool on parts of the world you aren't currently editing.
