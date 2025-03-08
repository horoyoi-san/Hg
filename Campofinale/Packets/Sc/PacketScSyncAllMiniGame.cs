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
    public class PacketScSyncAllMiniGame : Packet
    {

        public PacketScSyncAllMiniGame(Player client) {

            ScSyncAllMiniGame proto = new ScSyncAllMiniGame();
            SetData(ScMsgId.ScSyncAllMiniGame, proto);
        }

    }
}
