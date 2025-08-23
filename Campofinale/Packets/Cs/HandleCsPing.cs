using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsPing
    {

        [Server.Handler(CsMsgId.CsPing)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsPing req = packet.DecodeBody<CsPing>();
            long curtimestamp = DateTime.UtcNow.ToUnixTimestampMilliseconds();

            session.Send(Packet.EncodePacket((int)ScMsgId.ScPing, new ScPing()
            {
                ClientTs = req.ClientTs,
                ServerTs = (ulong)curtimestamp,
            }));
            session.factoryManager.SendFactoryHsSync();

            //Logger.Print("Server: " + curtimestamp + " client: " + req.ClientTs);
        }
       
    }
}
