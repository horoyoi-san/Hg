using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScSyncAllUnlock : Packet
    {

        public PacketScSyncAllUnlock(Player client) {

            ScSyncAllUnlock unlock = new()
            {
                UnlockSystems = {client.unlockedSystems},
                
            };
            
            SetData(ScMsgId.ScSyncAllUnlock, unlock);
        }

    }
}
