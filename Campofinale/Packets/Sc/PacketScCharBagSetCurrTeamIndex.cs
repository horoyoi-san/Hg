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
    public class PacketScCharBagSetCurrTeamIndex : Packet
    {

        public PacketScCharBagSetCurrTeamIndex(Player client) {

            CsCharBagSetCurrTeamIndex proto = new()
            {
                LeaderId = client.teams[client.teamIndex].leader,
                TeamIndex=client.teamIndex,
            };
            SetData(ScMsgId.ScCharBagSetCurrTeamIndex, proto);
        }

    }
}
