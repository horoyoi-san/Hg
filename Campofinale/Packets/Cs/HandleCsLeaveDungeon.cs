using Campofinale.Network;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsLeaveDungeon
    {
        
        [Server.Handler(CsMsgId.CsLeaveDungeon)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsLeaveDungeon req = packet.DecodeBody<CsLeaveDungeon>();

            session.LeaveDungeon(req);

        }
       
    }
}
