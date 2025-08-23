using Campofinale;
using Newtonsoft.Json;
using System.Net.Sockets;
using System.Net;
using Campofinale.Network;
using Campofinale.Protocol;
using Google.Protobuf;
using Pastel;
using System.Drawing;

class Program
{
    static void Main(string[] args)
    {
       StartServer(args);
       //FakeClientTester();
    }
    public static byte[] ConcatenateByteArrays(byte[] array1, byte[] array2)
    {
        return array1.Concat(array2).ToArray();
    }
    private static void FakeClientTester()
    {
        //
        string serverIp = "beyond-ric.gryphline.com"; 
        int serverPort = 30000;
        Socket socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);

        IPAddress[] addresses = Dns.GetHostAddresses(serverIp);

        IPAddress ipAddress = addresses[0];

        socket.Connect(new IPEndPoint(ipAddress, serverPort));

         socket.Send(Packet.EncodePacket((int)CsMsgId.CsLogin,new CsLogin() { ClientVersion="0.5.5",Uid= "", Token= "", Env=EnvType.Prod,PlatformId=ClientPlatformType.Windows,Area=AreaType.Oversea,ClientResVersion="", LoginToken= "" }.ToByteArray()));
        //socket.Send(Packet.EncodePacket((int)CsMsgId.CsFriendListSync, new CsFriendListSync() { }.ToByteArray()));
        while (true)
        {
            byte[] buffer = new byte[3];
            int length = socket.Receive(buffer);
            if (length == 3)
            {
                Packet packet = null;
                byte headLength = Packet.GetByte(buffer, 0);
                ushort bodyLength = Packet.GetUInt16(buffer, 1);
                byte[] moreData = new byte[bodyLength + headLength];
                
                while (socket.Available < moreData.Length)
                {

                }
                int mLength = socket.Receive(moreData);
                if (mLength == moreData.Length)
                {
                    buffer = ConcatenateByteArrays(buffer, moreData);
                    packet = Packet.Read(buffer);
                   
                    switch ((ScMsgId)packet.cmdId)
                    {
                        case ScMsgId.ScLogin:
                            ScLogin p1 = ScLogin.Parser.ParseFrom(packet.finishedBody);
                            Console.WriteLine(JsonConvert.SerializeObject(p1));
                            break;
                        case ScMsgId.ScNtfErrorCode:
                            ScNtfErrorCode p2 = ScNtfErrorCode.Parser.ParseFrom(packet.finishedBody);
                            Console.WriteLine(JsonConvert.SerializeObject(p2));
                            break;
                        default:
                            string base64 = Convert.ToBase64String(packet.finishedBody);
                            Console.WriteLine($"{(ScMsgId)packet.cmdId}: {base64}");
                            break;
                    }

                    

                }
            }
        }
    }
    private static void StartServer(string[] args)
    {
        Console.Title = "Initializing...";
        ConfigFile config = new ConfigFile();
        if (File.Exists("server_config.json"))
        {
            config = JsonConvert.DeserializeObject<ConfigFile>(File.ReadAllText("server_config.json"))!;
        }
        File.WriteAllText("server_config.json", JsonConvert.SerializeObject(config, Formatting.Indented));

        new Thread(() =>
        {
            new Server().Start(config);
        }).Start();
        AppDomain.CurrentDomain.ProcessExit += (_, _) =>
        {
            Logger.Print("Shutting down...");
            
            Server.Shutdown();
        };

        while (Server.Initialized == false)
        {

        }
        Console.Title = $"Campofinale Server v{Server.ServerVersion}";
    }
}