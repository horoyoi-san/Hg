using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScBitsetAdd : Packet
    {

        public PacketScBitsetAdd(Player client, int type, List<uint> values) {

            ScBitsetAdd proto = new()
            {
                Type = type,
                Value =
                {
                    values
                }
            };
            
            SetData(ScMsgId.ScBitsetAdd, proto);
        }

    }
}
