using Campofinale.Network;
using Campofinale.Protocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

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
