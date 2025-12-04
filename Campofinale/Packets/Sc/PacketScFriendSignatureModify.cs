using Campofinale.Network;
using Campofinale.Protocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Packets.Sc
{
    internal class PacketScFriendSignatureModify : Packet
    {
        public PacketScFriendSignatureModify(CsFriendSignatureModify req)
        {
            SetData(ScMsgId.ScFriendSignatureModify, new ScFriendSignatureModify() { Signature = req.Signature });
        }
    }
}
