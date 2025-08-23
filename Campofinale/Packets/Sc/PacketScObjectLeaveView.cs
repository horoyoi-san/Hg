using Campofinale.Network;
using Campofinale.Protocol;

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
