using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScSetName: Packet
    {
        public PacketScSetName(Player player, string nickname) {
            ScSetName proto = new ScSetName() {
                Name = nickname,
                ShortId = player.accountId
            };

            SetData(ScMsgId.ScSetName, proto);
        }
    }
}
