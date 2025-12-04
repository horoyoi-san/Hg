using Campofinale.Network;
using Campofinale.Protocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Packets.Sc
{
    internal class PacketScFriendBusinessCardExpandFlagModify : Packet
    {
        public PacketScFriendBusinessCardExpandFlagModify(CsFriendBusinessCardExpandFlagModify req)
        {
            SetData(ScMsgId.ScFriendBusinessCardExpandFlagModify, new ScFriendBusinessCardExpandFlagModify()
            {
                Flag = req.Flag,
            });
        }
    }
}
