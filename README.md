# Campofinale
[EN](README.md) | [IT](docs/README_it-IT.md) | [RU](docs/README_ru-RU.md) | [CN](docs/README_zh-CN.md) | [NL](docs/README_nl-NL.md)

Campofinale is a experimental server implementation for a certain factory building game.

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

## Installation Steps (Windows)

1. Install:
   * [.NET SDK](https://dotnet.microsoft.com/en-us/download) (8.0.12 is recommended)
   * [MongoDB](https://www.mongodb.com/try/download/community)
   * [mitmproxy](https://mitmproxy.org/)

    1. Make sure to setup Mitmproxy accordingly, and of course install the certificate system-wide.
    
2. Download the [precompiled build](https://github.com/Campofinale/Campofinale/releases/latest) or build it by yourself
3. Put the `Json`, `TableCfg` and `DynamicAssets` folders inside the `Campofinale.exe` folder (you can download a copy [here](https://github.com/PotRooms/EndFieldData/tree/main))
4. Run the server (`Campofinale.exe`)
5. Proxy post-install setup

    ```shell
    mitmproxy -s ak.py
    ```

    Get ak.py from [here](https://git.teamstardust.org/Campofinale/Campofinale/src/branch/development/docs/ak.py)
    
6. Run the Mitmproxy command (from above) if you haven't

7. Run the Game Client and start to play! (Note: Only OS client is supported for now)
8. You must create an account using `account create (username)` in the server console, then login in the game with an email like `(username)@randomemailformathere.whatyouwant`. There is no password so you can input a random password for its field.

## Additional Information

You can find the description of all server commands [here](docs/CommandList/commands_en-US.md).<br>
The list of all scenes is [here](docs/LevelsTable.md).<br>
The list of all enemies is [here](docs/EnemiesTable.md).<br>
The list of all characters is [here](docs/CharactersTable.md).<br>
The list of all items is [here](docs/ItemsTable.md).<br>

If you want to open the in-game console, go to `Settings -> Platform & Account -> Account Settings (Access Account button)`. To view available commands, type `help`.

## Discord for support

If you want to discuss, ask for support or help with this project, join our [Discord Server](https://discord.gg/YZGYtAxeZk)!

## Note

This project is developed independently, and all rights to the original game assets and intellectual property belong to their respective owners.
