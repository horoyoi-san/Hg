using Campofinale.Commands;
using Campofinale.Database;
using Campofinale.Game;
using Campofinale.Http;
using Campofinale.Protocol;
using Campofinale.Resource;
using Pastel;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Runtime.InteropServices;
using System.ServiceProcess;

namespace Campofinale
{
    public static class DateTimeExtensions
    {
        private static readonly DateTime UnixEpoch = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        public static long ToUnixTimestampMilliseconds(this DateTime dateTime)
        {
            return (long)(dateTime - UnixEpoch).TotalMilliseconds;
        }
        public static DateTime GetNextDailyReset(this DateTime dateTime)
        {
            DateTime now = DateTime.UtcNow;
            DateTime todayReset = new DateTime(now.Year, now.Month, now.Day, 6, 0, 0, DateTimeKind.Utc);

            // Se siamo già passati oltre le 6:00 AM di oggi, ritorna le 6:00 AM di domani
            if (now >= todayReset)
                return todayReset.AddDays(1);
            else
                return todayReset;
        }
    }
    public class Server
    {

        public class HandlerAttribute : Attribute
        {
            public CsMsgId CmdId { get; set; }
            public HandlerAttribute(CsMsgId cmdID)
            {
                this.CmdId = cmdID;
            }
            public delegate void HandlerDelegate(Player client, int cmdId, Network.Packet packet);
        }
        public class CommandAttribute : Attribute
        {
            public string command;
            public string desc;
            public bool requiredTarget;
            public CommandAttribute(string cmdName, string desc = "No description", bool requireTarget=false)
            {
                this.command = cmdName;
                this.desc = desc;
                this.requiredTarget = requireTarget;
            }
            public delegate void HandlerDelegate(Player sender, string command, string[] args, Player target);
        }
        public static List<Player> clients = new List<Player>();
        public static string ServerVersion = "1.1.8-dev";
        public static bool Initialized = false;
        public static bool showLogs = true;
        public static bool showWarningLogs = true;
        public static bool showBodyLogs = false;
        public static Dispatch? dispatch;
        public static ConfigFile? config;
        public static List<CsMsgId> csMessageToHide = new() { CsMsgId.CsMoveObjectMove, CsMsgId.CsBattleOp,CsMsgId.CsPing };
        public static List<ScMsgId> scMessageToHide = new() { ScMsgId.ScMoveObjectMove, ScMsgId.ScPing,ScMsgId.ScObjectEnterView,ScMsgId.ScFactoryHsSync };
        public void Start(ConfigFile config)
        {
            {
                Assembly assembly = Assembly.GetExecutingAssembly();
                Type[] types = assembly.GetTypes();

                foreach (var type in types)
                {
                    NotifyManager.AddReqGroupHandler(type);
                    CommandManager.AddReqGroupHandler(type);
                }

                NotifyManager.Init();
                CommandManager.Init();
            }
            
            Logger.Initialize();
            Server.config = config;
            showLogs = config.logOptions.packets;
            showWarningLogs = config.logOptions.packetWarnings;
            showBodyLogs = config.logOptions.packetBodies;
            Logger.Print($"Starting server version {ServerVersion} with supported client version: WINDOWS-{GameConstants.GAME_VERSION} and MOBILE-{GameConstants.GAME_VERSION_ANDROID}");
            Logger.Print($"Logs are {(showLogs ? "enabled" : "disabled")}");
            Logger.Print($"Warning logs are {(showWarningLogs ? "enabled" : "disabled")}");
            Logger.Print($"Packet body logs are {(showBodyLogs ? "enabled" : "disabled")}");
            StartDBService();
            DatabaseManager.Init();
            ResourceManager.Init();
            new Thread(new ThreadStart(DispatchServer)).Start();
            
            IPAddress ipAddress = IPAddress.Parse(Server.config.gameServer.bindAddress);
            int port = Server.config.gameServer.bindPort;
            Socket serverSocket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
            new Thread(new ThreadStart(CmdListener)).Start();
            new Thread(new ThreadStart(Update)).Start();
            try
            {
                serverSocket.Bind(new IPEndPoint(ipAddress, port));
                serverSocket.Listen(int.MaxValue);
                Logger.Print($"Server listening on {ipAddress}:{port}");
                Initialized = true;
                while (true)
                {
                    Socket clientSocket = serverSocket.Accept();
                    
                    if (clientSocket.Connected)
                    {
                        Logger.Print("Connected new client: " + clients.Count()+1);
                        try
                        {
                            Player client = new Player(clientSocket);
                            clients.Add(client);
                            client.receivorThread.Start();
                        }
                        catch (Exception e)
                        {
                            Logger.PrintError($" {e.Message}");
                        }
                        

                        
                    }


                }
            }
            catch (Exception ex)
            {
                Logger.PrintError($" {ex.Message}");
            }
            finally
            {
                serverSocket.Close();
                Logger.Print("Server stopped.");
            }

        }
        public void Update()
        {
            while (true)
            {
                try
                {
                    clients.ForEach(client => { if (client != null) client.Update(); });
                    Thread.Sleep(250);
                }
                catch (Exception ex)
                {

                }
            }
        }
        public void CmdListener()
        {
            while (true)
            {
                try
                {
                    string cmd = Console.ReadLine()!;
                    string[] split = cmd.Split(" ");
                    string[] args = cmd.Split(" ").Skip(1).ToArray();
                    string command = split[0].ToLower();
                    CommandManager.Notify(null,command, args,clients.Find(c=>c.accountId==CommandManager.targetId));
                }
                catch (Exception ex)
                {
                    Logger.PrintError(ex.Message);
                }

            } 

        }
        public void DispatchServer()
        {
            dispatch = new Dispatch();
            dispatch.Start();
        }

        public static string ColoredText(string text, string color)
        {
            return text.Pastel(color);
        }
        public static void Shutdown()
        {
            foreach (Player player in clients)
            {
                if(player.Initialized)
                player.Save();
                player.Kick(CODE.ErrServerClosed);
            }
        }
        private static void StartDBService()
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                try
                {
                    string mongodbService = "MongoDB";
                    using (ServiceController service = new ServiceController(mongodbService))
                    {
                        if (service.Status != ServiceControllerStatus.Running)
                        {
                            Logger.Print($"Starting {mongodbService} service...");
                            service.Start();
                            service.WaitForStatus(ServiceControllerStatus.Running, TimeSpan.FromSeconds(30));
                            Logger.Print($"Started {mongodbService} service");
                        }
                    }
                }
                catch (Exception e)
                {
                    Logger.PrintError($"Failed to Start MongoDB service: {e}");
                }
        }
    }
}
