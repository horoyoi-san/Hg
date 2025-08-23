using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsGetMail
    {

        [Server.Handler(CsMsgId.CsGetMail)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsGetMail req = packet.DecodeBody<CsGetMail>();
            session.Send(new PacketScGetMail(session));
        }
       
    }
}
