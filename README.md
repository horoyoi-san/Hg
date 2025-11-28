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
   * [Fiddler Classic](https://www.telerik.com/fiddler/fiddler-classic) OR [mitmproxy](https://mitmproxy.org/)

    1. When installing *Fiddler Classic*, make sure to **enable** "Decrypt HTTPS traffic" and **install** the certificate!
    1. You have to enable two features via Tools (top left in menubar) -> Options -> HTTPS -> Check "Capture HTTPS CONNECTs" and "Decrypt HTTPS traffic". You can also re-install the certificate via Actions (right next to "Capture HTTPS CONNECTs") -> Trust Root Certificate and press "Yes"
2. Download the [precompiled build](https://github.com/Campofinale/Campofinale/releases/latest) or build it by yourself
3. Put the `Json`, `TableCfg` and `DynamicAssets` folders inside the `Campofinale.exe` folder (you can download a copy [here](https://github.com/horoyoi-san/Hg/tree/EndfieldData))
4. Run the server (`Campofinale.exe`)
5. Overwrite the `C:\Users\<YourUserName>\Documents\Fiddler2\Scripts\CustomRules.js` script (or backup the default one and create a new file with the same name) with the following script:
    * You can also run *Fiddler Classic*, go to `Rules -> Customize Rules` (CTRL + R) and save it, or by selecting the *FiddlerScript* tab

    ```javascript
    import System;
    import System.Windows.Forms;
    import Fiddler;
    import System.Text.RegularExpressions;

    class Handlers
    {
        static function OnBeforeRequest(oS: Session) {
            if(
                oS.fullUrl.Contains("discord") ||
                oS.fullUrl.Contains("steam") ||
                oS.fullUrl.Contains("git") ||
                oS.fullUrl.Contains("yandex")
            //you can add any addresses if some sites don't work
            ) {
                oS.Ignore();
            }
        
            if (!oS.oRequest.headers.HTTPMethod.Equals("CONNECT")) {
                if(oS.fullUrl.Contains("gryphline.com") || oS.fullUrl.Contains("hg-cdn.com")) {
                    oS.fullUrl = oS.fullUrl.Replace("https://", "http://");
                    oS.host = "localhost"; // place another ip if you need
                    oS.port = 5000; //and port
                }
            }
        }
    };
    ```
    By Xannix
    Or you can use the mitmproxy command:

    ```shell
    mitmproxy -s ak.py
    ```

    ak.py:

    ```py
    import mitmproxy
    from mitmproxy import ctx, http
    class EndFieldModifier:
        def requestheaders(self,flow: mitmproxy.http.HTTPFlow):
            if "gryphline.com" in flow.request.host or "hg-cdn.com" in flow.request.host:
                if flow.request.method=="CONNECT":
                    return
                
                flow.request.scheme="http"
                flow.request.cookies.update({
                    "OriginalHost":flow.request.host,
                    "OriginalUrl":flow.request.url
                })
                flow.request.host="localhost"
                flow.request.port=5000
                ctx.log.info("URL:"+flow.request.url)
                
                
                
    addons=[
        EndFieldModifier()
    ]
    ```

6. Run *Fiddler Classic* - it should start with the new *Custom Rules script* (you can check it in the *FiddlerScript* tab)
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
