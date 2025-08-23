using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScBitsetRemove : Packet
    {

        public PacketScBitsetRemove(Player client, int type, List<uint> values) {

            ScBitsetRemove proto = new()
            {
                Type = type,
                Value =
                {
                    values
                }
            };
            
            SetData(ScMsgId.ScBitsetRemove, proto);
        }

    }
}
