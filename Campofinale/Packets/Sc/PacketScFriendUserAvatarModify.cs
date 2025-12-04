using Campofinale.Network;
using Campofinale.Protocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Packets.Sc
{
    internal class PacketScFriendUserAvatarModify : Packet
    {
        public PacketScFriendUserAvatarModify(CsFriendUserAvatarModify req)
        {
            SetData(ScMsgId.ScFriendUserAvatarModify, new ScFriendUserAvatarModify() { UserAvatarId = req.UserAvatarId });
        }
    }
}
