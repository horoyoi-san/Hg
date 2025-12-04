using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Packets.Cs
{
    internal class HandleCsFriendUserAvatarFrameModify
    {
        [Server.Handler(CsMsgId.CsFriendUserAvatarFrameModify)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFriendUserAvatarFrameModify req = packet.DecodeBody<CsFriendUserAvatarFrameModify>();

            session.personalData.userAvatarFrameId = (int)req.UserAvatarFrameId;
            session.Save();
            session.Send(new PacketScFriendUserAvatarFrameModify(req));
        }
    }
}
