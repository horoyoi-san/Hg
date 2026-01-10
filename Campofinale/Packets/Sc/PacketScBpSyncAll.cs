using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScBpSyncAll : Packet
    {

        public PacketScBpSyncAll(Player client) {

            ScBpSyncAll proto = client.battlePassManager.ToProto();

            SetData(ScMsgId.ScBpSyncAll, proto);
        }

    }
}
