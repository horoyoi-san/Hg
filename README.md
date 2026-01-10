# Campofinale
[EN](README.md) | [IT](docs/README_it-IT.md) | [RU](docs/README_ru-RU.md) | [CN](docs/README_zh-CN.md) | [NL](docs/README_nl-NL.md)

Campofinale is an experimental server implementation for a certain factory building game.

## Current Features

* Login
* Character switch
* Team switch
* Scene switch
* Save data with MongoDB
* Combat system


## TODO
* Android Support
* Mission System
* Working buffs
* Fixing Factory system for new versions

## Installation Steps (Windows)

1. Install:
   * [.NET SDK](https://dotnet.microsoft.com/en-us/download) (8.0.12 is recommended)
   * [MongoDB](https://www.mongodb.com/try/download/community)
    
2. Download the [precompiled build](https://git.teamstardust.org/Campofinale/Campofinale/releases/latest) or build it [yourself](#manual-build)

3. Get the `Json`, `TableCfg` and `DynamicAssets` folders from [here](https://git.teamstardust.org/Campofinale/EndfieldData) and place them in the same folder as `Campofinale.exe`
4. Run the server (`Campofinale.exe`)
5. Patch the game (get the patch from our Discord) - Run launcher.exe after (Note: Only OS client is supported for now, CN CBT3 could work too because offsets are the same)
6. Create an account (required) using `account create (username) [uid]` in the server console, then login in the game with an email like `(username)@randomemailformathere.whatyouwant`. (uid is optional) There is no actual password requirement for the ps so you can input a random password for its field.

## Additional Information

You can find the description of all server commands [here](docs/CommandList/commands_en-US.md).<br>
The list of all scenes is [here](docs/LevelsTable.md).<br>
The list of all enemies is [here](docs/EnemiesTable.md).<br>
The list of all characters is [here](docs/CharactersTable.md).<br>
The list of all items is [here](docs/ItemsTable.md).<br>

If you want to open the in-game console, go to `Settings -> Platform & Account -> Account Settings (Access Account button)`. To view available commands, type `help`.

## Manual build
- Make sure .NET 8.0 SDK is installed
- Open a command prompt/terminal in the same folder as the .sln file and run:
```sh
dotnet build -c Release
```
- Output will be at Campofinale/bin/Release/net8.0

- Or build with Visual Studio if you have it installed (and the .NET desktop development "module")


## Discord for support

If you want to discuss, ask for support or help with this project, join our [Discord Server](https://discord.gg/HdXZY2Q9vs)!

## Note

This project is developed independently, and all rights to the original game assets and intellectual property belong to their respective owners.
