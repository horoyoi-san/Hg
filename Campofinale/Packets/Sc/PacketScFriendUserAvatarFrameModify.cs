using Campofinale.Network;
using Campofinale.Protocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Packets.Sc
{
    internal class PacketScFriendUserAvatarFrameModify : Packet
    {
        public PacketScFriendUserAvatarFrameModify(CsFriendUserAvatarFrameModify req)
        {
            SetData(ScMsgId.ScFriendUserAvatarFrameModify, new ScFriendUserAvatarFrameModify() { UserAvatarFrameId = req.UserAvatarFrameId });
        }
    }
}
