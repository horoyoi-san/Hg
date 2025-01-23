# EndField PS for CBT2
Paste Json folder from [EndFieldData](https://github.com/PotRooms/EndFieldData/tree/main) in the server directory for make it work.
--
## Requirements
- ## [NET 8.0](https://download.visualstudio.microsoft.com/download/pr/136f4593-e3cd-4d52-bc25-579cdf46e80c/8b98c1347293b48c56c3a68d72f586a1/dotnet-runtime-8.0.12-win-x64.exe)

## 1. Open the project in Visual Studio Code:

- Open Visual Studio Code.
- Go to File > Open Folder... and select the EndFieldPS-master directory.
## 2. Restore NuGet packages:
```
dotnet restore
```
- Open the terminal in Visual Studio Code (Ctrl + ).
- Run the following command to restore the NuGet packages:
## 3. Build the project:
- In the terminal, run the following command to build the project:
```
dotnet build
```
## 4. Run the project:
- In the terminal, run the following command to run the project:
```
dotnet run --project EndFieldPS/EndFieldPS.csproj
```
This will start the application. Make sure you have the .NET SDK installed on your machine. If you encounter any issues, please provide the error messages for further assistance.

## Use this fiddler script, also make sure to use the os client, the cn one is not yet supported
```
import System;
import System.Windows.Forms;
import Fiddler;
import System.Text.RegularExpressions;

class Handlers
{
    static function OnBeforeRequest(oS: Session) {
        if(oS.host.Contains("gryphline.com") || oS.host.Contains("hg-cdn.com")) {
            if(oS.host.Contains("as") || oS.host.Contains("u8")){
              //  return;   
            }
            if(oS.HTTPMethodIs("CONNECT")){
                return;
            }
            FiddlerObject.log(">>>>>>>>>>>> URL:" + oS.fullUrl);
            oS.oRequest.headers.UriScheme = "http";
            oS.oRequest["Cookie"] = (oS.oRequest["Cookie"] + ";OriginalHost=" + oS.host + ";OriginalUrl=" + oS.fullUrl);
            oS.host = "localhost:5000";
        }
    }
};
```
----
CR. https://github.com/SuikoAkari/EndFieldPS
https://github.com/SuikoAkari/EndFieldPS/releases/tag/1.0.1
