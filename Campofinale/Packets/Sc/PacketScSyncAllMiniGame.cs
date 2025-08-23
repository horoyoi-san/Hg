using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScSyncAllMiniGame : Packet
    {

        public PacketScSyncAllMiniGame(Player client) {

            ScSyncAllMiniGame proto = new ScSyncAllMiniGame();
            SetData(ScMsgId.ScSyncAllMiniGame, proto);
        }

    }
}
