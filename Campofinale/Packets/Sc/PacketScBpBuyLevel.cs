using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    internal class PacketScBpBuyLevel : Packet
    {
        public PacketScBpBuyLevel(Player client, ScBpBuyLevel result)
        {
            SetData(ScMsgId.ScBpBuyLevel, result);
        }
    }
}

