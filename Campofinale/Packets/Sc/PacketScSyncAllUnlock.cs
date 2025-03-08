using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using static Campofinale.Resource.ResourceManager;

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
