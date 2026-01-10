using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScAdventureSyncAll : Packet
    {

        public PacketScAdventureSyncAll(Player session)
        {

            ScAdventureSyncAll adventure = new()
            {
                Exp = session.xp,
                Level = (int)session.level,
                WorldLevel = (int)session.worldLevel,
                UnlockWorldLevel = (int)session.unlockWorldLevel,
                LastSetWorldLevelTs = session.lastSetWorldLevelTs,
            };

            SetData(ScMsgId.ScAdventureSyncAll, adventure);
        }

    }
}
