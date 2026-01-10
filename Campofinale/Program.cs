using Campofinale;
using Newtonsoft.Json;
using System.Net.Sockets;
using System.Net;
using Campofinale.Network;
using Campofinale.Protocol;
using Google.Protobuf;
using System.Drawing;
using StardustUtils;

class Program
{
    static void Main(string[] args)
    {
        if (!F05774815C749192A285FA14BC2A757C.Method_DE2C9ACE2CD4DEEFE80F95290ECD5C6B())
        {
            throw new Exception("Signchecker validation failed!!!!!!!! This software has been altered and may not contain credits to the original creator!!!!");
        }

        try
        {
            StartServer(args);
            //FakeClientTester();
        }
        catch (Exception ex)
        {
            // Catch all exceptions to prevent window from closing
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("\n" + new string('=', 80));
            Console.WriteLine("FATAL ERROR:");
            Console.WriteLine(new string('=', 80));
            Console.WriteLine($"{ex.GetType().Name}: {ex.Message}");
            Console.WriteLine($"\nStackTrace:\n{ex.StackTrace}");
            Console.WriteLine(new string('=', 80));
            Console.ResetColor();

            // Keep window open
            Console.WriteLine("\nPress any key to exit...");
            Console.ReadKey();
        }
    }
    public static byte[] ConcatenateByteArrays(byte[] array1, byte[] array2)
    {
        return array1.Concat(array2).ToArray();
    }
    private static void FakeClientTester()
    {
        //beyond-ric.gryphline.com
        string serverIp = "beyond-euandus.gryphline.com";
        int serverPort = 30000;
        Socket socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
        IPAddress[] addresses = Dns.GetHostAddresses(serverIp);

        IPAddress ipAddress = addresses[0];

        socket.Connect(new IPEndPoint(ipAddress, serverPort));
        //CBT 3 info we got: Proto body encrypted, Packet format seem the same, Cmd Id is not encrypted and is not shuffled
        socket.Send(Packet.EncodePacket((int)CsMsgId.CsLogin, new CsLogin() { ClientVersion = "0.5.5", Uid = "", Token = "", Env = EnvType.Prod, PlatformId = ClientPlatformType.Windows, Area = AreaType.Oversea, ClientResVersion = "" }.ToByteArray()));
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
                            //ScNtfErrorCode p2 = ScNtfErrorCode.Parser.ParseFrom(packet.finishedBody);
                            //Console.WriteLine(JsonConvert.SerializeObject(p2));
                            string base642 = Convert.ToBase64String(packet.finishedBody);

                            Console.WriteLine($"{(ScMsgId)packet.cmdId}: HEAD:{packet.csHead.ToString()} BODY:{base642}");
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