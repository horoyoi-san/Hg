using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScMoveObjectMove : Packet
    {
        public PacketScMoveObjectMove(Player client, ScMoveObjectMove move)
        {
            SetData(ScMsgId.ScMoveObjectMove, move);
        }
    }
}

