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
    public class PacketScSyncStamina : Packet
    {

        public PacketScSyncStamina(Player client) {
            ScSyncStamina proto = new ScSyncStamina()
            {
                CurStamina=client.curStamina,
                MaxStamina=client.maxStamina,
                NextRecoverTime=client.nextRecoverTime / 1000,
            };

            SetData(ScMsgId.ScSyncStamina, proto);
        }

    }
}
