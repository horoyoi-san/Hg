using Campofinale.Game;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScAchieveSync : Packet
    {

        public PacketScAchieveSync(Player client) {

            ScAchieveSync proto = new ScAchieveSync()
            {
                AchieveDisplayInfo = new()
                {
                    
                },
                AchievePublicInfos =
                {
                    
                }
            };
            SetData(ScMsgId.ScAchieveSync, proto);
        }

    }
}
