using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Cs
{
    
    public class HandleCsFriendListQuery
    {
        [Server.Handler(CsMsgId.CsFriendListQuery)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFriendListQuery req = packet.DecodeBody<CsFriendListQuery>();
            session.Send(new PacketScFriendListQuery(session,req),packet.csHead.UpSeqid);
        }
    }
}
