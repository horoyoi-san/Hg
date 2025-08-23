using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScSyncAllMission : Packet
    {

        public PacketScSyncAllMission(Player client) {
            

            SetData(ScMsgId.ScSyncAllMission, client.missionSystem.ToProto());
        }

    }
}
