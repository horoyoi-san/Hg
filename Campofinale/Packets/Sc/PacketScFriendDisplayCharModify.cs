using Campofinale.Network;
using Campofinale.Protocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Packets.Sc
{
    internal class PacketScFriendDisplayCharModify : Packet
    {
        public PacketScFriendDisplayCharModify(CsFriendDisplayCharModify req)
        {
            ScFriendDisplayCharModify resp = new ScFriendDisplayCharModify() { ObjIdList = { } };
            foreach (var id in req.ObjIdList)
            {
                resp.ObjIdList.Add(id);
            }
            SetData(ScMsgId.ScFriendDisplayCharModify, resp);
        }
    }
}
