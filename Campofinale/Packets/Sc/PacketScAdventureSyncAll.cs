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
                WorldLevel=3,
                UnlockWorldLevel=3,
            };

            SetData(ScMsgId.ScAdventureSyncAll, adventure);
        }

    }
}
