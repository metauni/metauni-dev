To add a chat command, like `\ban username`
- Notice the `Chat` section of Explorer, which has nothing in it by default. This gets populated with the entire chat backend on startup, and can be partially overwritten as needed.
- Click `Play` in Roblox Studio to start up the world (the Chat section will be populated now).
- Copy the entire `ClientChatModules` and then stop the world.
- Paste it under `Chat` (same spot it was).
- Now we delete everything we want to leave as is (and get updated as Roblox does), for example, delete everything in `ClientChatModules` except `CommandModules` and delete everything in `CommandModules` except `InsertDefaultModules` (this is a `BoolValue` that tells Roblox to put the default command modules in this folder, even though we have "overwritten" it) and the `ModuleScript` called `GetVersion`, as an example template command.
- Modify the `GetVersion` module script as needed, and look here for the documentation. https://developer.roblox.com/en-us/articles/Lua-Chat-System 