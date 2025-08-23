using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScSyncGameMode : Packet
    {

        public PacketScSyncGameMode(Player client, string gamemode) {

            ScSyncGameMode proto = new ScSyncGameMode()
            {
                ModeId=gamemode,
                
            };

            SetData(ScMsgId.ScSyncGameMode, proto);
        }

    }
}
