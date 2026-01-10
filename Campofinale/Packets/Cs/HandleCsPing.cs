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
            long curTimestamp = DateTime.UtcNow.ToUnixTimestampMilliseconds();

            session.Send(Packet.EncodePacket((int)ScMsgId.ScPing, new ScPing()
            {
                ClientTs = req.ClientTs,
                ServerTs = (ulong)curTimestamp,
            }));
            session.factoryManager.SendFactoryHsSync();

            //Logger.Print("Server: " + curTimestamp + " client: " + req.ClientTs);
        }

    }
}
