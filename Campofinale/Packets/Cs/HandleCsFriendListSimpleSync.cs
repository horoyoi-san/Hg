using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Cs
{
    
    public class HandleCsFriendListSimpleSync
    {
        [Server.Handler(CsMsgId.CsFriendListSimpleSync)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFriendListSimpleSync req = packet.DecodeBody<CsFriendListSimpleSync>();
            session.Send(new PacketScFriendListSimpleSync(session));
        }
    }
}
