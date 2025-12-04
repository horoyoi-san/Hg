using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    internal class HandleCsFriendUserAvatarModify
    {
        [Server.Handler(CsMsgId.CsFriendUserAvatarModify)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFriendUserAvatarModify req = packet.DecodeBody<CsFriendUserAvatarModify>();

            session.personalData.userAvatarId = (int)req.UserAvatarId;
            session.Save();
            session.Send(new PacketScFriendUserAvatarModify(req));
        }
    }
}
