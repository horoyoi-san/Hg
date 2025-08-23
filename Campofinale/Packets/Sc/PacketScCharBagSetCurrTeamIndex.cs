using Campofinale.Network;
using Campofinale.Protocol;

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
