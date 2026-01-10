using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    internal class PacketScBpLevelModify : Packet
    {
        public PacketScBpLevelModify(Player client, ScBpLevelModify result)
        {
            SetData(ScMsgId.ScBpLevelModify, result);
        }
    }
}

