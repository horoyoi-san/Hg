using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsEnterDungeon
    {
        
        [Server.Handler(CsMsgId.CsEnterDungeon)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsEnterDungeon req = packet.DecodeBody<CsEnterDungeon>();
            session.EnterDungeon(req.DungeonId, req);

        }
       
    }
}
