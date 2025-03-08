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
    public class PacketScBitsetAdd : Packet
    {

        public PacketScBitsetAdd(Player client, int type, List<uint> values) {

            ScBitsetAdd proto = new()
            {
                Type = type,
                Value =
                {
                    values
                }
            };
            
            SetData(ScMsgId.ScBitsetAdd, proto);
        }

    }
}
