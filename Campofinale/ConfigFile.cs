namespace Campofinale
{
    public class ConfigFile
    {
        public MongoDatabaseSettings mongoDatabase = new();
        public DispatchServerSettings dispatchServer = new();
        public GameserverSettings gameServer = new();
        public ServerOptions serverOptions = new();
        public LogSettings logOptions = new();
        public ResourcePathsSettings resourcePaths = new();
    }
    public class ServerOptions
    {
        public int defaultSceneNumId = 87;
        public int maxPlayers = 20;
        /// <summary>
        /// Experimental, Mission System is still a work in progress.
        /// </summary>
        public bool missionsEnabled = false;

        //public bool giveAllItems = false;

        public bool disableLevelscripts = true;
        /// <summary>
        /// Not yet implemented
        /// </summary>
        public bool useEncryption = false;
        public ServerOptions()
        {
        }

    }
    public class LogSettings
    {
        public bool packets = true;
        public bool packetWarnings = true;
        public bool packetBodies = false;
        public bool debugPrint = false;
        public List<string> packetBodyMessages = new(); // List of message names to output body for

        public LogSettings()
        {
        }
    }
    public class GameserverSettings
    {
        public string bindAddress = "127.0.0.1";
        public int bindPort = 30000;
        public string accessAddress = "127.0.0.1";
        public int accessPort = 30000;
        public bool useExternalAuthSdk = false;
        public string externalAuthSdkUrl = "";
        public GameserverSettings()
        {
        }
    }
    public class DispatchServerSettings
    {
        public string bindAddress = "127.0.0.1";
        public int bindPort = 5000;
        public string accessAddress = "127.0.0.1";
        public int accessPort = 5000;
        public string emailFormat = "@campofinale.ps";
        public DispatchServerSettings()
        {

        }
    }
    public class MongoDatabaseSettings
    {
        public string uri = "mongodb://localhost:27017";
        public string collection = "Campofinale";
        public MongoDatabaseSettings()
        {
        }
    }
    public class ResourcePathsSettings
    {
        public string baseDirectory = "./";
        public string tableCfgPath = "TableCfg";
        public string jsonPath = "Json";
        public string dynamicAssetsPath = "DynamicAssets";
        public ResourcePathsSettings()
        {
        }
    }
}
