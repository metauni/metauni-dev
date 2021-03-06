# Metauni development

This repository hosts demonstration Roblox levels and common code snippets used within these nodes, as well as (eventually) open source tools.

## Discord bot

Here are the commands the Discord bot understands. You can issue these commands in any channel:

* `!setup` can only be issued by the server owner. Sets the log channel to the current channel.
* `!register <roblox-username>` registers the given Roblox username to the author of the command.
* `!unregister` unregisters the Roblox username associated to the author, if any.
* `!gather <zone_name>` move all users into the given voice channel.

## metauni-node-template.rbxl

- Workspace -> **Spawn Location**: where players spawn into your place (move this down into the ground to make it invisible)
- Workspace -> **Zones**: translucent zones which will correspond to voice channels within your discord channel
  - Each zone in this folder is a `Model` with a primary `Part` (the physical object), with `Transparency: 0.9` and `CanCollide` disabled so players can see and walk through it.
- Workspace -> **metauniPortal**: teleports players to the metauni hub.
  - This can be duplicated and customised to teleport to any other place (i.e. another metauni node).
  - To make a portal to, for example, [The Rising Sea](https://www.roblox.com/games/6224932973/The-Rising-Sea), duplicate the portal and take the placeID `6224932973` from the game url https://www.roblox.com/games/6224932973/The-Rising-Sea. Then double-click the `teleportScript` inside your new portal and modify the place ID in the line `local placeID_1 = 6233302798`.
  - If you'd like your node to be accessible from the metauni hub, send your place ID to <admin@metauni.org>. 
- ServerScriptService -> **ZonesScript**: adds triggers to each zone in the `Zones` folder, which tell the discord bot which voice channel to move each player into, according to the current zone they are touching

## TRS.rbxl

A reasonably up-to-date copy of the Rising Sea Roblox file, demonstrating many of the features you may wish to copy in your node (please go ahead!). The `ZonesScript` file is the only omission, since this is covered by `metauni-node-template`. Most of the objects in the world are locked, I left unlocked the things you are most likely to be interested in at the beginning (e.g. slides). To copy objects you will often need to copy the underlying Part and also the code in `StarterGUI`, see [this video](https://youtu.be/rHaRz8J79S4).

## Building tips

Be careful with the select tool, it does not have a distance filter! So if you drag to select a bunch of objects, be vigilant that you haven't selected parts halfway across the world (often this will manifest as trees or other objects being moved, or unanchored, so they fall over). To avoid problems like this you should get into the habit of using the Lock tool on parts of the world you aren't currently editing.

## Limitations

Here are the things that might break on you:

* The current Discord bot uses the [repl.it database](https://docs.repl.it/misc/database) which has a limit of 5000 keys. Since old registrations are not automatically removed, you should probably periodically check whether you are close to hitting this limit (if new users fail to register, you've probably hit it). In this case you will have to transition to a MongoDB database or host your own.

* There are rate limits on the Discord bot. In principle you could use one Discord server for many Roblox worlds, but if you have many users and many zones, it is possible that the Discord bot will exceed these rate limits (it seems unlikely to me but I haven't checked the numbers).

* Currently Roblox servers are capped at 100 users (at least the ones I can make). If you exceed this, it will spawn new users into a copy of the server. For example if you plan to host a talk, you can have >100 users on Discord listening but only 100 of them will be in the same copy of the server as the speaker.
