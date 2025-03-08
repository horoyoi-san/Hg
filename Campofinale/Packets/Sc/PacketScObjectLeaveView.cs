using Campofinale.Game.Entities;
using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Packets.Sc
{
    public class PacketScObjectLeaveView : Packet
    {

        public PacketScObjectLeaveView(Player session, List<ulong> guids) {

            ScObjectLeaveView proto = new()
            {
                
            };
            foreach(ulong guid in guids)
            {
                proto.ObjList.Add(new LeaveObjectInfo()
                {
                    ObjId = guid,
                    
                });
            }
           

            SetData(ScMsgId.ScObjectLeaveView, proto);
        }

    }
}
