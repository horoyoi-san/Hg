using Campofinale.Protocol;
using Campofinale.Network;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Packets.Sc
{
    internal class PacketScFriendBusinessCardTopicModify : Packet
    {
        public PacketScFriendBusinessCardTopicModify(CsFriendBusinessCardTopicModify req)
        {
            SetData(ScMsgId.ScFriendBusinessCardTopicModify, new ScFriendBusinessCardTopicModify()
            {
                Id = req.Id,
            });
        }
    }
}
