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
    public class PacketScAdventureSyncAll : Packet
    {

        public PacketScAdventureSyncAll(Player session) {

            ScAdventureSyncAll adventure = new()
            {
                Exp = session.xp,
                Level = (int)session.level,

            };

            SetData(ScMsgId.ScAdventureSyncAll, adventure);
        }

    }
}
