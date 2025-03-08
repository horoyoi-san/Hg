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
    public class PacketScBitsetRemove : Packet
    {

        public PacketScBitsetRemove(Player client, int type, List<uint> values) {

            ScBitsetRemove proto = new()
            {
                Type = type,
                Value =
                {
                    values
                }
            };
            
            SetData(ScMsgId.ScBitsetRemove, proto);
        }

    }
}
