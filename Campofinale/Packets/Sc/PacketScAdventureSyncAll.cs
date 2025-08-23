using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScAdventureSyncAll : Packet
    {

        public PacketScAdventureSyncAll(Player session) {

            ScAdventureSyncAll adventure = new()
            {
                Exp = session.xp,
                Level = (int)session.level,

            };

            SetData(ScMsgId.ScAdventureSyncAll, adventure);
        }

    }
}
