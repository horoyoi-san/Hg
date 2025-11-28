using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;

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
